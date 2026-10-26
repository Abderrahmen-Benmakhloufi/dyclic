import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../reading_settings/reading_settings_notifier.dart';
import 'learner_profile_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final learnerProfileProvider =
    StateNotifierProvider<LearnerProfileNotifier, LearnerProfile>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LearnerProfileNotifier(prefs);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class LearnerProfileNotifier extends StateNotifier<LearnerProfile> {
  final SharedPreferences _prefs;

  // SharedPreferences keys
  static const _kCompleted        = 'diag_completed';
  static const _kSkipped          = 'diag_skipped';
  static const _kAnswersJson      = 'diag_answers_json';
  static const _kB1               = 'diag_b1_score';
  static const _kB2               = 'diag_b2_score';
  static const _kB3               = 'diag_b3_score';
  static const _kB4               = 'diag_b4_score';
  static const _kMirrorLetter     = 'diag_flag_mirror_letter';
  static const _kVisualInstab     = 'diag_flag_visual_instability';
  static const _kAvoidsOral       = 'diag_flag_avoids_oral';
  static const _kSlowReading      = 'diag_flag_slow_reading';
  static const _kPoorDecoding     = 'diag_flag_poor_decoding';
  static const _kNeedsSpacing     = 'diag_flag_needs_spacing';
  static const _kCognitiveFatigue = 'diag_flag_cognitive_fatigue';
  static const _kOverwhelmed      = 'diag_flag_overwhelmed_text';

  LearnerProfileNotifier(this._prefs) : super(const LearnerProfile()) {
    _load();
  }

  // ── load from storage ─────────────────────────────────────────────────────

  void _load() {
    final completed = _prefs.getBool(_kCompleted) ?? false;
    final skipped   = _prefs.getBool(_kSkipped)   ?? false;
    if (!completed && !skipped) return;

    Map<String, int> answers = {};
    final json = _prefs.getString(_kAnswersJson);
    if (json != null) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      answers = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    state = LearnerProfile(
      diagnosticCompleted: completed,
      diagnosticSkipped:   skipped,
      answers:             answers,
      b1ReadingFluencyScore:  _prefs.getInt(_kB1) ?? 30,
      b2SpellingWritingScore: _prefs.getInt(_kB2) ?? 30,
      b3AuditoryMemoryScore:  _prefs.getInt(_kB3) ?? 30,
      b4CognitiveLoadScore:   _prefs.getInt(_kB4) ?? 30,
      mirrorLetterConfusion: _prefs.getBool(_kMirrorLetter)     ?? false,
      visualInstability:     _prefs.getBool(_kVisualInstab)     ?? false,
      avoidsOralReading:     _prefs.getBool(_kAvoidsOral)       ?? false,
      slowReadingSpeed:      _prefs.getBool(_kSlowReading)      ?? false,
      poorWordDecoding:      _prefs.getBool(_kPoorDecoding)     ?? false,
      needsVisualSpacing:    _prefs.getBool(_kNeedsSpacing)     ?? false,
      cognitiveFatigueHigh:  _prefs.getBool(_kCognitiveFatigue) ?? false,
      overwhelmedByText:     _prefs.getBool(_kOverwhelmed)      ?? false,
    );
  }

  // ── public actions ────────────────────────────────────────────────────────

  /// Save a completed profile after all 23 questions are answered.
  Future<void> saveCompletedProfile(LearnerProfile profile) async {
    state = profile;
    await Future.wait([
      _prefs.setBool(_kCompleted,    true),
      _prefs.setBool(_kSkipped,      false),
      _prefs.setString(_kAnswersJson, jsonEncode(profile.answers)),
      _prefs.setInt(_kB1, profile.b1ReadingFluencyScore),
      _prefs.setInt(_kB2, profile.b2SpellingWritingScore),
      _prefs.setInt(_kB3, profile.b3AuditoryMemoryScore),
      _prefs.setInt(_kB4, profile.b4CognitiveLoadScore),
      _prefs.setBool(_kMirrorLetter,     profile.mirrorLetterConfusion),
      _prefs.setBool(_kVisualInstab,     profile.visualInstability),
      _prefs.setBool(_kAvoidsOral,       profile.avoidsOralReading),
      _prefs.setBool(_kSlowReading,      profile.slowReadingSpeed),
      _prefs.setBool(_kPoorDecoding,     profile.poorWordDecoding),
      _prefs.setBool(_kNeedsSpacing,     profile.needsVisualSpacing),
      _prefs.setBool(_kCognitiveFatigue, profile.cognitiveFatigueHigh),
      _prefs.setBool(_kOverwhelmed,      profile.overwhelmedByText),
    ]);
  }

  /// Save a "skipped" profile with balanced defaults.
  Future<void> skipDiagnostic() async {
    state = LearnerProfile.balanced;
    await Future.wait([
      _prefs.setBool(_kCompleted, false),
      _prefs.setBool(_kSkipped,   true),
      _prefs.setInt(_kB1, 30),
      _prefs.setInt(_kB2, 30),
      _prefs.setInt(_kB3, 30),
      _prefs.setInt(_kB4, 30),
    ]);
  }
}
