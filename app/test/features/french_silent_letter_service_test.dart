import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/features/reading_support/services/french_silent_letter_service.dart';

void main() {
  group('FrenchSilentLetterService Tests', () {
    test('Detects final silent consonants in singular words', () {
      expect(FrenchSilentLetterService.getSilentIndices('chat'), {3});    // 't'
      expect(FrenchSilentLetterService.getSilentIndices('grand'), {4});   // 'd'
      expect(FrenchSilentLetterService.getSilentIndices('loup'), {3});    // 'p'
      expect(FrenchSilentLetterService.getSilentIndices('deux'), {3});    // 'x'
      expect(FrenchSilentLetterService.getSilentIndices('blanc'), {4});   // 'c' après 'n'
      expect(FrenchSilentLetterService.getSilentIndices('porc'), {3});    // 'c' après 'r'
    });

    test('Detects final silent consonants and -s in plural words', () {
      expect(FrenchSilentLetterService.getSilentIndices('chats'), {3, 4});  // 't', 's'
      expect(FrenchSilentLetterService.getSilentIndices('grands'), {4, 5}); // 'd', 's'
      expect(FrenchSilentLetterService.getSilentIndices('loups'), {3, 4});  // 'p', 's'
      expect(FrenchSilentLetterService.getSilentIndices('amis'), {3});      // 's'
      expect(FrenchSilentLetterService.getSilentIndices('livres'), {5});    // 's'
    });

    test('Detects internal silent letters for specific words', () {
      expect(FrenchSilentLetterService.getSilentIndices('doigt'), {3, 4}); // 'g', 't'
      expect(FrenchSilentLetterService.getSilentIndices('temps'), {3, 4}); // 'p', 's'
      expect(FrenchSilentLetterService.getSilentIndices('corps'), {3, 4}); // 'p', 's'
      expect(FrenchSilentLetterService.getSilentIndices('vingt'), {3, 4}); // 'g', 't'
      expect(FrenchSilentLetterService.getSilentIndices('sept'), {2});     // 'p' (t prononcé)
      expect(FrenchSilentLetterService.getSilentIndices('compter'), {2});  // 'p'
    });

    test('Detects silent -ent in 3rd person plural verbs', () {
      // 'chantent' len=8 -> indices 5,6,7 ('e','n','t')
      expect(FrenchSilentLetterService.getSilentIndices('chantent'), {5, 6, 7});
      expect(FrenchSilentLetterService.getSilentIndices('parlent'), {4, 5, 6});
      expect(FrenchSilentLetterService.getSilentIndices('mangent'), {4, 5, 6});
      expect(FrenchSilentLetterService.getSilentIndices('aiment'), {3, 4, 5});
    });

    test('Does NOT mark pronounced endings as silent', () {
      expect(FrenchSilentLetterService.getSilentIndices('sud'), <int>{});
      expect(FrenchSilentLetterService.getSilentIndices('bus'), <int>{});
      expect(FrenchSilentLetterService.getSilentIndices('ours'), <int>{});
      expect(FrenchSilentLetterService.getSilentIndices('mars'), <int>{});
      expect(FrenchSilentLetterService.getSilentIndices('sac'), <int>{});
      expect(FrenchSilentLetterService.getSilentIndices('avec'), <int>{});
      expect(FrenchSilentLetterService.getSilentIndices('net'), <int>{});
      expect(FrenchSilentLetterService.getSilentIndices('brut'), <int>{});
      expect(FrenchSilentLetterService.getSilentIndices('direct'), <int>{});
      // Dans les noms et adverbes en -ent (-ment), seul le 't' final est muet, 'e' et 'n' forment le son /ɑ̃/
      expect(FrenchSilentLetterService.getSilentIndices('moment'), {5});
      expect(FrenchSilentLetterService.getSilentIndices('vent'), {3});
      expect(FrenchSilentLetterService.getSilentIndices('doucement'), {8}); // len=9, seul 't' est muet
      expect(FrenchSilentLetterService.getSilentIndices('lentement'), {8}); // len=9, seul 't' est muet
      expect(FrenchSilentLetterService.getSilentIndices('content'), {6});   // len=7, seul 't' est muet
    });
  });
}
