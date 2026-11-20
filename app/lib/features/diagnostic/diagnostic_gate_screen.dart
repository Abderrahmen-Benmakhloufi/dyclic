import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learner_profile/learner_profile_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../home/main_navigation_scaffold.dart';
import 'diagnostic_question_screen.dart';

// ---------------------------------------------------------------------------
// DiagnosticGateScreen — Screen 1: "Do you have difficulties?"
// ---------------------------------------------------------------------------

class DiagnosticGateScreen extends ConsumerWidget {
  const DiagnosticGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                tooltip: 'Retour',
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    // ── Illustration ───────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9F6),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Center(
                          child: Image.asset(
                            AppUiAssets.appLogo,
                            width: 76,
                            height: 76,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // ── Main question ──────────────────────────────────────────
                    Text(
                      'As-tu des difficultés en lecture ou en écriture ?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Cette évaluation nous aide à adapter l'application à tes besoins. Tes réponses restent privées sur ton appareil.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ce test est uniquement informatif. Il ne constitue en aucun cas un diagnostic médical. Seul un professionnel de santé qualifié peut poser un diagnostic.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ── Choice cards ───────────────────────────────────────────
                    _ChoiceCard(
                      assetPath: AppUiAssets.clipboardQuiz,
                      emoji: '📋',
                      iconBg: const Color(0xFFEDE9F6),
                      iconColor: AppColors.primary,
                      cardBorder: AppColors.primary,
                      cardBg: const Color(0xFFF5F2FC),
                      title: 'Oui, répondre au questionnaire',
                      subtitle: '23 questions · environ 5 minutes',
                      onTap: () async {
                        final currentProfile = ref.read(learnerProfileProvider);
                        if (currentProfile.isDiagnosticDone) {
                          final proceed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange, size: 24),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Refaire le diagnostic ?',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              content: const Text(
                                'Tu as déjà un profil diagnostique enregistré. Si tu refais le questionnaire, tes réponses précédentes seront remplacées par les nouvelles.\n\nSouhaites-tu continuer ?',
                                style: TextStyle(fontSize: 13.5, height: 1.45),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Oui, recommencer'),
                                ),
                              ],
                            ),
                          );
                          if (proceed != true) return;
                        }

                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DiagnosticQuestionScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _ChoiceCard(
                      assetPath: AppUiAssets.rocketFast,
                      emoji: '🚀',
                      iconBg: const Color(0xFFEAF2EC),
                      iconColor: const Color(0xFF3C6B4E),
                      cardBorder: AppColors.secondary,
                      cardBg: const Color(0xFFF1F6F2),
                      title: 'Non, commencer directement',
                      subtitle: 'Tu pourras répondre plus tard dans les paramètres.',
                      onTap: () async {
                        await ref
                            .read(learnerProfileProvider.notifier)
                            .skipDiagnostic();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const MainNavigationScaffold(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    // ── Privacy note ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Aucune donnée personnelle n'est collectée",
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ChoiceCard — reusable interactive choice card
// ---------------------------------------------------------------------------

class _ChoiceCard extends StatelessWidget {
  final String? assetPath;
  final String emoji;
  final Color iconBg;
  final Color iconColor;
  final Color cardBorder;
  final Color cardBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    this.assetPath,
    required this.emoji,
    required this.iconBg,
    required this.iconColor,
    required this.cardBorder,
    required this.cardBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border.all(color: cardBorder, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: assetPath != null
                      ? AppAssetIcon(
                          assetPath: assetPath!,
                          size: 28,
                          fallbackEmoji: emoji,
                        )
                      : Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(Icons.chevron_right,
                  color: AppColors.textSecondary.withValues(alpha: 0.6), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
