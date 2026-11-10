import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/reading_palette.dart';
import '../../core/tts/tts_service.dart';
import '../decoding/decoding_screen.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'models/writing_feedback_model.dart';
import 'services/writing_cache_service.dart';

/// Dedicated results screen for Production écrite:
/// - Encouraging summary + strengths + topic relevance
/// - DYS-aligned error cards with filter pills, explanations, tips, and TTS audio
/// - Collapsible "Voir mon texte corrigé" section to encourage learning first
class WritingFeedbackScreen extends ConsumerStatefulWidget {
  final WritingFeedbackResult result;

  const WritingFeedbackScreen({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<WritingFeedbackScreen> createState() =>
      _WritingFeedbackScreenState();
}

class _WritingFeedbackScreenState extends ConsumerState<WritingFeedbackScreen> {
  late final TtsService _ttsService;
  bool _isPlaying = false;
  String? _currentlySpeakingText;
  bool _isFavorite = false;
  bool _showCorrectedText = false;
  WritingErrorCategory? _selectedCategory; // null means 'Tous'

  @override
  void initState() {
    super.initState();
    _ttsService = ref.read(ttsServiceProvider);
    _ttsService.isPlayingNotifier.addListener(_onTtsStateChanged);

    final prefs = ref.read(sharedPreferencesProvider);
    final cacheService = WritingCacheService(prefs);
    _isFavorite =
        cacheService.isFavorite(widget.result.id, widget.result.originalText);
  }

  void _onTtsStateChanged() {
    if (mounted) {
      setState(() {
        _isPlaying = _ttsService.isPlayingNotifier.value;
        if (!_isPlaying) {
          _currentlySpeakingText = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _ttsService.isPlayingNotifier.removeListener(_onTtsStateChanged);
    super.dispose();
  }

  Future<void> _speakText(String text) async {
    if (_isPlaying && _currentlySpeakingText == text) {
      await _ttsService.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlySpeakingText = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isPlaying = true;
        _currentlySpeakingText = text;
      });
    }

    await _ttsService.speakText(text);

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentlySpeakingText = null;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final cacheService = WritingCacheService(prefs);
    final newState = await cacheService.toggleFavorite(widget.result);
    if (!mounted) return;
    setState(() => _isFavorite = newState);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              newState ? Icons.star_rounded : Icons.star_border_rounded,
              color: newState ? Colors.amber : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              newState ? 'Ajouté aux favoris ⭐' : 'Retiré des favoris',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final palette = settings.contrastPreset.palette;
    final fontFamily = settings.fontFamily;
    final result = widget.result;

    // Categories present in the errors
    final presentCategories = <WritingErrorCategory>{};
    for (final err in result.errors) {
      presentCategories.add(err.category);
    }

    final filteredErrors = _selectedCategory == null
        ? result.errors
        : result.errors
            .where((e) => e.category == _selectedCategory)
            .toList();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mon bilan d\'écriture',
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? Colors.amber : palette.textPrimary,
              size: 26,
            ),
            tooltip:
                _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded, color: palette.textPrimary),
            tooltip: 'Réglages de lecture',
            onPressed: () => ReadingSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Encouraging Summary Card ──────────────────────────────
              _buildSummaryCard(result, fontFamily, palette),
              const SizedBox(height: 20),

              // ── 2. Mistakes Section Header & DYS Category Filters ────────
              if (result.errors.isEmpty)
                _buildZeroErrorsCelebration(fontFamily, palette)
              else ...[
                Text(
                  'Comprendre tes erreurs (${result.errors.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontFamily: fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chaque erreur est classée pour t\'aider à progresser sans stress.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: palette.textSecondary,
                    fontFamily: fontFamily,
                  ),
                ),
                const SizedBox(height: 12),

                // Filter chips strip
                if (presentCategories.length > 1) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryFilterChip(
                          label: 'Toutes (${result.errors.length})',
                          isSelected: _selectedCategory == null,
                          color: AppColors.primary,
                          onTap: () => setState(() => _selectedCategory = null),
                        ),
                        const SizedBox(width: 8),
                        ...presentCategories.map((cat) {
                          final count = result.errors
                              .where((e) => e.category == cat)
                              .length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CategoryFilterChip(
                              label: '${cat.emoji} ${cat.labelFr} ($count)',
                              isSelected: _selectedCategory == cat,
                              color: cat.color,
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── 3. Error Cards ───────────────────────────────────────
                ...filteredErrors.map(
                  (err) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildErrorCard(err, fontFamily, palette),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── 4. Pedagogical Reveal Corrected Text Section ─────────────
              _buildCorrectedTextSection(result, fontFamily, palette),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    WritingFeedbackResult result,
    String fontFamily,
    ReadingPalette palette,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✨ Bilan bienveillant',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              const Spacer(),
              _buildAudioPillButton(
                text: '${result.encouragementFr}. ${result.strengthsFr}',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.encouragementFr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
              fontFamily: fontFamily,
              height: 1.45,
            ),
          ),
          if (result.strengthsFr.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tes points forts :',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF047857),
                            fontFamily: fontFamily,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.strengthsFr,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: palette.textPrimary,
                            fontFamily: fontFamily,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (result.topicRelevanceFr.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Respect du sujet :',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0369A1),
                            fontFamily: fontFamily,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.topicRelevanceFr,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: palette.textPrimary,
                            fontFamily: fontFamily,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZeroErrorsCelebration(String fontFamily, ReadingPalette palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            'Aucune erreur détectée !',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF047857),
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ton texte est clair et bien écrit. Continue sur cette belle lancée !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: palette.textPrimary,
              fontFamily: fontFamily,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(
    WritingErrorItem error,
    String fontFamily,
    ReadingPalette palette,
  ) {
    final catColor = error.category.color;
    final spokenSummary =
        'Au lieu de ${error.wrongText}, on écrit ${error.correctedText}. ${error.explanationFr}. Astuce : ${error.tipFr}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: catColor.withValues(alpha: 0.3),
          width: 1.3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Category pill + Audio button
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: error.category.lightColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${error.category.emoji} ${error.category.labelFr}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: catColor,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              const Spacer(),
              _buildAudioPillButton(text: spokenSummary, color: catColor),
            ],
          ),
          const SizedBox(height: 12),

          // Visual comparison: ❌ wrongText  ➔  ✅ correctedText
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '❌ ${error.wrongText}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB91C1C),
                    decoration: TextDecoration.lineThrough,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '✅ ${error.correctedText}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF047857),
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ],
          ),

          if (error.sentenceContext.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Dans ta phrase : « ${error.sentenceContext} »',
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: palette.textSecondary,
                fontFamily: fontFamily,
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 10),

          // Why explanation
          Text(
            'Pourquoi ?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: catColor,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            error.explanationFr,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: palette.textPrimary,
              fontFamily: fontFamily,
            ),
          ),

          if (error.tipFr.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error.tipFr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                        fontFamily: fontFamily,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Helpful shortcut to Decoding rules for rule-based mistakes
          if (error.category == WritingErrorCategory.regleLecture) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DecodingScreen()),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded, size: 15),
                label: const Text('Réviser les règles des sons'),
                style: TextButton.styleFrom(
                  foregroundColor: catColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCorrectedTextSection(
    WritingFeedbackResult result,
    String fontFamily,
    ReadingPalette palette,
  ) {
    if (!_showCorrectedText) {
      return SizedBox(
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _showCorrectedText = true),
          icon: const Icon(Icons.visibility_rounded, size: 20),
          label: const Text(
            'Voir mon texte corrigé 👀',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '✅ Version corrigée complète',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF047857),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copier le texte',
                color: palette.textSecondary,
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: result.correctedFullText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Texte corrigé copié ! 📋'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildAudioPillButton(
                text: result.correctedFullText,
                color: const Color(0xFF047857),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.correctedFullText,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.7,
              color: palette.textPrimary,
              fontFamily: fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPillButton({required String text, required Color color}) {
    final isThisSpeaking = _isPlaying && _currentlySpeakingText == text;
    return Material(
      color: isThisSpeaking ? color : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _speakText(text),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isThisSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: 16,
                color: isThisSpeaking ? Colors.white : color,
              ),
              const SizedBox(width: 4),
              Text(
                isThisSpeaking ? 'Arrêter' : 'Écouter',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isThisSpeaking ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
