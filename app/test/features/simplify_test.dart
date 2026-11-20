import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lecture_aide/features/simplify/models/simplify_model.dart';
import 'package:lecture_aide/features/simplify/services/simplify_cache_service.dart';
import 'package:lecture_aide/features/simplify/data/french_curriculum_samples.dart';

void main() {
  group('Simplify Models and Data Tests', () {
    test('SimplifyResult serialization and deserialization works correctly', () {
      final sample = SimplifyResult(
        id: 'test_1',
        cycle: 'college',
        originalText: 'Un texte long et difficile.',
        summary: 'Un résumé clair en 3 phrases.',
        simplifiedText: 'Un texte simple. La syntaxe est allégée.',
        glosses: const [
          SimplifyWordGloss(
            word: 'difficile',
            definitionSimple: 'Qui n\'est pas facile à faire.',
          ),
        ],
        createdAt: DateTime(2026, 11, 14),
      );

      final json = sample.toJson();
      final fromJson = SimplifyResult.fromJson(json);

      expect(fromJson.id, 'test_1');
      expect(fromJson.cycle, 'college');
      expect(fromJson.originalText, 'Un texte long et difficile.');
      expect(fromJson.summary, 'Un résumé clair en 3 phrases.');
      expect(fromJson.simplifiedText, 'Un texte simple. La syntaxe est allégée.');
      expect(fromJson.glosses.length, 1);
      expect(fromJson.glosses.first.word, 'difficile');
      expect(fromJson.glosses.first.definitionSimple,
          'Qui n\'est pas facile à faire.');
    });

    test('French curriculum samples contains samples for all 3 cycles', () {
      final cycles = kFrenchCurriculumSamples.map((s) => s['cycle']).toSet();
      expect(cycles, containsAll(['primaire', 'college', 'lycee']));
      expect(kFrenchCurriculumSamples.length, 9);
    });
  });

  group('SimplifyCacheService Tests', () {
    late SharedPreferences prefs;
    late SimplifyCacheService cacheService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cacheService = SimplifyCacheService(prefs);
    });

    test('Saves, retrieves, and deduplicates by normalized text', () async {
      final item1 = SimplifyResult(
        id: 'item_1',
        cycle: 'college',
        originalText: 'Cosette traversait la forêt obscure...',
        summary: 'Cosette a peur dans la forêt.',
        simplifiedText: 'Cosette marche dans la forêt. Elle a peur.',
        glosses: const [],
        createdAt: DateTime.now(),
      );

      await cacheService.saveResult(item1);
      var history = cacheService.getHistory();
      expect(history.length, 1);
      expect(history.first.id, 'item_1');

      // Instant match lookup
      final found = cacheService.findInCache('cosette traversait la foret obscure...', 'college');
      expect(found, isNotNull);
      expect(found!.id, 'item_1');

      // Toggling favorite
      final isFav = await cacheService.toggleFavorite(item1);
      expect(isFav, isTrue);
      expect(cacheService.isFavorite('item_1', item1.originalText), isTrue);

      final isFavNow = await cacheService.toggleFavorite(item1);
      expect(isFavNow, isFalse);
    });
  });
}
