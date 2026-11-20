import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/core/widgets/app_card_press_effect.dart';

void main() {
  testWidgets('AppCardPressEffect scales down on tap and triggers callback', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCardPressEffect(
            onTap: () => tapped = true,
            pressedScale: 0.95,
            child: const Text('Press Me'),
          ),
        ),
      ),
    );

    expect(find.text('Press Me'), findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(find.text('Press Me')));
    await tester.pump(const Duration(milliseconds: 50));

    // Scale during press
    final scaleFinder = find.byType(AnimatedScale);
    expect(scaleFinder, findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
