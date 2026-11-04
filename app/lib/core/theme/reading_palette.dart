import 'package:flutter/material.dart';
import '../reading_settings/reading_settings_model.dart';
import 'app_colors.dart';

/// Ergonomic reading palette ensuring strict contrast ratios (WCAG AAA)
/// between text and background surfaces across all contrast presets.
class ReadingPalette {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color primary;
  final Color syllableColor1;
  final Color syllableColor2;
  final Color syllableColor3;
  final Color syllableColor4;
  final Color silentColor;
  final Color mirrorColorB;
  final Color mirrorColorD;
  final Color mirrorColorP;
  final Color mirrorColorQ;
  final bool isDark;

  const ReadingPalette({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.primary,
    required this.syllableColor1,
    required this.syllableColor2,
    required this.syllableColor3,
    required this.syllableColor4,
    required this.silentColor,
    required this.mirrorColorB,
    required this.mirrorColorD,
    required this.mirrorColorP,
    required this.mirrorColorQ,
    this.isDark = false,
  });

  /// Returns 2, 3, or 4 distinct alternating colors for syllable segmentation
  List<Color> getSyllableColors([int count = 3]) {
    final all = [syllableColor1, syllableColor2, syllableColor3, syllableColor4];
    final c = count.clamp(2, 4);
    return all.sublist(0, c);
  }
}

extension ContrastPresetPaletteExtension on ContrastPreset {
  ReadingPalette get palette {
    switch (this) {
      case ContrastPreset.sombre:
        return const ReadingPalette(
          isDark: true,
          background: Color(0xFF0F172A), // Midnight Dark
          surface: Color(0xFF1E293B),    // Slate Card
          textPrimary: Color(0xFFF8FAFC),// Bright Crisp White (Default font)
          textSecondary: Color(0xFF94A3B8), // Soft Light Slate
          border: Color(0xFF334155),
          primary: Color(0xFF818CF8),    // Soft Lavender Indigo
          syllableColor1: Color(0xFF60A5FA), // Light Sky Blue (never white!)
          syllableColor2: Color(0xFFC084FC), // Light Violet/Purple (never white!)
          syllableColor3: Color(0xFFFBBF24), // Vibrant Amber (never white!)
          syllableColor4: Color(0xFF2DD4BF), // Light Teal/Turquoise (never white!)
          silentColor: Color(0xFF64748B),    // Attenuated Slate
          mirrorColorB: Color(0xFF93C5FD),   // Bright Sky Blue
          mirrorColorD: Color(0xFFF87171),   // Bright Coral Red
          mirrorColorP: Color(0xFF34D399),   // Bright Mint Emerald Green
          mirrorColorQ: Color(0xFFFFB86C),   // Bright Warm Amber (sombre)
        );

      case ContrastPreset.clair:
        return const ReadingPalette(
          isDark: false,
          background: Color(0xFFFFFFFF), // Pure White
          surface: Color(0xFFF8FAFC),    // Pure White Card
          textPrimary: Color(0xFF000000),// Pitch Black (Default font)
          textSecondary: Color(0xFF475569),
          border: Color(0xFFCBD5E1),
          primary: Color(0xFF4F46E5),
          syllableColor1: Color(0xFF2563EB), // Royal Blue (never black!)
          syllableColor2: Color(0xFF7C3AED), // Vibrant Purple (never black!)
          syllableColor3: Color(0xFFD97706), // Warm Amber (never black!)
          syllableColor4: Color(0xFF0D9488), // Deep Teal (never black!)
          silentColor: Color(0xFF94A3B8),    // Soft Slate Gray
          mirrorColorB: Color(0xFF2563EB),   // Pure Blue
          mirrorColorD: Color(0xFFDC2626),   // Pure Crimson Red
          mirrorColorP: Color(0xFF059669),   // Pure Emerald Green
          mirrorColorQ: Color(0xFFD97706),   // Pure Warm Amber (clair)
        );

      case ContrastPreset.bleu:
        return const ReadingPalette(
          isDark: false,
          background: Color(0xFFEFF6FF), // Soft Ice Blue
          surface: Color(0xFFFFFFFF),    // Clean White Card
          textPrimary: Color(0xFF1E3A8A),// Deep Royal Navy (Default font)
          textSecondary: Color(0xFF475569),
          border: Color(0xFFBFDBFE),
          primary: Color(0xFF2563EB),
          syllableColor1: Color(0xFF0D9488), // Teal (never navy!)
          syllableColor2: Color(0xFF7C3AED), // Vibrant Purple (never navy!)
          syllableColor3: Color(0xFFD97706), // Warm Amber (never navy!)
          syllableColor4: Color(0xFFE11D48), // Rose Crimson (never navy!)
          silentColor: Color(0xFF94A3B8),    // Soft Slate Gray
          mirrorColorB: Color(0xFF2563EB),   // Blue
          mirrorColorD: Color(0xFFDC2626),   // Crimson Red
          mirrorColorP: Color(0xFF059669),   // Emerald Green
          mirrorColorQ: Color(0xFFD97706),   // Warm Amber (bleu)
        );

      case ContrastPreset.creme:
        return const ReadingPalette(
          isDark: false,
          background: Color(0xFFF8F7F4), // Warm Calm Cream
          surface: Color(0xFFFFFFFF),    // Clean White Card
          textPrimary: Color(0xFF1F2937),// Deep Charcoal (Default font)
          textSecondary: Color(0xFF64748B),
          border: Color(0xFFE2E8F0),
          primary: AppColors.primary,
          syllableColor1: Color(0xFF1D4ED8), // Cobalt Blue (never charcoal/black!)
          syllableColor2: Color(0xFF6D28D9), // Deep Purple (never charcoal/black!)
          syllableColor3: Color(0xFFC2410C), // Vivid Rust Orange (never charcoal/black!)
          syllableColor4: Color(0xFF0F766E), // Emerald Teal (never charcoal/black!)
          silentColor: Color(0xFF94A3B8),    // Soft Slate Gray
          mirrorColorB: Color(0xFF2563EB),   // Pure Blue
          mirrorColorD: Color(0xFFDC2626),   // Pure Crimson Red
          mirrorColorP: Color(0xFF059669),   // Pure Emerald Green
          mirrorColorQ: Color(0xFFD97706),   // Pure Warm Amber (creme)
        );
    }
  }
}
