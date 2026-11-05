import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/features/instructions/instruction_detail_screen.dart';
import 'package:lecture_aide/features/instructions/instructions_screen.dart';
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
        home: InstructionsScreen(),
      ),
    );
  }

  testWidgets(
      'InstructionsScreen renders header, banner, search, cycle filters, and type filters',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Title & Header
    expect(find.text('Comprendre les consignes 💡'), findsOneWidget);
    expect(find.textContaining('17 consignes d’examens expliquées pas à pas'),
        findsOneWidget);

    // Verify Cycle Filter Pills
    expect(find.textContaining('Tous les niveaux (17)'), findsOneWidget);
    expect(find.textContaining('Primaire (5)'), findsOneWidget);
    expect(find.textContaining('Collège (7)'), findsOneWidget);
    expect(find.textContaining('Lycée (5)'), findsOneWidget);

    // Verify Question Type Filter Pills
    expect(find.textContaining('Tous les types (17)'), findsOneWidget);
    expect(find.textContaining('Compréhension (8)'), findsOneWidget);
    expect(find.textContaining('Langue & Grammaire (5)'), findsOneWidget);
    expect(find.textContaining('Production écrite (4)'), findsOneWidget);

    // Verify exactly one flower emoji inside the header circle above the search bar
    expect(find.text('🌷'), findsOneWidget);

    // Verify Search Bar
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Rechercher une consigne'), findsOneWidget);
  });

  testWidgets('Filtering by Primaire pill shows only primary instructions',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap '🎒 Primaire'
    await tester.tap(find.textContaining('Primaire (5)'));
    await tester.pumpAndSettle();

    // Should display 5 consignes
    expect(find.text('5 consignes disponibles'), findsOneWidget);
    expect(find.text('Repérer une information explicite dans le texte'), findsOneWidget);
  });

  testWidgets(
      'Filtering by Question Type pill shows only matching type instructions',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Ensure visible and tap '✍️ Production écrite (4)'
    final prodFinder = find.textContaining('Production écrite (4)');
    await tester.ensureVisible(prodFinder);
    await tester.pumpAndSettle();
    await tester.tap(prodFinder);
    await tester.pumpAndSettle();

    expect(find.text('4 consignes disponibles'), findsOneWidget);
    expect(find.text('Production écrite : raconter un événement vécu'), findsOneWidget);
    expect(find.text('Production argumentative (Type BEM)'), findsOneWidget);
  });

  testWidgets('Searching filters list dynamically and shows empty state on no match',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Enter a search query
    await tester.enterText(find.byType(TextField), 'argument');
    await tester.pumpAndSettle();

    expect(find.text('Production argumentative (Type BEM)'), findsOneWidget);

    // Enter an invalid search query
    await tester.enterText(find.byType(TextField), 'xyznonexistent123');
    await tester.pumpAndSettle();

    expect(find.text('Aucune consigne trouvée'), findsOneWidget);
    expect(find.text('Réinitialiser la recherche'), findsOneWidget);

    // Tap reset button
    await tester.tap(find.text('Réinitialiser la recherche'));
    await tester.pumpAndSettle();

    expect(find.text('17 consignes disponibles'), findsOneWidget);
  });

  testWidgets(
      'Tapping a card opens dedicated InstructionDetailScreen with steps',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Find first card and tap it
    await tester.tap(find.text('Repérer une information explicite dans le texte'));
    await tester.pumpAndSettle();

    // Verify we navigated to InstructionDetailScreen
    expect(find.byType(InstructionDetailScreen), findsOneWidget);
    expect(find.text('Explication pas à pas'), findsOneWidget);
    expect(find.text('Énoncé officiel d\'examen'), findsOneWidget);
    expect(find.textContaining('Comment répondre ?'), findsOneWidget);
    expect(find.textContaining('Que dois-tu faire ?'), findsOneWidget);
    expect(find.text('Étape 1'), findsOneWidget);
    expect(find.byType(Image), findsWidgets); // Character holding numbers for Primaire
    expect(find.text('J\'ai bien compris cette consigne'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    // Verify back to InstructionsScreen
    expect(find.byType(InstructionDetailScreen), findsNothing);
    expect(find.byType(InstructionsScreen), findsOneWidget);
  });

  testWidgets('Screen renders with zero overflow on narrow device (320px width)',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Comprendre les consignes 💡'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Action Verbs strip renders and filters instructions by command verb',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Action Verbs row title
    expect(find.text('Verbe de la consigne :'), findsOneWidget);

    // Verify Action Verb chips
    expect(find.textContaining('Relever (4)'), findsOneWidget);
    expect(find.textContaining('Justifier / Vrai-Faux (5)'), findsOneWidget);
    expect(find.textContaining('Identifier / Dégager (6)'), findsOneWidget);

    // Tap Relever (4)
    await tester.tap(find.textContaining('Relever (4)'));
    await tester.pumpAndSettle();

    // Verify list is filtered
    expect(find.text('4 consignes disponibles'), findsOneWidget);
    expect(find.text('Repérer une information explicite dans le texte'),
        findsOneWidget);

    // Tap 'Effacer' to clear action verb filter
    expect(find.text('Effacer'), findsOneWidget);
    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();

    expect(find.text('17 consignes disponibles'), findsOneWidget);
  });

  testWidgets(
      'Each instruction card renders a quick audio button without triggering card tap',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Find quick audio listen button on cards
    final audioButtons = find.text('Écouter');
    expect(audioButtons, findsWidgets);

    // Tap the first quick audio button
    await tester.tap(audioButtons.first);
    await tester.pump();

    // Verify we remain on the list screen and do NOT push InstructionDetailScreen
    expect(find.byType(InstructionDetailScreen), findsNothing);
    expect(find.byType(InstructionsScreen), findsOneWidget);
  });
}
