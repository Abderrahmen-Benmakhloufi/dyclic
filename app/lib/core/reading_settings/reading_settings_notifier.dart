import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../learner_profile/learner_profile_model.dart';
import 'reading_settings_model.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized before runApp');
});

final readingSettingsProvider =
    StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReadingSettingsNotifier(prefs);
});

class ReadingSettingsNotifier extends StateNotifier<ReadingSettings> {
  final SharedPreferences _prefs;

  static const _keyFontSize = 'reading_font_size';
  static const _keyLineHeight = 'reading_line_height';
  static const _keyLetterSpacing = 'reading_letter_spacing';
  static const _keyWordSpacing = 'reading_word_spacing';
  static const _keyFontFamily = 'reading_font_family';
  static const _keyContrast = 'reading_contrast_preset';
  static const _keyFocusRuler = 'reading_focus_ruler';
  static const _keyLevel = 'learner_educational_level';
  static const _keyOnboardingDone = 'learner_onboarding_completed';
  static const _keyCalibrationDone = 'reading_calibration_completed';
  static const _keySyllableColorCount = 'reading_syllable_color_count';

  ReadingSettingsNotifier(this._prefs) : super(const ReadingSettings()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final fontSize = _prefs.getDouble(_keyFontSize) ?? 18.0;
    final lineHeight = _prefs.getDouble(_keyLineHeight) ?? 1.6;
    final letterSpacing = _prefs.getDouble(_keyLetterSpacing) ?? 0.5;
    final wordSpacing = _prefs.getDouble(_keyWordSpacing) ?? 1.5;
    final fontFamily = _prefs.getString(_keyFontFamily) ?? 'Atkinson Hyperlegible';
    final contrastStr = _prefs.getString(_keyContrast) ?? 'creme';
    final focusRuler = _prefs.getBool(_keyFocusRuler) ?? false;
    final levelStr = _prefs.getString(_keyLevel) ?? 'moyen';
    final onboardingDone = _prefs.getBool(_keyOnboardingDone) ?? false;
    final calibrationDone = _prefs.getBool(_keyCalibrationDone) ?? false;
    final syllableColorCount = _prefs.getInt(_keySyllableColorCount) ?? 3;

    state = ReadingSettings(
      fontSize: fontSize,
      lineHeight: lineHeight,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      fontFamily: fontFamily,
      contrastPreset: ContrastPresetExtension.fromString(contrastStr),
      focusRulerEnabled: focusRuler,
      learnerLevel: LearnerLevelExtension.fromString(levelStr),
      isOnboardingCompleted: onboardingDone,
      hasCompletedCalibration: calibrationDone,
      syllableColorCount: syllableColorCount,
    );
  }

  Future<void> setSyllableColorCount(int count) async {
    final clamped = count.clamp(2, 4);
    state = state.copyWith(syllableColorCount: clamped);
    await _prefs.setInt(_keySyllableColorCount, clamped);
  }

  Future<void> setFontSize(double size) async {
    final clamped = size.clamp(14.0, 28.0);
    state = state.copyWith(fontSize: clamped);
    await _prefs.setDouble(_keyFontSize, clamped);
  }

  Future<void> setLineHeight(double height) async {
    final clamped = height.clamp(1.4, 2.2);
    state = state.copyWith(lineHeight: clamped);
    await _prefs.setDouble(_keyLineHeight, clamped);
  }

  Future<void> setLetterSpacing(double spacing) async {
    final clamped = spacing.clamp(0.0, 3.0);
    state = state.copyWith(letterSpacing: clamped);
    await _prefs.setDouble(_keyLetterSpacing, clamped);
  }

