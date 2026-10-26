import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lecture_aide/core/learner_profile/learner_profile_model.dart';
import 'package:lecture_aide/core/learner_profile/learner_profile_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LearnerProfile Model', () {
    test('Default profile has zero scores and not completed', () {
      const profile = LearnerProfile();
      expect(profile.diagnosticCompleted, isFalse);
      expect(profile.diagnosticSkipped, isFalse);
      expect(profile.isDiagnosticDone, isFalse);
      expect(profile.b1ReadingFluencyScore, 0);
      expect(profile.b1Level, DiagnosticLevel.none);
    });

    test('Balanced profile sets all 4 dimensions to 30% and marked as skipped', () {
      const profile = LearnerProfile.balanced;
      expect(profile.diagnosticCompleted, isFalse);
      expect(profile.diagnosticSkipped, isTrue);
      expect(profile.isDiagnosticDone, isTrue);
      expect(profile.b1ReadingFluencyScore, 30);
      expect(profile.b2SpellingWritingScore, 30);
      expect(profile.b3AuditoryMemoryScore, 30);
      expect(profile.b4CognitiveLoadScore, 30);
      expect(profile.b1Level, DiagnosticLevel.mild);
    });

    test('fromAnswers calculates severity and flags accurately', () {
      final sampleAnswers = {
        'q1': 2,
        'q2': 4,
        'q3': 4,
        'q4': 4,
        'q5': 2,
        'q6': 2,
        'q7': 2,
        'q8': 4,
        'q9': 4,
        'q10': 4, // mirror letter confusion
        'q11': 2, // visual instability
        'q12': 4, // overwhelmed
        'q13': 2, // avoids oral reading
        'q14': 2, // poor word decoding
        'q15': 4,
        'q16': 4,
        'q17': 2,
        'q18': 2,
        'q19': 2, // slow reading
        'q20': 2,
        'q22': 4,
        'q23': 4,
        'q24': 4,
      };

      final profile = LearnerProfile.fromAnswers(sampleAnswers);

      expect(profile.diagnosticCompleted, isTrue);
      expect(profile.diagnosticSkipped, isFalse);
      expect(profile.isDiagnosticDone, isTrue);

      // Flags
      expect(profile.mirrorLetterConfusion, isTrue);
      expect(profile.visualInstability, isTrue);
      expect(profile.avoidsOralReading, isTrue);
      expect(profile.slowReadingSpeed, isTrue);
      expect(profile.poorWordDecoding, isTrue);
      expect(profile.needsVisualSpacing, isTrue);
      expect(profile.cognitiveFatigueHigh, isTrue);
      expect(profile.overwhelmedByText, isTrue);

      // All dimensions should be severe given max answers
      expect(profile.b1Level, DiagnosticLevel.severe);
      expect(profile.b2Level, DiagnosticLevel.severe);
      expect(profile.b3Level, DiagnosticLevel.severe);
      expect(profile.b4Level, DiagnosticLevel.severe);

      // Verify dimensions list has 4 elements
      expect(profile.dimensions.length, 4);
    });
  });

  group('LearnerProfileNotifier', () {
    test('Initializes with default when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = LearnerProfileNotifier(prefs);

      expect(notifier.state.diagnosticCompleted, isFalse);
      expect(notifier.state.isDiagnosticDone, isFalse);
    });

    test('skipDiagnostic updates state and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = LearnerProfileNotifier(prefs);

      await notifier.skipDiagnostic();

      expect(notifier.state.diagnosticSkipped, isTrue);
      expect(notifier.state.isDiagnosticDone, isTrue);
      expect(prefs.getBool('diag_skipped'), isTrue);
      expect(prefs.getInt('diag_b1_score'), 30);
    });

    test('saveCompletedProfile persists scores and flags', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = LearnerProfileNotifier(prefs);

      final profile = LearnerProfile.fromAnswers({
        'q10': 3,
        'q13': 2,
      });

      await notifier.saveCompletedProfile(profile);

      expect(notifier.state.diagnosticCompleted, isTrue);
      expect(prefs.getBool('diag_completed'), isTrue);
      expect(prefs.getBool('diag_flag_mirror_letter'), isTrue);
      expect(prefs.getBool('diag_flag_avoids_oral'), isTrue);
    });
  });
}
