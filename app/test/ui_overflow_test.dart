import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/features/about/about_us_screen.dart';
import 'package:lecture_aide/features/auth/login_screen.dart';
import 'package:lecture_aide/features/decoding/decoding_screen.dart';
import 'package:lecture_aide/features/home/home_screen.dart';
import 'package:lecture_aide/features/home/hubs/listening_hub_screen.dart';
import 'package:lecture_aide/features/home/hubs/reading_hub_screen.dart';
import 'package:lecture_aide/features/home/hubs/writing_hub_screen.dart';
import 'package:lecture_aide/features/instructions/instruction_ai_screen.dart';
import 'package:lecture_aide/features/onboarding/onboarding_screen.dart';
import 'package:lecture_aide/features/profile/profile_screen.dart';
import 'package:lecture_aide/features/simplify/models/simplify_model.dart';
import 'package:lecture_aide/features/simplify/simplify_result_screen.dart';
import 'package:lecture_aide/features/simplify/simplify_screen.dart';
import 'package:lecture_aide/features/writing/writing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const narrowSizes = [
    Size(320, 640), // iPhone SE / small Android
    Size(360, 800), // Standard Android
  ];

  for (final size in narrowSizes) {
    group('Screen Overflow Tests at ${size.width}x${size.height}', () {
      late SharedPreferences prefs;

      setUp(() async {
        SharedPreferences.setMockInitialValues({
          'learner_onboarding_completed': true,
          'learner_educational_level': 'moyen',
          'diag_completed': true,
        });
        prefs = await SharedPreferences.getInstance();
      });

      Future<void> testScreen(WidgetTester tester, Widget screen) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(home: screen),
          ),
        );
        await tester.pumpAndSettle();
        final ex = tester.takeException();
        if (ex != null) {
          debugPrint('>>> OVERFLOW on ${screen.runtimeType} at $size: $ex');
          if (ex is FlutterError) {
            debugPrint('>>> DETAILS: ${ex.diagnostics.map((d) => d.toString()).join('\n')}');
          }
        }
        expect(ex, isNull,
            reason: 'Overflow caught on ${screen.runtimeType} at $size');
      }

      testWidgets('SimplifyScreen has no overflow', (tester) async {
        await testScreen(tester, const SimplifyScreen());
      });

      testWidgets('SimplifyResultScreen has no overflow with long vocabulary', (tester) async {
        final sampleResult = SimplifyResult(
          id: 'test_123',
          cycle: 'college',
          originalText: 'Un long texte original difficile avec du vocabulaire.',
          summary: 'Voici le résumé en quelques phrases simples et claires.',
          simplifiedText: 'Voici le texte simplifié selon les règles FALC avec des phrases courtes.',
          glosses: const [
            SimplifyWordGloss(
              word: 'Incommensurablement',
              definitionSimple: 'D\'une manière tellement immense et gigantesque qu\'on ne peut pas du tout la mesurer avec un instrument ordinaire.',
            ),
            SimplifyWordGloss(
              word: 'Circonspection',
              definitionSimple: 'Prudence attentive et grande retenue avant d\'agir.',
            ),
          ],
          createdAt: DateTime.now(),
        );
        await testScreen(tester, SimplifyResultScreen(result: sampleResult));
      });

      testWidgets('WritingScreen has no overflow', (tester) async {
        await testScreen(tester, const WritingScreen());
      });

      testWidgets('InstructionAiScreen has no overflow', (tester) async {
        await testScreen(tester, const InstructionAiScreen());
      });

      testWidgets('HomeScreen has no overflow', (tester) async {
        await testScreen(tester, const HomeScreen());
      });

      testWidgets('ReadingHubScreen has no overflow', (tester) async {
        await testScreen(tester, const ReadingHubScreen());
      });

      testWidgets('ListeningHubScreen has no overflow', (tester) async {
        await testScreen(tester, const ListeningHubScreen());
      });

      testWidgets('WritingHubScreen has no overflow', (tester) async {
        await testScreen(tester, const WritingHubScreen());
      });

      testWidgets('DecodingScreen has no overflow', (tester) async {
        await testScreen(tester, const DecodingScreen());
      });

      testWidgets('LoginScreen has no overflow', (tester) async {
        await testScreen(tester, const LoginScreen());
      });

      testWidgets('OnboardingScreen has no overflow', (tester) async {
        await testScreen(tester, const OnboardingScreen());
      });

      testWidgets('AboutUsScreen has no overflow', (tester) async {
        await testScreen(tester, const AboutUsScreen());
      });

      testWidgets('ProfileScreen has no overflow', (tester) async {
        await testScreen(tester, const ProfileScreen());
      });
    });
  }
}
