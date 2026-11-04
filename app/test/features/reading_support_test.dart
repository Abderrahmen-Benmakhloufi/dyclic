import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/features/reading_support/reading_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ReadingSupportScreen switches between Input Mode and Reading Mode correctly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: ReadingSupportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial State: Mode Saisie
    expect(find.textContaining('Que souhaites-tu lire ?'), findsOneWidget);
    expect(find.text('Lire avec les aides'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Coller'), findsOneWidget);
    expect(find.text('Petite histoire'), findsOneWidget);
    expect(find.text('Exercice d’école'), findsOneWidget);
    expect(find.text('Phrase courte'), findsOneWidget);

    // 2. Empty submission shows warning
    await tester.tap(find.text('Lire avec les aides'));
    await tester.pumpAndSettle();
    expect(find.text('Colle ou écris d’abord un texte à lire.'), findsOneWidget);
    expect(find.textContaining('Que souhaites-tu lire ?'), findsOneWidget);

    // Wait for SnackBar to dismiss so it doesn't intercept touches later
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 3. Quick sample chip fills the text field
    await tester.tap(find.text('Phrase courte'));
    await tester.pumpAndSettle();
    expect(find.text('Le soleil brille et le ciel est bleu.'), findsOneWidget);

    // 4. Enter custom text and proceed
    await tester.enterText(find.byType(TextField), 'Le petit chat blanc dort tranquillement.');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lire avec les aides'));
    await tester.pumpAndSettle();

    // 5. Reading Mode: Serene reading canvas visible
    expect(find.textContaining('Que souhaites-tu lire ?'), findsNothing);
    expect(find.text('Le petit chat blanc dort tranquillement.'), findsOneWidget);
    expect(find.text('Modifier le texte'), findsWidgets);
    expect(find.text('Aides & Couleurs'), findsOneWidget);
    expect(find.text('Écouter'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);

    // Tapping a word in Reading Canvas activates pronunciation & visual highlight
    await tester.tap(find.text('Le petit chat blanc dort tranquillement.'));
    await tester.pump();

    // 6. Open Aides & Couleurs Interactive Modal Sheet
    await tester.tap(find.text('Aides & Couleurs'));
    await tester.pumpAndSettle();

    expect(find.text('Aides visuelles & Légende 🎨'), findsOneWidget);
    expect(find.text('Découpage des syllabes'), findsOneWidget);
    expect(find.text('Lettres muettes'), findsOneWidget);
    expect(find.text('Lettres miroirs (b / d / p / q)'), findsOneWidget);
    expect(find.text('Sons complexes'), findsOneWidget);
    expect(find.text('Voyelle E (é, è, ê)'), findsOneWidget);
    expect(find.text('Sons contextuels (C, G, S, Z)'), findsOneWidget);
    expect(find.text('Appliquer les repères ✨'), findsOneWidget);

    // 7. Toggle switches in the sheet
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // 8. Close sheet via Apply button
    await tester.tap(find.text('Appliquer les repères ✨'));
    await tester.pumpAndSettle();

    // 9. Return to Mode Saisie
    await tester.tap(find.text('Modifier le texte').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Que souhaites-tu lire ?'), findsOneWidget);
    expect(find.text('Le petit chat blanc dort tranquillement.'), findsOneWidget);
  });

  testWidgets('Reading aids persistence in SharedPreferences works correctly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: ReadingSupportScreen(key: Key('screen1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select short phrase and start reading
    await tester.tap(find.text('Phrase courte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lire avec les aides'));
    await tester.pumpAndSettle();

    // Find switches: Syllables is first and TRUE, Silent letters is second and FALSE
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches[0].value, isTrue); // Syllables
    expect(switches[1].value, isFalse); // Silent letters
    expect(switches[2].value, isFalse); // Mirror letters
    expect(switches[3].value, isFalse); // Complex sounds
    expect(switches[4].value, isFalse); // Vowel E
    expect(switches[5].value, isFalse); // Contextual letters

    // Toggle Silent letters (second switch)
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();

    // Verify persisted in SharedPreferences
    expect(prefs.getBool('reading_aid_silent_letters'), isTrue);

    // Now reload a new screen with the same SharedPreferences instance
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: ReadingSupportScreen(key: Key('screen2')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phrase courte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lire avec les aides'));
    await tester.pumpAndSettle();

    final reloadedSwitches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(reloadedSwitches[0].value, isTrue); // Syllables still true
    expect(reloadedSwitches[1].value, isTrue); // Silent letters now persisted as TRUE!
  });

  testWidgets('Half-screen modal settings and syllable visual modes work correctly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: ReadingSupportScreen(key: Key('half_screen_test')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fill sample and proceed to Reading Mode
    await tester.tap(find.text('Phrase courte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lire avec les aides'));
    await tester.pumpAndSettle();

    // 1. Syllable visual mode toggle (default is Blocs)
    expect(find.text('Blocs'), findsOneWidget);
    await tester.tap(find.text('Blocs'));
    await tester.pumpAndSettle();

    // Now should be Souligné and saved to SharedPreferences
    expect(find.text('Souligné'), findsOneWidget);
    expect(prefs.getString('reading_aid_syllable_visual_mode'), 'underlines');

    // Toggle back to Blocs
    await tester.tap(find.text('Souligné'));
    await tester.pumpAndSettle();
    expect(find.text('Blocs'), findsOneWidget);
    expect(prefs.getString('reading_aid_syllable_visual_mode'), 'translucentBoxes');

    // 2. Open typography settings via "Ajuster la police & taille"
    await tester.tap(find.text('Ajuster la police & taille'));
    await tester.pumpAndSettle();

    // Verify ReadingSettingsSheet opened in modal
    expect(find.text('Réglages de lecture'), findsOneWidget);
    expect(find.text('Taille du texte'), findsOneWidget);

    // Increase font size
    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();

    // Close the sheet via close button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Ensure sheet is dismissed and reading screen remains active
    expect(find.text('Réglages de lecture'), findsNothing);
    expect(find.text('Le soleil brille et le ciel est bleu.'), findsOneWidget);
  });
}
