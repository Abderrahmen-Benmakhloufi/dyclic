/// Model classes for the phoneme discrimination mini-quiz.
///
/// Each [QuizQuestion] asks the learner to identify what sound a specific
/// letter (or letter cluster) makes in a given word by listening and choosing
/// from multiple phonemic options.
library;

// ─── Enum: difficulty tier ─────────────────────────────────────────────────

enum QuizDifficulty {
  /// Words with very common, unambiguous sound patterns.
  decouverte,

  /// Two phonemic options — the classic discrimination task.
  discrimination,

  /// Three options including a plausible distractor.
  defi,
}

extension QuizDifficultyExt on QuizDifficulty {
  String get label {
    switch (this) {
      case QuizDifficulty.decouverte:
        return '🌱 Découverte';
      case QuizDifficulty.discrimination:
        return '🎯 Discrimination';
      case QuizDifficulty.defi:
        return '🏆 Défi';
    }
  }

  String get description {
    switch (this) {
      case QuizDifficulty.decouverte:
        return 'Sons simples et bien distincts';
      case QuizDifficulty.discrimination:
        return 'Choisis le bon son parmi deux';
      case QuizDifficulty.defi:
        return 'Trois choix possibles, sois attentif !';
    }
  }
}

// ─── Main question model ────────────────────────────────────────────────────

class QuizQuestion {
  /// The word the learner will HEAR (spoken by TTS).
  final String word;

  /// The letter or cluster whose sound is being tested (e.g. "S", "G", "CH").
  final String testedLetter;

  /// The index range of [testedLetter] inside [word] for visual highlight.
  final List<int> testedIndices;

  /// A short pedagogical hint shown after an incorrect answer.
  final String hintFr;

  /// All phonemic choices displayed as answer buttons.
  final List<String> choices;

  /// Index inside [choices] that is correct.
  final int correctChoiceIndex;

  /// Which rule category this question belongs to (matches DecodingRule.id).
  final String ruleId;

  /// Difficulty level for filtering / progress.
  final QuizDifficulty difficulty;

  const QuizQuestion({
    required this.word,
    required this.testedLetter,
    required this.testedIndices,
    required this.hintFr,
    required this.choices,
    required this.correctChoiceIndex,
    required this.ruleId,
    required this.difficulty,
  });

  /// The IPA string for the correct answer.
  String get correctChoice => choices[correctChoiceIndex];
}

// ─── Session result ─────────────────────────────────────────────────────────

class QuizSessionResult {
  final int totalQuestions;
  final int correctAnswers;
  final List<bool> answerHistory; // true = correct, false = wrong

  const QuizSessionResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.answerHistory,
  });

  int get wrongAnswers => totalQuestions - correctAnswers;
  double get successRate => totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;

  String get medal {
    if (successRate == 1.0) return '🏆';
    if (successRate >= 0.8) return '🥇';
    if (successRate >= 0.6) return '🥈';
    return '🥉';
  }

  String get feedbackFr {
    if (successRate == 1.0) return 'Parfait ! Tu maîtrises tous ces sons !';
    if (successRate >= 0.8) return 'Excellent travail ! Continue comme ça.';
    if (successRate >= 0.6) return 'Bon effort ! Réécoute les sons difficiles.';
    return "Continue de t'entraîner, tu vas y arriver !";
  }
}
