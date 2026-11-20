import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learner_profile/learner_profile_notifier.dart';
import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ai_exit_confirm_dialog.dart';
import '../../core/widgets/ai_waiting_card.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'data/french_curriculum_samples.dart';
import 'models/simplify_model.dart';
import 'services/simplify_cache_service.dart';
import 'services/simplify_gemini_service.dart';
import 'simplify_result_screen.dart';

/// Main screen for "Simplifier le texte" (F1).
/// Features:
/// - Text input with Camera OCR, Paste, and Clear buttons
/// - French curriculum sample chips (Primaire, Moyen, Lycée)
/// - Direct local cache check to recover previous results instantly
/// - Gemini AI analysis with FALC syntactic restructuring
/// - History and Favorites section
class SimplifyScreen extends ConsumerStatefulWidget {
  const SimplifyScreen({super.key});

  @override
  ConsumerState<SimplifyScreen> createState() => _SimplifyScreenState();
}

class _SimplifyScreenState extends ConsumerState<SimplifyScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  SimplifyCacheService? _cacheService;
  List<SimplifyResult> _history = [];
  List<SimplifyResult> _favorites = [];
  bool _showFavoritesTab = false;

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    final prefs = ref.read(sharedPreferencesProvider);
    _cacheService = SimplifyCacheService(prefs);
    _history = _cacheService!.getHistory();
    _favorites = _cacheService!.getFavorites();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

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
        return 'Moyen';
    }
  }

  Future<void> _openResult(SimplifyResult result) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SimplifyResultScreen(result: result),
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
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final settings = ref.read(readingSettingsProvider);
    final profile = ref.read(learnerProfileProvider);
    final learnerCode = settings.learnerLevel.code;
    final cycle = _cycleString(settings);

    // 1. Instant Cache Check
    if (_cacheService != null) {
      final cached = _cacheService!.findInCache(text, cycle);
      if (cached != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Récupéré depuis tes textes récents ⚡'),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _openResult(cached);
        return;
      }
    }

    // 2. AI Request with Gemini
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _isCancelled = false;
    });

    try {
      final service = SimplifyGeminiService();
      final cloudMistakes = ref.read(cachedLearnerMistakesSummaryProvider);
      final result = await service.simplifyText(
        rawText: text,
        learnerLevelCode: learnerCode,
        profile: profile,
        cloudMistakesSummary: cloudMistakes,
      );

      if (_isCancelled || !mounted) return;

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

      await _openResult(result);
    } on SimplifyOfflineException catch (e) {
      if (_isCancelled || !mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.message;
      });
    } on SimplifyParseException catch (e) {
      if (_isCancelled || !mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (_isCancelled || !mounted) return;
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
        _controller.text = scanned.trim();
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
        _controller.text = text;
        _hasError = false;
      });
    }
  }

  void _clearInput() {
    _controller.clear();
    setState(() => _hasError = false);
    _focusNode.requestFocus();
  }

  void _fillSample(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() => _hasError = false);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final rawText = _controller.text.trim();
    final wordCount =
        rawText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final hasEnoughText = wordCount >= 5;

    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await AiExitConfirmDialog.show(context);
        if (shouldExit && context.mounted) {
          _isCancelled = true;
          setState(() => _isLoading = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              if (_isLoading) {
                final shouldExit = await AiExitConfirmDialog.show(context);
                if (shouldExit && context.mounted) {
                  _isCancelled = true;
                  setState(() => _isLoading = false);
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Retour',
          ),
        title: const Row(
          children: [
            Hero(
              tag: 'hero_${AppUiAssets.featSimplify}',
              child: AppAssetIcon(
                assetPath: AppUiAssets.featSimplify,
                size: 26,
              ),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Simplifier le texte',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ),
          ],
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
              // ── 1. Cycle pill indicator ──────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Programme :',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ReadingSettingsSheet.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            AppAssetIcon(
                              assetPath:
                                  AppUiAssets.cycleForLevel(settings.learnerLevel),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _cycleLabel(settings),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
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
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 2. Text Input Area ───────────────────────────────────────
              _buildInputSection(settings, rawText.isNotEmpty),
              const SizedBox(height: 6),

              // Word count indicator
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    wordCount < 5
                        ? '$wordCount / 5 mots minimum'
                        : '$wordCount mots',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: wordCount < 5
                          ? Colors.orange.shade700
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── 3. French Curriculum Test Samples ────────────────────────
              _buildSamplesRow(settings),
              const SizedBox(height: 20),

              // ── 4. Error Banner ──────────────────────────────────────────
              if (_hasError) ...[
                _buildErrorBanner(),
                const SizedBox(height: 16),
              ],

              // ── 5. Submit CTA Button ─────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: (hasEnoughText && !_isLoading) ? _submit : null,
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
                              'Simplification en cours…',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Simplifier et résumer le texte ✨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              if (_isLoading) ...[
                const SizedBox(height: 14),
                const AiWaitingCard(
                  title: 'Simplification en cours… ⏳',
                  message:
                      'L\'IA allège les phrases, prépare le résumé et extrait les définitions simples des mots difficiles.',
                  tip:
                      '💡 Astuce : Respire calmement, ton texte simplifié arrive dans un instant !',
                ),
              ],

              // ── 6. History and Favorites Section ─────────────────────────
              if (_history.isNotEmpty || _favorites.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildArchivesDivider(),
                const SizedBox(height: 18),
                _buildHistoryAndFavoritesSection(),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(ReadingSettings settings, bool hasText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            const Text(
              'Texte à simplifier',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildActionChip(
                  icon: Icons.camera_alt_rounded,
                  label: 'Scanner',
                  color: AppColors.primary,
                  onTap: _scanText,
                ),
                _buildActionChip(
                  icon: Icons.content_paste_rounded,
                  label: 'Coller',
                  color: AppColors.textSecondary,
                  onTap: _pasteText,
                ),
                if (hasText)
                  _buildActionChip(
                    icon: Icons.close_rounded,
                    label: 'Effacer',
                    color: Colors.red,
                    onTap: _clearInput,
                  ),
              ],
            ),
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
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (_) => setState(() {}),
            minLines: 5,
            maxLines: 12,
            style: TextStyle(
              fontFamily: settings.fontFamily,
              fontSize: 15.5,
              height: 1.65,
              color: AppColors.textPrimary,
            ),
            scrollPadding: const EdgeInsets.only(bottom: 140.0),
            decoration: InputDecoration(
              hintText:
                  'Colle ou écris un texte difficile ici…\nJe vais le résumer, l’aérer et t’expliquer les mots compliqués !',
              hintStyle: TextStyle(
                fontFamily: settings.fontFamily,
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                height: 1.6,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: Colors.red, size: 20),
                      tooltip: 'Effacer le texte',
                      onPressed: _clearInput,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSamplesRow(ReadingSettings settings) {
    final activeCycle = _cycleString(settings);
    final samplesForCycle = kFrenchCurriculumSamples
        .where((s) => s['cycle'] == activeCycle)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Textes types du programme (${samplesForCycle.length})',
          style: const TextStyle(
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
                  onTap: () => _fillSample(sample['text'] ?? ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
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
                  _errorMessage,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
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

  Widget _buildArchivesDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cardBorder.withValues(alpha: 0.1),
                  AppColors.cardBorder,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open_rounded,
                    size: 14, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text(
                  'MES ARCHIVES & FAVORIS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cardBorder,
                  AppColors.cardBorder.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryAndFavoritesSection() {
    final activeList = _showFavoritesTab ? _favorites : _history;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Recents tab
                    GestureDetector(
                      onTap: () => setState(() => _showFavoritesTab = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: !_showFavoritesTab
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 14,
                              color: !_showFavoritesTab
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Récents (${_history.length})',
                              style: TextStyle(
                                fontSize: 11.5,
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
                    const SizedBox(width: 4),
                    // Favorites tab
                    GestureDetector(
                      onTap: () => setState(() => _showFavoritesTab = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _showFavoritesTab
                              ? Colors.amber.shade700
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: _showFavoritesTab
                                  ? Colors.white
                                  : Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Favoris (${_favorites.length})',
                              style: TextStyle(
                                fontSize: 11.5,
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
                  ],
                ),
              ),
              if (!_showFavoritesTab && _history.isNotEmpty)
                InkWell(
                  onTap: () async {
                    if (_cacheService != null) {
                      await _cacheService!.clearHistory();
                    }
                    setState(() => _history = []);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 14, color: AppColors.textSecondary),
                        SizedBox(width: 2),
                        Text(
                          'Effacer',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (activeList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder, width: 1.0),
              ),
              child: Center(
                child: Text(
                  _showFavoritesTab
                      ? 'Aucun texte en favoris pour le moment.\nTouche l\'étoile ⭐ pour garder tes textes préférés ici !'
                      : 'Aucun texte simplifié récemment.',
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
              itemCount: activeList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = activeList[index];
                final isFav = _cacheService?.isFavorite(
                        item.id, item.originalText) ??
                    false;

                return Dismissible(
                  key: ValueKey('simplify_item_${item.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: AppColors.errorRed,
                      size: 22,
                    ),
                  ),
                  onDismissed: (_) async {
                    if (_cacheService != null) {
                      await _cacheService!.deleteFromHistory(item.id);
                    }
                    setState(() {
                      _history.removeWhere((h) => h.id == item.id);
                      _favorites.removeWhere((f) => f.id == item.id);
                    });
                  },
                  child: InkWell(
                    onTap: () => _openResult(item),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isFav ? Icons.star_rounded : Icons.history_rounded,
                            size: 18,
                            color: isFav
                                ? Colors.amber.shade700
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.summary.isNotEmpty
                                      ? item.summary
                                      : item.originalText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.glosses.length} mot(s) expliqué(s)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
