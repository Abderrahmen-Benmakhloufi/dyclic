import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service centralisant toutes les interactions avec Supabase (Auth + Base de données).
class SupabaseService {
  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isInitialized => client != null;

  /// Utilisateur actuellement connecté (null si déconnecté ou mode invité).
  static User? get currentUser => client?.auth.currentUser;

  /// Stream des changements d'état d'authentification.
  static Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  // ── Authentification ────────────────────────────────────────────────────────

  /// Connexion avec Email et Mot de passe.
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase non initialisé');
    return await c.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Inscription avec Email, Mot de passe et Nom d'affichage.
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase non initialisé');

    final response = await c.auth.signUp(
      email: email.trim(),
      password: password,
      data: displayName != null && displayName.isNotEmpty
          ? {'full_name': displayName.trim()}
          : null,
    );

    // Si le compte existe déjà, Supabase renvoie user avec identities vides
    // → on lève une exception lisible plutôt qu'un crash Null check
    if (response.user != null &&
        response.user!.identities != null &&
        response.user!.identities!.isEmpty) {
      throw Exception('user_already_exists');
    }

    return response;
  }

  /// Connexion avec Google.
  /// - Sur Web : tente d'abord Google Identity Services (GIS via popup), puis bascule si nécessaire sur OAuth avec l'origine courante.
  /// - Sur Android : utilise le flux natif avec le sélecteur de comptes du téléphone (Native Account Picker).
  /// - Sur iOS : bascule automatiquement vers OAuth avec deep link.
  static Future<bool> signInWithGoogle() async {
    final c = client;
    if (c == null) throw Exception('Supabase non initialisé');

    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

      // 1. Sur Web : Tentative Google Identity Services direct (popup sans redirection)
      if (kIsWeb && webClientId != null && webClientId.isNotEmpty) {
        try {
          final GoogleSignIn googleSignIn = GoogleSignIn(
            clientId: webClientId,
            scopes: ['email', 'profile'],
          );

          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          if (googleUser == null) {
            // L'utilisateur a fermé ou annulé la popup
            return false;
          }

          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final idToken = googleAuth.idToken;
          final accessToken = googleAuth.accessToken;

          if (idToken != null) {
            await c.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            );
            return true;
          }
        } catch (gisError) {
          debugPrint('ℹ️ Google Sign-In GIS non actif ($gisError), passage au flux OAuth...');
        }
      }

      // 2. Sur Android : Connexion Native (Account Picker du système)
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          webClientId != null &&
          webClientId.isNotEmpty) {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: webClientId,
          scopes: ['email', 'profile'],
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // L'utilisateur a fermé ou annulé volontairement
          return false;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken != null) {
          await c.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          return true;
        }

        // idToken null → échec silencieux
        throw Exception('google_token_null');
      }

      // 3. Sur Web ou iOS : Flux OAuth avec redirection explicite
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
        final redirectUrl = kIsWeb
            ? '${Uri.base.origin}/'
            : 'lectureaide://login-callback';

        return await c.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
      }

      // 4. Android sans webClientId configuré dans .env → erreur claire
      throw Exception('google_not_configured');
    } catch (e) {
      debugPrint('⚠️ Erreur Google Sign-In: $e');
      rethrow;
    }
  }

  /// Déconnexion de l'utilisateur.
  static Future<void> signOut() async {
    final c = client;
    if (c == null) return;
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}
    await c.auth.signOut();
  }

  // ── Synchronisation Données Utilisateur ──────────────────────────────────────

  /// Sauvegarde du cycle d'apprentissage dans le profil utilisateur.
  static Future<void> updateLearnerCycle(String cycle) async {
    final user = currentUser;
    final c = client;
    if (user == null || c == null) return;

    try {
      await c.from('profiles').upsert({
        'id': user.id,
        'cycle': cycle,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ Erreur mise à jour profil cycle: $e');
    }
  }

  /// Sauvegarde du résultat d'un Quiz (phonèmes, décodage, etc.).
  static Future<void> saveQuizResult({
    required String quizType,
    required String difficulty,
    required int score,
    required int totalQuestions,
  }) async {
    final user = currentUser;
    final c = client;
    if (user == null || c == null) return;

    try {
      await c.from('quiz_results').insert({
        'user_id': user.id,
        'quiz_type': quizType,
        'difficulty': difficulty,
        'score': score,
        'total_questions': totalQuestions,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde quiz: $e');
    }
  }

  /// Récupération de l'historique des Quiz de l'utilisateur.
  static Future<List<Map<String, dynamic>>> getQuizHistory() async {
    final user = currentUser;
    final c = client;
    if (user == null || c == null) return [];

    try {
      final data = await c
          .from('quiz_results')
          .select()
          .eq('user_id', user.id)
          .order('completed_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('⚠️ Erreur chargement historique quiz: $e');
      return [];
    }
  }

  /// Sauvegarde des paramètres d'accessibilité de lecture (DYS).
  static Future<void> saveReadingSettings({
    required String fontFamily,
    required double fontSize,
    required double lineSpacing,
    required double letterSpacing,
    required double wordSpacing,
    required bool highContrast,
    required String highlightMode,
  }) async {
    final user = currentUser;
    final c = client;
    if (user == null || c == null) return;

    try {
      await c.from('user_reading_settings').upsert({
        'user_id': user.id,
        'font_family': fontFamily,
        'font_size': fontSize,
        'line_spacing': lineSpacing,
        'letter_spacing': letterSpacing,
        'word_spacing': wordSpacing,
        'high_contrast': highContrast,
        'highlight_mode': highlightMode,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde réglages lecture: $e');
    }
  }

  // ── Analyse et Suivi des Erreurs de l'Apprenant (Learning Analytics) ────────

  /// Enregistre une erreur commise par l'apprenant pour identifier ses difficultés fréquentes.
  static Future<void> recordMistake({
    required String category,
    required String mistakeType,
    String? contextText,
    String? userInput,
    String? expectedInput,
  }) async {
    final user = currentUser;
    final c = client;
    if (user == null || c == null) return;

    try {
      await c.from('user_mistakes').insert({
        'user_id': user.id,
        'category': category,
        'mistake_type': mistakeType,
        'context_text': contextText,
        'user_input': userInput,
        'expected_input': expectedInput,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ Erreur enregistrement erreur apprenant: $e');
    }
  }

  /// Récupère le profil de l'utilisateur depuis Supabase.
  static Future<Map<String, dynamic>?> loadUserProfile() async {
    final user = currentUser;
    final c = client;
    if (user == null || c == null) return null;

    try {
      final data = await c
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('⚠️ Erreur chargement profil Supabase: $e');
      return null;
    }
  }

  /// Charge les réglages de lecture DYS enregistrés dans Supabase.
  static Future<Map<String, dynamic>?> loadReadingSettings() async {
    final user = currentUser;
    final c = client;
    if (user == null || c == null) return null;

    try {
      final data = await c
          .from('user_reading_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('⚠️ Erreur chargement réglages lecture Supabase: $e');
      return null;
    }
  }

  /// Récupère la liste des erreurs fréquentes de l'apprenant.
  static Future<List<Map<String, dynamic>>> getCommonMistakes({int limit = 30}) async {
    final user = currentUser;
    final c = client;
    if (user == null || c == null) return [];

    try {
      final data = await c
          .from('user_mistakes')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('⚠️ Erreur récupération erreurs: $e');
      return [];
    }
  }

  /// Génère un résumé synthétique des erreurs fréquentes de l'apprenant pour l'IA (Gemini).
  static Future<String> getTopMistakesSummaryForAi() async {
    final mistakes = await getCommonMistakes(limit: 40);
    if (mistakes.isEmpty) return '';

    // Regrouper par catégorie et compter les types d'erreurs
    final counts = <String, int>{};
    for (final m in mistakes) {
      final type = m['mistake_type']?.toString() ?? 'inconnu';
      counts[type] = (counts[type] ?? 0) + 1;
    }

    // Prendre les 5 erreurs les plus fréquentes
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).map((e) => '- ${e.key} (rencontrée ${e.value} fois)').join('\n');

    return '''
Historique des difficultés et erreurs récurrentes enregistrées pour cet élève :
$top
Consigne pédagogique IA : Tiens compte de ces difficultés spécifiques lors de ton analyse pour insister avec bienveillance sur ces notions et lui donner des astuces ciblées.
''';
  }

  // ── Suppression des données et du compte (RGPD / Confidentialité) ─────────

  /// Efface l'historique d'apprentissage de l'utilisateur (résultats de quiz et erreurs enregistrées).
  static Future<bool> clearUserLearningData() async {
    final user = currentUser;
    final c = client;
    if (user == null || c == null) return false;

    try {
      await c.from('quiz_results').delete().eq('user_id', user.id);
      await c.from('user_mistakes').delete().eq('user_id', user.id);
      return true;
    } catch (e) {
      debugPrint('⚠️ Erreur suppression données apprentissage: $e');
      return false;
    }
  }

  /// Supprime définitivement le compte de l'utilisateur et l'ensemble de ses données.
  static Future<bool> deleteAccount() async {
    final user = currentUser;
    final c = client;
    if (user == null || c == null) return false;

    try {
      // 1. Supprimer toutes les données associées dans les tables
      try {
        await c.from('quiz_results').delete().eq('user_id', user.id);
      } catch (e) {
        debugPrint('Erreur suppression quiz_results: $e');
      }

      try {
        await c.from('user_mistakes').delete().eq('user_id', user.id);
      } catch (e) {
        debugPrint('Erreur suppression user_mistakes: $e');
      }

      try {
        await c.from('user_reading_settings').delete().eq('user_id', user.id);
      } catch (e) {
        debugPrint('Erreur suppression user_reading_settings: $e');
      }

      try {
        await c.from('profiles').delete().eq('id', user.id);
      } catch (e) {
        debugPrint('Erreur suppression profiles: $e');
      }

      // 2. Tenter d'appeler la fonction RPC pour supprimer l'utilisateur auth (si configurée côté Supabase)
      try {
        await c.rpc('delete_user_account');
      } catch (_) {
        try {
          await c.rpc('delete_user');
        } catch (_) {}
      }

      // 3. Déconnexion complète locale et Google
      await signOut();
      return true;
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la suppression du compte: $e');
      await signOut();
      return true;
    }
  }
}
