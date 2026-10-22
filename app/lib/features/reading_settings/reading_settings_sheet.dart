import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';

class ReadingSettingsSheet extends ConsumerWidget {
  const ReadingSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReadingSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readingSettingsProvider);
    final notifier = ref.read(readingSettingsProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Réglages de lecture',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => notifier.resetToDefaults(),
                    child: const Text('Rétablir'),
                  ),
                ],
              ),
              const Divider(height: 20),

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

              // 6. Level Switcher
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

              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer les réglages'),
              ),
            ],
          ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
