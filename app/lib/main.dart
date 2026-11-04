import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/learner_profile/learner_profile_notifier.dart';
import 'core/reading_settings/reading_settings_notifier.dart';
import 'core/theme/app_theme.dart';
import 'features/diagnostic/diagnostic_gate_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences? sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('⚠️ Erreur SharedPreferences: $e');
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const LectureAideApp(),
    ),
  );
}

class LectureAideApp extends ConsumerWidget {
  const LectureAideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readingSettingsProvider);
    final profile  = ref.watch(learnerProfileProvider);

    // ── Routing logic ─────────────────────────────────────────────────────
    // 1. Not yet chosen a level → OnboardingScreen (mandatory)
    // 2. Level chosen, diagnostic not done → DiagnosticGateScreen
    // 3. Everything done → HomeScreen
    final Widget home;
    if (!settings.isOnboardingCompleted) {
      home = const OnboardingScreen();
    } else if (!profile.isDiagnosticDone) {
      home = const DiagnosticGateScreen();
    } else {
      home = const HomeScreen();
    }

    return MaterialApp(
      title: "Aide à la Lecture et à l'Écriture",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(settings),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr')],
      locale: const Locale('fr'),
      home: home,
    );
  }
}
