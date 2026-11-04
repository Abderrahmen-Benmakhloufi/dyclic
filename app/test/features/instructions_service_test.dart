import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/features/instructions/models/instruction_model.dart';
import 'package:lecture_aide/features/instructions/services/instructions_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Instructions Data and Model Tests', () {
    late List<InstructionItem> instructions;

    setUpAll(() {
      final file = File('assets/data/consignes.json');
      expect(file.existsSync(), isTrue,
          reason: 'consignes.json must exist in assets/data/');

      final jsonContent = file.readAsStringSync();
      final decoded = jsonDecode(jsonContent) as List<dynamic>;

      instructions = decoded
          .map((item) => InstructionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    });

    test('Loads exactly 17 decomposed instructions', () {
      expect(instructions.length, 17);
    });

    test('Cycle distribution matches specification (5 Primaire, 7 Collège, 5 Lycée)', () {
      final primaire =
          instructions.where((i) => i.cycle == 'primaire').toList();
      final college = instructions.where((i) => i.cycle == 'college').toList();
      final lycee = instructions.where((i) => i.cycle == 'lycee').toList();

      expect(primaire.length, 5);
      expect(college.length, 7);
      expect(lycee.length, 5);
    });

    test('Question type distribution matches specification (8 Compréhension, 5 Langue, 4 Production)', () {
      final comp = instructions.where((i) => i.questionType == 'comprehension').toList();
      final langue = instructions.where((i) => i.questionType == 'langue').toList();
      final prod = instructions.where((i) => i.questionType == 'production').toList();

      expect(comp.length, 8);
      expect(langue.length, 5);
      expect(prod.length, 4);
    });

    test('Every instruction contains all mandatory pedagogical fields in French only', () {
      for (final item in instructions) {
        expect(item.id.isNotEmpty, isTrue);
        expect(item.title.isNotEmpty, isTrue);
        expect(item.level.isNotEmpty, isTrue);
        expect(item.domain.isNotEmpty, isTrue);
        expect(item.questionType.isNotEmpty, isTrue);
        expect(item.originalFr.isNotEmpty, isTrue);
        expect(item.steps.length, greaterThanOrEqualTo(2),
            reason: '${item.id} should have at least 2 decomposed steps');

        for (final step in item.steps) {
          expect(step.stepNumber, greaterThan(0));
          expect(step.textFr.isNotEmpty, isTrue);
        }
      }
    });

    test('Filter by cycle works correctly', () {
      final service = InstructionsService.instance;

      final all = service.filterAndSearch(items: instructions, cycle: 'all');
      expect(all.length, 17);

      final pri =
          service.filterAndSearch(items: instructions, cycle: 'primaire');
      expect(pri.length, 5);
      expect(pri.every((i) => i.cycle == 'primaire'), isTrue);

      final col =
          service.filterAndSearch(items: instructions, cycle: 'college');
      expect(col.length, 7);
      expect(col.every((i) => i.cycle == 'college'), isTrue);

      final lyc =
          service.filterAndSearch(items: instructions, cycle: 'lycee');
      expect(lyc.length, 5);
      expect(lyc.every((i) => i.cycle == 'lycee'), isTrue);
    });

    test('Filter by questionType works correctly', () {
      final service = InstructionsService.instance;

      final all = service.filterAndSearch(items: instructions, questionType: 'all');
      expect(all.length, 17);

      final comp = service.filterAndSearch(items: instructions, questionType: 'comprehension');
      expect(comp.length, 8);
      expect(comp.every((i) => i.questionType == 'comprehension'), isTrue);

      final langue = service.filterAndSearch(items: instructions, questionType: 'langue');
      expect(langue.length, 5);
      expect(langue.every((i) => i.questionType == 'langue'), isTrue);

      final prod = service.filterAndSearch(items: instructions, questionType: 'production');
      expect(prod.length, 4);
      expect(prod.every((i) => i.questionType == 'production'), isTrue);
    });

    test('Combined filter (cycle + questionType) works correctly', () {
      final service = InstructionsService.instance;

      final collegeProd = service.filterAndSearch(
        items: instructions,
        cycle: 'college',
        questionType: 'production',
      );
      expect(collegeProd.length, 1);
      expect(collegeProd.first.id, 'MOY-04');
    });

    test('Search query matches title, keywords, and steps correctly', () {
      final service = InstructionsService.instance;

      // Searching for "argument" should find MOY-04 and SEC-04
      final argumentResults =
          service.filterAndSearch(items: instructions, query: 'argument');
      expect(argumentResults.isNotEmpty, isTrue);
      expect(argumentResults.any((i) => i.id == 'MOY-04'), isTrue);

      // Searching for "Vrai"
      final vraiResults =
          service.filterAndSearch(items: instructions, query: 'Vrai');
      expect(vraiResults.any((i) => i.id == 'PRI-02'), isTrue);
      expect(vraiResults.any((i) => i.id == 'MOY-02'), isTrue);

      // Empty query returns all
      final emptyResults =
          service.filterAndSearch(items: instructions, query: '   ');
      expect(emptyResults.length, 17);
    });
  });
}
