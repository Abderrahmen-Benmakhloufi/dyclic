import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_model.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReadingSettings Model', () {
    test('default values match client accessibility specifications', () {
      const settings = ReadingSettings();
      expect(settings.fontSize, 18.0);
      expect(settings.lineHeight, 1.6);
      expect(settings.letterSpacing, 0.5);
      expect(settings.wordSpacing, 1.5);
      expect(settings.fontFamily, 'Atkinson Hyperlegible');
      expect(settings.contrastPreset, ContrastPreset.creme);
      expect(settings.learnerLevel, LearnerLevel.moyen);
      expect(settings.focusRulerEnabled, false);
      expect(settings.isOnboardingCompleted, false);
    });

    test('copyWith updates specified fields correctly', () {
      const settings = ReadingSettings();
      final updated = settings.copyWith(
        fontSize: 22.0,
        fontFamily: 'Lexend',
        learnerLevel: LearnerLevel.primaire,
        isOnboardingCompleted: true,
      );

      expect(updated.fontSize, 22.0);
      expect(updated.fontFamily, 'Lexend');
      expect(updated.learnerLevel, LearnerLevel.primaire);
      expect(updated.isOnboardingCompleted, true);
      expect(updated.lineHeight, 1.6); // unchanged
    });
  });

  group('ReadingSettingsNotifier', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initializes with defaults when SharedPreferences is empty', () {
      final notifier = ReadingSettingsNotifier(prefs);
      expect(notifier.state.fontSize, 18.0);
      expect(notifier.state.fontFamily, 'Atkinson Hyperlegible');
      expect(notifier.state.learnerLevel, LearnerLevel.moyen);
    });

    test('clamps fontSize between 14.0 and 28.0', () async {
      final notifier = ReadingSettingsNotifier(prefs);

      await notifier.setFontSize(35.0);
      expect(notifier.state.fontSize, 28.0);

      await notifier.setFontSize(10.0);
      expect(notifier.state.fontSize, 14.0);
    });

    test('setting learner level marks onboarding as completed', () async {
      final notifier = ReadingSettingsNotifier(prefs);
      expect(notifier.state.isOnboardingCompleted, false);

      await notifier.setLearnerLevel(LearnerLevel.secondaire);
      expect(notifier.state.learnerLevel, LearnerLevel.secondaire);
      expect(notifier.state.isOnboardingCompleted, true);
      expect(prefs.getBool('learner_onboarding_completed'), true);
      expect(prefs.getString('learner_educational_level'), 'secondaire');
    });

    test('resetToDefaults restores accessibility baseline', () async {
      final notifier = ReadingSettingsNotifier(prefs);
      await notifier.setFontSize(26.0);
      await notifier.setFontFamily('Lexend');
      await notifier.toggleFocusRuler();

      expect(notifier.state.fontSize, 26.0);
      expect(notifier.state.focusRulerEnabled, true);

      await notifier.resetToDefaults();
      expect(notifier.state.fontSize, 18.0);
      expect(notifier.state.fontFamily, 'Atkinson Hyperlegible');
      expect(notifier.state.focusRulerEnabled, false);
    });
  });
}
