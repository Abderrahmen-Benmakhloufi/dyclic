// All 23 diagnostic questions with their metadata.
// Question IDs are stable keys used in LearnerProfile.answers map.

// ---------------------------------------------------------------------------
// Question types
// ---------------------------------------------------------------------------

enum QuestionType {
  /// Binary: Oui / Non
  yesNo,

  /// 5-level frequency: Jamais → Toujours
  frequency,

  /// Multiple choice with custom options (Q4)
  multiChoice,
}

// ---------------------------------------------------------------------------
// Question data class
// ---------------------------------------------------------------------------

class DiagnosticQuestion {
  final String id;
  final String text;
  final QuestionType type;
  final String categoryName;
  final String categoryEmoji;

  /// Only used when [type] == [QuestionType.multiChoice].
  final List<String>? choices;

  const DiagnosticQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.categoryName,
    required this.categoryEmoji,
    this.choices,
  });
}

// ---------------------------------------------------------------------------
// Score helpers
// ---------------------------------------------------------------------------

/// Oui = 2, Non = 0
int yesNoScore(bool isYes) => isYes ? 2 : 0;

/// Jamais=0, Rarement=1, Parfois=2, Souvent=3, Toujours=4
int frequencyScore(int index) => index;

/// Q4 specific: immediate=0, prefers-written=1, needs-repeat=3, forgets=4
int multiChoiceScore(int index) {
  switch (index) {
    case 0:  return 0;
    case 1:  return 1;
    case 2:  return 3;
    case 3:  return 4;
    default: return 0;
  }
}

// ---------------------------------------------------------------------------
// Labels
// ---------------------------------------------------------------------------

const List<String> frequencyLabels = [
  'Jamais',
  'Rarement',
  'Parfois',
  'Souvent',
  'Toujours',
];

/// Resolves the human-readable text corresponding to a raw score for a given question
String getAnswerText(DiagnosticQuestion question, int score) {
  switch (question.type) {
    case QuestionType.yesNo:
      return score == 2 ? 'Oui' : 'Non';
    case QuestionType.frequency:
      if (score >= 0 && score < frequencyLabels.length) {
        return frequencyLabels[score];
      }
      return 'Score $score';
    case QuestionType.multiChoice:
      final choices = question.choices;
      if (choices != null && choices.isNotEmpty) {
        if (score == 0) return choices[0];
        if (score == 1 && choices.length > 1) return choices[1];
        if (score == 3 && choices.length > 2) return choices[2];
        if (score == 4 && choices.length > 3) return choices[3];
      }
      return 'Option $score';
  }
}

// ---------------------------------------------------------------------------
// The 23 questions
// ---------------------------------------------------------------------------

