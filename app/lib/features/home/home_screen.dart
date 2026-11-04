import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../reading_settings/reading_settings_sheet.dart';
import '../reading_support/calibration/reading_calibration_screen.dart';
import '../reading_support/reading_support_screen.dart';
import '../decoding/decoding_screen.dart';
import '../tts/tts_screen.dart';
import '../writing/writing_screen.dart';
import '../simplify/simplify_screen.dart';
import '../instructions/instructions_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readingSettingsProvider);
    final theme = Theme.of(context);

    final levelLabel = _getLevelLabel(settings.learnerLevel);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: InkWell(
          onTap: () => ReadingSettingsSheet.show(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  levelLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Réglages de lecture',
            onPressed: () => ReadingSettingsSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            // Greeting Header
            Text(
              'Bonjour 👋',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Que souhaitez-vous faire aujourd’hui ?',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // 1. M'aider à lire
            _buildFeatureCard(
              context: context,
              icon: '📖',
              title: 'M’aider à lire',
              description: 'Faciliter la lecture du texte.',
              onTap: () {
                final currentSettings = ref.read(readingSettingsProvider);
                if (!currentSettings.hasCompletedCalibration) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReadingCalibrationScreen(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReadingSupportScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 14),

            // Aide au décodage (Lettres et sons)
            _buildFeatureCard(
              context: context,
              icon: '🔤',
              title: 'Aide au décodage',
              description: 'Découvrir comment se prononcent les lettres et les sons.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DecodingScreen()),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Écouter le texte
            _buildFeatureCard(
              context: context,
              icon: '🔊',
              title: 'Écouter le texte',
              description: 'Écouter le texte à voix haute.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TtsScreen()),
              ),
            ),
            const SizedBox(height: 14),

            // 3. M'aider à écrire
            _buildFeatureCard(
              context: context,
              icon: '✏️',
              title: 'M’aider à écrire',
              description: 'Être accompagné pour réaliser une production écrite.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WritingScreen()),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Simplifier le texte
            _buildFeatureCard(
              context: context,
              icon: '📝',
              title: 'Simplifier le texte',
              description: 'Rendre le texte plus simple et plus facile à comprendre.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SimplifyScreen()),
              ),
            ),
            const SizedBox(height: 14),

            // 5. Expliquer la consigne
            _buildFeatureCard(
              context: context,
              icon: '💡',
              title: 'Expliquer la consigne',
              description: 'Comprendre ce qu’on me demande de faire.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InstructionsScreen()),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'v1.0.17',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder, width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7F4),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 16),
            // Text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelLabel(LearnerLevel level) {
    switch (level) {
      case LearnerLevel.primaire:
        return 'Primaire (5e AP)';
      case LearnerLevel.secondaire:
        return 'Secondaire (Lycée)';
      case LearnerLevel.moyen:
        return 'Moyen (Collège)';
    }
  }
}
