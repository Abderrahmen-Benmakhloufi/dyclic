import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/learner_profile/learner_profile_notifier.dart';
import 'core/reading_settings/reading_settings_notifier.dart';
import 'core/theme/app_theme.dart';
import 'features/diagnostic/diagnostic_question_screen.dart';
import 'features/home/main_navigation_scaffold.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/web_install/web_install_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (API keys, etc.) with automatic fallback for web hosting where dotfiles are blocked
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env non chargé depuis le serveur ($e), configuration Supabase par défaut.');
    dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://ohllztkenhpxiosekddf.supabase.co
SUPABASE_ANON_KEY=sb_publishable_B_k4K2HFQhOUjcsUVYYpVA_jz4t9kDK
GOOGLE_WEB_CLIENT_ID=325703599741-45k9eqdd29urb8cidh5q1u64flcp5if6.apps.googleusercontent.com
''');
  }

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl != null &&
      supabaseAnonKey != null &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('⚠️ Erreur Supabase init: $e');
    }
  }
  
  SharedPreferences? sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('⚠️ Erreur SharedPreferences init: $e');
    try {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    } catch (e2) {
      debugPrint('⚠️ Erreur SharedPreferences mock: $e2');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        if (sharedPreferences != null)
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const LectureAideApp(),
    ),
  );
}

class LectureAideApp extends ConsumerStatefulWidget {
  const LectureAideApp({super.key});

  @override
  ConsumerState<LectureAideApp> createState() => _LectureAideAppState();
}

class _LectureAideAppState extends ConsumerState<LectureAideApp> {
  bool _dismissedWebPrompt = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final profile = ref.watch(learnerProfileProvider);

    // ── Routing logic ─────────────────────────────────────────────────────
    // 0. Web entrance → always show installation / shortcut guide first
    // 1. Not yet chosen a level → OnboardingScreen (mandatory)
    // 2. Level chosen, diagnostic not done → DiagnosticQuestionScreen
    // 3. Everything done → HomeScreen
    final Widget home;
    if (kIsWeb && !_dismissedWebPrompt) {
      home = WebInstallPromptScreen(
        onProceed: () {
          setState(() {
            _dismissedWebPrompt = true;
          });
        },
      );
    } else if (!settings.isOnboardingCompleted) {
      home = const OnboardingScreen();
    } else if (!profile.isDiagnosticDone) {
      home = const DiagnosticQuestionScreen();
    } else {
      home = const MainNavigationScaffold();
    }

    return MaterialApp(
      title: 'AideLecture',
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
