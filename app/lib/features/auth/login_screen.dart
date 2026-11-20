import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../home/main_navigation_scaffold.dart';
class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLoginSuccess;
  final bool isDismissible;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    this.isDismissible = true,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        final response = await SupabaseService.signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );

        // Si session est null → Supabase attend une confirmation par email
        if (response.session == null) {
          if (mounted) {
            setState(() => _isLoading = false);
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Vérifiez votre email 📬'),
                content: Text(
                  'Un lien de confirmation a été envoyé à ${_emailController.text.trim()}.\n\n'
                  'Cliquez sur le lien dans l\'email pour activer votre compte, puis connectez-vous.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() => _isSignUp = false);
                    },
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            );
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé avec succès ! Bienvenue.'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } else {
        await SupabaseService.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion réussie !'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }

      // Synchronisation immédiate des données et de l'historique d'erreurs
      try {
        await CloudSyncService.syncFromCloud(ref);
      } catch (syncError) {
        debugPrint('⚠️ Sync cloud ignorée après connexion: $syncError');
      }

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const MainNavigationScaffold(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e, stack) {
      debugPrint('❌ Erreur authentification email: $e\n$stack');
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await SupabaseService.signInWithGoogle();
      if (success) {
        try {
          await CloudSyncService.syncFromCloud(ref);
        } catch (syncError) {
          debugPrint('⚠️ Sync cloud ignorée après Google Sign-In: $syncError');
        }
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const MainNavigationScaffold(),
            ),
            (route) => false,
          );
        }
      }
      // success == false → l'utilisateur a annulé, on ne fait rien (pas d'erreur)
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyErrorMessage(String raw) {
    final lower = raw.toLowerCase();

    // Problèmes de réseau / connexion Internet / Timeout
    if (lower.contains('socketexception') ||
        lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('connection closed') ||
        lower.contains('clientexception') ||
        lower.contains('timeout') ||
        lower.contains('handshake') ||
        lower.contains('offline')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion Internet et réessayez.';
    }

    // Identifiants incorrects
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Email ou mot de passe incorrect. Vérifiez vos identifiants.';
    }

    // Compte déjà existant lors de l'inscription
    if (lower.contains('user already registered') ||
        lower.contains('user_already_exists') ||
        lower.contains('already in use') ||
        lower.contains('already_exists')) {
      return 'Un compte existe déjà avec cette adresse email. Touchez "Déjà inscrit ? Se connecter" ci-dessous.';
    }

    // Null check interne (compte existant ou session non créée)
    if (lower.contains('null check operator') ||
        lower.contains('null_check') ||
        lower.contains('google_token_null')) {
      return 'Une erreur inattendue est survenue. Si vous avez déjà un compte, essayez de vous connecter. Sinon, réessayez dans quelques instants.';
    }

    // Google non configuré
    if (lower.contains('google_not_configured')) {
      return 'La connexion Google n\'est pas disponible sur cet appareil. Utilisez votre email pour vous connecter.';
    }

    // Email invalide
    if (lower.contains('invalid email') ||
        lower.contains('unable to validate email address') ||
        lower.contains('email address is invalid')) {
      return 'Veuillez saisir une adresse email valide.';
    }

    // Mot de passe trop court ou trop faible
    if (lower.contains('password should be at least') ||
        lower.contains('weak_password')) {
      return 'Le mot de passe doit comporter au moins 6 caractères.';
    }

    // Trop de tentatives (Rate limit)
    if (lower.contains('too many requests') ||
        lower.contains('rate limit') ||
        lower.contains('over_request_rate_limit')) {
      return 'Trop de tentatives en peu de temps. Veuillez patienter un instant avant de réessayer.';
    }

    // Erreur de redirection Google Cloud OAuth
    if (lower.contains('redirect_uri_mismatch') ||
        lower.contains('redirect_uri')) {
      return 'Configuration Google Cloud requise : ajoutez l\'URI https://ohllztkenhpxiosekddf.supabase.co/auth/v1/callback dans la console Google Cloud. Vous pouvez vous connecter immédiatement par email ou continuer en mode invité.';
    }

    // Erreur de configuration Google OAuth
    if (lower.contains('10') ||
        lower.contains('sign_in_failed') ||
        lower.contains('sign_in_canceled') ||
        lower.contains('google')) {
      return 'La connexion avec Google est momentanément indisponible. Vous pouvez vous connecter par email ou continuer en mode invité.';
    }

    // Email non confirmé si Supabase requiert confirmation
    if (lower.contains('email not confirmed')) {
      return 'Veuillez confirmer votre adresse email en cliquant sur le lien reçu dans votre boîte de réception.';
    }

    // Erreurs d'annulation utilisateur
    if (lower.contains('canceled') || lower.contains('cancelled')) {
      return 'Connexion annulée.';
    }

    // Erreur générique propre et rassurante
    return 'Une difficulté temporaire est survenue lors de la connexion. Vous pouvez continuer en mode invité ou réessayer dans quelques instants.';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isSignUp ? 'Créer un compte' : 'Connexion',
          style: TextStyle(
            fontFamily: settings.fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: widget.isDismissible && Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icône et Titre
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_circle,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mon Espace Personnel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sauvegardez vos progrès, vos réglages personnalisés et retrouvez-les sur tous vos appareils.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Message d'erreur s'il y en a un
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontFamily: settings.fontFamily,
                                  color: AppColors.errorRed,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Bouton Google Sign-In
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFD0D7DE), width: 1.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                            height: 22,
                            width: 22,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata,
                              size: 26,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Continuer avec Google',
                              style: TextStyle(
                                fontFamily: settings.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Séparateur "ou"
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ou avec un email',
                            style: TextStyle(
                              fontFamily: settings.fontFamily,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Champ Nom (uniquement pour inscription)
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Prénom ou Pseudo',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir votre prénom ou pseudo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Champ Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Adresse email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir une adresse email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Format d\'email non valide';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Champ Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir un mot de passe';
                        }
                        if (value.length < 6) {
                          return 'Minimum 6 caractères';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 22),

                    // Bouton de validation Email
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isSignUp ? 'Créer mon compte' : 'Se connecter',
                              style: TextStyle(
                                fontFamily: settings.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    const SizedBox(height: 14),

                    // Basculer Connexion / Inscription
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                              });
                            },
                      child: Text(
                        _isSignUp
                            ? 'Déjà inscrit ? Se connecter'
                            : 'Nouveau ici ? Créer un compte',
                        style: TextStyle(
                          fontFamily: settings.fontFamily,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Mode Invité
                    if (widget.isDismissible) ...[
                      OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (widget.onLoginSuccess != null) {
                                  widget.onLoginSuccess!();
                                } else {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const MainNavigationScaffold(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Continuer sans compte (Mode Invité)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
