import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/features/writing/writing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        home: WritingScreen(),
      ),
    );
  }

  testWidgets('WritingScreen renders title, level pill, input field, and OCR button',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text("M'aider à écrire ✍️"), findsOneWidget);
    expect(find.text('Collège'), findsOneWidget);
    expect(find.text('Mon texte'), findsOneWidget);
    expect(find.text('Scanner'), findsOneWidget);
  });

  testWidgets('Optional subject field toggles open when tapped', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Sujet demandé (optionnel)'), findsNothing);

    await tester.tap(find.text('Ajouter le sujet du professeur (optionnel)'));
    await tester.pumpAndSettle();

    expect(find.text('Sujet demandé (optionnel)'), findsOneWidget);
  });

  testWidgets('Submit button is disabled when empty and enables on input',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final emptyBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Analyser mon texte ✨'),
    );
    expect(emptyBtn.onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'Le chavel court.');
    await tester.pump();

    final activeBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Analyser mon texte ✨'),
    );
    expect(activeBtn.onPressed, isNotNull);
  });

  testWidgets('Tapping sample chip fills text and subject fields',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Exemples pour tester (10)'), findsOneWidget);

    await tester.tap(find.text('Sortie en forêt'));
    await tester.pumpAndSettle();

    expect(find.text('Sujet demandé (optionnel)'), findsOneWidget);
    final activeBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Analyser mon texte ✨'),
    );
    expect(activeBtn.onPressed, isNotNull);
  });
}
