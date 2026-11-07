import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/features/instructions/services/instruction_matching_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('InstructionMatchingService finds exact match from catalog', () async {
    const exactQuery =
        'Relève dans le premier paragraphe la phrase qui montre que le personnage principal est fatigué.';

    final match = await InstructionMatchingService.findBestMatch(
      query: exactQuery,
      cycle: 'primaire',
    );

    expect(match, isNotNull);
    expect(match!.isExact, isTrue);
    expect(match.confidence, equals(1.0));
    expect(match.item.id, equals('PRI-01'));
  });

  test('InstructionMatchingService matches high similarity substring', () async {
    const partialQuery = 'Relève dans le premier paragraphe la phrase qui montre que le personnage';

    final match = await InstructionMatchingService.findBestMatch(
      query: partialQuery,
      cycle: 'primaire',
    );

    expect(match, isNotNull);
    expect(match!.confidence, greaterThanOrEqualTo(0.70));
    expect(match.item.id, equals('PRI-01'));
  });

  test('InstructionMatchingService returns null for gibberish or unrelated queries', () async {
    const gibberish = 'xyz qwerty 12345 foo bar';

    final match = await InstructionMatchingService.findBestMatch(
      query: gibberish,
      cycle: 'primaire',
    );

    expect(match, isNull);
  });
}
