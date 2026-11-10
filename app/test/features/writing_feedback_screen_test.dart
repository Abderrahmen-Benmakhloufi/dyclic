import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/features/writing/models/writing_feedback_model.dart';
import 'package:lecture_aide/features/writing/services/writing_cache_service.dart';
import 'package:lecture_aide/features/writing/writing_feedback_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final sampleFeedback = WritingFeedbackResult(
    id: 'WR-TEST-1',
    originalText: 'Un gran chavel.',
    subjectPrompt: 'Décris un animal.',
    cycle: 'primaire',
    encouragementFr: 'Bravo pour ton effort !',
    strengthsFr: 'Bonne idée de description.',
    topicRelevanceFr: 'Tu as bien décrit un animal.',
    correctedFullText: 'Un grand cheval.',
    errors: const [
      WritingErrorItem(
        wrongText: 'gran',
        correctedText: 'grand',
        sentenceContext: 'Un gran chavel.',
        category: WritingErrorCategory.phonetique,
        explanationFr: 'Il manque la lettre muette d à la fin.',
        tipFr: 'Pense au féminin : grande !',
      ),
      WritingErrorItem(
        wrongText: 'chavel',
        correctedText: 'cheval',
        sentenceContext: 'Un gran chavel.',
        category: WritingErrorCategory.inversion,
        explanationFr: 'Les lettres e et a sont inversées.',
        tipFr: 'Lis syllabe par syllabe : che - val.',
      ),
    ],
    createdAtMs: 1700000000000,
  );

  Widget createTestWidget(WritingFeedbackResult result) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: WritingFeedbackScreen(result: result),
      ),
    );
  }

  testWidgets('WritingFeedbackScreen displays summary, errors, and hides corrected text initially',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget(sampleFeedback));
    await tester.pumpAndSettle();

    expect(find.text("Mon bilan d'écriture"), findsOneWidget);
    expect(find.text('Bravo pour ton effort !'), findsOneWidget);
    expect(find.text('Bonne idée de description.'), findsOneWidget);
    expect(find.text('Tu as bien décrit un animal.'), findsOneWidget);

    expect(find.text('Comprendre tes erreurs (2)'), findsOneWidget);
    expect(find.text('❌ gran'), findsOneWidget);
    expect(find.text('✅ grand'), findsOneWidget);
    expect(find.text('❌ chavel'), findsOneWidget);
    expect(find.text('✅ cheval'), findsOneWidget);

    // Full corrected text is hidden behind pedagogical reveal button
    expect(find.text('Un grand cheval.'), findsNothing);
    expect(find.text('Voir mon texte corrigé 👀'), findsOneWidget);
  });

  testWidgets('Tapping "Voir mon texte corrigé 👀" reveals the corrected text',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget(sampleFeedback));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voir mon texte corrigé 👀'));
    await tester.pumpAndSettle();

    expect(find.text('✅ Version corrigée complète'), findsOneWidget);
    expect(find.text('Un grand cheval.'), findsOneWidget);
  });

  testWidgets('Category filter chips filter displayed error cards',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget(sampleFeedback));
    await tester.pumpAndSettle();

    // Tap Inversion & Confusion filter
    await tester.tap(find.text('🔄 Inversion & Confusion (1)'));
    await tester.pumpAndSettle();

    expect(find.text('❌ chavel'), findsOneWidget);
    expect(find.text('❌ gran'), findsNothing);

    // Tap Toutes filter
    await tester.tap(find.text('Toutes (2)'));
    await tester.pumpAndSettle();

    expect(find.text('❌ gran'), findsOneWidget);
    expect(find.text('❌ chavel'), findsOneWidget);
  });

  testWidgets('Favorite star toggles and saves to WritingCacheService',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget(sampleFeedback));
    await tester.pumpAndSettle();

    final cacheService = WritingCacheService(prefs);
    expect(cacheService.isFavorite('WR-TEST-1'), isFalse);

    await tester.tap(find.byIcon(Icons.star_outline_rounded));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.star_rounded),
      ),
      findsOneWidget,
    );
    expect(cacheService.isFavorite('WR-TEST-1'), isTrue);
  });
}
