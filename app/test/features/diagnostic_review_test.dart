import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/features/diagnostic/diagnostic_review_screen.dart';
import 'package:lecture_aide/features/diagnostic/diagnostic_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DiagnosticReviewScreen displays choices and allows validation', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final answers = <String, int>{
      'q1': 2,
      'q2': 1,
      'q3': 3,
      'q4': 1,
      'q5': 2,
      'q6': 0,
      'q7': 2,
      'q8': 2,
      'q9': 1,
      'q10': 3,
      'q11': 0,
      'q12': 2,
      'q13': 2,
      'q14': 2,
      'q15': 3,
      'q16': 1,
      'q17': 2,
      'q18': 0,
      'q19': 2,
      'q20': 2,
      'q22': 2,
      'q23': 1,
      'q24': 3,
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: DiagnosticReviewScreen(answers: answers),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and header
    expect(find.text('Récapitulatif de tes réponses'), findsOneWidget);
    expect(find.text('Vérifie tes réponses'), findsOneWidget);
    expect(find.text('23 questions répondues ✓'), findsOneWidget);

    // Verify presence of Recommencer and Valider buttons
    expect(find.text('Recommencer'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);

    // Verify answers rendered
    expect(find.text('Question 1 / 23'), findsOneWidget);
    expect(find.textContaining('Ta réponse :'), findsWidgets);

    // Tap Valider button and verify transition
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.byType(DiagnosticResultScreen), findsOneWidget);
    expect(find.text('Ton profil'), findsOneWidget);
  });
}
