import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/reading_palette.dart';
import '../../core/tts/tts_service.dart';
import '../decoding/decoding_screen.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'services/french_phoneme_service.dart';
import 'services/french_silent_letter_service.dart';
import 'services/french_syllable_service.dart';

// ---------------------------------------------------------------------------
// ReadingSupportScreen — Module d'aide visuelle & ergonomique à la lecture
// ---------------------------------------------------------------------------

enum SyllableVisualMode {
  translucentBoxes,
  underlines,
}

class ReadingSupportScreen extends ConsumerStatefulWidget {
  const ReadingSupportScreen({super.key});

  @override
  ConsumerState<ReadingSupportScreen> createState() =>
      _ReadingSupportScreenState();
}

class _ReadingSupportScreenState extends ConsumerState<ReadingSupportScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _inputScrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _readingTextScrollController = ScrollController();
  final ScrollController _settingsScrollController = ScrollController();

  /// false = Mode Saisie (input), true = Mode Lecture (reading)
  bool _isReadingMode = false;

  /// Speech rate selected by the user (0.8x, 1.0x, 1.2x)
  double _speechRate = 1.0;

  // SharedPreferences keys for reading aids persistence
  static const _keyAidSyllables = 'reading_aid_syllables';
  static const _keyAidSilentLetters = 'reading_aid_silent_letters';
  static const _keyAidMirrorLetters = 'reading_aid_mirror_letters';
  static const _keyAidComplexSounds = 'reading_aid_complex_sounds';
  static const _keyAidVowelE = 'reading_aid_vowel_e';
  static const _keyAidContextualLetters = 'reading_aid_contextual_letters';
  static const _keySyllableVisualMode = 'reading_aid_syllable_visual_mode';

  /// Visual reading aids toggles
  /// Only syllables is true by default; all letter and sound coloring aids are false by default
  bool _showSyllables = true;
  bool _showSilentLetters = false;
  bool _showMirrorLetters = false;
  bool _showComplexSounds = false;
  bool _showVowelE = false;
  bool _showContextualLetters = false;

  /// Visual style for distinguishing syllables without text color clash
  SyllableVisualMode _syllableVisualMode = SyllableVisualMode.translucentBoxes;

  /// Règle de lecture translucide (guide de ligne)
  bool _showReadingRuler = false;

  /// Text-to-speech audio state
  bool _isPlayingAudio = false;

  /// List of gesture recognizers created for clickable words, cleanly disposed on each build
  final List<TapGestureRecognizer> _wordRecognizers = [];

  /// Index of the word currently being spoken via word tap (for visual highlight)
  int? _speakingWordIndex;

  late final TtsService _ttsService;

  @override
  void initState() {
    super.initState();
    _ttsService = ref.read(ttsServiceProvider);
    _ttsService.isPlayingNotifier.addListener(_onTtsStateChanged);
    _inputFocusNode.addListener(_onInputFocusChanged);
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAidsPreferences();
  }

  void _loadAidsPreferences() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      _showSyllables = prefs.getBool(_keyAidSyllables) ?? true;
      _showSilentLetters = prefs.getBool(_keyAidSilentLetters) ?? false;
      _showMirrorLetters = prefs.getBool(_keyAidMirrorLetters) ?? false;
      _showComplexSounds = prefs.getBool(_keyAidComplexSounds) ?? false;
      _showVowelE = prefs.getBool(_keyAidVowelE) ?? false;
      _showContextualLetters = prefs.getBool(_keyAidContextualLetters) ?? false;
      final modeStr = prefs.getString(_keySyllableVisualMode);
      if (modeStr == 'underlines') {
        _syllableVisualMode = SyllableVisualMode.underlines;
      } else {
        _syllableVisualMode = SyllableVisualMode.translucentBoxes;
      }
    } catch (e) {
      debugPrint('Error loading aid preferences: $e');
    }
  }

  Future<void> _updateAid(
    String key,
    bool value,
    VoidCallback updateState,
  ) async {
    setState(updateState);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error persisting aid preference $key: $e');
    }
  }

  Future<void> _updateSyllableVisualMode(SyllableVisualMode mode) async {
    setState(() {
      _syllableVisualMode = mode;
    });
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_keySyllableVisualMode, mode.name);
    } catch (e) {
      debugPrint('Error persisting syllable visual mode: $e');
    }
  }

  void _onInputFocusChanged() {
    if (_inputFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        if (_inputScrollController.hasClients) {
          _inputScrollController.animateTo(
            55.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _onTtsStateChanged() {
    if (mounted) {
      setState(() {
        _isPlayingAudio = _ttsService.isPlayingNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    _disposeWordRecognizers();
    _ttsService.isPlayingNotifier.removeListener(_onTtsStateChanged);
    if (_isPlayingAudio) {
      _ttsService.stop();
    }
    _inputFocusNode.removeListener(_onInputFocusChanged);
    _inputFocusNode.dispose();
    _inputScrollController.dispose();
    _readingTextScrollController.dispose();
    _settingsScrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _disposeWordRecognizers() {
    for (final recognizer in _wordRecognizers) {
      recognizer.dispose();
    }
    _wordRecognizers.clear();
  }

  Future<void> _speakWord(String word, int wordIndex) async {
    final clean =
        word.replaceAll(RegExp(r"[^\p{L}\p{M}\-']", unicode: true), '').trim();
    if (clean.isEmpty) return;

    if (mounted) {
      setState(() {
        _speakingWordIndex = wordIndex;
      });
    }

    try {
      await ref.read(ttsServiceProvider).speakWord(clean);
    } catch (e) {
      debugPrint('Error speaking word: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && _speakingWordIndex == wordIndex) {
          setState(() {
            _speakingWordIndex = null;
          });
        }
      });
    }
  }

  Future<void> _toggleAudioReading() async {
    final tts = ref.read(ttsServiceProvider);
    if (_isPlayingAudio) {
      setState(() => _isPlayingAudio = false);
      await tts.stop();
    } else {
      final text = _textController.text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colle ou écris d’abord un texte à écouter.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      setState(() {
        _isPlayingAudio = true;
        _speakingWordIndex = null;
      });
      await tts.speakText(text);
    }
  }

  void _startReading() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colle ou écris d’abord un texte à lire.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isReadingMode = true);
  }

  void _applySampleText(String sample) {
    _textController.text = sample;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
    setState(() {});
  }

  // 10 échantillons variés pour chaque catégorie (30 textes au total)
  static const List<String> _sampleStories = [
    'Le petit chat blanc dort tranquillement au soleil sur le grand balcon de la maison. Soudain, un bel oiseau chanteur se pose sur la branche du cerisier.',
    'Léo prépare son sac d’école avec sa maman. Il range soigneusement ses crayons de couleur, sa règle bleue et son beau cahier de poésie.',
    'Dans le grenier de grand-père, Nina a découvert un vieux livre doré plein d’images magiques. Les pages sentent bon le papier ancien et les secrets d’autrefois.',
    'Ce matin, la neige tombe doucement sur le village endormi. Thomas enfile ses bottes rouges et son écharpe en laine pour faire un grand bonhomme souriant.',
    'La petite tortue Nina avance pas à pas le long du chemin sablonneux. Elle adore grignoter les petites feuilles tendres de salade verte dans le potager.',
    'À la bibliothèque du quartier, Sophie écoute attentivement une belle histoire de dragons gentils et de châteaux perchés sur les collines fleuries.',
    'Au fond du jardin, un petit hérisson timide sort de sa cachette de feuilles d’or. Il cherche des graines sucrées sous la lune ronde et brillante.',
    'Lucas et son chien Filou courent joyeusement sur la plage dorée. Les vagues légères mouillent leurs pattes et le vent fait voler leurs casquettes.',
    'Dans la forêt enchantée, les écureuils roux sautent d’arbre en arbre. Ils font de jolies provisions de glands pour passer un hiver bien au chaud.',
    'Le soir venu, papa ouvre un livre d’aventures maritimes. Les yeux de Maya pétillent en imaginant des îles mystérieuses et des bateaux à voiles blanches.',
  ];

  static const List<String> _sampleExercises = [
    'Aujourd’hui, les enfants découvrent les animaux de la forêt. Le renard roux observe les lapins qui jouent dans l’herbe verte.',
    'Complète la phrase avec le mot qui convient : le maître écrit la leçon de grammaire sur le grand tableau noir de la classe.',
    'En classe de sciences, nous apprenons comment la petite graine de tournesol germe dans la terre humide pour devenir une belle plante fleurie.',
    'Lis attentivement ce problème de mathématiques : Julien a six pommes rouges dans son panier et sa sœur lui en donne quatre de plus.',
    'Pour la fête de l’école, chaque élève récite une strophe du poème sur les quatre saisons. Tout le monde applaudit avec enthousiasme.',
    'Recopie ces trois mots sans oublier les accents : un élève attentif, une forêt profonde et un château mystérieux.',
    'Pendant la récréation, Léa et ses camarades sautent à la corde dans la cour en comptant jusqu’à vingt sans jamais s’arrêter.',
    'Trouve tous les verbes d’action dans ce court paragraphe : les oiseaux chantent, le ruisseau coule et les enfants rient aux éclats.',
    'En cours d’arts plastiques, nous mélangeons la peinture bleue et la peinture jaune pour fabriquer différentes nuances de vert printanier.',
    'Chaque matin avant d’ouvrir son cahier du jour, Camille trace la date en lettres soignées avec son stylo plume bleu marine.',
  ];

  static const List<String> _sampleShortPhrases = [
    'Le soleil brille et le ciel est bleu.',
    'Le gentil chien brun remue la queue avec joie.',
    'Maman prépare une délicieuse tarte aux pommes dorées.',
    'La cloche de l’école sonne la fin de la récréation.',
    'Un joli papillon jaune volette près des roses fraîches.',
    'Mon ami Martin lit son livre préféré assis sous l’arbre.',
    'La lune argentée éclaire la chambre silencieuse cette nuit.',
    'Nous marchons d’un pas joyeux vers le grand parc fleuri.',
    'Le vent d’automne fait danser les feuilles multicolores.',
    'J’adore écouter le doux bruit de la pluie sur les vitres.',
  ];

  int _lastStoryIndex = -1;
  int _lastExerciseIndex = -1;
  int _lastPhraseIndex = -1;

  void _pickCategorySample(int categoryType) {
    final List<String> list;
    int lastIndex;

    if (categoryType == 0) {
      list = _sampleStories;
      lastIndex = _lastStoryIndex;
    } else if (categoryType == 1) {
      list = _sampleExercises;
      lastIndex = _lastExerciseIndex;
    } else {
      list = _sampleShortPhrases;
      lastIndex = _lastPhraseIndex;
    }

    int nextIndex;
    if (lastIndex == -1) {
      nextIndex = 0;
    } else {
      final random = Random();
      do {
        nextIndex = random.nextInt(list.length);
      } while (nextIndex == lastIndex && list.length > 1);
    }

    if (categoryType == 0) {
      _lastStoryIndex = nextIndex;
    } else if (categoryType == 1) {
      _lastExerciseIndex = nextIndex;
    } else {
      _lastPhraseIndex = nextIndex;
    }

    _applySampleText(list[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final palette = settings.contrastPreset.palette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: _isReadingMode ? 'Modifier le texte' : 'Retour',
          onPressed: () {
            if (_isReadingMode) {
              if (_isPlayingAudio) {
                _ttsService.stop();
                setState(() => _isPlayingAudio = false);
              }
              setState(() => _isReadingMode = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: _isReadingMode
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Lecture adaptée',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Confort actif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : const Text('M’aider à lire'),
        titleSpacing: 0,
        actions: [
          if (!_isReadingMode)
            IconButton(
              icon: Icon(
                _isPlayingAudio
                    ? Icons.stop_circle_rounded
                    : Icons.volume_up_rounded,
                color: _isPlayingAudio ? AppColors.errorRed : palette.primary,
                size: 26,
              ),
              tooltip: _isPlayingAudio ? 'Arrêter la lecture' : 'Écouter le texte',
              onPressed: _toggleAudioReading,
            ),
          IconButton(
            icon: const Icon(Icons.spellcheck_rounded),
            tooltip: 'Aide au décodage',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DecodingScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Réglages de lecture',
            onPressed: () {
              if (_isReadingMode && _readingTextScrollController.hasClients) {
                _readingTextScrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
              ReadingSettingsSheet.show(
                context,
                halfScreen: _isReadingMode,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _isReadingMode
              ? _buildReadingMode(context, settings, palette)
              : _buildInputMode(context, settings, palette),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // MODE 1 : Saisie & Choix du texte (Stitch Screen 1)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildInputMode(
    BuildContext context,
    ReadingSettings settings,
    ReadingPalette palette,
  ) {
    final theme = Theme.of(context);
    final charCount = _textController.text.length;
    final effectiveFontSize = settings.fontSize.clamp(16.0, 20.0);
    final effectiveLineHeight = effectiveFontSize * 1.6;

    return SingleChildScrollView(
      key: const ValueKey('input_mode'),
      controller: _inputScrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting & Supportive Header (compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text('📖', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour ! 👋 Que souhaites-tu lire ?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Colle ton devoir, écris ou choisis un exemple ci-dessous.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Main Ergonomic Input Card with Ruled Notebook Lines
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: charCount > 0 ? palette.primary : palette.border,
                width: charCount > 0 ? 1.5 : 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomPaint(
                  painter: _LinedPaperPainter(
                    lineHeight: effectiveLineHeight,
                    lineColor: palette.border.withValues(alpha: 0.85),
                    topOffset: 6.0,
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _inputFocusNode,
                    scrollPadding: const EdgeInsets.only(bottom: 120.0, top: 20.0),
                    minLines: 4,
                    maxLines: 8,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10000),
                    ],
                    style: TextStyle(
                      fontFamily: settings.fontFamily,
                      fontSize: effectiveFontSize,
                      height: 1.6,
                      color: palette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Coller ou écris ton texte ici...',
                      hintStyle: TextStyle(
                        fontFamily: settings.fontFamily,
                        color: palette.textSecondary.withValues(alpha: 0.65),
                        fontSize: effectiveFontSize,
                        height: 1.6,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: palette.border),
                const SizedBox(height: 6),

                // Quick Action Bar inside the card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Coller (Paste) Button
                        OutlinedButton.icon(
                          onPressed: () async {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            final text = data?.text?.trim() ?? '';
                            if (text.isNotEmpty) {
                              final clamped = text.length > 10000
                                  ? text.substring(0, 10000)
                                  : text;
                              _applySampleText(clamped);
                            }
                          },
                          icon: const Icon(Icons.content_paste_rounded, size: 16),
                          label: const Text('Coller'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.primary,
                            side: BorderSide(color: palette.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        if (charCount > 0) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _toggleAudioReading,
                            icon: Icon(
                              _isPlayingAudio
                                  ? Icons.stop_rounded
                                  : Icons.volume_up_rounded,
                              size: 16,
                              color: _isPlayingAudio
                                  ? AppColors.errorRed
                                  : palette.primary,
                            ),
                            label: Text(
                              _isPlayingAudio ? 'Arrêter' : 'Écouter',
                              style: TextStyle(
                                color: _isPlayingAudio
                                    ? AppColors.errorRed
                                    : palette.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _isPlayingAudio
                                    ? AppColors.errorRed
                                    : palette.border,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Clear button (when text is present)
                    if (charCount > 0)
                      TextButton.icon(
                        onPressed: () => _textController.clear(),
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 16,
                          color: palette.textSecondary,
                        ),
                        label: Text(
                          'Effacer',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick Sample Chips Section
          Text(
            'Ou choisis un exemple pour tester :',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildSampleChip(
                palette: palette,
                icon: '📖',
                title: 'Petite histoire',
                onTap: () => _pickCategorySample(0),
              ),
              _buildSampleChip(
                palette: palette,
                icon: '✏️',
                title: 'Exercice d’école',
                onTap: () => _pickCategorySample(1),
              ),
              _buildSampleChip(
                palette: palette,
                icon: '💬',
                title: 'Phrase courte',
                onTap: () => _pickCategorySample(2),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Primary Launch Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _startReading,
              icon: const Icon(Icons.auto_stories_rounded, size: 20),
              label: const Text('Lire avec les aides'),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Tu pourras ajuster les couleurs des syllabes, les sons et la voix de lecture.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: palette.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleChip({
    required ReadingPalette palette,
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // MODE 2 : Lecture adaptée & sereine (Stitch Screen 2)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildReadingMode(
    BuildContext context,
    ReadingSettings settings,
    ReadingPalette palette,
  ) {
    return Stack(
      key: const ValueKey('reading_mode'),
      children: [
        // 1. Unified, fully scrollable reading view
        Scrollbar(
          controller: _readingTextScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _readingTextScrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Reading Canvas Card
                _buildReadingCanvasCard(context, settings, palette),
                const SizedBox(height: 14),

                // 2. Tactile Audio Action Bar (52px prominent button + speed pills)
                _buildAudioPlayerCard(context, palette),
                const SizedBox(height: 14),

                // 3. Quick jump pill row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        _readingTextScrollController.animateTo(
                          320.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: palette.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              size: 16,
                              color: palette.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Aides & Couleurs',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: palette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_isPlayingAudio) {
                          _ttsService.stop();
                          setState(() => _isPlayingAudio = false);
                        }
                        setState(() => _isReadingMode = false);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text(
                        'Modifier le texte',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: palette.textSecondary,
                        side: BorderSide(color: palette.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Visual Aids & Colors Legend Section
                _buildVisualAidesSection(context, settings, palette),
                const SizedBox(height: 14),

                // 5. Warm supportive encouragement banner
                _buildEncouragementCard(palette),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // 2. Fixed Bottom Dock (Ajuster la police & taille, Règle de lecture, Contraste)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomDock(context, settings, palette),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Reading Canvas Card (Canevas de lecture épuré)
  // ---------------------------------------------------------------------------

  Widget _buildReadingCanvasCard(
    BuildContext context,
    ReadingSettings settings,
    ReadingPalette palette,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top status & quick switch bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 17,
                  color: palette.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Texte adapté',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Quick Syllables Toggle Pill
                InkWell(
                  onTap: () => _updateAid(
                    _keyAidSyllables,
                    !_showSyllables,
                    () => _showSyllables = !_showSyllables,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _showSyllables
                          ? palette.primary.withValues(alpha: 0.12)
                          : palette.border.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _showSyllables
                            ? palette.primary
                            : palette.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _showSyllables
                                ? palette.primary
                                : palette.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Syllabes ${_showSyllables ? "ON" : "OFF"}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _showSyllables
                                ? palette.primary
                                : palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.border),

          // Reading ruler active reminder
          if (_showReadingRuler)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.highlightYellow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.view_headline_rounded,
                    size: 16,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Guide de lecture activé : touche un mot pour le lire.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main Adapted Text Spans
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Text.rich(
              TextSpan(
                children: _buildAdaptedSpans(
                  text: _textController.text.trim(),
                  settings: settings,
                  palette: palette,
                ),
              ),
            ),
          ),

          // Bottom tip container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: palette.background.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Touche n’importe quel mot pour entendre sa voix et voir son modèle décomposé.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Audio Action Card (Bandeau tactile prioritaire 52px+)
  // ---------------------------------------------------------------------------

  Widget _buildAudioPlayerCard(BuildContext context, ReadingPalette palette) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 52px Tactile Audio Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _toggleAudioReading,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPlayingAudio
                    ? AppColors.errorRed
                    : palette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _isPlayingAudio
                          ? Icons.stop_rounded
                          : Icons.volume_up_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isPlayingAudio ? 'Arrêter' : 'Écouter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isPlayingAudio ? 'la lecture' : 'tout le texte',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isPlayingAudio
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Speech Speed Controls
          Row(
            children: [
              Icon(
                Icons.speed_rounded,
                size: 15,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Vitesse de voix :',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildSpeedPill(palette, label: '0.8x ralenti', rate: 0.8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSpeedPill(palette, label: '1.0x normal', rate: 1.0),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSpeedPill(palette, label: '1.2x rapide', rate: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedPill(
    ReadingPalette palette, {
    required String label,
    required double rate,
  }) {
    final isSelected = (_speechRate - rate).abs() < 0.05;
    return InkWell(
      onTap: () => setState(() => _speechRate = rate),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 30,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : palette.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? palette.primary : palette.border,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Visual Aids & Colors Legend Section (Repères visuels & couleurs)
  // ---------------------------------------------------------------------------

  Widget _buildVisualAidesSection(
    BuildContext context,
    ReadingSettings settings,
    ReadingPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aides visuelles & Légende 🎨',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Personnalise les repères pour soulager ton regard',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Repères visuels appliqués ! ✨'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                'Appliquer les repères ✨',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: palette.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Bento Stack of 6 Breathable, Clear Cards
        // Card 1: Syllabes (Blocs doux ou soulignement)
        _buildBreathableAidCard(
          palette: palette,
          title: 'Découpage des syllabes',
          explanation:
              'Distingue chaque syllabe par blocs doux ou soulignement, sans altérer la couleur des lettres b, d, p.',
          isActive: _showSyllables,
          onToggle: (val) => _updateAid(_keyAidSyllables, val, () => _showSyllables = val),
          legendBadge: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _syllableVisualMode == SyllableVisualMode.translucentBoxes
                            ? palette.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'cho',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                          decoration: _syllableVisualMode == SyllableVisualMode.underlines
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: palette.primary,
                          decorationThickness: 2.0,
                        ),
                      ),
                    ),
                    Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                    Text(
                      'co',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _syllableVisualMode == SyllableVisualMode.translucentBoxes
                            ? palette.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'lat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                          decoration: _syllableVisualMode == SyllableVisualMode.underlines
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: palette.primary,
                          decorationThickness: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  final nextMode = _syllableVisualMode == SyllableVisualMode.translucentBoxes
                      ? SyllableVisualMode.underlines
                      : SyllableVisualMode.translucentBoxes;
                  _updateSyllableVisualMode(nextMode);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _syllableVisualMode == SyllableVisualMode.translucentBoxes
                            ? Icons.crop_square_rounded
                            : Icons.horizontal_rule_rounded,
                        size: 13,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _syllableVisualMode == SyllableVisualMode.translucentBoxes
                            ? 'Blocs'
                            : 'Souligné',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: palette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Card 2: Lettres muettes
        _buildBreathableAidCard(
          palette: palette,
          title: 'Lettres muettes',
          explanation:
              'Lettres grisées et soulignées qui ne s\'entendent pas.',
          isActive: _showSilentLetters,
          onToggle: (val) => _updateAid(_keyAidSilentLetters, val, () => _showSilentLetters = val),
          legendBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'pe-ti',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  't',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    color: palette.silentColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '(le t dort)',
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Card 3: Lettres miroirs (b / d / p)
        _buildBreathableAidCard(
          palette: palette,
          title: 'Lettres miroirs (b / d / p / q)',
          explanation:
              'Repères visuels colorés pour ne plus confondre b, d, p, q.',
          isActive: _showMirrorLetters,
          onToggle: (val) => _updateAid(_keyAidMirrorLetters, val, () => _showMirrorLetters = val),
          legendBadge: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniLetterBadge('b', palette.mirrorColorB, 'bateau'),
              const SizedBox(width: 6),
              _buildMiniLetterBadge('d', palette.mirrorColorD, 'dessin'),
              const SizedBox(width: 6),
              _buildMiniLetterBadge('p', palette.mirrorColorP, 'pomme'),
              const SizedBox(width: 6),
              _buildMiniLetterBadge('q', palette.mirrorColorQ, 'queue'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Card 4: Sons complexes
        _buildBreathableAidCard(
          palette: palette,
          title: 'Sons complexes',
          explanation:
              'Plusieurs lettres qui s\'unissent pour chanter un seul son.',
          isActive: _showComplexSounds,
          onToggle: (val) => _updateAid(_keyAidComplexSounds, val, () => _showComplexSounds = val),
          legendBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ch',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successGreen,
                    decoration: TextDecoration.underline,
                  ),
                ),
                Text(
                  'â-t',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  'eau',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successGreen,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '✨ 2 sons',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Card 5: Voyelle E (é, è, ê)
        _buildBreathableAidCard(
          palette: palette,
          title: 'Voyelle E (é, è, ê)',
          explanation:
              'Repères d\'accents pour bien distinguer les sonorités.',
          isActive: _showVowelE,
          onToggle: (val) => _updateAid(_keyAidVowelE, val, () => _showVowelE = val),
          legendBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'élè-ve',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '·',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'forêt',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Card 6: Sons contextuels (C, G, S, Z)
        _buildBreathableAidCard(
          palette: palette,
          title: 'Sons contextuels (C, G, S, Z)',
          explanation: 'Selon les voyelles qui suivent la lettre.',
          isActive: _showContextualLetters,
          onToggle: (val) => _updateAid(_keyAidContextualLetters, val, () => _showContextualLetters = val),
          rulesSummary: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: palette.border.withValues(alpha: 0.7),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContextualRuleItem(
                  palette: palette,
                  rule: 'C se prononce K',
                  detail: 'devant : a, o, u',
                ),
                const SizedBox(height: 4),
                _buildContextualRuleItem(
                  palette: palette,
                  rule: 'C se prononce S',
                  detail: 'devant : e, i',
                ),
                const SizedBox(height: 4),
                _buildContextualRuleItem(
                  palette: palette,
                  rule: 'G se prononce g',
                  detail: 'devant : a, o, u',
                ),
                const SizedBox(height: 4),
                _buildContextualRuleItem(
                  palette: palette,
                  rule: 'G se prononce J',
                  detail: 'devant : e, i',
                ),
                const SizedBox(height: 4),
                _buildContextualRuleItem(
                  palette: palette,
                  rule: 'S se prononce Z',
                  detail: 'entre deux voyelles',
                ),
              ],
            ),
          ),
          legendBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'cerise',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '·',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'girafe',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContextualRuleItem({
    required ReadingPalette palette,
    required String rule,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(right: 7),
          decoration: BoxDecoration(
            color: palette.primary,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          rule,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            detail,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBreathableAidCard({
    required ReadingPalette palette,
    required String title,
    required String explanation,
    required bool isActive,
    required ValueChanged<bool> onToggle,
    required Widget legendBadge,
    Widget? rulesSummary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? palette.primary.withValues(alpha: 0.04)
            : palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? palette.primary.withValues(alpha: 0.4)
              : palette.border,
          width: isActive ? 1.3 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? palette.textPrimary
                        : palette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 26,
                child: Switch.adaptive(
                  value: isActive,
                  onChanged: onToggle,
                  activeTrackColor: palette.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.3,
              color: palette.textSecondary,
            ),
          ),
          if (rulesSummary != null) ...[
            const SizedBox(height: 8),
            rulesSummary,
          ],
          const SizedBox(height: 8),
          legendBadge,
        ],
      ),
    );
  }

  Widget _buildMiniLetterBadge(String letter, Color color, String example) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            letter,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            example.substring(1),
            style: TextStyle(
              fontSize: 11.5,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Encouragement Banner
  // ---------------------------------------------------------------------------

  Widget _buildEncouragementCard(ReadingPalette palette) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sentiment_satisfied_alt_rounded,
            size: 26,
            color: AppColors.successGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prends tout ton temps',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ici, aucun chronomètre. Chaque mot lu est une belle victoire !',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Fixed Bottom Dock (Typography & Ruler Shortcuts)
  // ---------------------------------------------------------------------------

  Widget _buildBottomDock(
    BuildContext context,
    ReadingSettings settings,
    ReadingPalette palette,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: palette.border)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Main Typography & Size Button
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_readingTextScrollController.hasClients) {
                    _readingTextScrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                  ReadingSettingsSheet.show(context, halfScreen: true);
                },
                icon: Icon(
                  Icons.text_fields_rounded,
                  size: 20,
                  color: palette.primary,
                ),
                label: Text(
                  'Ajuster la police & taille',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.surface,
                  foregroundColor: palette.primary,
                  elevation: 0,
                  side: BorderSide(color: palette.border, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reading ruler quick toggle
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: () =>
                  setState(() => _showReadingRuler = !_showReadingRuler),
              icon: Icon(
                _showReadingRuler
                    ? Icons.view_headline_rounded
                    : Icons.horizontal_rule_rounded,
                color: _showReadingRuler
                    ? palette.primary
                    : palette.textSecondary,
              ),
              tooltip: 'Guide de lecture',
              style: IconButton.styleFrom(
                backgroundColor: _showReadingRuler
                    ? palette.primary.withValues(alpha: 0.12)
                    : palette.surface,
                side: BorderSide(
                  color: _showReadingRuler ? palette.primary : palette.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Contrast theme cycle button
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: () {
                final presets = ContrastPreset.values;
                final nextIndex =
                    (presets.indexOf(settings.contrastPreset) + 1) %
                        presets.length;
                ref
                    .read(readingSettingsProvider.notifier)
                    .setContrastPreset(presets[nextIndex]);
              },
              icon: Icon(
                Icons.palette_outlined,
                color: palette.primary,
              ),
              tooltip: 'Changer le contraste',
              style: IconButton.styleFrom(
                backgroundColor: palette.surface,
                side: BorderSide(color: palette.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // PHONETIC & SYLLABIC SPANS GENERATION
  // ═════════════════════════════════════════════════════════════════════════════

  List<InlineSpan> _buildAdaptedSpans({
    required String text,
    required ReadingSettings settings,
    required ReadingPalette palette,
  }) {
    _disposeWordRecognizers();

    final defaultTextColor = palette.textPrimary;
    final silentColor = palette.silentColor;
    final mirrorColorB = palette.mirrorColorB;
    final mirrorColorD = palette.mirrorColorD;
    final mirrorColorP = palette.mirrorColorP;
    final mirrorColorQ = palette.mirrorColorQ;

    final baseStyle = TextStyle(
      fontSize: settings.fontSize,
      fontFamily: settings.fontFamily,
      height: settings.lineHeight,
      letterSpacing: settings.letterSpacing,
      wordSpacing: settings.wordSpacing,
      color: defaultTextColor,
    );

    final spans = <InlineSpan>[];
    final pattern =
        RegExp(r"([a-zA-ZÀ-ÿ]+(?:['’][a-zA-ZÀ-ÿ]+)?|[^a-zA-ZÀ-ÿ]+)");
    final matches = pattern.allMatches(text);

    int wordIndex = 0;
    for (final match in matches) {
      final token = match.group(0) ?? '';
      if (token.isEmpty) continue;

      if (RegExp(r"[a-zA-ZÀ-ÿ]").hasMatch(token)) {
        final currentWordIndex = wordIndex++;
        final apoIdx = token.indexOf(RegExp(r"['’]"));
        if (apoIdx != -1) {
          final prefix = token.substring(0, apoIdx + 1);
          final rest = token.substring(apoIdx + 1);
          spans.add(TextSpan(text: prefix, style: baseStyle));
          _appendWordSpans(
            spans: spans,
            word: rest,
            wordIndex: currentWordIndex,
            baseStyle: baseStyle,
            defaultTextColor: defaultTextColor,
            silentColor: silentColor,
            mirrorColorB: mirrorColorB,
            mirrorColorD: mirrorColorD,
            mirrorColorP: mirrorColorP,
            mirrorColorQ: mirrorColorQ,
            palette: palette,
          );
        } else {
          _appendWordSpans(
            spans: spans,
            word: token,
            wordIndex: currentWordIndex,
            baseStyle: baseStyle,
            defaultTextColor: defaultTextColor,
            silentColor: silentColor,
            mirrorColorB: mirrorColorB,
            mirrorColorD: mirrorColorD,
            mirrorColorP: mirrorColorP,
            mirrorColorQ: mirrorColorQ,
            palette: palette,
          );
        }
      } else {
        spans.add(TextSpan(text: token, style: baseStyle));
      }
    }

    return spans;
  }

  void _appendWordSpans({
    required List<InlineSpan> spans,
    required String word,
    required int wordIndex,
    required TextStyle baseStyle,
    required Color defaultTextColor,
    required Color silentColor,
    required Color mirrorColorB,
    required Color mirrorColorD,
    required Color mirrorColorP,
    required Color mirrorColorQ,
    required ReadingPalette palette,
  }) {
    final wordSpans = <InlineSpan>[];
    final isSpeakingThisWord = _speakingWordIndex == wordIndex;
    final wordRecognizer = TapGestureRecognizer()
      ..onTap = () => _speakWord(word, wordIndex);
    _wordRecognizers.add(wordRecognizer);

    final silentIndices = _showSilentLetters
        ? FrenchSilentLetterService.getSilentIndices(word)
        : const <int>{};

    final complexPhonemes = _showComplexSounds
        ? FrenchPhonemeService.getComplexPhonemes(word, isDark: palette.isDark)
        : const <int, SoundHighlight>{};

    final vowelEHighlights = _showVowelE
        ? FrenchPhonemeService.getVowelEHighlights(word, isDark: palette.isDark)
        : const <int, SoundHighlight>{};

    final contextualLetters = _showContextualLetters
        ? FrenchPhonemeService.getContextualLetters(word, isDark: palette.isDark)
        : const <int, SoundHighlight>{};

    final hasDetailedAids = _showSilentLetters ||
        _showMirrorLetters ||
        _showComplexSounds ||
        _showVowelE ||
        _showContextualLetters;

    if (_showSyllables) {
      final syllables = FrenchSyllableService.segmentWord(word);
      int charOffset = 0;

      for (int i = 0; i < syllables.length; i++) {
        final syl = syllables[i];
        final isEvenSyl = (i % 2 == 0);

        // Visual distinction without text color clash:
        // - Translucent boxes: subtle alternating background highlight on even syllables
        // - Underlines: clean underline on even syllables
        // The text color remains defaultTextColor so b, d, p and silent letters never clash!
        final sylBgColor = (syllables.length > 1 &&
                isEvenSyl &&
                _syllableVisualMode == SyllableVisualMode.translucentBoxes)
            ? (palette.isDark
                ? Colors.white.withValues(alpha: 0.16)
                : palette.primary.withValues(alpha: 0.12))
            : null;

        final sylDecoration = (syllables.length > 1 &&
                isEvenSyl &&
                _syllableVisualMode == SyllableVisualMode.underlines)
            ? TextDecoration.underline
            : TextDecoration.none;

        final sylDecoColor = palette.primary.withValues(alpha: 0.7);

        if (hasDetailedAids) {
          for (int c = 0; c < syl.length; c++) {
            final globalIndex = charOffset + c;
            wordSpans.add(_buildCharSpan(
              char: syl[c],
              globalIndex: globalIndex,
              silentIndices: silentIndices,
              complexPhonemes: complexPhonemes,
              vowelEHighlights: vowelEHighlights,
              contextualLetters: contextualLetters,
              baseStyle: baseStyle,
              defaultColor: defaultTextColor,
              silentColor: silentColor,
              mirrorColorB: mirrorColorB,
              mirrorColorD: mirrorColorD,
              mirrorColorP: mirrorColorP,
              mirrorColorQ: mirrorColorQ,
              sylBackgroundColor: sylBgColor,
              sylDecoration: sylDecoration,
              sylDecorationColor: sylDecoColor,
              normalWeight: (syllables.length > 1 && isEvenSyl)
                  ? FontWeight.w700
                  : FontWeight.w500,
              recognizer: wordRecognizer,
              isSpeaking: isSpeakingThisWord,
            ));
          }
        } else {
          final bg = isSpeakingThisWord
              ? AppColors.highlightYellow.withValues(alpha: 0.65)
              : sylBgColor;

          wordSpans.add(TextSpan(
            text: syl,
            recognizer: wordRecognizer,
            style: baseStyle.copyWith(
              color: defaultTextColor,
              backgroundColor: bg,
              decoration:
                  isSpeakingThisWord ? TextDecoration.none : sylDecoration,
              decorationColor: sylDecoColor,
              decorationThickness: 2.0,
              fontWeight: (syllables.length <= 1)
                  ? FontWeight.w500
                  : (isEvenSyl ? FontWeight.w700 : FontWeight.w500),
            ),
          ));
        }

        charOffset += syl.length;
      }
    } else if (hasDetailedAids) {
      for (int i = 0; i < word.length; i++) {
        wordSpans.add(_buildCharSpan(
          char: word[i],
          globalIndex: i,
          silentIndices: silentIndices,
          complexPhonemes: complexPhonemes,
          vowelEHighlights: vowelEHighlights,
          contextualLetters: contextualLetters,
          baseStyle: baseStyle,
          defaultColor: defaultTextColor,
          silentColor: silentColor,
          mirrorColorB: mirrorColorB,
          mirrorColorD: mirrorColorD,
          mirrorColorP: mirrorColorP,
          mirrorColorQ: mirrorColorQ,
          sylBackgroundColor: null,
          sylDecoration: TextDecoration.none,
          normalWeight: FontWeight.w500,
          recognizer: wordRecognizer,
          isSpeaking: isSpeakingThisWord,
        ));
      }
    } else {
      wordSpans.add(TextSpan(
        text: word,
        recognizer: wordRecognizer,
        style: baseStyle.copyWith(
          color: defaultTextColor,
          backgroundColor: isSpeakingThisWord
              ? AppColors.highlightYellow.withValues(alpha: 0.65)
              : null,
        ),
      ));
    }

    spans.add(
      TextSpan(
        children: wordSpans,
      ),
    );
  }

  TextSpan _buildCharSpan({
    required String char,
    required int globalIndex,
    required Set<int> silentIndices,
    required Map<int, SoundHighlight> complexPhonemes,
    required Map<int, SoundHighlight> vowelEHighlights,
    required Map<int, SoundHighlight> contextualLetters,
    required TextStyle baseStyle,
    required Color defaultColor,
    required Color silentColor,
    required Color mirrorColorB,
    required Color mirrorColorD,
    required Color mirrorColorP,
    required Color mirrorColorQ,
    Color? sylBackgroundColor,
    TextDecoration sylDecoration = TextDecoration.none,
    Color? sylDecorationColor,
    FontWeight? normalWeight,
    GestureRecognizer? recognizer,
    bool isSpeaking = false,
  }) {
    final speechBg = isSpeaking
        ? AppColors.highlightYellow.withValues(alpha: 0.65)
        : null;

    final charBg = speechBg ?? sylBackgroundColor;
    final effectiveDecoration =
        isSpeaking ? TextDecoration.none : sylDecoration;

    if (_showSilentLetters && silentIndices.contains(globalIndex)) {
      return TextSpan(
        text: char,
        recognizer: recognizer,
        style: baseStyle.copyWith(
          color: silentColor,
          backgroundColor: charBg,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          decoration: effectiveDecoration != TextDecoration.none
              ? effectiveDecoration
              : TextDecoration.underline,
          decorationColor: effectiveDecoration != TextDecoration.none
              ? (sylDecorationColor ?? silentColor)
              : silentColor,
          decorationThickness: 2.0,
        ),
      );
    }

    if (_showMirrorLetters) {
      if (char == 'b' || char == 'B') {
        return TextSpan(
          text: char,
          recognizer: recognizer,
          style: baseStyle.copyWith(
            color: mirrorColorB,
            backgroundColor: charBg,
            fontWeight: FontWeight.w800,
            decoration: effectiveDecoration != TextDecoration.none
                ? effectiveDecoration
                : null,
            decorationColor: sylDecorationColor,
            decorationThickness: 2.0,
          ),
        );
      } else if (char == 'd' || char == 'D') {
        return TextSpan(
          text: char,
          recognizer: recognizer,
          style: baseStyle.copyWith(
            color: mirrorColorD,
            backgroundColor: charBg,
            fontWeight: FontWeight.w800,
            decoration: effectiveDecoration != TextDecoration.none
                ? effectiveDecoration
                : null,
            decorationColor: sylDecorationColor,
            decorationThickness: 2.0,
          ),
        );
      } else if (char == 'p' || char == 'P') {
        return TextSpan(
          text: char,
          recognizer: recognizer,
          style: baseStyle.copyWith(
            color: mirrorColorP,
            backgroundColor: charBg,
            fontWeight: FontWeight.w800,
            decoration: effectiveDecoration != TextDecoration.none
                ? effectiveDecoration
                : null,
            decorationColor: sylDecorationColor,
            decorationThickness: 2.0,
          ),
        );
      } else if (char == 'q' || char == 'Q') {
        return TextSpan(
          text: char,
          recognizer: recognizer,
          style: baseStyle.copyWith(
            color: mirrorColorQ,
            backgroundColor: charBg,
            fontWeight: FontWeight.w800,
            decoration: effectiveDecoration != TextDecoration.none
                ? effectiveDecoration
                : null,
            decorationColor: sylDecorationColor,
            decorationThickness: 2.0,
          ),
        );
      }
    }

    if (_showContextualLetters &&
        contextualLetters.containsKey(globalIndex)) {
      final highlight = contextualLetters[globalIndex]!;
      return TextSpan(
        text: char,
        recognizer: recognizer,
        style: baseStyle.copyWith(
          color: highlight.color,
          backgroundColor: charBg,
          fontWeight: FontWeight.w800,
          decoration: effectiveDecoration != TextDecoration.none
              ? effectiveDecoration
              : null,
          decorationColor: sylDecorationColor,
          decorationThickness: 2.0,
        ),
      );
    }

    if (_showVowelE && vowelEHighlights.containsKey(globalIndex)) {
      final highlight = vowelEHighlights[globalIndex]!;
      return TextSpan(
        text: char,
        recognizer: recognizer,
        style: baseStyle.copyWith(
          color: highlight.color,
          backgroundColor: charBg,
          fontWeight: FontWeight.w800,
          decoration: effectiveDecoration != TextDecoration.none
              ? effectiveDecoration
              : null,
          decorationColor: sylDecorationColor,
          decorationThickness: 2.0,
        ),
      );
    }

    if (_showComplexSounds &&
        complexPhonemes.containsKey(globalIndex)) {
      final highlight = complexPhonemes[globalIndex]!;
      return TextSpan(
        text: char,
        recognizer: recognizer,
        style: baseStyle.copyWith(
          color: highlight.color,
          backgroundColor: charBg,
          fontWeight: FontWeight.w800,
          decoration: highlight.isUnderlined
              ? TextDecoration.underline
              : (effectiveDecoration != TextDecoration.none
                  ? effectiveDecoration
                  : TextDecoration.none),
          decorationColor: highlight.isUnderlined
              ? highlight.color
              : sylDecorationColor,
          decorationThickness: 2.0,
        ),
      );
    }

    return TextSpan(
      text: char,
      recognizer: recognizer,
      style: baseStyle.copyWith(
        color: defaultColor,
        backgroundColor: charBg,
        fontWeight: normalWeight ?? FontWeight.w500,
        decoration: effectiveDecoration != TextDecoration.none
            ? effectiveDecoration
            : null,
        decorationColor: sylDecorationColor,
        decorationThickness: 2.0,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lined Paper Painter for authentic handwriting lines (cahier de classe)
// ---------------------------------------------------------------------------

class _LinedPaperPainter extends CustomPainter {
  final double lineHeight;
  final Color lineColor;
  final double topOffset;

  const _LinedPaperPainter({
    required this.lineHeight,
    required this.lineColor,
    this.topOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines across the width of the input area
    double y = topOffset + (lineHeight * 0.84);
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _LinedPaperPainter oldDelegate) {
    return oldDelegate.lineHeight != lineHeight ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.topOffset != topOffset;
  }
}
