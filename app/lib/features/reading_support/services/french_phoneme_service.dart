import 'package:flutter/material.dart';

enum SoundHighlightType {
  // Consonnes complexes & digraphes
  soundCH,      // CH -> /ʃ/
  soundPH,      // PH -> /f/
  soundGN,      // GN -> /ɲ/
  soundILL,     // ILL, AIL, EIL -> /j/

  // Voyelles complexes (digraphes vocaliques)
  soundOU,      // OU -> /u/
  soundON,      // ON, OM -> /ɔ̃/
  soundAN,      // AN, AM, EN, EM -> /ɑ̃/
  soundIN,      // IN, IM, AIN, EIN -> /ɛ̃/
  soundOI,      // OI -> /wa/
  soundAU,      // AU, EAU -> /o/
  soundEU,      // EU, ŒU -> /ø/

  // La voyelle E et ses prononciations
  soundEFerme,  // É, -er, -ez -> /e/
  soundEOuvert, // È, Ê, Ë -> /ɛ/
  soundECaduc,  // E caduc -> /ə/

  // Lettres contextuelles (G, C, S, Z)
  gSoft,        // G devant E, I, Y -> /ʒ/
  gHard,        // G devant A, O, U ou GU -> /g/
  cSoft,        // C devant E, I, Y ou Ç -> /s/
  sVoiced,      // S unique entre 2 voyelles -> /z/
  sUnvoiced,    // S standard sourd -> /s/
  soundZ,       // Lettre Z -> /z/
}

class SoundHighlight {
  final SoundHighlightType type;
  final String label;
  final String soundIpa;
  final Color color;
  final String description;
  final String example;
  final bool isUnderlined;

  const SoundHighlight({
    required this.type,
    required this.label,
    required this.soundIpa,
    required this.color,
    required this.description,
    required this.example,
    this.isUnderlined = false,
  });
}

class ReadingLegendItem {
  final String category; // 'syllable', 'complex_sound', 'vowel_e', 'contextual', 'mirror', 'silent'
  final String label;
  final String soundIpa;
  final Color color;
  final String description;
  final String example;
  final String exampleAudioWord;
  final bool isUnderlined;
  final bool isItalic;

  const ReadingLegendItem({
    this.category = 'complex_sound',
    required this.label,
    required this.soundIpa,
    required this.color,
    required this.description,
    required this.example,
    this.exampleAudioWord = '',
    this.isUnderlined = false,
    this.isItalic = false,
  });
}

class FrenchPhonemeService {
  static const Set<String> _frenchVowels = {
    'a', 'e', 'i', 'o', 'u', 'y',
    'à', 'â', 'ä', 'é', 'è', 'ê', 'ë', 'î', 'ï', 'ô', 'ö', 'ù', 'û', 'ü', 'ÿ',
  };

  // ── Couleurs dynamiques à contraste élevé (Chaque son a sa couleur exclusive et unique) ───
  static Color colorCH(bool isDark) => isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
  static Color colorPH(bool isDark) => isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  static Color colorGN(bool isDark) => isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
  static Color colorILL(bool isDark) => isDark ? const Color(0xFFFACC15) : const Color(0xFFA16207);

