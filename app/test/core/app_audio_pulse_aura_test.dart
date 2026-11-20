import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/core/widgets/app_audio_pulse_aura.dart';

void main() {
  testWidgets('AppAudioPulseAura renders child and handles pulsing state gracefully', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppAudioPulseAura(
            isPulsing: false,
            child: Text('Headphones'),
          ),
        ),
      ),
    );

    expect(find.text('Headphones'), findsOneWidget);

    // Switch to pulsing
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppAudioPulseAura(
            isPulsing: true,
            child: Text('Headphones'),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Headphones'), findsOneWidget);

    // Switch back to idle
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppAudioPulseAura(
            isPulsing: false,
            child: Text('Headphones'),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Headphones'), findsOneWidget);
  });
}
