import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/features/reading_support/services/french_syllable_service.dart';

void main() {
  group('FrenchSyllableService Tests', () {
    test('Monosyllables are not split', () {
      expect(FrenchSyllableService.segmentWord('le'), ['le']);
      expect(FrenchSyllableService.segmentWord('chat'), ['chat']);
      expect(FrenchSyllableService.segmentWord('grand'), ['grand']);
      expect(FrenchSyllableService.segmentWord('un'), ['un']);
      expect(FrenchSyllableService.segmentWord('dans'), ['dans']);
    });

    test('VCV structure splits before single consonant', () {
      expect(FrenchSyllableService.segmentWord('cheval'), ['che', 'val']);
      expect(FrenchSyllableService.segmentWord('café'), ['ca', 'fé']);
      expect(FrenchSyllableService.segmentWord('ami'), ['a', 'mi']);
      expect(FrenchSyllableService.segmentWord('vélo'), ['vé', 'lo']);
    });

    test('VCCV structure splits between identical or distinct consonants', () {
      expect(FrenchSyllableService.segmentWord('pomme'), ['pom', 'me']);
      expect(FrenchSyllableService.segmentWord('ballon'), ['bal', 'lon']);
      expect(FrenchSyllableService.segmentWord('parler'), ['par', 'ler']);
      expect(FrenchSyllableService.segmentWord('porte'), ['por', 'te']);
    });

    test('Inseparable clusters are kept together with following vowel', () {
      expect(FrenchSyllableService.segmentWord('tableau'), ['ta', 'bleau']);
      expect(FrenchSyllableService.segmentWord('livre'), ['li', 'vre']);
      expect(FrenchSyllableService.segmentWord('chèvre'), ['chè', 'vre']);
      expect(FrenchSyllableService.segmentWord('machine'), ['ma', 'chi', 'ne']);
      expect(FrenchSyllableService.segmentWord('montagne'), ['mon', 'ta', 'gne']);
    });

    test('Complex vowel digraphs stay intact', () {
      expect(FrenchSyllableService.segmentWord('maison'), ['mai', 'son']);
      expect(FrenchSyllableService.segmentWord('château'), ['châ', 'teau']);
      expect(FrenchSyllableService.segmentWord('bonjour'), ['bon', 'jour']);
    });

    test('Preserves capitalization', () {
      expect(FrenchSyllableService.segmentWord('Cheval'), ['Che', 'val']);
      expect(FrenchSyllableService.segmentWord('Tableau'), ['Ta', 'bleau']);
    });
  });
}
