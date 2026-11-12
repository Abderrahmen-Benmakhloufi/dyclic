import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learner_profile/learner_profile_notifier.dart';
import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../instructions/services/gemini_service.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'models/writing_feedback_model.dart';
import 'services/writing_cache_service.dart';
import 'services/writing_gemini_service.dart';
import 'writing_feedback_screen.dart';

/// Quick sample student essays containing typical DYS mistakes (10 per cycle: Primaire, Collège, Lycée).
const List<Map<String, String>> _kSampleTexts = [
  // ── PRIMAIRE (10 exemples) ──────────────────────────────────────────────
  {
    'cycle': 'primaire',
    'label': 'Visite à la ferme',
    'subject': 'Décris une visite à la ferme.',
    'text':
        'Hier, je suis aler à la ferme avec mon père. J ai vu un gran chavel blanc qui manger de l herbe. Il y avais aussi un bato sur la rivière.',
  },
  {
    'cycle': 'primaire',
    'label': 'Mon chat',
    'subject': 'Décris ton animal préféré.',
    'text':
        'Mon chat s appelle Minou. Il a des poils doux et une longue qeu. Il aime boire du lai et dormire sur le canapé du salon.',
  },
  {
    'cycle': 'primaire',
    'label': 'La récréation',
    'subject': 'Raconte ce que tu fais pendant la récréation.',
    'text':
        'Quand la cloche sone, je sors vite dans la cour. Mes amis et moi jouons au balon. Parfois, nous faisons la course et nous rigolon beaucoup.',
  },
  {
    'cycle': 'primaire',
    'label': 'Mon cartable',
    'subject': 'Décris ce qu’il y a dans ton cartable.',
    'text':
        'Dans mon cartabel bleu, je range mes cahiers et ma trousse. J ai trois crayions de couleur, une gome blanche et un livre de fransais.',
  },
  {
    'cycle': 'primaire',
    'label': 'L’anniversaire',
    'subject': 'Raconte la fête d’anniversaire de ton ami.',
    'text':
        'Samedi, nous avons fêté l anivairsaire de Sami. Sa maman a préparé un gro gato au chocola avec huit bougies dessus.',
  },
  {
    'cycle': 'primaire',
    'label': 'À la plage',
    'subject': 'Raconte une journée à la plage.',
    'text':
        'En été, je vais à la mer avec ma famile. Je construit un chato de sable avec mon petit frère. L eau est fraiche et bleue.',
  },
  {
    'cycle': 'primaire',
    'label': 'L’arbre du jardin',
    'subject': 'Décris un arbre que tu aimes.',
    'text':
        'Dans notre jardin, il y a un grand pomier. Au printemp, ses branches sont couvertes de jolies fleures blanches. En automne, on cueille de bon fruits.',
  },
  {
    'cycle': 'primaire',
    'label': 'La rentrée',
    'subject': 'Raconte ton premier jour d’école.',
    'text':
        'Ce matin, j étais très conten de retrouver mes camarades. La maîtresse nous a souri et nous a montré notre nouvel classe décorée.',
  },
  {
    'cycle': 'primaire',
    'label': 'Mon plat préféré',
    'subject': 'Décris ton plat préféré.',
    'text':
        'J aime beaucoup le couscous que prépare ma grand-mère. Il y a des légumes tendre, des pois chiches et une bonne sause chaude.',
  },
  {
    'cycle': 'primaire',
    'label': 'Le petit oiseau',
    'subject': 'Imagine l’histoire d’un petit oiseau.',
    'text':
        'Un matin, un petit oiso tombé de son nid pleurait sous l arbre. Lina l a pris doucement dans ses mains et l a déposé près de sa maman.',
  },

  // ── COLLÈGE (10 exemples) ───────────────────────────────────────────────
  {
    'cycle': 'college',
    'label': 'Sortie en forêt',
    'subject': 'Raconte une sortie en forêt.',
    'text':
        'La semain dernière, nous avons visiter une foret magnifique. Les arbres étais très haut et les oiseaux chanter dans les branches. Nous avons pris de baux photos.',
  },
  {
    'cycle': 'college',
    'label': 'Protéger la nature',
    'subject': 'Explique pourquoi il faut protéger la nature.',
    'text':
        'La polution menace nos océans et nos animaux. Chaque citoyen doit jeter ses déchet dans la poubelle et planter des arbres pour gardé l air pur.',
  },
  {
    'cycle': 'college',
    'label': 'Mon sport favori',
    'subject': 'Présente ton sport préféré et ses bienfaits.',
    'text':
        'Je pratique la natation depuis trois an. Ce sport développe les muscles et apprend à bien respiré. Après chaque séance, je me sens calme et plein d énergi.',
  },
  {
    'cycle': 'college',
    'label': 'Souvenir d’enfance',
    'subject': 'Raconte un souvenir marquant de ton enfance.',
    'text':
        'Je me souviens de mon premier vélo rouge. Mon père m a tenu par la selle pendant que je pédalais. Quand j ai réussi tout seul, j étais vraiment fière.',
  },
  {
    'cycle': 'college',
    'label': 'Sécurité routière',
    'subject': 'Rédige des conseils pour éviter les accidents de la route.',
    'text':
        'Pour traverser la rue sans danger, il faut toujours regarder à gauche et à droit. Les piéton doivent utiliser le passage clouté et ne jamais courir devant les voiture.',
  },
  {
    'cycle': 'college',
    'label': 'Économiser l’eau',
    'subject': 'Explique l’importance d’économiser l’eau.',
    'text':
        'L eau est une ressource précieuse qui devient rare. Il ne faut pas laisser le robinet ouvert quand on se brosse les dent. Préférer une douche courte permet aussi d évité le gaspillage.',
  },
  {
    'cycle': 'college',
    'label': 'Mon futur métier',
    'subject': 'Décris le métier que tu aimerais exercer plus tard.',
    'text':
        'Plus tard, je voudrais devenir pharmacien pour soigner les gens. C est un métier utile où il faut bien connaître les médicament et savoir écouté les patients.',
  },
  {
    'cycle': 'college',
    'label': 'La solidarité',
    'subject': 'Raconte une situation où tu as aidé quelqu’un.',
    'text':
        'Un jour, mon voisin âgé portait des sacs très lourd devant l immeuble. Je lui ai proposé de l aider jusqu à sa porte. Il m a remercié avec un grand sourir.',
  },
  {
    'cycle': 'college',
    'label': 'Voyage en train',
    'subject': 'Raconte un voyage en train avec ta famille.',
    'text':
        'Pendant les vacance, nous avons pris le train pour aller à Constantine. Par la fenêtre, je regardais défiler les montagnes et les champs vert. Le trajet a passé vite.',
  },
  {
    'cycle': 'college',
    'label': 'Plaisir de lire',
    'subject': 'Explique pourquoi lire des livres est utile.',
    'text':
        'Lire des romans enrichit notre vocabulaire et développe notre imagination. Même quinze minute par jour suffisent pour voyager dans d autres monde et mieux écrire.',
  },

  // ── LYCÉE (10 exemples) ─────────────────────────────────────────────────
  {
    'cycle': 'lycee',
    'label': 'Téléphone en classe',
    'subject': 'Donne ton avis sur l’utilisation du téléphone en classe.',
    'text':
        'Le téléphone portable est devenus un outil indispensable dans notre vie quotidien. Cependant, son utilisation en classe peut perturbé la concentration des élève si elle n est pas encadrer.',
  },
  {
    'cycle': 'lycee',
    'label': 'Réseaux sociaux',
    'subject': 'Analyse les avantages et les risques des réseaux sociaux.',
    'text':
        'Les réseaux sociaux permettent de communiquer rapidement et de partagé des informations utiles. Toutefois, passer trop d heure devant l écran nuit au sommeil et crée parfois un isolement social.',
  },
  {
    'cycle': 'lycee',
    'label': 'L’IA à l’école',
    'subject': 'Donne ton point de vue sur l’intelligence artificielle à l’école.',
    'text':
        'L intelligence artificielle offre des outils formidables pour comprendre des notions complexe. Néanmoins, l élève doit resté actif dans son apprentissage et ne pas copier les réponses sans réfléchir.',
  },
  {
    'cycle': 'lycee',
    'label': 'Le bénévolat',
    'subject': 'Rédige un plaidoyer en faveur du bénévolat chez les jeunes.',
    'text':
        'S engager dans une association bénévole apprend le sens des responsabilité et la solidarité. Les jeunes qui donne de leur temps acquiert aussi une précieuse expérience humaine.',
  },
  {
    'cycle': 'lycee',
    'label': 'Climat en danger',
    'subject': 'Explique les conséquences du réchauffement climatique.',
    'text':
        'L augmentation des températures provoque des sécheresses prolongées et la fonte des glacier. Il est urgent de réduire nos émissions polluantes afin de préservé l équilibre de la planète.',
  },
  {
    'cycle': 'lycee',
    'label': 'Papier vs Écran',
    'subject': 'Compare le livre papier et la lecture sur écran.',
    'text':
        'Bien que la liseuse numérique soit pratique pour transporter plusieurs ouvrage, le livre papier offre un confort visuel incomparable. De plus, tourner les pages facilite souvent la mémorisation.',
  },
  {
    'cycle': 'lycee',
    'label': 'Éducation pour tous',
    'subject': 'Réfléchis à l’importance de l’éducation pour tous.',
    'text':
        'L accès à l instruction constitue le fondement d une société juste et prospère. Garantir l égalité des chances permet à chaque jeune de développer ces talents, quelle que soit son origine.',
  },
  {
    'cycle': 'lycee',
    'label': 'L’exode rural',
    'subject': 'Expose les causes du départ des jeunes vers les grandes villes.',
    'text':
        'Beaucoup de jeunes quittent les régions rurales à la recherche d emploi et d universités. Ce phénomène vide progressivement les villages et crée une surcharge démographique dans les métropole.',
  },
  {
    'cycle': 'lycee',
    'label': 'Apprendre des langues',
    'subject': 'Explique l’intérêt d’apprendre plusieurs langues.',
    'text':
        'Maîtriser plusieurs langues étrangères ouvre de nombreuses opportunité professionnelles et culturelles. Cela stimule également la souplesse intellectuelle et encourage la tolérance envers autrui.',
  },
  {
    'cycle': 'lycee',
    'label': 'Travail d’équipe',
    'subject': 'Montre pourquoi le travail en groupe favorise la réussite.',
    'text':
        'Collaborer au sein d une équipe permet de confronter des idées différentes et de résoudre des problèmes complexes plus efficacement. Chacun apporte ses compétences pour atteindre un objectif commun.',
  },
];

