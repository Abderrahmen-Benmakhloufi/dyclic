// ---------------------------------------------------------------------------
// FrenchSilentLetterService — Détection des lettres muettes en français
// Conçu pour l'accessibilité DYS et l'apprentissage de la lecture.
// ---------------------------------------------------------------------------

class FrenchSilentLetterService {
  FrenchSilentLetterService._();

  /// Mots où la consonne finale est prononcée (exceptions aux consonnes muettes)
  static const Set<String> _pronouncedFinalExceptions = {
    // Terminaison en -t prononcée
    'sept', 'huit', 'ouest', 'brut', 'net', 'dot', 'contact', 'direct',
    'strict', 'correct', 'rapt', 'yacht', 'chut', 'déficit', 'granit',
    'transit', 'kit', 'but',

    // Terminaison en -d prononcée
    'sud', 'bled', 'david', 'madrid', 'cid', 'caïd',

    // Terminaison en -s prononcée
    'bus', 'mars', 'ours', 'virus', 'tennis', 'os', 'plus', 'fils',
    'atlas', 'cactus', 'coulis', 'oasis', 'vis', 'maïs', 'bis', 'sens',
    'laps', 'campus', 'chorus', 'cosinus', 'terminus', 'hélas', 'albatros',
    'rhinocéros', 'ananas', 'albinos', 'iris', 'as', 'lys', 'lis',

    // Terminaison en -p prononcée
    'cap', 'stop', 'cep', 'slip', 'handicap', 'hip',

    // Terminaison en -x prononcée
    'six', 'dix', 'index', 'thorax', 'larynx', 'pharynx', 'lynx', 'inox',
    'prefix', 'suffix', 'boxer',

    // Terminaison en -z prononcée
    'gaz', 'jazz', 'quartz',

    // Terminaison en -c prononcée (la grande majorité des mots en -c)
    'avec', 'sac', 'lac', 'parc', 'sec', 'pic', 'roc', 'duc',
    'zinc', 'truc', 'clic', 'bloc', 'bouc', 'bac', 'flic', 'tic',
    'troc', 'croc', 'choc',
  };

  /// Mots courants spécifiques avec lettres muettes internes ou complexes
  static const Map<String, List<int>> _specificWordSilentIndices = {
    'temps': [3, 4],     // 'p', 's'
    'corps': [3, 4],     // 'p', 's'
    'doigt': [3, 4],     // 'g', 't'
    'doigts': [3, 4, 5], // 'g', 't', 's'
    'vingt': [3, 4],     // 'g', 't'
    'vingts': [3, 4, 5], // 'g', 't', 's'
    'poids': [3, 4],     // 'd', 's'
    'sculpteur': [1],    // 'p'
    'sculpteurs': [1, 9],// 'p', 's'
    'sculpter': [1],     // 'p'
    'sculpture': [1],    // 'p'
    'sculptures': [1, 9],// 'p', 's'
    'compter': [2],      // 'p'
    'compte': [2],       // 'p'
    'comptes': [2, 6],   // 'p', 's'
    'compteur': [2],     // 'p'
    'compteurs': [2, 8], // 'p', 's'
    'automne': [2],      // 'm'
    'automnes': [2, 7],  // 'm', 's'
    'sept': [2],         // 'p' (t est prononcé)
  };

  /// Verbes se terminant en -ment (3e personne du pluriel)
  static const Set<String> _verbMentWords = {
    'aiment', 'fument', 'arment', 'calment', 'enferment', 'consomment',
    'assomment', 'abîment', 'estiment', 'impriment', 'expriment', 'animent',
    'rythment', 'filment', 'charment', 'blâment', 'diment',
  };

