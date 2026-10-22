import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    );
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

  Future<void> resetToDefaults() async {
    state = state.copyWith(
      fontSize: 18.0,
      lineHeight: 1.6,
      letterSpacing: 0.5,
      wordSpacing: 1.5,
      fontFamily: 'Atkinson Hyperlegible',
      contrastPreset: ContrastPreset.creme,
      focusRulerEnabled: false,
    );
    await _prefs.setDouble(_keyFontSize, 18.0);
    await _prefs.setDouble(_keyLineHeight, 1.6);
    await _prefs.setDouble(_keyLetterSpacing, 0.5);
    await _prefs.setDouble(_keyWordSpacing, 1.5);
    await _prefs.setString(_keyFontFamily, 'Atkinson Hyperlegible');
    await _prefs.setString(_keyContrast, 'creme');
    await _prefs.setBool(_keyFocusRuler, false);
  }
}
