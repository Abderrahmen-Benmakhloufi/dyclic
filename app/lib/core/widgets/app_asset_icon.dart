import 'package:flutter/material.dart';
import '../reading_settings/reading_settings_model.dart';

/// Centralized registry of transparent PNG illustrations in `assets/images/ui/`.
class AppUiAssets {
  AppUiAssets._();

  static const String _base = 'assets/images/ui';

  // Cycles
  static const String cyclePrimaire = '$_base/cycle_primaire.png';
  static const String cycleCollege = '$_base/cycle_college.png';
  static const String cycleLycee = '$_base/cycle_lycee.png';

  // Cycle-adapted avatars
  static const String avatarPrimaire = '$_base/avatar_primaire.png';
  static const String avatarCollege = '$_base/avatar_college.png';
  static const String avatarLycee = '$_base/avatar_lycee.png';

  // Home features
  static const String featReading = '$_base/feat_reading.png';
  static const String featDecoding = '$_base/feat_decoding.png';
  static const String featTts = '$_base/feat_tts.png';
  static const String featWriting = '$_base/feat_writing.png';
  static const String featSimplify = '$_base/feat_simplify.png';
  static const String featInstructions = '$_base/feat_instructions.png';

  // Instruction question types
  static const String qtypeComprehension = '$_base/qtype_comprehension.png';
  static const String qtypeLangue = '$_base/qtype_langue.png';
  static const String qtypeProduction = featWriting;

  // Writing error categories & celebration
  static const String errInversion = '$_base/err_inversion.png';
  static const String errPhonetique = '$_base/err_phonetique.png';
  static const String errRegle = '$_base/err_regle.png';
  static const String errGrammaire = '$_base/err_grammaire.png';
  static const String errPonctuation = '$_base/err_ponctuation.png';
  static const String writingCelebration = '$_base/writing_celebration.png';

  // Brand logo
  static const String appLogo = '$_base/app_logo.png';
  static const String appLogoMark = '$_base/app_logo_mark.png';

  // Extended UI illustrations & icons
  static const String badgeSuccess = '$_base/badge_success.png';
  static const String bookWelcome = '$_base/book_welcome.png';
  static const String brainMind = '$_base/brain_mind.png';
  static const String clipboardQuiz = '$_base/clipboard_quiz.png';
  static const String heartSupport = '$_base/heart_support.png';
  static const String quizAudioHeadset = '$_base/quiz_audio_headset.png';
  static const String rocketFast = '$_base/rocket_fast.png';
  static const String scannerCamera = '$_base/scanner_camera.png';
  static const String sproutDiscovery = '$_base/sprout_discovery.png';
  static const String trophyAchievement = '$_base/trophy_achievement.png';

  static String cycleForLevel(LearnerLevel level) {
    switch (level) {
      case LearnerLevel.primaire:
        return cyclePrimaire;
      case LearnerLevel.moyen:
        return cycleCollege;
      case LearnerLevel.secondaire:
        return cycleLycee;
    }
  }

  static String avatarForLevel(LearnerLevel level) {
    switch (level) {
      case LearnerLevel.primaire:
        return avatarPrimaire;
      case LearnerLevel.moyen:
        return avatarCollege;
      case LearnerLevel.secondaire:
        return avatarLycee;
    }
  }

  static String cycleForCode(String cycle) {
    switch (cycle.toLowerCase()) {
      case 'primaire':
        return cyclePrimaire;
      case 'lycee':
      case 'secondaire':
        return cycleLycee;
      case 'college':
      case 'moyen':
      default:
        return cycleCollege;
    }
  }
}

/// Renders a crisp transparent asset icon with a safe fallback if unavailable.
class AppAssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final String? fallbackEmoji;

  const AppAssetIcon({
    super.key,
    required this.assetPath,
    this.size = 24,
    this.fallbackEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        if (fallbackEmoji != null) {
          return Text(
            fallbackEmoji!,
            style: TextStyle(fontSize: size * 0.78),
          );
        }
        return SizedBox(width: size, height: size);
      },
    );
  }
}
