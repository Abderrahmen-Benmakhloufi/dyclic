import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lecture_aide/main.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App shows OnboardingScreen when first launched', (tester) async {
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

    expect(find.text('Bienvenue ! 👋'), findsOneWidget);
    expect(find.text('Primaire'), findsOneWidget);
    expect(find.text('Moyen (Collège)'), findsOneWidget);
    expect(find.text('Secondaire (Lycée)'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });

  testWidgets('App shows HomeScreen directly when onboarding is already done', (tester) async {
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

    expect(find.text('Bonjour 👋'), findsOneWidget);
    expect(find.text('M’aider à lire'), findsOneWidget);
    expect(find.text('Écouter le texte'), findsOneWidget);
    expect(find.text('M’aider à écrire'), findsOneWidget);
    expect(find.text('Simplifier le texte'), findsOneWidget);
    expect(find.text('Expliquer la consigne'), findsOneWidget);
  });
}
