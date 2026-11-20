import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learner_profile/learner_profile_notifier.dart';
import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../auth/login_screen.dart';
import '../diagnostic/diagnostic_question_screen.dart';
import '../diagnostic/diagnostic_result_screen.dart';
import '../reading_settings/reading_settings_sheet.dart';

/// Screen displaying the learner profile, DYS diagnostic adaptations,
/// educational level, accessibility preferences, and account management.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getCycleLabel(LearnerLevel level) {
    switch (level) {
      case LearnerLevel.primaire:
        return 'Primaire';
      case LearnerLevel.secondaire:
        return 'Lycée';
      case LearnerLevel.moyen:
        return 'Moyen';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readingSettingsProvider);
    final profile = ref.watch(learnerProfileProvider);
    final user = SupabaseService.currentUser;

    final displayName = user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@').first ??
        'Apprenant';
    final email = user?.email ?? 'Compte invité (hors-ligne)';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Réglages d\'affichage',
            onPressed: () => ReadingSettingsSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Carte En-tête Utilisateur ───────────────────────────
              _buildUserHeaderCard(
                context: context,
                displayName: displayName,
                email: email,
                avatarUrl: avatarUrl,
                settings: settings,
              ),

              const SizedBox(height: 20),

              // ── 2. Carte Bilan & Diagnostic DYS ────────────────────────
              _buildDiagnosticCard(
                context: context,
                ref: ref,
                profile: profile,
                fontFamily: settings.fontFamily,
              ),

              const SizedBox(height: 20),

              // ── 3. Carte Groupée Préférences & Suivi ───────────────────
              _buildPreferencesGroupCard(
                context: context,
                ref: ref,
                settings: settings,
              ),

              const SizedBox(height: 20),

              // ── 4. Carte Compte & Sécurité ─────────────────────────────
              _buildAccountCard(
                context: context,
                ref: ref,
                user: user,
                fontFamily: settings.fontFamily,
              ),

              const SizedBox(height: 24),

              // ── 5. Pied de page discret ────────────────────────────────
              Center(
                child: Text(
                  'Mon Assistant Français • v1.0.17',
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeaderCard({
    required BuildContext context,
    required String displayName,
    required String email,
    required String? avatarUrl,
    required ReadingSettings settings,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(20),
              border: Border.all(color: AppColors.primary.withAlpha(40), width: 1.5),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackAvatar(settings),
                    )
                  : _buildFallbackAvatar(settings),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: 17.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppAssetIcon(
                        assetPath: AppUiAssets.cycleForLevel(settings.learnerLevel),
                        size: 16,
                        fallbackEmoji: '🎓',
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _getCycleLabel(settings.learnerLevel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(ReadingSettings settings) {
    return Center(
      child: AppAssetIcon(
        assetPath: AppUiAssets.avatarForLevel(settings.learnerLevel),
        size: 38,
        fallbackEmoji: '👤',
      ),
    );
  }

  Widget _buildDiagnosticCard({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic profile,
    required String fontFamily,
  }) {
    final isDone = profile.isDiagnosticDone as bool;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const AppAssetIcon(
                  assetPath: AppUiAssets.brainMind,
                  size: 28,
                  fallbackEmoji: '🧠',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil cognitif & DYS',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDone
                            ? '✓ Adaptations actives'
                            : '• Diagnostic à réaliser',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? const Color(0xFF2E7D32)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isDone
                ? 'Tes réglages et adaptations spécifiques sont automatiquement pris en compte pour tous tes exercices.'
                : 'Passe le questionnaire rapide pour permettre à l\'application d\'adapter sa lecture et son écriture à tes besoins.',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 17),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Voir le bilan'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      if (isDone) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DiagnosticResultScreen(profile: profile),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DiagnosticQuestionScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Refaire'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DiagnosticQuestionScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesGroupCard({
    required BuildContext context,
    required WidgetRef ref,
    required ReadingSettings settings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Préférences & Suivi',
            style: TextStyle(
              fontFamily: settings.fontFamily,
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Niveau scolaire
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_outlined, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  'Niveau scolaire',
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _getCycleLabel(settings.learnerLevel),
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => _showCyclePicker(context, ref, settings.learnerLevel),
              ),

              const Divider(height: 1, indent: 56, endIndent: 16),

              // 2. Police & Confort
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.format_size_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                title: Text(
                  'Police & Confort visuel',
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${settings.fontFamily} • ${settings.fontSize.toInt()} pt',
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => ReadingSettingsSheet.show(context),
              ),

              const Divider(height: 1, indent: 56, endIndent: 16),

              // 3. Historique & Erreurs
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.insights_rounded, color: Color(0xFFE65100), size: 20),
                ),
                title: Text(
                  'Résultats & Historique des erreurs',
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Sauvegardés pour personnaliser tes révisions',
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE65100),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _confirmClearLearningData(context),
                  child: const Text(
                    'Effacer',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic user,
    required String fontFamily,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Compte & Sécurité',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: user != null
              ? Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBorder.withAlpha(90),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
                      ),
                      title: Text(
                        'Se déconnecter',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () async {
                        await SupabaseService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: AppColors.errorRed, size: 20),
                      ),
                      title: Text(
                        'Supprimer mon compte',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.errorRed,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.errorRed),
                      onTap: () => _confirmDeleteAccount(context, ref),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text(
                        'Se connecter / Créer un compte',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmClearLearningData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_outlined, color: Color(0xFFE65100)),
            SizedBox(width: 10),
            Expanded(child: Text('Effacer l\'historique ?')),
          ],
        ),
        content: const Text(
          'Tous vos résultats de quiz et l\'historique de vos erreurs d\'apprentissage enregistrées sur votre compte seront définitivement effacés.\n\nVotre profil et vos réglages de lecture seront conservés.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await SupabaseService.clearUserLearningData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Vos résultats et l\'historique de vos erreurs ont été effacés avec succès.'
                  : 'Une erreur est survenue lors de l\'effacement.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRed),
            SizedBox(width: 10),
            Expanded(child: Text('Supprimer définitivement le compte ?')),
          ],
        ),
        content: const Text(
          'Attention : Cette action est irréversible !\n\nToutes vos données personnelles, vos résultats, vos erreurs d\'apprentissage enregistrées et vos réglages de lecture seront définitivement effacés.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await SupabaseService.deleteAccount();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Votre compte et vos données ont été définitivement supprimés.'
                  : 'Compte déconnecté. Vos données ont été nettoyées.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showCyclePicker(BuildContext context, WidgetRef ref, LearnerLevel current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choisir le cycle scolaire',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...LearnerLevel.values.map((lvl) {
                final isSelected = lvl == current;
                return ListTile(
                  title: Text(_getCycleLabel(lvl)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected ? AppColors.primary.withAlpha(20) : null,
                  onTap: () {
                    ref.read(readingSettingsProvider.notifier).setLearnerLevel(lvl);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