  /// Exceptions nominales et adjectivales où -ent est la voyelle nasale /ɑ̃/
  static const Set<String> _nominalEntWords = {
    'moment', 'moments', 'souvent', 'comment', 'enfant', 'enfants',
    'présent', 'présents', 'parent', 'parents', 'serpent', 'serpents',
    'accent', 'accents', 'argent', 'client', 'clients', 'talent', 'talents',
    'aliment', 'aliments', 'élément', 'éléments', 'document', 'documents',
    'sentiment', 'sentiments', 'mouvement', 'mouvements', 'vêtement', 'vêtements',
    'tourment', 'tourments', 'régiment', 'régiments', 'accident', 'accidents',
    'incident', 'incidents', 'occident', 'orient', 'patient', 'patients',
    'prudent', 'prudents', 'lent', 'lents', 'vent', 'vents',
    'dent', 'dents', 'cent', 'cents', 'agent', 'agents', 'torrent', 'torrents',
    'content', 'contents', 'urgent', 'urgents', 'intelligent', 'intelligents',
    'différent', 'différents', 'excellent', 'excellents', 'violent', 'violents',
    'récent', 'récents', 'fréquent', 'fréquents', 'absent', 'absents',
    'continent', 'continents', 'président', 'présidents', 'sergent', 'sergents',
    'polyvalent', 'polyvalents', 'équivalent', 'équivalents', 'insolent', 'insolents',
    'innocent', 'innocents', 'appartement', 'appartements', 'bâtiment', 'bâtiments',
  };

  /// Terminaisons verbales en -ent (3e personne du pluriel)
  static bool _isSilentVerbEnding(String lower) {
    if (lower.length < 5 || !lower.endsWith('ent')) return false;

    // 1. Tous les adverbes et noms en -ment (ex: doucement, lentement, justement)
    // Sauf les quelques rares verbes dont le radical se termine en 'm' (aiment, fument, etc.)
    if (lower.endsWith('ment')) {
      return _verbMentWords.contains(lower);
    }

    // 2. Mots nominaux/adjectivaux où -ent est la voyelle nasale /ɑ̃/ (non verbal)
    if (_nominalEntWords.contains(lower)) return false;

    // 3. Verbes courants : -ent est muet
    return true;
  }

  /// Retourne l'ensemble des indices (0-based) des caractères muets dans le mot donné.
  static Set<int> getSilentIndices(String word) {
    if (word.isEmpty) return const {};

    final lower = word.toLowerCase();
    final silent = <int>{};

    // 1. Vérifier la table des mots spécifiques
    if (_specificWordSilentIndices.containsKey(lower)) {
      silent.addAll(_specificWordSilentIndices[lower]!);
      return silent;
    }

    final len = lower.length;

    // 2. Terminaison verbale silencieuse -ent (ex: chantent, parlent, mangent)
    if (_isSilentVerbEnding(lower)) {
      // Les lettres 'e', 'n', 't' finales sont muettes
      silent.add(len - 3); // 'e'
      silent.add(len - 2); // 'n'
      silent.add(len - 1); // 't'
      return silent;
    }

    // 3. Cas des consonnes muettes finales régulières
    if (len >= 2 && !_pronouncedFinalExceptions.contains(lower)) {
      final last = lower[len - 1];
      final penultimate = lower[len - 2];

      // Cas des pluriels réguliers avec consonne muette + s (ex: chats, grands, loups, bancs)
      if (last == 's' && len >= 3) {
        if ('dtpgcbx'.contains(penultimate)) {
          // Les deux dernières consonnes sont muettes (ex: cha-ts, gran-ds, lou-ps)
          silent.add(len - 2);
          silent.add(len - 1);
          return silent;
        } else {
          // Le 's' final seul est muet (ex: les, des, maisons, livres, amis)
          silent.add(len - 1);
          return silent;
        }
      }

      // Consonnes finales muettes singulières : d, t, p, s, x, z, g, b
      if ('dtpsxzg'.contains(last)) {
        silent.add(len - 1);
      } else if (last == 'c' && 'nr'.contains(penultimate)) {
        // 'c' après 'n' ou 'r' est muet (ex: blanc, banc, franc, tronc, porc)
        silent.add(len - 1);
      }
    }

    return silent;
  }
}
