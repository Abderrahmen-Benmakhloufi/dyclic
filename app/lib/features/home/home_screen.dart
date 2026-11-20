import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../../core/widgets/app_card_press_effect.dart';
import '../reading_settings/reading_settings_sheet.dart';
import '../reading_support/calibration/reading_calibration_screen.dart';
import '../reading_support/reading_support_screen.dart';
import '../decoding/decoding_screen.dart';
import '../tts/tts_screen.dart';
import '../writing/writing_screen.dart';
import '../simplify/simplify_screen.dart';
import '../instructions/instruction_ai_screen.dart';
import '../../core/services/cloud_sync_service.dart';
import 'widgets/app_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        CloudSyncService.syncFromCloud(ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final theme = Theme.of(context);

    final levelLabel = _getLevelLabel(settings.learnerLevel);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu principal',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
                Flexible(
                  child: Text(
                    levelLabel,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
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
            // Greeting Header with cycle-adapted mascot avatar
            Row(
              children: [
                AppAssetIcon(
                  assetPath: AppUiAssets.avatarForLevel(settings.learnerLevel),
                  size: 48,
                  fallbackEmoji: '👋',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour !',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Que souhaitez-vous faire aujourd’hui ?',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Section 1 : LECTURE & COMPRÉHENSION ──
            _buildSectionHeader('📖 Lecture & Compréhension'),
            const SizedBox(height: 12),

            // 1. M'aider à lire
            _buildFeatureCard(
              context: context,
              assetPath: AppUiAssets.featReading,
              fallbackEmoji: '📖',
              title: 'M’aider à lire',
              description: 'Faciliter la lecture et le confort visuel',
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
            const SizedBox(height: 12),

            // 2. Simplifier le texte
            _buildFeatureCard(
              context: context,
              assetPath: AppUiAssets.featSimplify,
              fallbackEmoji: '📝',
              title: 'Simplifier le texte',
              description: 'Rendre un texte plus court et accessible',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SimplifyScreen()),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Écouter le texte
            _buildFeatureCard(
              context: context,
              assetPath: AppUiAssets.featTts,
              fallbackEmoji: '🔊',
              title: 'Écouter le texte',
              description: 'Synthèse vocale mot à mot',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TtsScreen()),
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 2 : ÉCRITURE & RÉDACTION ──
            _buildSectionHeader('✏️ Écriture & Rédaction'),
            const SizedBox(height: 12),

            // 4. M'aider à écrire
            _buildFeatureCard(
              context: context,
              assetPath: AppUiAssets.featWriting,
              fallbackEmoji: '✏️',
              title: 'M’aider à écrire',
              description: 'Corriger et valoriser ma rédaction avec l\'IA',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WritingScreen()),
              ),
            ),
            const SizedBox(height: 12),

            // 5. Expliquer la consigne
            _buildFeatureCard(
              context: context,
              assetPath: AppUiAssets.featInstructions,
              fallbackEmoji: '💡',
              title: 'Expliquer la consigne',
              description: 'Comprendre le sujet d\'exercice pas à pas',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InstructionAiScreen()),
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 3 : DÉCODAGE & PHONÉTIQUE (Isolée en bas) ──
            _buildSectionHeader('🔤 Apprentissage des sons & Décodage'),
            const SizedBox(height: 12),

            // 6. Aide au décodage (Seule en bas)
            _buildFeatureCard(
              context: context,
              assetPath: AppUiAssets.featDecoding,
              fallbackEmoji: '🔤',
              title: 'Aide au décodage & Quiz',
              description:
                  'Découvrir comment se prononcent les lettres et les sons',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DecodingScreen()),
              ),
            ),
            const SizedBox(height: 20),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String assetPath,
    required String fallbackEmoji,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return AppCardPressEffect(
      onTap: onTap,
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
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7F4),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Hero(
                tag: 'hero_$assetPath',
                child: AppAssetIcon(
                  assetPath: assetPath,
                  size: 40,
                  fallbackEmoji: fallbackEmoji,
                ),
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
        return 'Primaire';
      case LearnerLevel.secondaire:
        return 'Lycée';
      case LearnerLevel.moyen:
        return 'Moyen';
    }
  }
}
