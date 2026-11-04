import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../diagnostics/tts_diagnostics_screen.dart';
import '../reading_support/calibration/reading_calibration_screen.dart';

class ReadingSettingsSheet extends ConsumerWidget {
  final bool halfScreen;

  const ReadingSettingsSheet({
    super.key,
    this.halfScreen = false,
  });

  static Future<void> show(BuildContext context, {bool halfScreen = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: halfScreen
          ? Colors.black.withValues(alpha: 0.15)
          : Colors.black54,
      builder: (_) => ReadingSettingsSheet(halfScreen: halfScreen),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readingSettingsProvider);
    final notifier = ref.read(readingSettingsProvider.notifier);
    final screenHeight = MediaQuery.of(context).size.height;

    final scrollableBody = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Font Size Control: − A +
          _buildStepControl(
            label: 'Taille du texte',
            currentValueText: '${settings.fontSize.toInt()} px',
            onDecrement: () => notifier.setFontSize(settings.fontSize - 2),
            onIncrement: () => notifier.setFontSize(settings.fontSize + 2),
          ),
          const SizedBox(height: 12),

          // 2. Line Height Control: − ↕ +
          _buildStepControl(
            label: 'Espacement des lignes',
            currentValueText: settings.lineHeight.toStringAsFixed(1),
            onDecrement: () => notifier.setLineHeight(settings.lineHeight - 0.1),
            onIncrement: () => notifier.setLineHeight(settings.lineHeight + 0.1),
          ),
          const SizedBox(height: 12),

          // 3. Letter Spacing Control: − AB +
          _buildStepControl(
            label: 'Espacement des lettres',
            currentValueText: settings.letterSpacing.toStringAsFixed(1),
            onDecrement: () => notifier.setLetterSpacing(settings.letterSpacing - 0.2),
            onIncrement: () => notifier.setLetterSpacing(settings.letterSpacing + 0.2),
          ),
          const SizedBox(height: 18),

          // 4. Font Choice
          const Text(
            'Type de police',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFontChoiceChip(
                label: 'Atkinson Hyperlegible',
                isSelected: settings.fontFamily == 'Atkinson Hyperlegible',
                onSelected: () => notifier.setFontFamily('Atkinson Hyperlegible'),
              ),
              _buildFontChoiceChip(
                label: 'Lexend',
                isSelected: settings.fontFamily == 'Lexend',
                onSelected: () => notifier.setFontFamily('Lexend'),
              ),
              _buildFontChoiceChip(
                label: 'Système',
                isSelected: settings.fontFamily == 'System',
                onSelected: () => notifier.setFontFamily('System'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 5. Contrast Mode
          const Text(
            'Couleur de lecture',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildContrastColorOption(
                title: 'Crème',
                bgColor: AppColors.background,
                textColor: AppColors.textPrimary,
                isSelected: settings.contrastPreset == ContrastPreset.creme,
                onTap: () => notifier.setContrastPreset(ContrastPreset.creme),
              ),
              const SizedBox(width: 8),
              _buildContrastColorOption(
                title: 'Clair',
                bgColor: const Color(0xFFF8FAFC),
                textColor: const Color(0xFF1E293B),
                isSelected: settings.contrastPreset == ContrastPreset.clair,
                onTap: () => notifier.setContrastPreset(ContrastPreset.clair),
              ),
              const SizedBox(width: 8),
              _buildContrastColorOption(
                title: 'Pastel',
                bgColor: AppColors.bluePastelBackground,
                textColor: const Color(0xFF1E293B),
                isSelected: settings.contrastPreset == ContrastPreset.bleu,
                onTap: () => notifier.setContrastPreset(ContrastPreset.bleu),
              ),
              const SizedBox(width: 8),
              _buildContrastColorOption(
                title: 'Sombre',
                bgColor: AppColors.darkBackground,
                textColor: AppColors.darkTextPrimary,
                isSelected: settings.contrastPreset == ContrastPreset.sombre,
                onTap: () => notifier.setContrastPreset(ContrastPreset.sombre),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 6. Syllable Colors Count (2, 3 ou 4 couleurs distinctes)
          const Text(
            'Couleurs des syllabes (alternance)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 2,
                label: Text('2 couleurs'),
              ),
              ButtonSegment(
                value: 3,
                label: Text('3 couleurs'),
              ),
              ButtonSegment(
                value: 4,
                label: Text('4 couleurs'),
              ),
            ],
            selected: {settings.syllableColorCount},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                notifier.setSyllableColorCount(set.first);
              }
            },
          ),
          const SizedBox(height: 20),

          // 7. Level Switcher
          const Text(
            'Niveau scolaire actuel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<LearnerLevel>(
            segments: const [
              ButtonSegment(
                value: LearnerLevel.primaire,
                label: Text('Primaire'),
              ),
              ButtonSegment(
                value: LearnerLevel.moyen,
                label: Text('Moyen'),
              ),
              ButtonSegment(
                value: LearnerLevel.secondaire,
                label: Text('Secondaire'),
              ),
            ],
            selected: {settings.learnerLevel},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                notifier.setLearnerLevel(set.first);
              }
            },
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: const Text('Assistant de calibrage personnalisé'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReadingCalibrationScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            icon: const Icon(Icons.volume_up_rounded, size: 18),
            label: const Text('Tester le son / Diagnostic vocal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade700,
              side: BorderSide(color: Colors.blue.shade300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TtsDiagnosticsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer les réglages'),
          ),
        ],
      ),
    );

    return Container(
      height: halfScreen ? screenHeight * 0.52 : null,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: halfScreen ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title bar with reset and close buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Réglages de lecture',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => notifier.resetToDefaults(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Rétablir'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      tooltip: 'Fermer',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),

            // Body
            if (halfScreen)
              Expanded(child: scrollableBody)
            else
              scrollableBody,
          ],
        ),
      ),
    );
  }

  Widget _buildStepControl({
    required String label,
    required String currentValueText,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
                onPressed: onDecrement,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 50),
                alignment: Alignment.center,
                child: Text(
                  currentValueText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                onPressed: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withAlpha(35),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildContrastColorOption({
    required String title,
    required Color bgColor,
    required Color textColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withAlpha(200),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
