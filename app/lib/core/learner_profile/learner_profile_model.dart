import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// DiagnosticLevel — severity of each dimension
// ---------------------------------------------------------------------------

enum DiagnosticLevel { none, mild, moderate, severe }

extension DiagnosticLevelX on DiagnosticLevel {
  String get label {
    switch (this) {
      case DiagnosticLevel.none:     return 'Aucune';
      case DiagnosticLevel.mild:     return 'Légère';
      case DiagnosticLevel.moderate: return 'Modérée';
      case DiagnosticLevel.severe:   return 'Sévère';
    }
  }

  Color get badgeBackground {
    switch (this) {
      case DiagnosticLevel.none:     return const Color(0xFFDFFBE8);
      case DiagnosticLevel.mild:     return const Color(0xFFFFF9C4);
      case DiagnosticLevel.moderate: return const Color(0xFFFFE5CC);
      case DiagnosticLevel.severe:   return const Color(0xFFFFD6D6);
    }
  }

  Color get badgeText {
    switch (this) {
      case DiagnosticLevel.none:     return const Color(0xFF2D7A4F);
      case DiagnosticLevel.mild:     return const Color(0xFF8A6A00);
      case DiagnosticLevel.moderate: return const Color(0xFF9B5400);
      case DiagnosticLevel.severe:   return const Color(0xFF9B1A1A);
    }
  }

  Color get barColor {
    switch (this) {
      case DiagnosticLevel.none:     return const Color(0xFF5A9B6E);
      case DiagnosticLevel.mild:     return const Color(0xFFD4A017);
      case DiagnosticLevel.moderate: return const Color(0xFFE07B54);
      case DiagnosticLevel.severe:   return const Color(0xFFC0392B);
    }
  }

  static DiagnosticLevel fromScore(int score) {
    if (score <= 25) return DiagnosticLevel.none;
    if (score <= 50) return DiagnosticLevel.mild;
    if (score <= 75) return DiagnosticLevel.moderate;
    return DiagnosticLevel.severe;
  }
}

// ---------------------------------------------------------------------------
// DimensionResult — one evaluated dimension
// ---------------------------------------------------------------------------

@immutable
class DimensionResult {
  final String emoji;
  final String name;
  final int score; // 0-100
  final DiagnosticLevel level;
  final List<String> flags;

  const DimensionResult({
    required this.emoji,
    required this.name,
    required this.score,
    required this.level,
    this.flags = const [],
  });
}

// ---------------------------------------------------------------------------
// LearnerProfile — full diagnostic output stored locally
// ---------------------------------------------------------------------------

@immutable
class LearnerProfile {
  // ── meta ──────────────────────────────────────────────────────────────────
  final bool diagnosticCompleted;
  final bool diagnosticSkipped;

  // ── raw answers (questionId → int score) ─────────────────────────────────
  final Map<String, int> answers;

  // ── dimension scores (0–100) ──────────────────────────────────────────────
  final int b1ReadingFluencyScore;
  final int b2SpellingWritingScore;
  final int b3AuditoryMemoryScore;
  final int b4CognitiveLoadScore;

  // ── key behavioral flags ──────────────────────────────────────────────────
  final bool mirrorLetterConfusion;   // Q10 >= 2
  final bool visualInstability;       // Q11 = true
  final bool avoidsOralReading;       // Q13 = true
  final bool slowReadingSpeed;        // Q19 = true
  final bool poorWordDecoding;        // Q14 = true
  final bool needsVisualSpacing;      // Q5  = true
  final bool cognitiveFatigueHigh;    // Q3  >= 3
  final bool overwhelmedByText;       // Q12 >= 3 or Q24 >= 3

  const LearnerProfile({
    this.diagnosticCompleted = false,
    this.diagnosticSkipped = false,
    this.answers = const {},
    this.b1ReadingFluencyScore = 0,
    this.b2SpellingWritingScore = 0,
    this.b3AuditoryMemoryScore = 0,
    this.b4CognitiveLoadScore = 0,
    this.mirrorLetterConfusion = false,
    this.visualInstability = false,
    this.avoidsOralReading = false,
    this.slowReadingSpeed = false,
    this.poorWordDecoding = false,
    this.needsVisualSpacing = false,
    this.cognitiveFatigueHigh = false,
    this.overwhelmedByText = false,
  });

  // ── computed ──────────────────────────────────────────────────────────────

  bool get isDiagnosticDone => diagnosticCompleted || diagnosticSkipped;

