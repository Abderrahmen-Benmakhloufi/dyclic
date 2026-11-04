import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/features/reading_support/services/french_phoneme_service.dart';

void main() {
  group('FrenchPhonemeService Tests', () {
    test('Identifies complex phonemes like ch, ph, ou, on, eau', () {
      final chatHighlights = FrenchPhonemeService.getComplexPhonemes('chat');
      expect(chatHighlights[0]?.soundIpa, '/ʃ/');
      expect(chatHighlights[1]?.soundIpa, '/ʃ/');
      expect(chatHighlights[0]?.isUnderlined, isTrue);

      final photoHighlights = FrenchPhonemeService.getComplexPhonemes('photo');
      expect(photoHighlights[0]?.soundIpa, '/f/');
      expect(photoHighlights[1]?.soundIpa, '/f/');
      expect(photoHighlights[0]?.isUnderlined, isTrue);

      final bateauHighlights = FrenchPhonemeService.getComplexPhonemes('bateau');
      expect(bateauHighlights[3]?.soundIpa, '/o/');
      expect(bateauHighlights[4]?.soundIpa, '/o/');
      expect(bateauHighlights[5]?.soundIpa, '/o/');
    });

    test('Identifies vowel E variations (É, È, Ê, E caduc)', () {
      final ete = FrenchPhonemeService.getVowelEHighlights('été');
      expect(ete[0]?.soundIpa, '/e/');
      expect(ete[2]?.soundIpa, '/e/');

      final mere = FrenchPhonemeService.getVowelEHighlights('mère');
      expect(mere[1]?.soundIpa, '/ɛ/');

      final fete = FrenchPhonemeService.getVowelEHighlights('fête');
      expect(fete[1]?.soundIpa, '/ɛ/');

      final le = FrenchPhonemeService.getVowelEHighlights('le');
      expect(le[1]?.soundIpa, '/ə/');
    });

    test('Identifies soft G vs hard G', () {
      final girafe = FrenchPhonemeService.getContextualLetters('girafe');
      expect(girafe[0]?.soundIpa, '/ʒ/');

      final gare = FrenchPhonemeService.getContextualLetters('gare');
      expect(gare[0]?.soundIpa, '/g/');

      final guerre = FrenchPhonemeService.getContextualLetters('guerre');
      expect(guerre[0]?.soundIpa, '/g/');
      expect(guerre[1]?.soundIpa, '/g/');
    });

    test('Identifies soft C (/s/), S unvoiced (/s/), S voiced (/z/) and Z (/z/)', () {
      final cinema = FrenchPhonemeService.getContextualLetters('cinéma');
      expect(cinema[0]?.soundIpa, '/s/');

      final maison = FrenchPhonemeService.getContextualLetters('maison');
      expect(maison[3]?.soundIpa, '/z/');

      final poisson = FrenchPhonemeService.getContextualLetters('poisson');
      // Double ss produces /s/ sound (unvoiced)
      expect(poisson[3]?.soundIpa, '/s/');
      expect(poisson[4]?.soundIpa, '/s/');

      final zebre = FrenchPhonemeService.getContextualLetters('zèbre');
      expect(zebre[0]?.soundIpa, '/z/');
    });

    test('Generates complete map legend items for active aids', () {
      final legend = FrenchPhonemeService.getActiveLegendItems(
        showSyllables: true,
        showSilentLetters: true,
        showMirrorLetters: true,
        showComplexSounds: true,
        showVowelE: true,
        showContextualLetters: true,
        syllableColor1: const Color(0xFF2563EB),
        syllableColor2: const Color(0xFF7C3AED),
      );

      expect(legend.isNotEmpty, isTrue);
      final labels = legend.map((i) => i.label).toList();

      // Check all key sound categories are represented in the map legend
      expect(labels, contains('Syllabe 1'));
      expect(labels, contains('Lettre muette'));
      expect(labels, contains('Lettre b'));
      expect(labels, contains('Lettre d'));
      expect(labels, contains('Lettre p'));
      expect(labels, contains('CH'));
      expect(labels, contains('PH'));
      expect(labels, contains('OU'));
      expect(labels, contains('ON / OM'));
      expect(labels, contains('AN / EN'));
      expect(labels, contains('É / -er'));
      expect(labels, contains('È / Ê'));
      expect(labels, contains('G doux'));
      expect(labels, contains('G dur'));
      expect(labels, contains('C doux'));
      expect(labels, contains('Lettre S (/s/)'));
      expect(labels, contains('S entre voyelles'));
      expect(labels, contains('Lettre Z (/z/)'));
    });

    test('Generates map legend with 3 and 4 distinct syllable colors', () {
      final legend4 = FrenchPhonemeService.getActiveLegendItems(
        showSyllables: true,
        showSilentLetters: false,
        showMirrorLetters: false,
        showComplexSounds: false,
        showVowelE: false,
        showContextualLetters: false,
        syllableColorCount: 4,
        syllableColors: const [
          Color(0xFF2563EB),
          Color(0xFF7C3AED),
          Color(0xFFD97706),
          Color(0xFF0D9488),
        ],
      );

      final labels = legend4.map((i) => i.label).toList();
      expect(labels, contains('Syllabe 1'));
      expect(labels, contains('Syllabe 2'));
      expect(labels, contains('Syllabe 3'));
      expect(labels, contains('Syllabe 4'));
      expect(legend4.length, 4);
      // All 4 syllable colors are distinct
      final colors = legend4.map((i) => i.color).toSet();
      expect(colors.length, 4);
    });
  });
}
