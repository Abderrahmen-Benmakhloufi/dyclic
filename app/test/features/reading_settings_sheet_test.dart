import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_notifier.dart';
import 'package:lecture_aide/features/reading_settings/reading_settings_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('ReadingSettingsSheet scrolls cleanly on small screen without overflow',
      (tester) async {
    // Small phone screen (360x640) where settings exceed 88% viewport height
    tester.view.physicalSize = const Size(360, 640);
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
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ReadingSettingsSheet.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Réglages de lecture'), findsOneWidget);

    // Verify we can scroll down to the bottom button cleanly
    final scrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Fermer les réglages'),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(find.text('Fermer les réglages'), findsOneWidget);
  });
}
