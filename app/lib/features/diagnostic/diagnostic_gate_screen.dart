import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learner_profile/learner_profile_notifier.dart';
import '../../core/theme/app_colors.dart';
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
                        child: const Center(
                          child: Text('📖', style: TextStyle(fontSize: 56)),
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
                    const SizedBox(height: 32),
                    // ── Choice cards ───────────────────────────────────────────
                    _ChoiceCard(
                      emoji: '📋',
                      iconBg: const Color(0xFFEDE9F6),
                      iconColor: AppColors.primary,
                      cardBorder: AppColors.primary,
                      cardBg: const Color(0xFFF5F2FC),
                      title: 'Oui, répondre au questionnaire',
                      subtitle: '24 questions · environ 5 minutes',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DiagnosticQuestionScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ChoiceCard(
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
                          Text(
                            "Aucune donnée personnelle n'est collectée",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
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
  final String emoji;
  final Color iconBg;
  final Color iconColor;
  final Color cardBorder;
  final Color cardBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
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
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
