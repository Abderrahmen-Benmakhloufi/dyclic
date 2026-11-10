import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/features/writing/models/writing_feedback_model.dart';
import 'package:lecture_aide/features/writing/services/writing_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late WritingCacheService cacheService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cacheService = WritingCacheService(prefs);
  });

  final sampleResult = WritingFeedbackResult(
    id: 'WR-01',
    originalText: 'Le chavel mange.',
    subjectPrompt: 'Décris un animal.',
    cycle: 'primaire',
    encouragementFr: 'Bravo pour ta phrase !',
    strengthsFr: 'Tu as mis la majuscule et le point.',
    topicRelevanceFr: 'Le sujet est bien respecté.',
    correctedFullText: 'Le cheval mange.',
    errors: const [
      WritingErrorItem(
        wrongText: 'chavel',
        correctedText: 'cheval',
        sentenceContext: 'Le chavel mange.',
        category: WritingErrorCategory.inversion,
        explanationFr: 'Les lettres e et a ont été inversées.',
        tipFr: 'Prononce lentement chaque syllabe : che-val.',
      ),
    ],
    createdAtMs: 1700000000000,
  );

  test('WritingErrorCategory maps codes to labels and emojis properly', () {
    expect(WritingErrorCategoryX.fromCode('inversion'),
        equals(WritingErrorCategory.inversion));
    expect(WritingErrorCategoryX.fromCode('phonetique'),
        equals(WritingErrorCategory.phonetique));
    expect(WritingErrorCategoryX.fromCode('regle_lecture'),
        equals(WritingErrorCategory.regleLecture));
    expect(WritingErrorCategoryX.fromCode('grammaire'),
        equals(WritingErrorCategory.grammaire));
    expect(WritingErrorCategoryX.fromCode('ponctuation'),
        equals(WritingErrorCategory.ponctuation));
    expect(WritingErrorCategory.inversion.labelFr,
        equals('Inversion & Confusion'));
  });

  test('WritingCacheService saves, retrieves, and caches by normalized text',
      () async {
    expect(cacheService.getHistory(), isEmpty);

    await cacheService.saveResult(sampleResult);

    final history = cacheService.getHistory();
    expect(history.length, equals(1));
    expect(history.first.id, equals('WR-01'));
    expect(history.first.errors.first.category,
        equals(WritingErrorCategory.inversion));

    final cached = cacheService.findInCache(
      '  le chavel   mange. ',
      subject: 'décris un animal.',
      cycle: 'primaire',
    );
    expect(cached, isNotNull);
    expect(cached!.id, equals('WR-01'));
  });

  test('WritingCacheService toggles and persists favorites', () async {
    expect(cacheService.isFavorite('WR-01'), isFalse);

    final added = await cacheService.toggleFavorite(sampleResult);
    expect(added, isTrue);
    expect(cacheService.isFavorite('WR-01'), isTrue);
    expect(cacheService.getFavorites().length, equals(1));

    final removed = await cacheService.toggleFavorite(sampleResult);
    expect(removed, isFalse);
    expect(cacheService.isFavorite('WR-01'), isFalse);
    expect(cacheService.getFavorites(), isEmpty);
  });
}
