import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/features/home/home_screen.dart';
import 'package:lecture_aide/features/reading_support/calibration/reading_calibration_screen.dart';
import 'package:lecture_aide/features/reading_support/reading_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reading Calibration Wizard Tests', () {
    testWidgets('First time opening reading support routes to ReadingCalibrationScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'learner_onboarding_completed': true,
        'diagnostic_completed': true,
        'reading_calibration_completed': false,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "M'aider à lire"
      await tester.tap(find.text('M’aider à lire'));
      await tester.pumpAndSettle();

      // Should open Calibration Screen because calibration is not completed
      expect(find.byType(ReadingCalibrationScreen), findsOneWidget);
      expect(find.text('Calibrage de lecture'), findsOneWidget);
      expect(find.text('Aperçu en direct'), findsOneWidget);
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      expect(find.text('1. Taille du texte'), findsOneWidget);
    });

    testWidgets('Full 3-step calibration flow completes and persists default settings', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'reading_calibration_completed': false,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: ReadingCalibrationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Typography & Size
      expect(find.text('Étape 1 sur 3'), findsOneWidget);
      expect(find.text('Atkinson Hyperlegible'), findsWidgets);

      // Select Lexend font
      await tester.tap(find.text('Lexend'));
      await tester.pumpAndSettle();

      // Next to Step 2
      final nextBtn = find.byKey(const ValueKey('calibration_next_btn'));
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Step 2: Spacing
      expect(find.text('Étape 2 sur 3'), findsOneWidget);
      expect(find.text('1. Espacement entre les lettres'), findsOneWidget);
      expect(find.text('2. Espacement entre les mots'), findsOneWidget);
      expect(find.text('3. Hauteur des lignes'), findsOneWidget);

      // Next to Step 3
      await tester.tap(find.byKey(const ValueKey('calibration_next_btn')));
      await tester.pumpAndSettle();

      // Step 3: Contrast & Color
      expect(find.text('Étape 3 sur 3'), findsOneWidget);
      expect(find.text('Ambiance visuelle et contraste'), findsOneWidget);
      expect(find.text('Mode Sombre'), findsOneWidget);

      // Select Mode Sombre
      await tester.tap(find.text('Mode Sombre'));
      await tester.pumpAndSettle();

      // Finish calibration
      final finishBtn = find.byKey(const ValueKey('calibration_finish_btn'));
      expect(finishBtn, findsOneWidget);
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // Should transition to ReadingSupportScreen
      expect(find.byType(ReadingSupportScreen), findsOneWidget);

      // Verify settings were persisted into SharedPreferences
      expect(prefs.getBool('reading_calibration_completed'), isTrue);
      expect(prefs.getString('reading_font_family'), 'Lexend');
      expect(prefs.getString('reading_contrast_preset'), 'sombre');
    });

    testWidgets('Subsequent opening goes straight to ReadingSupportScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'reading_calibration_completed': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "M'aider à lire"
      await tester.tap(find.text('M’aider à lire'));
      await tester.pumpAndSettle();

      // Should open ReadingSupportScreen directly
      expect(find.byType(ReadingSupportScreen), findsOneWidget);
      expect(find.byType(ReadingCalibrationScreen), findsNothing);
    });
  });
}
