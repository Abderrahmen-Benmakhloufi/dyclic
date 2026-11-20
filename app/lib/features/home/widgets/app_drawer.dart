import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/reading_settings/reading_settings_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../about/about_us_screen.dart';
import '../../decoding/decoding_screen.dart';
import '../../instructions/instruction_ai_screen.dart';
import '../../reading_settings/reading_settings_sheet.dart';
import '../../reading_support/calibration/reading_calibration_screen.dart';
import '../../reading_support/reading_support_screen.dart';
import '../../simplify/simplify_screen.dart';
import '../../tts/tts_screen.dart';
import '../../writing/writing_screen.dart';

class AppDrawer extends ConsumerWidget {
  final VoidCallback? onHomeSelected;

  const AppDrawer({
    super.key,
    this.onHomeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readingSettingsProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      AppUiAssets.appLogo,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AideLecture',
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Français inclusif & DYS',
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Features List (with large font) ──────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                children: [
                  // Accueil
                  _buildLargeDrawerItem(
                    context: context,
                    icon: Icons.home_rounded,
                    iconColor: AppColors.primary,
                    title: 'Accueil',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onHomeSelected != null) onHomeSelected!();
                    },
                    fontFamily: settings.fontFamily,
                  ),

                  const SizedBox(height: 10),

                  // ── Catégorie : LECTURE ──
                  _buildDrawerSectionHeader('LECTURE'),
                  const SizedBox(height: 4),

                  // M'aider à lire
                  _buildLargeDrawerItem(
                    context: context,
                    assetPath: AppUiAssets.featReading,
                    iconColor: const Color(0xFF6B5B95),
                    title: 'M\'aider à lire',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => settings.hasCompletedCalibration
                              ? const ReadingSupportScreen()
                              : const ReadingCalibrationScreen(),
                        ),
                      );
                    },
                    fontFamily: settings.fontFamily,
                  ),

                  const SizedBox(height: 4),

                  // Aide au décodage
                  _buildLargeDrawerItem(
                    context: context,
                    assetPath: AppUiAssets.featDecoding,
                    iconColor: const Color(0xFF8E24AA),
                    title: 'Aide au décodage',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DecodingScreen(),
                        ),
                      );
                    },
                    fontFamily: settings.fontFamily,
                  ),

                  const SizedBox(height: 4),

                  // Simplifier le texte
                  _buildLargeDrawerItem(
                    context: context,
                    assetPath: AppUiAssets.featSimplify,
                    iconColor: const Color(0xFFE65100),
                    title: 'Simplifier le texte',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SimplifyScreen(),
                        ),
                      );
                    },
                    fontFamily: settings.fontFamily,
                  ),

                  const SizedBox(height: 4),

                  // Écouter le texte
                  _buildLargeDrawerItem(
                    context: context,
                    assetPath: AppUiAssets.featTts,
                    iconColor: const Color(0xFF1976D2),
                    title: 'Écouter le texte',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TtsScreen(),
                        ),
                      );
                    },
                    fontFamily: settings.fontFamily,
                  ),

                  const SizedBox(height: 10),

                  // ── Catégorie : ÉCRITURE ──
                  _buildDrawerSectionHeader('ÉCRITURE'),
                  const SizedBox(height: 4),

                  // M'aider à écrire
                  _buildLargeDrawerItem(
                    context: context,
                    assetPath: AppUiAssets.featWriting,
                    iconColor: const Color(0xFF2E7D32),
                    title: 'M\'aider à écrire',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WritingScreen(),
                        ),
                      );
                    },
                    fontFamily: settings.fontFamily,
                  ),

                  const SizedBox(height: 4),

                  // Expliquer une consigne
                  _buildLargeDrawerItem(
                    context: context,
                    assetPath: AppUiAssets.featInstructions,
                    iconColor: const Color(0xFF00897B),
                    title: 'Expliquer une consigne',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InstructionAiScreen(),
                        ),
                      );
                    },
                    fontFamily: settings.fontFamily,
                  ),
                ],
              ),
            ),

            // ── Foyer / Espace / Séparateur ───────────────────────────────
            const Divider(height: 1, color: AppColors.cardBorder),

            // ── Bas du Drawer (Paramètres & About Us) ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                children: [
                  // Écran À propos
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    title: Text(
                      'À propos',
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutUsScreen(),
                        ),
                      );
                    },
                  ),

                  // Réglages (titre plus petit)
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      'Réglages & Affichage',
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      ReadingSettingsSheet.show(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLargeDrawerItem({
    required BuildContext context,
    IconData? icon,
    String? assetPath,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    required String fontFamily,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: assetPath != null
            ? AppAssetIcon(assetPath: assetPath, size: 19)
            : Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      onTap: onTap,
    );
  }
}