/// Main AI-powered "Production écrite" screen.
/// Allows the student to write/paste/scan their own French text (with optional teacher topic),
/// then sends it to Gemini AI for DYS-aligned pedagogical error analysis & feedback.
class WritingScreen extends ConsumerStatefulWidget {
  const WritingScreen({super.key});

  @override
  ConsumerState<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends ConsumerState<WritingScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  WritingCacheService? _cacheService;
  List<WritingFeedbackResult> _history = [];
  List<WritingFeedbackResult> _favorites = [];
  bool _showFavoritesTab = false;
  bool _showSubjectField = false;

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _cacheService = WritingCacheService(prefs);
    _history = _cacheService!.getHistory();
    _favorites = _cacheService!.getFavorites();
  }

  @override
  void dispose() {
    _textController.dispose();
    _subjectController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  String _learnerCode(ReadingSettings s) => s.learnerLevel.code;

  String _cycleString(ReadingSettings s) {
    switch (s.learnerLevel) {
      case LearnerLevel.primaire:
        return 'primaire';
      case LearnerLevel.secondaire:
        return 'lycee';
      case LearnerLevel.moyen:
        return 'college';
    }
  }

  String _cycleLabel(ReadingSettings s) {
    switch (s.learnerLevel) {
      case LearnerLevel.primaire:
        return 'Primaire';
      case LearnerLevel.secondaire:
        return 'Lycée';
      case LearnerLevel.moyen:
        return 'Collège';
    }
  }

  Future<void> _openFeedback(WritingFeedbackResult result) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WritingFeedbackScreen(result: result),
      ),
    );
    if (!mounted) return;
    if (_cacheService != null) {
      setState(() {
        _history = _cacheService!.getHistory();
        _favorites = _cacheService!.getFavorites();
      });
    }
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final subject = _subjectController.text.trim();
    final settings = ref.read(readingSettingsProvider);
    final profile = ref.read(learnerProfileProvider);
    final learnerCode = _learnerCode(settings);
    final cycle = _cycleString(settings);

    // 1. Check local cache first for exact same text + subject
    if (_cacheService != null) {
      final cached = _cacheService!.findInCache(
        text,
        subject: subject,
        cycle: cycle,
      );
      if (cached != null) {
        await _cacheService!.saveResult(cached);
        if (!mounted) return;
        setState(() {
          _history = _cacheService!.getHistory();
          _isLoading = false;
          _hasError = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.history_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Récupéré depuis vos bilans récents ⚡'),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _openFeedback(cached);
        return;
      }
    }

    // 2. Call Gemini AI
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final service = WritingGeminiService();
      final errorProfile = _cacheService?.getErrorProfile();
      final result = await service.analyzeWriting(
        studentText: text,
        subjectPrompt: subject,
        learnerLevelCode: learnerCode,
        profile: profile,
        errorProfile: errorProfile,
      );

      if (_cacheService != null) {
        await _cacheService!.saveResult(result);
        await _cacheService!.recordErrorProfile(result);
      }

      if (!mounted) return;
      setState(() {
        if (_cacheService != null) {
          _history = _cacheService!.getHistory();
        }
        _isLoading = false;
      });

      await _openFeedback(result);
    } on GeminiOfflineException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.message;
      });
    } on GeminiParseException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scanText() async {
    final scanned = await OcrService.instance.scanTextWithPicker(context);
    if (scanned != null && scanned.trim().isNotEmpty) {
      setState(() {
        _textController.text = scanned.trim();
        _hasError = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Texte scanné avec succès ! 📷'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      setState(() {
        _textController.text = text;
        _hasError = false;
      });
    }
  }

  void _clearInput() {
    _textController.clear();
    setState(() => _hasError = false);
    _textFocusNode.requestFocus();
  }

  void _fillSample(Map<String, String> sample) {
    _subjectController.text = sample['subject'] ?? '';
    _textController.text = sample['text'] ?? '';
    setState(() {
      _showSubjectField = (_subjectController.text.isNotEmpty);
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final hasText = _textController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        title: const Text(
          'M\'aider à écrire ✍️',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Réglages de lecture',
            onPressed: () => ReadingSettingsSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Pedagogical Header & Level Chip ──────────────────────
              Row(
                children: [
                  Text(
                    'Niveau détecté :',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ReadingSettingsSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppAssetIcon(
                            assetPath:
                                AppUiAssets.cycleForLevel(settings.learnerLevel),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _cycleLabel(settings),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 2. Optional Teacher Subject Field ───────────────────────
              _buildOptionalSubjectSection(settings),
              const SizedBox(height: 14),

              // ── 3. Main Student Writing Input Box ───────────────────────
              _buildMainInputSection(settings, hasText),
              const SizedBox(height: 12),

              // ── 4. Quick Test Examples ──────────────────────────────────
              _buildSamplesRow(settings),
              const SizedBox(height: 20),

              // ── 5. Error Banner (if offline/parse error) ────────────────
              if (_hasError) ...[
                _buildErrorBanner(),
                const SizedBox(height: 16),
              ],

              // ── 6. Submit CTA Button ────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: (hasText && !_isLoading) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'L\'IA analyse ton texte…',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Analyser mon texte ✨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              // ── 7. Recent History & Favorites Tabs ──────────────────────
              if (_history.isNotEmpty || _favorites.isNotEmpty) ...[
                const SizedBox(height: 28),
                _buildHistoryAndFavoritesSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionalSubjectSection(ReadingSettings settings) {
    if (!_showSubjectField) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _showSubjectField = true),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
          label: const Text('Ajouter le sujet du professeur (optionnel)'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0284C7),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Sujet demandé (optionnel)',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _subjectController.clear();
                setState(() => _showSubjectField = false);
              },
              child: const Text(
                'Masquer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _subjectController,
          maxLines: 2,
          minLines: 1,
          style: TextStyle(
            fontFamily: settings.fontFamily,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Ex : Décris ton animal préféré en 5 lignes...',
            hintStyle: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary.withValues(alpha: 0.55),
            ),
            filled: true,
            fillColor: AppColors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.cardBorder,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainInputSection(ReadingSettings settings, bool hasText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mon texte',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            // OCR Scanner Button
            GestureDetector(
              onTap: _scanText,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        size: 13, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Scanner',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Paste Button
            GestureDetector(
              onTap: _pasteText,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.content_paste_rounded,
                        size: 13, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Coller',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasText) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _clearInput,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded, size: 13, color: Colors.red),
                      SizedBox(width: 3),
                      Text(
                        'Effacer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
          ),
          child: TextField(
            controller: _textController,
            focusNode: _textFocusNode,
            onChanged: (_) => setState(() {}),
            minLines: 6,
            maxLines: 14,
            style: TextStyle(
              fontFamily: settings.fontFamily,
              fontSize: 15.5,
              height: 1.65,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText:
                  'Écris ou colle ta production écrite ici…\nJe vais t\'aider à repérer tes erreurs, les comprendre et progresser !',
              hintStyle: TextStyle(
                fontFamily: settings.fontFamily,
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                height: 1.6,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSamplesRow(ReadingSettings settings) {
    final activeCycle = _cycleString(settings);
    final samplesForCycle =
        _kSampleTexts.where((s) => s['cycle'] == activeCycle).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exemples pour tester (${samplesForCycle.length})',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: samplesForCycle.map((sample) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _fillSample(sample),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.cardBorder, width: 1.1),
                    ),
                    child: Text(
                      sample['label'] ?? '',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    final isOffline = _errorMessage.toLowerCase().contains('connexion') ||
        _errorMessage.toLowerCase().contains('socket') ||
        _errorMessage.toLowerCase().contains('network') ||
        _errorMessage.toLowerCase().contains('offline');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOffline
                      ? 'Pas de connexion internet'
                      : 'L\'IA n\'a pas pu analyser ton texte',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isOffline
                ? 'Vérifie ta connexion et réessaie. Tes anciens bilans restent accessibles ci-dessous.'
                : 'Essaie à nouveau dans quelques instants.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text('Réessayer'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryAndFavoritesSection() {
    final activeList = _showFavoritesTab ? _favorites : _history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Recents tab
            GestureDetector(
              onTap: () => setState(() => _showFavoritesTab = false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: !_showFavoritesTab
                      ? AppColors.primary
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: !_showFavoritesTab
                        ? AppColors.primary
                        : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 15,
                      color: !_showFavoritesTab
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Récents (${_history.length})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: !_showFavoritesTab
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Favorites tab
            GestureDetector(
              onTap: () => setState(() => _showFavoritesTab = true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _showFavoritesTab
                      ? Colors.amber.shade700
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showFavoritesTab
                        ? Colors.amber.shade700
                        : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: _showFavoritesTab
                          ? Colors.white
                          : Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Favoris (${_favorites.length})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _showFavoritesTab
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (!_showFavoritesTab && _history.isNotEmpty)
              TextButton(
                onPressed: () async {
                  if (_cacheService != null) {
                    await _cacheService!.clearHistory();
                  }
                  setState(() => _history = []);
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: const Text(
                  'Effacer',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder, width: 1.0),
            ),
            child: Center(
              child: Text(
                _showFavoritesTab
                    ? 'Aucun bilan en favoris.\nTouche l\'étoile ⭐ sur un bilan pour le garder ici !'
                    : 'Aucun texte analysé récemment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeList.length > 5 ? 5 : activeList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = activeList[index];
              final errCount = item.errors.length;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openFeedback(item),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.cardBorder, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: errCount == 0
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AppAssetIcon(
                            assetPath: errCount == 0
                                ? AppUiAssets.writingCelebration
                                : AppUiAssets.featWriting,
                            size: 20,
                            fallbackEmoji: errCount == 0 ? '🎉' : '✍️',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.subjectPrompt.isNotEmpty
                                    ? item.subjectPrompt
                                    : item.originalText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                errCount == 0
                                    ? 'Aucune erreur détectée'
                                    : '$errCount erreur(s) analysée(s)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_showFavoritesTab)
                          const Icon(Icons.star_rounded,
                              size: 18, color: Colors.amber)
                        else
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 13, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
