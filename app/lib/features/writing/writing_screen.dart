import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learner_profile/learner_profile_notifier.dart';
import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme/app_colors.dart';
import '../instructions/services/gemini_service.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'models/writing_feedback_model.dart';
import 'services/writing_cache_service.dart';
import 'services/writing_gemini_service.dart';
import 'writing_feedback_screen.dart';

/// Quick sample student essays containing typical DYS mistakes (inversions, phonetic, rules, accords).
const _kSampleTexts = [
  {
    'label': '🐴 Exemple Primaire',
    'subject': 'Décris une visite à la ferme.',
    'text':
        'Hier, je suis aler à la ferme avec mon père. J ai vu un gran chavel blanc qui manger de l herbe. Il y avais aussi un bato sur la rivière.',
  },
  {
    'label': '🌿 Exemple Collège',
    'subject': 'Raconte une sortie en forêt.',
    'text':
        'La semain dernière, nous avons visiter une foret magnifique. Les arbres étais très haut et les oiseaux chanter dans les branches. Nous avons pris de baux photos.',
  },
  {
    'label': '🏙️ Exemple Lycée',
    'subject': 'Donne ton avis sur l\'utilisation du téléphone en classe.',
    'text':
        'Le téléphone portable est devenus un outil indispensable dans notre vie quotidien. Cependant, son utilisation en classe peut perturbé la concentration des élève si elle n est pas encadrer.',
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
        return '🎒 Primaire';
      case LearnerLevel.secondaire:
        return '🎓 Lycée';
      case LearnerLevel.moyen:
        return '📚 Collège';
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
      final result = await service.analyzeWriting(
        studentText: text,
        subjectPrompt: subject,
        learnerLevelCode: learnerCode,
        profile: profile,
      );

      if (_cacheService != null) {
        await _cacheService!.saveResult(result);
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
              _buildSamplesRow(),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🎯 Sujet demandé (optionnel)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0284C7),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _subjectController.clear();
                  setState(() => _showSubjectField = false);
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _subjectController,
            maxLines: 2,
            minLines: 1,
            style: TextStyle(
              fontFamily: settings.fontFamily,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: Décris ton animal préféré en 5 lignes...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
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

  Widget _buildSamplesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exemples pour tester',
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
            children: _kSampleTexts.map((sample) {
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: errCount == 0
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            errCount == 0 ? '🎉' : '✍️',
                            style: const TextStyle(fontSize: 14),
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
