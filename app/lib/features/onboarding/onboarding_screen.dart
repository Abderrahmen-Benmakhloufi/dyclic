import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../diagnostic/diagnostic_question_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  LearnerLevel _selectedLevel = LearnerLevel.moyen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Welcome header
              Row(
                children: [
                  AppAssetIcon(
                    assetPath: AppUiAssets.avatarForLevel(_selectedLevel),
                    size: 46,
                    fallbackEmoji: '👋',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bienvenue !',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Choisis ton niveau scolaire pour adapter tous les textes, la taille et les conseils :',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // 3 Mandatory Level Cards
              Expanded(
                child: ListView(
                  children: [
                    _buildLevelCard(
                      level: LearnerLevel.primaire,
                      assetPath: AppUiAssets.cyclePrimaire,
                      fallbackEmoji: '🎒',
                      title: 'Primaire',
                      subtitle: 'École primaire (Consolidation)',
                      description:
                          'Phrases courtes, repères visuels clairs et vocabulaire guidé.',
                    ),
                    const SizedBox(height: 14),
                    _buildLevelCard(
                      level: LearnerLevel.moyen,
                      assetPath: AppUiAssets.cycleCollege,
                      fallbackEmoji: '📚',
                      title: 'Moyen',
                      subtitle: 'Collège / Enseignement moyen (BEM / Brevet)',
                      description:
                          'Situations complexes, explications pas à pas et préparation aux épreuves.',
                    ),
                    const SizedBox(height: 14),
                    _buildLevelCard(
                      level: LearnerLevel.secondaire,
                      assetPath: AppUiAssets.cycleLycee,
                      fallbackEmoji: '🎓',
                      title: 'Lycée',
                      subtitle: 'Enseignement secondaire (Baccalauréat)',
                      description:
                          'Textes denses et argumentatifs, démarche réflexive et préparation au Bac.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Mandatory validation button
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(readingSettingsProvider.notifier)
                      .setLearnerLevel(_selectedLevel);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const DiagnosticQuestionScreen(),
                      ),
                    );
                  }
                },
                child: const Text('Commencer'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard({
    required LearnerLevel level,
    required String assetPath,
    required String fallbackEmoji,
    required String title,
    required String subtitle,
    required String description,
  }) {
    final isSelected = _selectedLevel == level;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedLevel = level;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cycle illustration badge
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlpha(20)
                    : const Color(0xFFF0EFEB),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: AppAssetIcon(
                assetPath: assetPath,
                size: 38,
                fallbackEmoji: fallbackEmoji,
              ),
            ),
            const SizedBox(width: 14),
            // Text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
