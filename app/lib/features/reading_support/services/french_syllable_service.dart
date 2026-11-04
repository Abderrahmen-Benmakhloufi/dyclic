// ---------------------------------------------------------------------------
// FrenchSyllableService — Algorithme de découpage syllabique pour la langue française
// Conçu pour l'accessibilité DYS et l'apprentissage de la lecture.
// ---------------------------------------------------------------------------

class FrenchSyllableService {
  FrenchSyllableService._();

  /// Groupes de consonnes inséparables en français :
  /// - Occlusive/fricative + liquide (l/r)
  /// - Digraphes formant un son consonantique unique (ch, ph, th, gn, qu, gu)
  static const Set<String> _inseparableClusters = {
    'bl', 'cl', 'fl', 'gl', 'pl',
    'br', 'cr', 'dr', 'fr', 'gr', 'pr', 'tr', 'vr',
    'ch', 'ph', 'th', 'gn', 'qu', 'gu',
  };

  /// Digraphes et trigraphes vocaliques complexes fréquents en français
  /// ordonnés du plus long au plus court pour le greedy matching
  static const List<String> _vowelGraphemes = [
    'eaux', 'eau', 'œu', 'oeu',
    'aie', 'aies', 'aient', 'ait',
    'aux', 'ai', 'ei', 'au', 'ou', 'eu', 'oi', 'ui',
    'œ', 'æ',
  ];

  static const String _singleVowels = 'aàâäeéèêëiîïoôöuùûüyÿ';

  static bool _isVowelChar(String char) {
    if (char.isEmpty) return false;
    return _singleVowels.contains(char.toLowerCase());
  }

  /// Découpe un mot unique en une liste de syllabes écrites.
  /// Préserve la casse originale des caractères.
  static List<String> segmentWord(String word) {
    if (word.length <= 2) return [word];

    final lower = word.toLowerCase();

    // 1. Trouver les noyaux vocaliques (intervalles [start, end[)
    final vowelSpans = <_Span>[];
    int i = 0;
    while (i < lower.length) {
      // Tester d'abord les digraphes / trigraphes complexes
      bool matched = false;
      for (final g in _vowelGraphemes) {
        if (lower.startsWith(g, i)) {
          vowelSpans.add(_Span(i, i + g.length));
          i += g.length;
          matched = true;
          break;
        }
      }
      if (matched) continue;

      // Tester les voyelles simples
      if (_isVowelChar(lower[i])) {
        vowelSpans.add(_Span(i, i + 1));
      }
      i++;
    }

    // Si le mot a 0 ou 1 seul noyau vocalique, c'est un monosyllabe
    if (vowelSpans.length <= 1) {
      return [word];
    }

    // 2. Déterminer les points de césure entre noyaux vocaliques consécutifs
    final cutIndices = <int>[];

    for (int k = 0; k < vowelSpans.length - 1; k++) {
      final v1 = vowelSpans[k];
      final v2 = vowelSpans[k + 1];

      final consStart = v1.end;
      final consEnd = v2.start;
      final consLen = consEnd - consStart;

      if (consLen <= 0) {
        // Deux voyelles contiguës non groupées (hiatus, ex: po-ète, a-érien)
        cutIndices.add(consStart);
      } else if (consLen == 1) {
        // 1 consonne entre 2 voyelles -> césure avant la consonne (ex: che-val, ca-fé)
        cutIndices.add(consStart);
      } else if (consLen == 2) {
        final pair = lower.substring(consStart, consEnd);
        if (_inseparableClusters.contains(pair)) {
          // Groupe inséparable -> césure avant le groupe (ex: ta-bleau, a-près)
          cutIndices.add(consStart);
        } else {
          // Deux consonnes distinctes ou jumelles -> césure entre les deux (ex: pom-me, par-ler)
          cutIndices.add(consStart + 1);
        }
      } else {
        // 3 consonnes ou plus
        // Vérifier si les deux dernières consonnes forment un groupe inséparable
        final lastPair = lower.substring(consEnd - 2, consEnd);
        if (_inseparableClusters.contains(lastPair)) {
          cutIndices.add(consEnd - 2); // ex: ar-bre, com-plet
        } else {
          // Règle générale : césure après la première consonne (ex: comp-ter, obs-tacle)
          cutIndices.add(consStart + 1);
        }
      }
    }

    // 3. Découper le mot original selon les indices de césure
    final syllables = <String>[];
    int prev = 0;
    for (final cut in cutIndices) {
      if (cut > prev && cut < word.length) {
        syllables.add(word.substring(prev, cut));
        prev = cut;
      }
    }
    if (prev < word.length) {
      syllables.add(word.substring(prev));
    }

    return syllables.isEmpty ? [word] : syllables;
  }
}

class _Span {
  final int start;
  final int end;
  const _Span(this.start, this.end);
}
