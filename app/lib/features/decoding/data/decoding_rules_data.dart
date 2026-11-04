import '../models/decoding_rule_model.dart';

const List<DecodingRule> decodingRulesCatalog = [
  // 1. La lettre G
  DecodingRule(
    id: 'rule_g',
    letter: 'G',
    titleFr: 'La lettre G',
    overviewFr: 'La lettre G peut produire deux sons principaux : /g/ et /ʒ/.',
    subRules: [
      DecodingSubRule(
        soundIpa: '/g/',
        conditionFr: 'Devant A, O, U ou avec GU devant E et I.',
        examples: [
          ExampleWord(
            word: 'gare',
            highlightIndices: [0],
            note: 'G suivi de A → son /g/',
          ),
          ExampleWord(
            word: 'gomme',
            highlightIndices: [0],
            note: 'G suivi de O → son /g/',
          ),
          ExampleWord(
            word: 'guerre',
            highlightIndices: [0, 1],
            note: 'GU devant E → son /g/',
          ),
        ],
      ),
      DecodingSubRule(
        soundIpa: '/ʒ/',
        conditionFr: 'Devant les voyelles E, I et Y.',
        examples: [
          ExampleWord(
            word: 'girafe',
            highlightIndices: [0],
            note: 'G suivi de I → son /ʒ/',
          ),
          ExampleWord(
            word: 'genou',
            highlightIndices: [0],
            note: 'G suivi de E → son /ʒ/',
          ),
          ExampleWord(
            word: 'genre',
            highlightIndices: [0],
            note: 'G suivi de E → son /ʒ/',
          ),
        ],
      ),
    ],
  ),

  // 2. La lettre S
  DecodingRule(
    id: 'rule_s',
    letter: 'S',
    titleFr: 'La lettre S',
    overviewFr: 'La lettre S peut se prononcer /s/ ou /z/.',
    subRules: [
      DecodingSubRule(
        soundIpa: '/s/',
        conditionFr: 'En début de mot ou avec deux SS entre deux voyelles.',
        examples: [
          ExampleWord(
            word: 'soleil',
            highlightIndices: [0],
            note: 'S au début → son /s/',
          ),
          ExampleWord(
            word: 'poisson',
            highlightIndices: [3, 4],
            note: 'Double SS entre voyelles → son /s/',
          ),
        ],
      ),
      DecodingSubRule(
        soundIpa: '/z/',
        conditionFr: 'Un seul S placé entre deux voyelles.',
        examples: [
          ExampleWord(
            word: 'maison',
            highlightIndices: [3],
            note: 'S entre I et O → son /z/',
          ),
          ExampleWord(
            word: 'plaisir',
            highlightIndices: [4],
            note: 'S entre I et I → son /z/',
          ),
        ],
      ),
    ],
  ),

  // 3. La lettre C
  DecodingRule(
    id: 'rule_c',
    letter: 'C',
    titleFr: 'La lettre C',
    overviewFr: 'La lettre C produit principalement le son /k/ ou le son /s/.',
    subRules: [
      DecodingSubRule(
        soundIpa: '/k/',
        conditionFr: 'Devant les voyelles A, O et U.',
        examples: [
          ExampleWord(
            word: 'cadeau',
            highlightIndices: [0],
            note: 'C suivi de A → son /k/',
          ),
        ],
      ),
      DecodingSubRule(
        soundIpa: '/s/',
        conditionFr: 'Devant les voyelles E, I et Y.',
        examples: [
          ExampleWord(
            word: 'cinéma',
            highlightIndices: [0],
            note: 'C suivi de I → son /s/',
          ),
        ],
      ),
    ],
  ),

  // 4. Le groupe de lettres CH
  DecodingRule(
    id: 'rule_ch',
    letter: 'CH',
    titleFr: 'Le groupe de lettres CH',
    overviewFr: 'Les lettres CH s\'associent pour former le son /ʃ/.',
    subRules: [
      DecodingSubRule(
        soundIpa: '/ʃ/',
        conditionFr: 'Association constante des lettres C et H.',
        examples: [
          ExampleWord(
            word: 'chat',
            highlightIndices: [0, 1],
            note: 'CH → son /ʃ/',
          ),
          ExampleWord(
            word: 'cheval',
            highlightIndices: [0, 1],
            note: 'CH → son /ʃ/',
          ),
          ExampleWord(
            word: 'chocolat',
            highlightIndices: [0, 1],
            note: 'CH → son /ʃ/',
          ),
        ],
      ),
    ],
  ),

  // 5. Le groupe de lettres PH
  DecodingRule(
    id: 'rule_ph',
    letter: 'PH',
    titleFr: 'Le groupe de lettres PH',
    overviewFr: 'Les lettres PH se prononcent /f/.',
    subRules: [
      DecodingSubRule(
        soundIpa: '/f/',
        conditionFr: 'Association des lettres P et H.',
        examples: [
          ExampleWord(
            word: 'photo',
            highlightIndices: [0, 1],
            note: 'PH → son /f/',
          ),
          ExampleWord(
            word: 'pharmacie',
            highlightIndices: [0, 1],
            note: 'PH → son /f/',
          ),
          ExampleWord(
            word: 'éléphant',
            highlightIndices: [3, 4],
            note: 'PH → son /f/',
          ),
        ],
      ),
    ],
  ),

  // 6. La voyelle E
  DecodingRule(
    id: 'rule_e',
    letter: 'E',
    titleFr: 'La voyelle E',
    overviewFr: 'La lettre E possède plusieurs prononciations selon le mot et les accents.',
    subRules: [
      DecodingSubRule(
        soundIpa: '/ə/',
        conditionFr: 'Dans les petits mots ou en syllabe ouverte.',
        examples: [
          ExampleWord(
            word: 'le',
            highlightIndices: [1],
            note: 'E simple prononcé /ə/',
          ),
        ],
      ),
      DecodingSubRule(
        soundIpa: '/e/',
        conditionFr: 'Avec accent aigu (é) ou terminaisons -er / -ez.',
        examples: [
          ExampleWord(
            word: 'été',
            highlightIndices: [0, 2],
            note: 'É accent aigu → son /e/ fermé',
          ),
        ],
      ),
      DecodingSubRule(
        soundIpa: '/ɛ/',
        conditionFr: 'Avec accent grave (è) ou circonflexe (ê).',
        examples: [
          ExampleWord(
            word: 'mère',
            highlightIndices: [1],
            note: 'È accent grave → son /ɛ/ ouvert',
          ),
        ],
      ),
    ],
  ),

  // 7. Les lettres muettes
  DecodingRule(
    id: 'rule_muettes',
    letter: 'Ø',
    titleFr: 'Les lettres muettes',
    overviewFr: 'Certaines lettres écrites à la fin des mots ne se prononcent pas.',
    subRules: [
      DecodingSubRule(
        soundIpa: 'Muette',
        conditionFr: 'Lettre finale silencieuse dans le mot isolé.',
        examples: [
          ExampleWord(
            word: 'petit',
            highlightIndices: [4],
            note: 'Le T final est muet',
          ),
          ExampleWord(
            word: 'grand',
            highlightIndices: [4],
            note: 'Le D final est muet',
          ),
          ExampleWord(
            word: 'beaucoup',
            highlightIndices: [7],
            note: 'Le P final est muet, se termine par le son /u/',
          ),
        ],
      ),
    ],
  ),
];