  DiagnosticLevel get b1Level =>
      DiagnosticLevelX.fromScore(b1ReadingFluencyScore);
  DiagnosticLevel get b2Level =>
      DiagnosticLevelX.fromScore(b2SpellingWritingScore);
  DiagnosticLevel get b3Level =>
      DiagnosticLevelX.fromScore(b3AuditoryMemoryScore);
  DiagnosticLevel get b4Level =>
      DiagnosticLevelX.fromScore(b4CognitiveLoadScore);

  List<DimensionResult> get dimensions => [
        DimensionResult(
          emoji: '📖',
          name: 'Fluidité de lecture',
          score: b1ReadingFluencyScore,
          level: b1Level,
          flags: [
            if (slowReadingSpeed) 'Lecture lente',
            if (avoidsOralReading) 'Évite la lecture orale',
            if (mirrorLetterConfusion) 'Confusion b/d',
            if (visualInstability) 'Lettres mobiles',
            if (poorWordDecoding) 'Déchiffrage difficile',
            if (needsVisualSpacing) 'Grands caractères',
          ],
        ),
        DimensionResult(
          emoji: '✍️',
          name: 'Orthographe',
          score: b2SpellingWritingScore,
          level: b2Level,
          flags: const [],
        ),
        DimensionResult(
          emoji: '🧠',
          name: 'Mémoire auditive',
          score: b3AuditoryMemoryScore,
          level: b3Level,
          flags: const [],
        ),
        DimensionResult(
          emoji: '💭',
          name: 'Charge cognitive',
          score: b4CognitiveLoadScore,
          level: b4Level,
          flags: [
            if (overwhelmedByText) 'Textes longs',
            if (cognitiveFatigueHigh) 'Fatigue mentale',
          ],
        ),
      ];

  // ── factories ─────────────────────────────────────────────────────────────

  /// Build a full profile from the raw answers map.
  static LearnerProfile fromAnswers(Map<String, int> answers) {
    int q(String key) => answers[key] ?? 0;

    // B1 — Fluidité de lecture (includes visual perception)
    // Q1(0/2), Q5(0/2), Q6(0/2), Q7(0/2), Q8(0-4), Q10(0-4),
    // Q11(0/2), Q13(0/2), Q14(0/2), Q17(0/2), Q18(0/2), Q19(0/2), Q21(0-4)
    const b1Max = 2+2+2+2+4+4+2+2+2+2+2+2+4; // 34
    final b1Raw = q('q1')+q('q5')+q('q6')+q('q7')+q('q8')+q('q10')+
        q('q11')+q('q13')+q('q14')+q('q17')+q('q18')+q('q19')+q('q21');

    // B2 — Orthographe et écriture
    // Q9(0-4), Q16(0-4), Q20(0/2), Q21(0-4), Q22(0-4)
    const b2Max = 4+4+2+4+4; // 18
    final b2Raw = q('q9')+q('q16')+q('q20')+q('q21')+q('q22');

    // B3 — Mémoire et traitement auditif
    // Q4(0-4), Q15(0-4), Q23(0-4)
    const b3Max = 4+4+4; // 12
    final b3Raw = q('q4')+q('q15')+q('q23');

    // B4 — Charge cognitive et fatigue
    // Q2(0-4), Q3(0-4), Q12(0-4), Q17(0/2), Q18(0/2), Q23(0-4), Q24(0-4)
    const b4Max = 4+4+4+2+2+4+4; // 24
    final b4Raw = q('q2')+q('q3')+q('q12')+q('q17')+q('q18')+q('q23')+q('q24');

    int pct(int raw, int max) => ((raw / max) * 100).round().clamp(0, 100);

    return LearnerProfile(
      diagnosticCompleted: true,
      diagnosticSkipped: false,
      answers: answers,
      b1ReadingFluencyScore: pct(b1Raw, b1Max),
      b2SpellingWritingScore: pct(b2Raw, b2Max),
      b3AuditoryMemoryScore: pct(b3Raw, b3Max),
      b4CognitiveLoadScore: pct(b4Raw, b4Max),
      mirrorLetterConfusion: q('q10') >= 2,
      visualInstability: q('q11') >= 2,
      avoidsOralReading: q('q13') >= 2,
      slowReadingSpeed: q('q19') >= 2,
      poorWordDecoding: q('q14') >= 2,
      needsVisualSpacing: q('q5') >= 2,
      cognitiveFatigueHigh: q('q3') >= 3,
      overwhelmedByText: q('q12') >= 3 || q('q24') >= 3,
    );
  }

  /// Default balanced profile when the student skips the diagnostic.
  static const LearnerProfile balanced = LearnerProfile(
    diagnosticCompleted: false,
    diagnosticSkipped: true,
    b1ReadingFluencyScore: 30,
    b2SpellingWritingScore: 30,
    b3AuditoryMemoryScore: 30,
    b4CognitiveLoadScore: 30,
  );
}