const List<DiagnosticQuestion> diagnosticQuestions = [
  DiagnosticQuestion(
    id: 'q1',
    text: "J'ai besoin de plus de temps que mes camarades pour terminer les travaux écrits ou les examens.",
    type: QuestionType.yesNo,
    categoryName: 'Fluidité de lecture',
    categoryEmoji: '📖',
  ),
  DiagnosticQuestion(
    id: 'q2',
    text: "J'ai besoin de plus de temps pour bien comprendre les idées complexes.",
    type: QuestionType.frequency,
    categoryName: 'Charge cognitive',
    categoryEmoji: '💭',
  ),
  DiagnosticQuestion(
    id: 'q3',
    text: "Je me sens mentalement épuisé(e) après de longues séances de lecture ou d'écriture.",
    type: QuestionType.frequency,
    categoryName: 'Charge cognitive',
    categoryEmoji: '💭',
  ),
  DiagnosticQuestion(
    id: 'q4',
    text: 'Lorsque je reçois des consignes verbales, je :',
    type: QuestionType.multiChoice,
    categoryName: 'Mémoire auditive',
    categoryEmoji: '🧠',
    choices: [
      "Les comprends immédiatement et m'en souviens.",
      'Préfère les avoir par écrit.',
      "Ai besoin de les entendre plusieurs fois.",
      "Les oublie souvent si elles ne sont pas répétées plusieurs fois.",
    ],
  ),
  DiagnosticQuestion(
    id: 'q5',
    text: "Je trouve qu'il m'est plus facile de lire lorsque le texte est écrit en gros caractères ou que l'espacement entre les lettres et les lignes est plus important.",
    type: QuestionType.yesNo,
    categoryName: 'Fluidité de lecture',
    categoryEmoji: '📖',
  ),
  DiagnosticQuestion(
    id: 'q6',
    text: "Je confonds parfois des mots qui se ressemblent visuellement, comme « cheval » et « chavel ».",
    type: QuestionType.yesNo,
    categoryName: 'Fluidité de lecture',
    categoryEmoji: '📖',
  ),
  DiagnosticQuestion(
    id: 'q7',
    text: "Il m'arrive de remplacer, sans m'en rendre compte, un mot par un autre qui lui ressemble visuellement.",
    type: QuestionType.yesNo,
    categoryName: 'Fluidité de lecture',
    categoryEmoji: '📖',
  ),
  DiagnosticQuestion(
    id: 'q8',
    text: "Il m'arrive de sauter des mots ou des lignes lorsque je lis.",
    type: QuestionType.frequency,
    categoryName: 'Fluidité de lecture',
    categoryEmoji: '📖',
  ),
  DiagnosticQuestion(
    id: 'q9',
    text: "Il m'arrive d'inverser l'ordre des lettres lorsque j'écris des mots.",
    type: QuestionType.frequency,
    categoryName: 'Orthographe',
    categoryEmoji: '✍️',
  ),
  DiagnosticQuestion(
    id: 'q10',
    text: "Je confonds des lettres qui se ressemblent visuellement, comme « b » et « d ».",
    type: QuestionType.frequency,
    categoryName: 'Fluidité de lecture',
    categoryEmoji: '📖',
  ),
  DiagnosticQuestion(
    id: 'q11',
    text: "J'ai parfois l'impression que les lettres ou les mots bougent sur la page.",
    type: QuestionType.yesNo,
    categoryName: 'Fluidité de lecture',
    categoryEmoji: '📖',
  ),
  DiagnosticQuestion(
    id: 'q12',
    text: "Je me sens dépassé(e) lorsque je lis de longs paragraphes, car le texte me semble trop dense et désordonné.",
    type: QuestionType.frequency,
    categoryName: 'Charge cognitive',
    categoryEmoji: '💭',
  ),
  DiagnosticQuestion(
    id: 'q13',
    text: "J'évite de lire à voix haute parce que cela me stresse.",
    type: QuestionType.yesNo,
    categoryName: 'Fluidité de lecture',
    categoryEmoji: '📖',
  ),
  DiagnosticQuestion(
    id: 'q14',
    text: "J'ai du mal à déchiffrer les mots que je ne connais pas lorsque je lis.",
    type: QuestionType.yesNo,
    categoryName: 'Fluidité de lecture',
    categoryEmoji: '📖',
  ),
  DiagnosticQuestion(
    id: 'q15',
    text: "J'ai besoin d'entendre plusieurs fois une nouvelle information avant de pouvoir m'en souvenir correctement.",
    type: QuestionType.frequency,
    categoryName: 'Mémoire auditive',
    categoryEmoji: '🧠',
  ),
  DiagnosticQuestion(
    id: 'q16',
    text: "J'ai du mal à orthographier les mots dont la prononciation ne correspond pas à l'écriture.",
    type: QuestionType.frequency,
    categoryName: 'Orthographe',
    categoryEmoji: '✍️',
  ),
  DiagnosticQuestion(
    id: 'q17',
    text: "Je préfère lire des articles courts ou des résumés plutôt que de longs rapports.",
    type: QuestionType.yesNo,
    categoryName: 'Charge cognitive',
    categoryEmoji: '💭',
  ),
  DiagnosticQuestion(
    id: 'q18',
    text: "Je perds parfois le fil de l'idée principale lorsque je lis des textes longs.",
    type: QuestionType.yesNo,
    categoryName: 'Charge cognitive',
    categoryEmoji: '💭',
  ),
  DiagnosticQuestion(
    id: 'q19',
    text: "Je lis plus lentement que les personnes de mon âge ou que mes camarades.",
    type: QuestionType.yesNo,
    categoryName: 'Fluidité de lecture',
    categoryEmoji: '📖',
  ),
  DiagnosticQuestion(
    id: 'q20',
    text: "J'ai parfois l'impression que mes écrits sont mal compris à cause de mes erreurs d'orthographe ou de grammaire.",
    type: QuestionType.yesNo,
    categoryName: 'Orthographe',
    categoryEmoji: '✍️',
  ),
  DiagnosticQuestion(
    id: 'q22',
    text: "J'ai du mal à mémoriser certaines règles de grammaire, par exemple la différence entre le son de « g » dans « gare » et celui de « g » dans « girafe ».",
    type: QuestionType.frequency,
    categoryName: 'Orthographe',
    categoryEmoji: '✍️',
  ),
  DiagnosticQuestion(
    id: 'q23',
    text: "J'ai des difficultés à comprendre les consignes",
    type: QuestionType.frequency,
    categoryName: 'Mémoire auditive',
    categoryEmoji: '🧠',
  ),
  DiagnosticQuestion(
    id: 'q24',
    text: "Je me sens dépassé(e) lorsque je suis confronté(e) à de longs blocs de texte.",
    type: QuestionType.frequency,
    categoryName: 'Charge cognitive',
    categoryEmoji: '💭',
  ),
];
