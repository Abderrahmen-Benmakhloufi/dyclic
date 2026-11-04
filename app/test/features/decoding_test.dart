import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/core/tts/tts_service.dart';
import 'package:lecture_aide/features/decoding/data/decoding_rules_data.dart';
import 'package:lecture_aide/features/decoding/decoding_screen.dart';

class FakeTtsService extends TtsService {
  String? lastSpokenWord;

  @override
  Future<void> speakWord(String word) async {
    lastSpokenWord = word;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Decoding Rules Catalog Validation', () {
    test('Catalog contains all 7 rules requested in pedagogy specs', () {
      expect(decodingRulesCatalog.length, 7);

      final ruleIds = decodingRulesCatalog.map((r) => r.id).toList();
      expect(ruleIds, containsAll([
        'rule_g',
        'rule_s',
        'rule_c',
        'rule_ch',
        'rule_ph',
        'rule_e',
        'rule_muettes',
      ]));
    });

    test('All example highlight indices are within word bounds', () {
      for (final rule in decodingRulesCatalog) {
        expect(rule.titleFr.isNotEmpty, isTrue);
        expect(rule.subRules.isNotEmpty, isTrue);

        for (final sub in rule.subRules) {
          expect(sub.soundIpa.isNotEmpty, isTrue);
          expect(sub.examples.isNotEmpty, isTrue);

          for (final ex in sub.examples) {
            expect(ex.word.isNotEmpty, isTrue);
            for (final idx in ex.highlightIndices) {
              expect(idx, greaterThanOrEqualTo(0));
              expect(idx, lessThan(ex.word.length),
                  reason: 'Index $idx out of bounds for word "${ex.word}" in ${rule.id}');
            }
          }
        }
      }
    });
  });

  group('DecodingScreen Widget Tests', () {
    testWidgets('Renders all rules, filters by letter, and plays word audio', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeTts = FakeTtsService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            ttsServiceProvider.overrideWithValue(fakeTts),
          ],
          child: const MaterialApp(
            home: DecodingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Initial State: Title and filter chips
      expect(find.text('Aide au décodage'), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_Toutes')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_G')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_S')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_CH')), findsOneWidget);

      // 2. Initial list shows all rules
      expect(find.text('La lettre G'), findsOneWidget);
      expect(find.text('La lettre S'), findsOneWidget);

      // 3. Filter by CH
      await tester.tap(find.byKey(const ValueKey('filter_CH')));
      await tester.pumpAndSettle();

      expect(find.text('Le groupe de lettres CH'), findsOneWidget);
      expect(find.text('La lettre G'), findsNothing);
      expect(find.text('La lettre S'), findsNothing);

      // 4. Tap an example word ("chat") to trigger audio
      final wordChat = find.byKey(const ValueKey('word_chat'));
      expect(wordChat, findsOneWidget);
      await tester.tap(wordChat);
      await tester.pump();

      expect(fakeTts.lastSpokenWord, 'chat');

      // Allow speaking indicator timer to complete
      await tester.pump(const Duration(seconds: 2));

      // 5. Reset to all rules
      await tester.tap(find.byKey(const ValueKey('filter_Toutes')));
      await tester.pumpAndSettle();

      expect(find.text('La lettre G'), findsOneWidget);
    });
  });
}