  static Color colorOU(bool isDark) => isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
  static Color colorON(bool isDark) => isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE);
  static Color colorAN(bool isDark) => isDark ? const Color(0xFFF472B6) : const Color(0xFFBE185D);
  static Color colorIN(bool isDark) => isDark ? const Color(0xFFFB7185) : const Color(0xFFBE123C);
  static Color colorOI(bool isDark) => isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
  static Color colorAU(bool isDark) => isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
  static Color colorEU(bool isDark) => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

  static Color colorEFerme(bool isDark) => isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);
  static Color colorEOuvert(bool isDark) => isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  static Color colorECaduc(bool isDark) => isDark ? const Color(0xFFE2E8F0) : const Color(0xFF78350F);

  static Color colorGSoft(bool isDark) => isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA);
  static Color colorGHard(bool isDark) => isDark ? const Color(0xFF93C5FD) : const Color(0xFF0369A1);
  static Color colorCSoft(bool isDark) => isDark ? const Color(0xFFE879F9) : const Color(0xFFA21CAF);
  static Color colorSVoiced(bool isDark) => isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C);
  static Color colorSUnvoiced(bool isDark) => isDark ? const Color(0xFF67E8F9) : const Color(0xFF0891B2);
  static Color colorSoundZ(bool isDark) => isDark ? const Color(0xFFE879F9) : const Color(0xFF9333EA);

  static Color colorMirrorB(bool isDark) => isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
  static Color colorMirrorD(bool isDark) => isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  static Color colorMirrorP(bool isDark) => isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  static Color colorSilent(bool isDark) => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  /// Détecte les sons complexes (ch, ph, ou, on, an, in, oi, eau, gn, etc.)
  static Map<int, SoundHighlight> getComplexPhonemes(String word, {bool isDark = false}) {
    final highlights = <int, SoundHighlight>{};
    final lower = word.toLowerCase();
    final len = lower.length;

    final patterns = [
      ('eau', SoundHighlightType.soundAU, 'EAU', '/o/', colorAU(isDark), 'EAU → son /o/ comme dans bateau', 'bateau, eau'),
      ('ain', SoundHighlightType.soundIN, 'AIN', '/ɛ̃/', colorIN(isDark), 'AIN → son /ɛ̃/ comme dans train', 'train, pain'),
      ('ein', SoundHighlightType.soundIN, 'EIN', '/ɛ̃/', colorIN(isDark), 'EIN → son /ɛ̃/ comme dans plein', 'plein, peinture'),
      ('ill', SoundHighlightType.soundILL, 'ILL', '/j/', colorILL(isDark), 'ILL → son /j/ comme dans fille', 'fille, bille'),
      ('ail', SoundHighlightType.soundILL, 'AIL', '/j/', colorILL(isDark), 'AIL → son /j/ comme dans travail', 'travail, émail'),
      ('eil', SoundHighlightType.soundILL, 'EIL', '/j/', colorILL(isDark), 'EIL → son /j/ comme dans soleil', 'soleil, réveil'),
      ('ch', SoundHighlightType.soundCH, 'CH', '/ʃ/', colorCH(isDark), 'CH → son /ʃ/ comme dans chat', 'chat, cheval, chocolat'),
      ('ph', SoundHighlightType.soundPH, 'PH', '/f/', colorPH(isDark), 'PH → son /f/ comme dans photo', 'photo, éléphant'),
      ('ou', SoundHighlightType.soundOU, 'OU', '/u/', colorOU(isDark), 'OU → son /u/ comme dans loup', 'loup, rouge'),
      ('on', SoundHighlightType.soundON, 'ON', '/ɔ̃/', colorON(isDark), 'ON → son /ɔ̃/ comme dans bonbon', 'bonbon, ballon'),
      ('om', SoundHighlightType.soundON, 'OM', '/ɔ̃/', colorON(isDark), 'OM → son /ɔ̃/ devant b ou p', 'pompe, ombre'),
      ('an', SoundHighlightType.soundAN, 'AN', '/ɑ̃/', colorAN(isDark), 'AN → son /ɑ̃/ comme dans maman', 'maman, blanc'),
      ('am', SoundHighlightType.soundAN, 'AM', '/ɑ̃/', colorAN(isDark), 'AM → son /ɑ̃/ devant b ou p', 'chambre, lampe'),
      ('en', SoundHighlightType.soundAN, 'EN', '/ɑ̃/', colorAN(isDark), 'EN → son /ɑ̃/ comme dans enfant', 'enfant, vent'),
      ('em', SoundHighlightType.soundAN, 'EM', '/ɑ̃/', colorAN(isDark), 'EM → son /ɑ̃/ devant b ou p', 'temps, ensemble'),
      ('in', SoundHighlightType.soundIN, 'IN', '/ɛ̃/', colorIN(isDark), 'IN → son /ɛ̃/ comme dans lapin', 'lapin, matin'),
      ('im', SoundHighlightType.soundIN, 'IM', '/ɛ̃/', colorIN(isDark), 'IM → son /ɛ̃/ devant b ou p', 'timbre, simple'),
      ('oi', SoundHighlightType.soundOI, 'OI', '/wa/', colorOI(isDark), 'OI → son /wa/ comme dans roi', 'roi, oiseau, boîte'),
      ('au', SoundHighlightType.soundAU, 'AU', '/o/', colorAU(isDark), 'AU → son /o/ comme dans auto', 'auto, chaud'),
      ('eu', SoundHighlightType.soundEU, 'EU', '/ø/', colorEU(isDark), 'EU → son /ø/ comme dans bleu', 'bleu, fleur'),
      ('gn', SoundHighlightType.soundGN, 'GN', '/ɲ/', colorGN(isDark), 'GN → son /ɲ/ comme dans montagne', 'montagne, ligne'),
    ];

    int i = 0;
    while (i < len) {
      bool matched = false;
      for (final (pat, type, label, ipa, col, desc, ex) in patterns) {
        if (i + pat.length <= len && lower.substring(i, i + pat.length) == pat) {
          final highlight = SoundHighlight(
            type: type,
            label: label,
            soundIpa: ipa,
            color: col,
            description: desc,
            example: ex,
            isUnderlined: (type == SoundHighlightType.soundCH || type == SoundHighlightType.soundPH),
          );
          for (int k = 0; k < pat.length; k++) {
            highlights[i + k] = highlight;
          }
          i += pat.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        i++;
      }
    }

    return highlights;
  }

  /// Détecte les prononciations de la voyelle E (É, È, Ê, E caduc)
  static Map<int, SoundHighlight> getVowelEHighlights(String word, {bool isDark = false}) {
    final highlights = <int, SoundHighlight>{};
    final lower = word.toLowerCase();
    final len = lower.length;

    for (int i = 0; i < len; i++) {
      final c = lower[i];

      // 1. É accent aigu ou terminaison -er / -ez
      if (c == 'é') {
        highlights[i] = SoundHighlight(
          type: SoundHighlightType.soundEFerme,
          label: 'É',
          soundIpa: '/e/',
          color: colorEFerme(isDark),
          description: 'É accent aigu → son /e/ fermé',
          example: 'été, école',
        );
      } else if (c == 'e' && i == len - 2 && (lower[i + 1] == 'r' || lower[i + 1] == 'z') && len > 2) {
        // -er ou -ez en fin de mot
        final hl = SoundHighlight(
          type: SoundHighlightType.soundEFerme,
          label: '-er/-ez',
          soundIpa: '/e/',
          color: colorEFerme(isDark),
          description: 'Terminaison -er ou -ez → son /e/',
          example: 'parler, aimez',
        );
        highlights[i] = hl;
        highlights[i + 1] = hl;
      }
      // 2. È accent grave, Ê circonflexe ou Ë tréma
      else if (c == 'è' || c == 'ê' || c == 'ë') {
        highlights[i] = SoundHighlight(
          type: SoundHighlightType.soundEOuvert,
          label: c.toUpperCase(),
          soundIpa: '/ɛ/',
          color: colorEOuvert(isDark),
          description: '$c accentué → son /ɛ/ ouvert',
          example: 'mère, fête, noël',
        );
      }
      // 3. E caduc simple (dans petits mots : le, me, te, se, de, ne, que, ce)
      else if (c == 'e' && len <= 3 && (' le me te se de ne que ce '.contains(' $lower '))) {
        highlights[i] = SoundHighlight(
          type: SoundHighlightType.soundECaduc,
          label: 'E caduc',
          soundIpa: '/ə/',
          color: colorECaduc(isDark),
          description: 'E simple en syllabe ouverte → son /ə/',
          example: 'le, me, petit',
        );
      }
    }

    return highlights;
  }

  /// Détecte les règles de décodage contextuelles pour G, C, S
  static Map<int, SoundHighlight> getContextualLetters(String word, {bool isDark = false}) {
    final highlights = <int, SoundHighlight>{};
    final lower = word.toLowerCase();
    final len = lower.length;

    for (int i = 0; i < len; i++) {
      final c = lower[i];
      final next = (i + 1 < len) ? lower[i + 1] : '';
      final prev = (i - 1 >= 0) ? lower[i - 1] : '';

      // 1. Lettre G
      if (c == 'g') {
        if (next == 'e' || next == 'i' || next == 'y' || next == 'é' || next == 'è' || next == 'ê') {
          highlights[i] = SoundHighlight(
            type: SoundHighlightType.gSoft,
            label: 'G doux',
            soundIpa: '/ʒ/',
            color: colorGSoft(isDark),
            description: 'G devant E, I ou Y → son /ʒ/',
            example: 'girafe, genou, cage',
          );
        } else if (next == 'u' && i + 2 < len && ('eiyéèê'.contains(lower[i + 2]))) {
          // GU devant voyelle
          final hl = SoundHighlight(
            type: SoundHighlightType.gHard,
            label: 'GU',
            soundIpa: '/g/',
            color: colorGHard(isDark),
            description: 'GU devant E ou I → son /g/',
            example: 'guerre, bague',
          );
          highlights[i] = hl;
          highlights[i + 1] = hl;
        } else {
          highlights[i] = SoundHighlight(
            type: SoundHighlightType.gHard,
            label: 'G dur',
            soundIpa: '/g/',
            color: colorGHard(isDark),
            description: 'G devant A, O, U ou consonne → son /g/',
            example: 'gare, gomme, grand',
          );
        }
      }

      // 2. Lettre C ou Ç
      else if (c == 'c' || c == 'ç') {
        if (c == 'ç' || next == 'e' || next == 'i' || next == 'y' || next == 'é' || next == 'è' || next == 'ê') {
          highlights[i] = SoundHighlight(
            type: SoundHighlightType.cSoft,
            label: 'C doux',
            soundIpa: '/s/',
            color: colorCSoft(isDark),
            description: 'C devant E, I, Y ou Ç → son /s/',
            example: 'cinéma, cerise, garçon',
          );
        }
      }

      // 3. Lettre S
      else if (c == 's') {
        final isSurroundedByVowels = _frenchVowels.contains(prev) &&
            _frenchVowels.contains(next) &&
            (i + 2 >= len || lower[i + 1] != 's') &&
            (i - 2 < 0 || lower[i - 1] != 's');

        if (isSurroundedByVowels) {
          highlights[i] = SoundHighlight(
            type: SoundHighlightType.sVoiced,
            label: 'S voisé',
            soundIpa: '/z/',
            color: colorSVoiced(isDark),
            description: 'S seul entre deux voyelles → son /z/',
            example: 'maison, rose, oiseau',
          );
        } else {
          highlights[i] = SoundHighlight(
            type: SoundHighlightType.sUnvoiced,
            label: 'Lettre S',
            soundIpa: '/s/',
            color: colorSUnvoiced(isDark),
            description: 'S se prononce /s/ (siffle comme le serpent)',
            example: 'soleil, sac, danse, souris',
          );
        }
      }

      // 4. Lettre Z
      else if (c == 'z') {
        highlights[i] = SoundHighlight(
          type: SoundHighlightType.soundZ,
          label: 'Lettre Z',
          soundIpa: '/z/',
          color: colorSoundZ(isDark),
          description: 'Z se prononce /z/ (bourdonne comme l\'abeille)',
          example: 'zèbre, zéro, gaz, pizza',
        );
      }
    }

    return highlights;
  }

  /// Génère la liste complète des repères pour la Légende / Échelle de carte des couleurs
  static List<ReadingLegendItem> getActiveLegendItems({
    required bool showSyllables,
    required bool showSilentLetters,
    required bool showMirrorLetters,
    required bool showComplexSounds,
    required bool showVowelE,
    required bool showContextualLetters,
    Color? syllableColor1,
    Color? syllableColor2,
    Color? syllableColor3,
    Color? syllableColor4,
    List<Color>? syllableColors,
    int syllableColorCount = 3,
    bool isDark = false,
  }) {
    final list = <ReadingLegendItem>[];

    // Résolution de la liste des couleurs de syllabes (2, 3 ou 4 couleurs)
    final resolvedSyllableColors = syllableColors ??
        [
          syllableColor1 ?? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
          syllableColor2 ?? (isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED)),
          syllableColor3 ?? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
          syllableColor4 ?? (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488)),
        ];

    final effectiveColorCount = syllableColorCount.clamp(2, resolvedSyllableColors.length);

    // 1. Syllabes découpées (2 à 4 couleurs alternées distinctes)
    if (showSyllables) {
      final ordinals = ['1ère', '2ème', '3ème', '4ème'];
      final exParts = ['or', 'di', 'na', 'teur'];

      for (int i = 0; i < effectiveColorCount; i++) {
        list.add(ReadingLegendItem(
          category: 'syllables',
          label: 'Syllabe ${i + 1}',
          soundIpa: ordinals[i],
          color: resolvedSyllableColors[i],
          description: 'Syllabe n°${i + 1} en alternance ($effectiveColorCount couleurs distinctes)',
          example: 'ex: ${exParts[i]} dans or-di-na-teur',
          exampleAudioWord: 'ordinateur',
        ));
      }
    }

    // 2. Lettres muettes
    if (showSilentLetters) {
      list.add(ReadingLegendItem(
        category: 'rules',
        label: 'Lettre muette',
        soundIpa: 'Ø (silence)',
        color: colorSilent(isDark),
        description: 'Lettre finale ou interne silencieuse (ne se prononce pas)',
        example: 'petit, grand, beaucoup',
        exampleAudioWord: 'petit',
        isItalic: true,
      ));
    }

    // 3. Lettres miroir b / d / p
    if (showMirrorLetters) {
      list.add(ReadingLegendItem(
        category: 'rules',
        label: 'Lettre b',
        soundIpa: '/b/',
        color: colorMirrorB(isDark),
        description: 'Ventre orienté vers la droite [ b ]',
        example: 'bateau, ballon',
        exampleAudioWord: 'bateau',
      ));
      list.add(ReadingLegendItem(
        category: 'rules',
        label: 'Lettre d',
        soundIpa: '/d/',
        color: colorMirrorD(isDark),
        description: 'Ventre orienté vers la gauche [ d ]',
        example: 'dormir, grand',
        exampleAudioWord: 'dormir',
      ));
      list.add(ReadingLegendItem(
        category: 'rules',
        label: 'Lettre p',
        soundIpa: '/p/',
        color: colorMirrorP(isDark),
        description: 'Jambe vers le bas et boucle à droite [ p ]',
        example: 'papa, porte, pomme',
        exampleAudioWord: 'porte',
      ));
    }

    // 4. Sons complexes (CH, PH, OU, ON, AN, IN, OI, AU/EAU, GN, ILL)
    if (showComplexSounds) {
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'CH',
        soundIpa: '/ʃ/',
        color: colorCH(isDark),
        description: 'CH forme le son chuinté /ʃ/',
        example: 'chat, chocolat, cheval',
        exampleAudioWord: 'chocolat',
        isUnderlined: true,
      ));
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'PH',
        soundIpa: '/f/',
        color: colorPH(isDark),
        description: 'PH se prononce comme un F (/f/)',
        example: 'photo, pharmacie, éléphant',
        exampleAudioWord: 'photo',
        isUnderlined: true,
      ));
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'OU',
        soundIpa: '/u/',
        color: colorOU(isDark),
        description: 'OU forme le son vocalique /u/',
        example: 'loup, rouge, roue',
        exampleAudioWord: 'loup',
      ));
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'ON / OM',
        soundIpa: '/ɔ̃/',
        color: colorON(isDark),
        description: 'Voyelle nasale arrondie /ɔ̃/',
        example: 'bonbon, pont, ombre',
        exampleAudioWord: 'bonbon',
      ));
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'AN / EN',
        soundIpa: '/ɑ̃/',
        color: colorAN(isDark),
        description: 'Voyelle nasale ouverte /ɑ̃/',
        example: 'maman, vent, enfant',
        exampleAudioWord: 'enfant',
      ));
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'IN / AIN',
        soundIpa: '/ɛ̃/',
        color: colorIN(isDark),
        description: 'Voyelle nasale étirée /ɛ̃/',
        example: 'lapin, train, plein',
        exampleAudioWord: 'lapin',
      ));
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'OI',
        soundIpa: '/wa/',
        color: colorOI(isDark),
        description: 'OI produit la diphtongue /wa/',
        example: 'roi, oiseau, boîte',
        exampleAudioWord: 'oiseau',
      ));
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'AU / EAU',
        soundIpa: '/o/',
        color: colorAU(isDark),
        description: 'AU et EAU forment le son /o/ fermé',
        example: 'auto, bateau, eau',
        exampleAudioWord: 'bateau',
      ));
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'EU / ŒU',
        soundIpa: '/ø/',
        color: colorEU(isDark),
        description: 'EU forme le son arrondi /ø/ ou /œ/',
        example: 'bleu, fleur, cœur',
        exampleAudioWord: 'fleur',
      ));
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'GN',
        soundIpa: '/ɲ/',
        color: colorGN(isDark),
        description: 'GN forme le son palatal /ɲ/',
        example: 'montagne, ligne, agneau',
        exampleAudioWord: 'montagne',
      ));
      list.add(ReadingLegendItem(
        category: 'complex',
        label: 'ILL / EIL',
        soundIpa: '/j/',
        color: colorILL(isDark),
        description: 'Son mouillé glide /j/',
        example: 'fille, soleil, réveil',
        exampleAudioWord: 'soleil',
      ));
    }

    // 5. Voyelle E et ses prononciations
    if (showVowelE) {
      list.add(ReadingLegendItem(
        category: 'vowel_e',
        label: 'É / -er',
        soundIpa: '/e/',
        color: colorEFerme(isDark),
        description: 'Accent aigu ou terminaison -er/-ez → son /e/ fermé',
        example: 'été, école, parler',
        exampleAudioWord: 'école',
      ));
      list.add(ReadingLegendItem(
        category: 'vowel_e',
        label: 'È / Ê',
        soundIpa: '/ɛ/',
        color: colorEOuvert(isDark),
        description: 'Accent grave ou circonflexe → son /ɛ/ ouvert',
        example: 'mère, fête, père',
        exampleAudioWord: 'fête',
      ));
      list.add(ReadingLegendItem(
        category: 'vowel_e',
        label: 'E caduc',
        soundIpa: '/ə/',
        color: colorECaduc(isDark),
        description: 'E simple prononcé /ə/ (en syllabe ouverte)',
        example: 'le, me, petit',
        exampleAudioWord: 'petit',
      ));
    }

    // 6. Règles contextuelles G, C, S, Z
    if (showContextualLetters) {
      list.add(ReadingLegendItem(
        category: 'contextual',
        label: 'G doux',
        soundIpa: '/ʒ/',
        color: colorGSoft(isDark),
        description: 'G devant E, I ou Y se prononce /ʒ/',
        example: 'girafe, genou, cage',
        exampleAudioWord: 'girafe',
      ));
      list.add(ReadingLegendItem(
        category: 'contextual',
        label: 'G dur',
        soundIpa: '/g/',
        color: colorGHard(isDark),
        description: 'G devant A, O, U ou GU se prononce /g/',
        example: 'gare, gomme, guerre',
        exampleAudioWord: 'gare',
      ));
      list.add(ReadingLegendItem(
        category: 'contextual',
        label: 'C doux',
        soundIpa: '/s/',
        color: colorCSoft(isDark),
        description: 'C devant E, I, Y ou Ç se prononce /s/',
        example: 'cinéma, cerise, garçon',
        exampleAudioWord: 'cinéma',
      ));
      list.add(ReadingLegendItem(
        category: 'contextual',
        label: 'Lettre S (/s/)',
        soundIpa: '/s/',
        color: colorSUnvoiced(isDark),
        description: 'S se prononce /s/ (siffle comme le serpent)',
        example: 'soleil, sac, danse',
        exampleAudioWord: 'soleil',
      ));
      list.add(ReadingLegendItem(
        category: 'contextual',
        label: 'S entre voyelles',
        soundIpa: '/z/',
        color: colorSVoiced(isDark),
        description: 'S seul entre 2 voyelles se prononce /z/',
        example: 'maison, rose, oiseau',
        exampleAudioWord: 'maison',
      ));
      list.add(ReadingLegendItem(
        category: 'contextual',
        label: 'Lettre Z (/z/)',
        soundIpa: '/z/',
        color: colorSoundZ(isDark),
        description: 'Z se prononce /z/ (bourdonne comme l\'abeille)',
        example: 'zèbre, zéro, gaz, zoo',
        exampleAudioWord: 'zèbre',
      ));
    }

    return list;
  }
}
