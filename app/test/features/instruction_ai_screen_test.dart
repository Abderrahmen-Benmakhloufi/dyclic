import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/features/instructions/instruction_ai_screen.dart';
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
        home: InstructionAiScreen(),
      ),
    );
  }

  testWidgets('InstructionAiScreen renders appbar title', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Expliquer une consigne 💡'), findsOneWidget);
  });

  testWidgets('InstructionAiScreen shows 17 consignes catalog button in AppBar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('17 consignes'), findsOneWidget);
  });

  testWidgets('InstructionAiScreen shows cycle pill', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Default learner level is "moyen" → Collège
    expect(find.text('📚 Collège'), findsOneWidget);
    expect(find.text('Niveau détecté :'), findsOneWidget);
  });

  testWidgets('InstructionAiScreen shows input field and label', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Ta consigne'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Submit button is disabled when input is empty', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Expliquer ma consigne ✨'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Submit button enables when text is entered', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField),
        'Relève du texte les phrases qui décrivent le personnage.');
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Expliquer ma consigne ✨'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Quick example chips are visible', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Exemples rapides'), findsOneWidget);
  });

  testWidgets('Tapping an example chip fills the text field', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // The first example chip starts with "Relève du texte"
    final firstChip = find.byWidgetPredicate(
      (widget) => widget is Text && (widget.data?.startsWith('Relève du texte') ?? false),
    );
    expect(firstChip, findsOneWidget);

    await tester.tap(firstChip);
    await tester.pump();

    final tf = tester.widget<TextField>(find.byType(TextField));
    expect(tf.controller?.text, isNotEmpty);
  });

  testWidgets('Clear button appears and clears text', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'test');
    await tester.pump();

    expect(find.text('Effacer'), findsOneWidget);

    await tester.tap(find.text('Effacer'));
    await tester.pump();

    final tf = tester.widget<TextField>(find.byType(TextField));
    expect(tf.controller?.text, isEmpty);
  });

  testWidgets('Recent history section displays and can be cleared', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Seed history into SharedPreferences
    await prefs.setStringList('ai_instructions_history', [
      '{"id":"HIST-1","title":"Historique 1","cycle":"college","level":"Collège","domain":"Compréhension","questionType":"comprehension","originalFr":"Question passée","steps":[]}'
    ]);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Consignes récentes'), findsOneWidget);
    expect(find.text('Historique 1'), findsOneWidget);

    // Tap "Effacer l'historique"
    await tester.tap(find.text("Effacer l'historique"));
    await tester.pumpAndSettle();

    expect(find.text('Consignes récentes'), findsNothing);
  });
}
