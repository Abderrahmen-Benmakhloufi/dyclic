import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../reading_settings/reading_settings_model.dart';

class AppTheme {
  AppTheme._();

  /// Build dynamic ThemeData based on active ReadingSettings
  static ThemeData buildTheme(ReadingSettings settings) {
    final colors = _getPresetColors(settings.contrastPreset);

    // Resolve base font style using GoogleFonts with safe fallbacks
    TextStyle baseTextStyle;
    switch (settings.fontFamily) {
      case 'Lexend':
        baseTextStyle = TextStyle(
          fontFamily: 'Lexend',
          color: colors.textPrimary,
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          letterSpacing: settings.letterSpacing,
          wordSpacing: settings.wordSpacing,
        );
        break;
      case 'System':
        baseTextStyle = TextStyle(
          color: colors.textPrimary,
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          letterSpacing: settings.letterSpacing,
          wordSpacing: settings.wordSpacing,
        );
        break;
      case 'Atkinson Hyperlegible':
      default:
        baseTextStyle = TextStyle(
          fontFamily: 'Atkinson Hyperlegible',
          color: colors.textPrimary,
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          letterSpacing: settings.letterSpacing,
          wordSpacing: settings.wordSpacing,
        );
        break;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: colors.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: colors.isDark ? Brightness.dark : Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textPrimary,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: AppColors.errorRed,
        onError: Colors.white,
      ),

      // Card styling: 18px rounded corners, 1px subtle border, no heavy drop shadows
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: BorderSide(
            color: colors.isDark ? Colors.white12 : AppColors.cardBorder,
            width: 1.0,
          ),
        ),
      ),

      // Button styling: 48-52px height, 12-14px border radius, clear bold text
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Atkinson Hyperlegible',
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Atkinson Hyperlegible',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // App bar styling: flat, calm, clear title
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Atkinson Hyperlegible',
          color: colors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Text styling hierarchy
      textTheme: TextTheme(
        displayLarge: baseTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
        displayMedium: baseTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: baseTextStyle.copyWith(fontSize: settings.fontSize),
        bodyMedium: baseTextStyle.copyWith(fontSize: (settings.fontSize - 2).clamp(16.0, 24.0)),
        bodySmall: baseTextStyle.copyWith(
          fontSize: (settings.fontSize - 3).clamp(14.0, 20.0),
          color: colors.textSecondary,
        ),
      ),
    );
  }

  static _PresetColors _getPresetColors(ContrastPreset preset) {
    switch (preset) {
      case ContrastPreset.clair:
        return _PresetColors(
          background: const Color(0xFFF8FAFC),
          surface: Colors.white,
          textPrimary: const Color(0xFF1E293B),
          textSecondary: const Color(0xFF64748B),
          isDark: false,
        );
      case ContrastPreset.bleu:
        return _PresetColors(
          background: AppColors.bluePastelBackground,
          surface: AppColors.bluePastelSurface,
          textPrimary: const Color(0xFF1E293B),
          textSecondary: const Color(0xFF64748B),
          isDark: false,
        );
      case ContrastPreset.sombre:
        return _PresetColors(
          background: AppColors.darkBackground,
          surface: AppColors.darkSurface,
          textPrimary: AppColors.darkTextPrimary,
          textSecondary: AppColors.darkTextSecondary,
          isDark: true,
        );
      case ContrastPreset.creme:
        return _PresetColors(
          background: AppColors.background,
          surface: AppColors.surfaceCard,
          textPrimary: AppColors.textPrimary,
          textSecondary: AppColors.textSecondary,
          isDark: false,
        );
    }
  }
}

class _PresetColors {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  _PresetColors({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });
}
