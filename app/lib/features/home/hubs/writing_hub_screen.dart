import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reading_settings/reading_settings_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_card_press_effect.dart';
import '../../instructions/instruction_ai_screen.dart';
import '../../reading_settings/reading_settings_sheet.dart';
import '../../writing/writing_screen.dart';

/// Hub screen for the "Écriture" bottom navigation tab.
/// Gives learners two clear writing options: assisted writing & feedback or instruction explanation.
class WritingHubScreen extends ConsumerWidget {
  const WritingHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readingSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Écriture & Rédaction',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Banner ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const AppAssetIcon(
                        assetPath: AppUiAssets.featWriting,
                        size: 34,
                        fallbackEmoji: '✏️',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Espace Écriture',
                            style: TextStyle(
                              fontFamily: settings.fontFamily,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Rédige en toute confiance avec l\'aide de l\'IA et décortique tes consignes scolaires.',
                            style: TextStyle(
                              fontFamily: settings.fontFamily,
                              fontSize: 12.5,
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

              const SizedBox(height: 20),

              // ── Option 1: M'aider à écrire ──────────────────────────────
              _WritingHubCard(
                assetPath: AppUiAssets.featWriting,
                fallbackEmoji: '✏️',
                title: 'M’aider à écrire',
                description:
                    'Correction bienveillante de tes textes, détection des confusions phonétiques et valorisation de tes réussites.',
                accentColor: const Color(0xFFE65100),
                fontFamily: settings.fontFamily,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WritingScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // ── Option 2: Expliquer la consigne ─────────────────────────
              _WritingHubCard(
                assetPath: AppUiAssets.featInstructions,
                fallbackEmoji: '💡',
                title: 'Expliquer la consigne',
                description:
                    'Comprendre ce que demande un exercice scolaire pas à pas, avec repérage des verbes d\'action.',
                accentColor: const Color(0xFFF59E0B),
                fontFamily: settings.fontFamily,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const InstructionAiScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WritingHubCard extends StatelessWidget {
  final String assetPath;
  final String fallbackEmoji;
  final String title;
  final String description;
  final Color accentColor;
  final String fontFamily;
  final VoidCallback onTap;

  const _WritingHubCard({
    required this.assetPath,
    required this.fallbackEmoji,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.fontFamily,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCardPressEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
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
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Hero(
                  tag: 'hero_$assetPath',
                  child: AppAssetIcon(
                    assetPath: assetPath,
                    size: 40,
                    fallbackEmoji: fallbackEmoji,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: accentColor,
            ),
          ],
        ),
      ),
    );
  }
}
