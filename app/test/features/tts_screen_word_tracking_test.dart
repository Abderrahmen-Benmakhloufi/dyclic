import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/features/tts/tts_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('TtsScreen displays live word-by-word tracking during continuous speech',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: TtsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Type a sample French sentence
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    await tester.enterText(textField, 'Le petit chat dort.');
    await tester.pumpAndSettle();

    // Verify word container renders
    expect(find.text('Touche un mot pour l\'écouter individuellement :'), findsOneWidget);
    expect(find.textContaining('Le petit chat dort.'), findsWidgets);

    // Tap speak button
    final speakButton = find.text('Écouter à voix haute');
    expect(speakButton, findsOneWidget);
    await tester.tap(speakButton);
    await tester.pump();

    // Now it should show 'Lecture en cours (suivi mot à mot) :'
    expect(find.text('Lecture en cours (suivi mot à mot) :'), findsOneWidget);
    expect(find.text('Arrêter la lecture'), findsOneWidget);

    // Advance timer slightly to test word progression
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 400));

    // Tap stop button
    final stopButton = find.text('Arrêter la lecture');
    expect(stopButton, findsOneWidget);
    await tester.tap(stopButton);
    await tester.pumpAndSettle();

    // Reverts to idle
    expect(find.text('Écouter à voix haute'), findsOneWidget);
    expect(find.text('Touche un mot pour l\'écouter individuellement :'), findsOneWidget);
  });
}
