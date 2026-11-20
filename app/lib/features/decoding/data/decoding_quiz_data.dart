import '../models/decoding_quiz_model.dart';

/// Complete phoneme-discrimination quiz bank.
///
/// Structure:
/// - 7 rule groups matching [decodingRulesCatalog] ids.
/// - Each group has 3 difficulty tiers: découverte → discrimination → défi.
/// - Each question is fully self-contained: word + hint + choices + answer.
///
/// Sound notation uses IPA between slashes (e.g. /s/, /z/, /ʒ/) and the
/// name of the phoneme in French for accessibility.

const List<QuizQuestion> kDecodingQuizBank = [

  // ════════════════════════════════════════════════════════════════════════
  // RULE G  —  /g/ vs /ʒ/
  // ════════════════════════════════════════════════════════════════════════

  QuizQuestion(
    ruleId: 'rule_g',
    difficulty: QuizDifficulty.decouverte,
    word: 'gare',
    testedLetter: 'G',
    testedIndices: [0],
    choices: ['/g/ comme dans "gâteau"', '/ʒ/ comme dans "jardin"'],
    correctChoiceIndex: 0,
    hintFr: "G devant A, O, U → son /g/ dur, comme dans \"gâteau\".",

  ),
  QuizQuestion(
    ruleId: 'rule_g',
    difficulty: QuizDifficulty.decouverte,
    word: 'girafe',
    testedLetter: 'G',
    testedIndices: [0],
    choices: ['/g/ comme dans "gâteau"', '/ʒ/ comme dans "jardin"'],
    correctChoiceIndex: 1,
    hintFr: "G devant I, E, Y → son /ʒ/ doux, comme dans \"jardin\".",

  ),
  QuizQuestion(
    ruleId: 'rule_g',
    difficulty: QuizDifficulty.discrimination,
    word: 'genou',
    testedLetter: 'G',
    testedIndices: [0],
    choices: ['/g/ — son dur', '/ʒ/ — son doux'],
    correctChoiceIndex: 1,
    hintFr: "G suivi de E → son /ʒ/ doux. Pense à \"jardin\" ou \"journal\".",

  ),
  QuizQuestion(
    ruleId: 'rule_g',
    difficulty: QuizDifficulty.discrimination,
    word: 'guerre',
    testedLetter: 'GU',
    testedIndices: [0, 1],
    choices: ['/g/ — son dur', '/ʒ/ — son doux'],
    correctChoiceIndex: 0,
    hintFr: "GU devant E ou I → son /g/ dur (le U est silencieux). Ex : \"guitare\".",

  ),
  QuizQuestion(
    ruleId: 'rule_g',
    difficulty: QuizDifficulty.defi,
    word: 'danger',
    testedLetter: 'G',
    testedIndices: [3],
    choices: ['/g/ — son dur', '/ʒ/ — son doux', '/k/ — son sourd'],
    correctChoiceIndex: 1,
    hintFr: "G entre A et E → le son est toujours /ʒ/ car la voyelle qui suit (E) est douce.",

  ),
  QuizQuestion(
    ruleId: 'rule_g',
    difficulty: QuizDifficulty.defi,
    word: 'gorille',
    testedLetter: 'G',
    testedIndices: [0],
    choices: ['/g/ — son dur', '/ʒ/ — son doux', 'Son muet'],
    correctChoiceIndex: 0,
    hintFr: "G devant O → son /g/ dur. Le O est une voyelle \"dure\" pour le G.",

  ),

  // ════════════════════════════════════════════════════════════════════════
  // RULE S  —  /s/ vs /z/
  // ════════════════════════════════════════════════════════════════════════

  QuizQuestion(
    ruleId: 'rule_s',
    difficulty: QuizDifficulty.decouverte,
    word: 'soleil',
    testedLetter: 'S',
    testedIndices: [0],
    choices: ['/s/ comme dans "serpent"', '/z/ comme dans "zèbre"'],
    correctChoiceIndex: 0,
    hintFr: "S au début d'un mot → toujours /s/. Pense à \"sac\", \"sel\", \"soleil\".",

  ),
  QuizQuestion(
    ruleId: 'rule_s',
    difficulty: QuizDifficulty.decouverte,
    word: 'maison',
    testedLetter: 'S',
    testedIndices: [3],
    choices: ['/s/ comme dans "serpent"', '/z/ comme dans "zèbre"'],
    correctChoiceIndex: 1,
    hintFr: "Un seul S entre deux voyelles → son /z/. Dans \"maison\" : i-S-on.",

  ),
  QuizQuestion(
    ruleId: 'rule_s',
    difficulty: QuizDifficulty.discrimination,
    word: 'poisson',
    testedLetter: 'SS',
    testedIndices: [3, 4],
    choices: ['/s/ — sifflement sourd', '/z/ — sifflement sonore'],
    correctChoiceIndex: 0,
    hintFr: "Double SS entre deux voyelles → toujours /s/. SS sonne comme \"serpent\".",

  ),
  QuizQuestion(
    ruleId: 'rule_s',
    difficulty: QuizDifficulty.discrimination,
    word: 'plaisir',
    testedLetter: 'S',
    testedIndices: [4],
    choices: ['/s/ — sifflement sourd', '/z/ — sifflement sonore'],
    correctChoiceIndex: 1,
    hintFr: "Dans \"plaisir\" : le S est entre I et I → c'est un seul S entre deux voyelles → son /z/.",

  ),
  QuizQuestion(
    ruleId: 'rule_s',
    difficulty: QuizDifficulty.defi,
    word: 'dessert',
    testedLetter: 'SS',
    testedIndices: [2, 3],
    choices: ['/s/ — sifflement sourd', '/z/ — sifflement sonore', 'Son muet'],
    correctChoiceIndex: 0,
    hintFr: "Dans \"dessert\" : e-SS-ert → double SS entre deux voyelles → son /s/ sourd.",

  ),
  QuizQuestion(
    ruleId: 'rule_s',
    difficulty: QuizDifficulty.defi,
    word: 'résultat',
    testedLetter: 'S',
    testedIndices: [2],
    choices: ['/s/ — sifflement sourd', '/z/ — sifflement sonore', '/ʃ/ — son CH'],
    correctChoiceIndex: 1,
    hintFr: "Dans \"résultat\" : é-S-ul → S unique entre deux voyelles → son /z/.",

  ),

  // ════════════════════════════════════════════════════════════════════════
  // RULE C  —  /k/ vs /s/
  // ════════════════════════════════════════════════════════════════════════

  QuizQuestion(
    ruleId: 'rule_c',
    difficulty: QuizDifficulty.decouverte,
    word: 'cadeau',
    testedLetter: 'C',
    testedIndices: [0],
    choices: ['/k/ comme dans "kiwi"', '/s/ comme dans "serpent"'],
    correctChoiceIndex: 0,
    hintFr: "C devant A, O, U → son /k/ dur. Pense à \"carte\", \"coq\", \"cube\".",

  ),
  QuizQuestion(
    ruleId: 'rule_c',
    difficulty: QuizDifficulty.decouverte,
    word: 'cinéma',
    testedLetter: 'C',
    testedIndices: [0],
    choices: ['/k/ comme dans "kiwi"', '/s/ comme dans "serpent"'],
    correctChoiceIndex: 1,
    hintFr: "C devant E, I, Y → son /s/ doux. Pense à \"cerise\", \"cible\".",

  ),
  QuizQuestion(
    ruleId: 'rule_c',
    difficulty: QuizDifficulty.discrimination,
    word: 'cerise',
    testedLetter: 'C',
    testedIndices: [0],
    choices: ['/k/ — son dur', '/s/ — son doux'],
    correctChoiceIndex: 1,
    hintFr: "C suivi de E → son /s/. La voyelle E \"adoucit\" le C.",

  ),
  QuizQuestion(
    ruleId: 'rule_c',
    difficulty: QuizDifficulty.discrimination,
    word: 'couleur',
    testedLetter: 'C',
    testedIndices: [0],
    choices: ['/k/ — son dur', '/s/ — son doux'],
    correctChoiceIndex: 0,
    hintFr: "C devant OU → son /k/ dur. Le U \"durcit\" le C.",

  ),
  QuizQuestion(
    ruleId: 'rule_c',
    difficulty: QuizDifficulty.defi,
    word: 'glace',
    testedLetter: 'C',
    testedIndices: [3],
    choices: ['/k/ — son dur', '/s/ — son doux', 'Son muet'],
    correctChoiceIndex: 1,
    hintFr: "Dans \"glace\" : a-C-e → C devant E → son /s/ doux.",

  ),
  QuizQuestion(
    ruleId: 'rule_c',
    difficulty: QuizDifficulty.defi,
    word: 'accord',
    testedLetter: 'CC',
    testedIndices: [1, 2],
    choices: ['/k/ — son dur', '/s/ — deux sons', '/ks/ — double son'],
    correctChoiceIndex: 0,
    hintFr: "CC devant O → double C donne /k/. Dans \"accident\" (CC + I), ça donne /ks/.",

  ),

  // ════════════════════════════════════════════════════════════════════════
  // RULE CH  —  /ʃ/ (toujours)
  // ════════════════════════════════════════════════════════════════════════

  QuizQuestion(
    ruleId: 'rule_ch',
    difficulty: QuizDifficulty.decouverte,
    word: 'chat',
    testedLetter: 'CH',
    testedIndices: [0, 1],
    choices: ['/ʃ/ comme dans "cheval"', '/k/ comme dans "kiwi"'],
    correctChoiceIndex: 0,
    hintFr: "En français, CH se prononce presque toujours /ʃ/. Comme \"chanter\" ou \"chien\".",

  ),
  QuizQuestion(
    ruleId: 'rule_ch',
    difficulty: QuizDifficulty.discrimination,
    word: 'chocolat',
    testedLetter: 'CH',
    testedIndices: [0, 1],
    choices: ['/ʃ/ — son CH français', '/k/ — son dur'],
    correctChoiceIndex: 0,
    hintFr: "CH en français donne le son /ʃ/. Attention : en espagnol ou latin c'est parfois /k/.",

  ),
  QuizQuestion(
    ruleId: 'rule_ch',
    difficulty: QuizDifficulty.defi,
    word: 'cheval',
    testedLetter: 'CH',
    testedIndices: [0, 1],
    choices: ['/ʃ/ — son CH', '/k/ — son dur', '/s/ — son sifflement'],
    correctChoiceIndex: 0,
    hintFr: "CH → /ʃ/ en français. Ne confonds pas avec l'anglais (chair = /tʃ/).",

  ),

  // ════════════════════════════════════════════════════════════════════════
  // RULE PH  —  /f/
  // ════════════════════════════════════════════════════════════════════════

  QuizQuestion(
    ruleId: 'rule_ph',
    difficulty: QuizDifficulty.decouverte,
    word: 'photo',
    testedLetter: 'PH',
    testedIndices: [0, 1],
    choices: ['/f/ comme dans "fourmi"', '/p/ comme dans "pomme"'],
    correctChoiceIndex: 0,
    hintFr: "PH se prononce /f/ en français. C'est comme écrire un \"F\" grec.",

  ),
  QuizQuestion(
    ruleId: 'rule_ph',
    difficulty: QuizDifficulty.discrimination,
    word: 'pharmacie',
    testedLetter: 'PH',
    testedIndices: [0, 1],
    choices: ['/f/ — son de "fourmi"', '/p/ — son de "pomme"'],
    correctChoiceIndex: 0,
    hintFr: "PH dans \"pharmacie\" → /f/. D'origine grecque : φ (phi) = F.",

  ),
  QuizQuestion(
    ruleId: 'rule_ph',
    difficulty: QuizDifficulty.defi,
    word: 'éléphant',
    testedLetter: 'PH',
    testedIndices: [3, 4],
    choices: ['/f/ — son de "fourmi"', '/p/ — son de "pomme"', '/v/ — son de "vache"'],
    correctChoiceIndex: 0,
    hintFr: "Dans \"éléphant\" : élé-PH-ant → PH = /f/. Prononce \"éléfant\".",

  ),

  // ════════════════════════════════════════════════════════════════════════
  // RULE E  —  /ə/ vs /e/ vs /ɛ/
  // ════════════════════════════════════════════════════════════════════════

  QuizQuestion(
    ruleId: 'rule_e',
    difficulty: QuizDifficulty.decouverte,
    word: 'été',
    testedLetter: 'É',
    testedIndices: [0, 2],
    choices: ['/e/ fermé — bouche souriante', '/ɛ/ ouvert — bouche plus ouverte'],
    correctChoiceIndex: 0,
    hintFr: "L'accent aigu É donne toujours le son /e/ fermé. Lèvres légèrement souriantes.",

  ),
  QuizQuestion(
    ruleId: 'rule_e',
    difficulty: QuizDifficulty.decouverte,
    word: 'mère',
    testedLetter: 'È',
    testedIndices: [1],
    choices: ['/e/ fermé — bouche souriante', '/ɛ/ ouvert — bouche plus ouverte'],
    correctChoiceIndex: 1,
    hintFr: "L'accent grave È donne le son /ɛ/ ouvert. Pense à \"terre\", \"père\", \"fête\".",

  ),
  QuizQuestion(
    ruleId: 'rule_e',
    difficulty: QuizDifficulty.discrimination,
    word: 'fête',
    testedLetter: 'Ê',
    testedIndices: [1],
    choices: ['/e/ fermé', '/ɛ/ ouvert'],
    correctChoiceIndex: 1,
    hintFr: "L'accent circonflexe Ê donne le son /ɛ/ ouvert, comme \"père\" ou \"terre\".",

  ),
  QuizQuestion(
    ruleId: 'rule_e',
    difficulty: QuizDifficulty.defi,
    word: 'chanter',
    testedLetter: 'ER',
    testedIndices: [5, 6],
    choices: ['/e/ fermé — terminaison infinitif', '/ɛ/ ouvert — accent grave', '/ə/ — e muet'],
    correctChoiceIndex: 0,
    hintFr: "La terminaison -ER des verbes à l'infinitif se prononce /e/ fermé. \"chanter\" = \"chanté\".",

  ),

  // ════════════════════════════════════════════════════════════════════════
  // RULE MUETTES  —  lettres finales silencieuses
  // ════════════════════════════════════════════════════════════════════════

  QuizQuestion(
    ruleId: 'rule_muettes',
    difficulty: QuizDifficulty.decouverte,
    word: 'petit',
    testedLetter: 'T',
    testedIndices: [4],
    choices: ['Le T se prononce', 'Le T est muet (silencieux)'],
    correctChoiceIndex: 1,
    hintFr: "Dans \"petit\", le T final ne se prononce pas seul. Il devient /t/ en liaison : \"petit enfant\".",

  ),
  QuizQuestion(
    ruleId: 'rule_muettes',
    difficulty: QuizDifficulty.decouverte,
    word: 'grand',
    testedLetter: 'D',
    testedIndices: [4],
    choices: ['Le D se prononce /d/', 'Le D est muet (silencieux)'],
    correctChoiceIndex: 1,
    hintFr: "Dans \"grand\", le D final est muet. On dit \"gran\". En liaison : \"grand ami\" = \"gran-t-ami\".",

  ),
  QuizQuestion(
    ruleId: 'rule_muettes',
    difficulty: QuizDifficulty.discrimination,
    word: 'beaucoup',
    testedLetter: 'P',
    testedIndices: [7],
    choices: ['Le P se prononce /p/', 'Le P est muet (silencieux)'],
    correctChoiceIndex: 1,
    hintFr: "Dans \"beaucoup\", le P final est toujours muet. Pas de liaison avec ce mot.",

  ),
  QuizQuestion(
    ruleId: 'rule_muettes',
    difficulty: QuizDifficulty.defi,
    word: 'long',
    testedLetter: 'G',
    testedIndices: [3],
    choices: ['Le G se prononce /g/', 'Le G est muet (silencieux)', 'Le G se prononce /ʒ/'],
    correctChoiceIndex: 1,
    hintFr: "Dans \"long\", le G final est muet. On dit \"lon\". Mais en liaison : \"long hiver\" = \"lon-k-iver\".",

  ),
];

/// Returns all questions for a given [ruleId], optionally filtered by [difficulty].
List<QuizQuestion> getQuestionsForRule(
  String ruleId, {
  QuizDifficulty? difficulty,
}) {
  final filtered = kDecodingQuizBank.where((q) => q.ruleId == ruleId);
  if (difficulty != null) {
    return filtered.where((q) => q.difficulty == difficulty).toList();
  }
  return filtered.toList();
}

/// Returns all quiz questions shuffled for a full mixed-rule session.
List<QuizQuestion> getAllQuestions({QuizDifficulty? difficulty}) {
  final all = difficulty != null
      ? kDecodingQuizBank.where((q) => q.difficulty == difficulty).toList()
      : List<QuizQuestion>.from(kDecodingQuizBank);
  all.shuffle();
  return all;
}
