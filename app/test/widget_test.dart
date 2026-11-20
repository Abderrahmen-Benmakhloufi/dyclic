import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lecture_aide/main.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App shows OnboardingScreen when first launched', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LectureAideApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bienvenue !'), findsOneWidget);
    expect(find.text('Primaire'), findsOneWidget);
    expect(find.text('Moyen'), findsOneWidget);
    expect(find.text('Lycée'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });

  testWidgets('App shows DiagnosticQuestionScreen when onboarding is done but diagnostic is not done', (tester) async {
    SharedPreferences.setMockInitialValues({
      'learner_onboarding_completed': true,
      'learner_educational_level': 'moyen',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LectureAideApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Évaluation'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
  });

  testWidgets('App shows HomeScreen directly when onboarding and diagnostic are already done', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'learner_onboarding_completed': true,
      'learner_educational_level': 'moyen',
      'diag_completed': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LectureAideApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bonjour !'), findsOneWidget);
    expect(find.text('M’aider à lire'), findsOneWidget);
    expect(find.text('Écouter le texte'), findsWidgets);
    expect(find.text('M’aider à écrire'), findsOneWidget);
    expect(find.text('Simplifier le texte'), findsWidgets);
    expect(find.text('Expliquer la consigne'), findsOneWidget);
  });

  testWidgets('Skipping diagnostic navigates to HomeScreen without error', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'learner_onboarding_completed': true,
      'learner_educational_level': 'moyen',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LectureAideApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Passer'), findsOneWidget);
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    // In the confirmation dialog, tap "Passer"
    expect(find.text('Passer l\'évaluation ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Passer'));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour !'), findsOneWidget);
  });
}
