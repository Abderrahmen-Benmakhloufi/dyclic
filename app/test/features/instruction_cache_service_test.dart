import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/features/instructions/models/instruction_model.dart';
import 'package:lecture_aide/features/instructions/services/instruction_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late InstructionCacheService cacheService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cacheService = InstructionCacheService(prefs);
  });

  const sampleItem = InstructionItem(
    id: 'TEST-01',
    title: 'Test instruction',
    cycle: 'primaire',
    level: 'Primaire',
    domain: 'Compréhension',
    questionType: 'comprehension',
    originalFr: 'Relève dans le texte les mots...',
    steps: [
      InstructionStep(stepNumber: 1, textFr: 'Première étape'),
      InstructionStep(stepNumber: 2, textFr: 'Deuxième étape'),
    ],
  );

  test('InstructionCacheService saves and retrieves history', () async {
    expect(cacheService.getHistory(), isEmpty);

    await cacheService.saveInstruction(sampleItem);

    final history = cacheService.getHistory();
    expect(history.length, equals(1));
    expect(history.first.id, equals('TEST-01'));
    expect(history.first.title, equals('Test instruction'));
  });

  test('InstructionCacheService findInCache matches normalized text', () async {
    await cacheService.saveInstruction(sampleItem);

    // Query with different casing and extra spaces
    final found = cacheService.findInCache('  RELÈVE DANS LE TEXTE les mots...  ');
    expect(found, isNotNull);
    expect(found!.id, equals('TEST-01'));

    final notFound = cacheService.findInCache('Question inconnue');
    expect(notFound, isNull);
  });

  test('InstructionCacheService delete and clear work properly', () async {
    await cacheService.saveInstruction(sampleItem);
    expect(cacheService.getHistory().length, equals(1));

    await cacheService.deleteInstruction('TEST-01');
    expect(cacheService.getHistory(), isEmpty);

    await cacheService.saveInstruction(sampleItem);
    await cacheService.clearHistory();
    expect(cacheService.getHistory(), isEmpty);
  });
}
