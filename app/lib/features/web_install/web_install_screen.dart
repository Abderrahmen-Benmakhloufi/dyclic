import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_asset_icon.dart';

/// Screen displayed automatically for users accessing the app via Web browsers.
/// Explains how to add AideLecture to the home screen on iOS (Safari) and Android,
/// followed by a prominent button to proceed into the application.
class WebInstallPromptScreen extends StatelessWidget {
  final VoidCallback onProceed;

  const WebInstallPromptScreen({
    super.key,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E1B2E) : const Color(0xFFF8F7F4);
    final cardBg = isDark ? const Color(0xFF2A2640) : Colors.white;
    final textCol = isDark ? Colors.white : AppColors.textPrimary;
    final subTextCol =
        isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo & Title Header ──────────────────────────────────────
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Image(
                        image: AssetImage(AppUiAssets.appLogo),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bienvenue sur AideLecture',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textCol,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ton assistant inclusif pour lire, comprendre et écrire sereinement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: subTextCol,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Install Hint Card ─────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '📲 Installer l’application',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ajouter AideLecture à votre écran d’accueil',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pour une utilisation plein écran rapide et confortable (comme une vraie application, avec le son et sans barre de navigateur) :',
                          style: TextStyle(
                            fontSize: 13,
                            color: subTextCol,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section Safari iOS
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1B2E)
                                : const Color(0xFFF3F0FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    '🍎 Sur iPhone ou iPad (Safari) :',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildStep(
                                number: '1',
                                title: 'Appuyez sur le bouton Partager',
                                detail:
                                    'L’icône avec un carré et une flèche vers le haut ⎋ (en bas ou en haut de Safari).',
                                textCol: textCol,
                                subCol: subTextCol,
                              ),
                              const SizedBox(height: 8),
                              _buildStep(
                                number: '2',
                                title: 'Sélectionnez « Sur l’écran d’accueil »',
                                detail:
                                    'Faites défiler le menu vers le bas et touchez « Sur l’écran d’accueil » ➕.',
                                textCol: textCol,
                                subCol: subTextCol,
                              ),
                              const SizedBox(height: 8),
                              _buildStep(
                                number: '3',
                                title: 'Touchez « Ajouter »',
                                detail:
                                    'En haut à droite de l’écran. L’icône apparaîtra sur votre écran d’accueil !',
                                textCol: textCol,
                                subCol: subTextCol,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Section Android / Chrome
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF221F33)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('🤖 ', style: TextStyle(fontSize: 18)),
                              Expanded(
                                child: Text(
                                  'Sur Android (Chrome) : Touchez le menu ⋮ en haut à droite puis « Ajouter à l’écran d’accueil » ou « Installer ».',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subTextCol,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Button to Proceed ─────────────────────────────────────────
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor:
                            AppColors.primary.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Accéder à l’application',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Gratuit • Sans inscription obligatoire • Conforme RGPD',
                      style: TextStyle(
                        fontSize: 11,
                        color: subTextCol.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String detail,
    required Color textCol,
    required Color subCol,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textCol,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  color: subCol,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
