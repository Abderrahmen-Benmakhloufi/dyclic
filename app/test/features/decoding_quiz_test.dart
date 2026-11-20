import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/core/tts/tts_service.dart';
import 'package:lecture_aide/features/decoding/data/decoding_quiz_data.dart';
import 'package:lecture_aide/features/decoding/decoding_quiz_screen.dart';
import 'package:lecture_aide/features/decoding/models/decoding_quiz_model.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

class FakeTtsService extends TtsService {
  String? lastSpokenWord;

  @override
  Future<void> speakWord(String word) async {
    lastSpokenWord = word;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── 1. Data integrity ───────────────────────────────────────────────────────

  group('kDecodingQuizBank – data integrity', () {
    test('has at least 30 questions', () {
      expect(kDecodingQuizBank.length, greaterThanOrEqualTo(30));
    });

    test('every question has at least 2 choices', () {
      for (final q in kDecodingQuizBank) {
        expect(
          q.choices.length,
          greaterThanOrEqualTo(2),
          reason: '${q.word} (${q.ruleId}) has only ${q.choices.length} choice(s)',
        );
      }
    });

    test('correctChoiceIndex is within choices bounds for every question', () {
      for (final q in kDecodingQuizBank) {
        expect(
          q.correctChoiceIndex,
          inInclusiveRange(0, q.choices.length - 1),
          reason: '${q.word}: correctChoiceIndex=${q.correctChoiceIndex} '
              'but choices.length=${q.choices.length}',
        );
      }
    });

    test('all questions have non-empty word, testedLetter, hintFr', () {
      for (final q in kDecodingQuizBank) {
        expect(q.word.isNotEmpty, isTrue, reason: 'Empty word in ${q.ruleId}');
        expect(q.testedLetter.isNotEmpty, isTrue,
            reason: 'Empty testedLetter for ${q.word}');
        expect(q.hintFr.isNotEmpty, isTrue,
            reason: 'Empty hintFr for ${q.word}');
      }
    });

    test('all testedIndices are within word bounds', () {
      for (final q in kDecodingQuizBank) {
        for (final idx in q.testedIndices) {
          expect(
            idx,
            inInclusiveRange(0, q.word.length - 1),
            reason:
                '${q.word}: testedIndex $idx out of range (length ${q.word.length})',
          );
        }
      }
    });
  });

  // ── 2. getQuestionsForRule ──────────────────────────────────────────────────

  group('getQuestionsForRule', () {
    test('returns only rule_s questions', () {
      final qs = getQuestionsForRule('rule_s');
      expect(qs.isNotEmpty, isTrue);
      for (final q in qs) {
        expect(q.ruleId, equals('rule_s'));
      }
    });

    test('filters by difficulty when provided', () {
      final qs = getQuestionsForRule(
        'rule_g',
        difficulty: QuizDifficulty.decouverte,
      );
      expect(qs.isNotEmpty, isTrue);
      for (final q in qs) {
        expect(q.difficulty, equals(QuizDifficulty.decouverte));
        expect(q.ruleId, equals('rule_g'));
      }
    });

    test('returns empty list for unknown ruleId', () {
      final qs = getQuestionsForRule('rule_unknown');
      expect(qs, isEmpty);
    });
  });

  // ── 3. getAllQuestions ──────────────────────────────────────────────────────

  group('getAllQuestions', () {
    test('without filter returns all questions', () {
      final qs = getAllQuestions();
      expect(qs.length, equals(kDecodingQuizBank.length));
    });

    test('filtered by decouverte returns only decouverte questions', () {
      final qs = getAllQuestions(difficulty: QuizDifficulty.decouverte);
      expect(qs.isNotEmpty, isTrue);
      for (final q in qs) {
        expect(q.difficulty, equals(QuizDifficulty.decouverte));
      }
    });

    test('filtered by defi returns only defi questions', () {
      final qs = getAllQuestions(difficulty: QuizDifficulty.defi);
      expect(qs.isNotEmpty, isTrue);
      for (final q in qs) {
        expect(q.difficulty, equals(QuizDifficulty.defi));
      }
    });
  });

  // ── 4. QuizDifficultyExt ───────────────────────────────────────────────────

  group('QuizDifficultyExt', () {
    test('label is non-empty for all difficulties', () {
      for (final d in QuizDifficulty.values) {
        expect(d.label.isNotEmpty, isTrue);
      }
    });

    test('description is non-empty for all difficulties', () {
      for (final d in QuizDifficulty.values) {
        expect(d.description.isNotEmpty, isTrue);
      }
    });
  });

  // ── 5. QuizSessionResult ───────────────────────────────────────────────────

  group('QuizSessionResult', () {
    test('10/10 → 🏆 medal and perfect feedback', () {
      final result = QuizSessionResult(
        totalQuestions: 10,
        correctAnswers: 10,
        answerHistory: List.filled(10, true),
      );
      expect(result.medal, equals('🏆'));
      expect(result.successRate, equals(1.0));
      expect(result.feedbackFr, contains('Parfait'));
    });

    test('8/10 → 🥇 medal', () {
      final result = QuizSessionResult(
        totalQuestions: 10,
        correctAnswers: 8,
        answerHistory: [...List.filled(8, true), false, false],
      );
      expect(result.medal, equals('🥇'));
      expect(result.successRate, equals(0.8));
    });

    test('6/10 → 🥈 medal', () {
      final result = QuizSessionResult(
        totalQuestions: 10,
        correctAnswers: 6,
        answerHistory: [...List.filled(6, true), ...List.filled(4, false)],
      );
      expect(result.medal, equals('🥈'));
    });

    test('3/10 → 🥉 medal', () {
      final result = QuizSessionResult(
        totalQuestions: 10,
        correctAnswers: 3,
        answerHistory: [...List.filled(3, true), ...List.filled(7, false)],
      );
      expect(result.medal, equals('🥉'));
    });

    test('wrongAnswers is computed correctly', () {
      final result = QuizSessionResult(
        totalQuestions: 8,
        correctAnswers: 5,
        answerHistory: [],
      );
      expect(result.wrongAnswers, equals(3));
    });

    test('zero total → successRate is 0', () {
      final result = QuizSessionResult(
        totalQuestions: 0,
        correctAnswers: 0,
        answerHistory: [],
      );
      expect(result.successRate, equals(0.0));
    });
  });

  // ── 6. QuizQuestion.correctChoice getter ───────────────────────────────────

  group('QuizQuestion.correctChoice', () {
    test('returns the correct choice string', () {
      const q = QuizQuestion(
        word: 'soleil',
        testedLetter: 'S',
        testedIndices: [0],
        hintFr: 'Hint',
        choices: ['/s/ serpent', '/z/ zèbre'],
        correctChoiceIndex: 0,
        ruleId: 'rule_s',
        difficulty: QuizDifficulty.decouverte,
      );
      expect(q.correctChoice, equals('/s/ serpent'));
    });
  });

  // ── 7. Widget tests ────────────────────────────────────────────────────────

  group('DecodingQuizScreen – widget', () {
    late SharedPreferences prefs;
    late FakeTtsService fakeTts;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      fakeTts = FakeTtsService();
    });

    Widget buildTestApp({String? ruleId, QuizDifficulty? initialDifficulty}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ttsServiceProvider.overrideWithValue(fakeTts),
        ],
        child: MaterialApp(
          home: DecodingQuizScreen(
            ruleId: ruleId,
            initialDifficulty: initialDifficulty,
          ),
        ),
      );
    }

    testWidgets('shows difficulty selector by default', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Quiz d\'écoute'), findsWidgets);
      expect(find.text('Découverte'), findsOneWidget);
      expect(find.text('Discrimination'), findsOneWidget);
      expect(find.text('Défi'), findsOneWidget);
    });

    testWidgets('tapping Découverte shows first question', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Découverte'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should now show question view with listen button and progress indicator
      expect(find.text('Écouter le mot'), findsOneWidget);
      expect(find.textContaining('Question'), findsOneWidget);
    });

    testWidgets('shows choice buttons after difficulty selected', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Découverte'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // At least one choice button (A, B…)
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('tapping a choice shows feedback (green or red border)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Découverte'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Tap the first visible choice button labelled 'A'
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      // After answer: "Question suivante" or "Voir les résultats" button appears
      final nextBtn = find.textContaining('suivante');
      final resultBtn = find.textContaining('résultats');
      expect(nextBtn.evaluate().isNotEmpty || resultBtn.evaluate().isNotEmpty, isTrue);
    });
  });
}