  Future<void> setWordSpacing(double spacing) async {
    final clamped = spacing.clamp(0.0, 6.0);
    state = state.copyWith(wordSpacing: clamped);
    await _prefs.setDouble(_keyWordSpacing, clamped);
  }

  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    await _prefs.setString(_keyFontFamily, family);
  }

  Future<void> setContrastPreset(ContrastPreset preset) async {
    state = state.copyWith(contrastPreset: preset);
    await _prefs.setString(_keyContrast, preset.code);
  }

  Future<void> toggleFocusRuler() async {
    final newVal = !state.focusRulerEnabled;
    state = state.copyWith(focusRulerEnabled: newVal);
    await _prefs.setBool(_keyFocusRuler, newVal);
  }

  Future<void> setLearnerLevel(LearnerLevel level) async {
    state = state.copyWith(
      learnerLevel: level,
      isOnboardingCompleted: true,
    );
    await _prefs.setString(_keyLevel, level.code);
    await _prefs.setBool(_keyOnboardingDone, true);
  }

  Future<void> setCalibrationCompleted(bool completed) async {
    state = state.copyWith(hasCompletedCalibration: completed);
    await _prefs.setBool(_keyCalibrationDone, completed);
  }

  Future<void> saveCalibrationSettings({
    required double fontSize,
    required double lineHeight,
    required double letterSpacing,
    required double wordSpacing,
    required String fontFamily,
    required ContrastPreset contrastPreset,
  }) async {
    final clampedFontSize = fontSize.clamp(14.0, 28.0);
    final clampedLineHeight = lineHeight.clamp(1.4, 2.2);
    final clampedLetterSpacing = letterSpacing.clamp(0.0, 3.0);
    final clampedWordSpacing = wordSpacing.clamp(0.0, 6.0);

    state = state.copyWith(
      fontSize: clampedFontSize,
      lineHeight: clampedLineHeight,
      letterSpacing: clampedLetterSpacing,
      wordSpacing: clampedWordSpacing,
      fontFamily: fontFamily,
      contrastPreset: contrastPreset,
      hasCompletedCalibration: true,
    );

    await _prefs.setDouble(_keyFontSize, clampedFontSize);
    await _prefs.setDouble(_keyLineHeight, clampedLineHeight);
    await _prefs.setDouble(_keyLetterSpacing, clampedLetterSpacing);
    await _prefs.setDouble(_keyWordSpacing, clampedWordSpacing);
    await _prefs.setString(_keyFontFamily, fontFamily);
    await _prefs.setString(_keyContrast, contrastPreset.code);
    await _prefs.setBool(_keyCalibrationDone, true);
  }

  /// Applies recommended reading settings defaults based on the student's LearnerProfile
  Future<void> applyProfileDefaults(LearnerProfile profile) async {
    double newFontSize = state.fontSize;
    double newLineHeight = state.lineHeight;
    double newLetterSpacing = state.letterSpacing;
    double newWordSpacing = state.wordSpacing;
    bool newFocusRuler = state.focusRulerEnabled;
    int newSyllableCount = state.syllableColorCount;
    ContrastPreset newContrast = state.contrastPreset;

    // 1. Spacing needs
    if (profile.needsVisualSpacing) {
      newFontSize = 20.0;
      newLineHeight = 1.8;
      newLetterSpacing = 1.0;
      newWordSpacing = 2.5;
    }

    // 2. Visual instability (letters move / visual stress)
    if (profile.visualInstability) {
      newFocusRuler = true;
      if (newContrast == ContrastPreset.clair) {
        newContrast = ContrastPreset.creme;
      }
    }

    // 3. Decoding difficulties (poor word decoding)
    if (profile.poorWordDecoding) {
      newSyllableCount = 3;
    }

    // 4. General reading fluency needs
    if (profile.b1ReadingFluencyScore > 50) {
      if (newFontSize < 20.0) newFontSize = 20.0;
      if (newLineHeight < 1.8) newLineHeight = 1.8;
    }

    state = state.copyWith(
      fontSize: newFontSize,
      lineHeight: newLineHeight,
      letterSpacing: newLetterSpacing,
      wordSpacing: newWordSpacing,
      focusRulerEnabled: newFocusRuler,
      syllableColorCount: newSyllableCount,
      contrastPreset: newContrast,
      hasCompletedCalibration: true,
    );

    await _prefs.setDouble(_keyFontSize, newFontSize);
    await _prefs.setDouble(_keyLineHeight, newLineHeight);
    await _prefs.setDouble(_keyLetterSpacing, newLetterSpacing);
    await _prefs.setDouble(_keyWordSpacing, newWordSpacing);
    await _prefs.setBool(_keyFocusRuler, newFocusRuler);
    await _prefs.setInt(_keySyllableColorCount, newSyllableCount);
    await _prefs.setString(_keyContrast, newContrast.code);
    await _prefs.setBool(_keyCalibrationDone, true);
  }

  Future<void> resetToDefaults() async {
    state = state.copyWith(
      fontSize: 18.0,
      lineHeight: 1.6,
      letterSpacing: 0.5,
      wordSpacing: 1.5,
      fontFamily: 'Atkinson Hyperlegible',
      contrastPreset: ContrastPreset.creme,
      focusRulerEnabled: false,
      syllableColorCount: 3,
    );
    await _prefs.setDouble(_keyFontSize, 18.0);
    await _prefs.setDouble(_keyLineHeight, 1.6);
    await _prefs.setDouble(_keyLetterSpacing, 0.5);
    await _prefs.setDouble(_keyWordSpacing, 1.5);
    await _prefs.setString(_keyFontFamily, 'Atkinson Hyperlegible');
    await _prefs.setString(_keyContrast, 'creme');
    await _prefs.setBool(_keyFocusRuler, false);
    await _prefs.setInt(_keySyllableColorCount, 3);
  }
}
