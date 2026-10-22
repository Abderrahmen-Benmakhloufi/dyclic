import 'package:flutter/foundation.dart';

/// Supported educational cycles (Algerian school system)
enum LearnerLevel {
  primaire,
  moyen,
  secondaire,
}

extension LearnerLevelExtension on LearnerLevel {
  String get code {
    switch (this) {
      case LearnerLevel.primaire:
        return 'primaire';
      case LearnerLevel.moyen:
        return 'moyen';
      case LearnerLevel.secondaire:
        return 'secondaire';
    }
  }

  static LearnerLevel fromString(String? value) {
    switch (value) {
      case 'primaire':
        return LearnerLevel.primaire;
      case 'secondaire':
        return LearnerLevel.secondaire;
      case 'moyen':
      default:
        return LearnerLevel.moyen;
    }
  }
}

/// Supported contrast modes for visual comfort
enum ContrastPreset {
  creme,
  clair,
  bleu,
  sombre,
}

extension ContrastPresetExtension on ContrastPreset {
  String get code {
    switch (this) {
      case ContrastPreset.creme:
        return 'creme';
      case ContrastPreset.clair:
        return 'clair';
      case ContrastPreset.bleu:
        return 'bleu';
      case ContrastPreset.sombre:
        return 'sombre';
    }
  }

  static ContrastPreset fromString(String? value) {
    switch (value) {
      case 'clair':
        return ContrastPreset.clair;
      case 'bleu':
        return ContrastPreset.bleu;
      case 'sombre':
        return ContrastPreset.sombre;
      case 'creme':
      default:
        return ContrastPreset.creme;
    }
  }
}

/// Immutable Reading Settings Model
@immutable
class ReadingSettings {
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final double wordSpacing;
  final String fontFamily; // 'Atkinson Hyperlegible', 'Lexend', 'OpenDyslexic', 'System'
  final ContrastPreset contrastPreset;
  final bool focusRulerEnabled;
  final LearnerLevel learnerLevel;
  final bool isOnboardingCompleted;

  const ReadingSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.6,
    this.letterSpacing = 0.5,
    this.wordSpacing = 1.5,
    this.fontFamily = 'Atkinson Hyperlegible',
    this.contrastPreset = ContrastPreset.creme,
    this.focusRulerEnabled = false,
    this.learnerLevel = LearnerLevel.moyen,
    this.isOnboardingCompleted = false,
  });

  ReadingSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? letterSpacing,
    double? wordSpacing,
    String? fontFamily,
    ContrastPreset? contrastPreset,
    bool? focusRulerEnabled,
    LearnerLevel? learnerLevel,
    bool? isOnboardingCompleted,
  }) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      fontFamily: fontFamily ?? this.fontFamily,
      contrastPreset: contrastPreset ?? this.contrastPreset,
      focusRulerEnabled: focusRulerEnabled ?? this.focusRulerEnabled,
      learnerLevel: learnerLevel ?? this.learnerLevel,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingSettings &&
          runtimeType == other.runtimeType &&
          fontSize == other.fontSize &&
          lineHeight == other.lineHeight &&
          letterSpacing == other.letterSpacing &&
          wordSpacing == other.wordSpacing &&
          fontFamily == other.fontFamily &&
          contrastPreset == other.contrastPreset &&
          focusRulerEnabled == other.focusRulerEnabled &&
          learnerLevel == other.learnerLevel &&
          isOnboardingCompleted == other.isOnboardingCompleted;

  @override
  int get hashCode =>
      fontSize.hashCode ^
      lineHeight.hashCode ^
      letterSpacing.hashCode ^
      wordSpacing.hashCode ^
      fontFamily.hashCode ^
      contrastPreset.hashCode ^
      focusRulerEnabled.hashCode ^
      learnerLevel.hashCode ^
      isOnboardingCompleted.hashCode;
}
