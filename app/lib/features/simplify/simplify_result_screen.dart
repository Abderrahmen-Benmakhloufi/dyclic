import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/reading_palette.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../reading_settings/reading_settings_sheet.dart';
import '../reading_support/reading_support_screen.dart';
import 'models/simplify_model.dart';
import 'services/simplify_cache_service.dart';

/// Screen presenting the simplification results:
/// - Summary (2-4 sentences) with direct audio player
/// - FALC-structured simplified text with bridge to "M'aider à lire"
/// - Key vocabulary glosses with individual pronunciation buttons
class SimplifyResultScreen extends ConsumerStatefulWidget {
  final SimplifyResult result;

  const SimplifyResultScreen({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<SimplifyResultScreen> createState() =>
      _SimplifyResultScreenState();
}

class _SimplifyResultScreenState extends ConsumerState<SimplifyResultScreen> {
  late final TtsService _ttsService;
  bool _isPlaying = false;
  String? _currentlySpeakingText;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _ttsService = ref.read(ttsServiceProvider);
    _ttsService.isPlayingNotifier.addListener(_onTtsStateChanged);

    final prefs = ref.read(sharedPreferencesProvider);
    final cacheService = SimplifyCacheService(prefs);
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

    if (_isPlaying) {
      await _ttsService.stop();
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
    final cacheService = SimplifyCacheService(prefs);
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

  void _openInReadingSupport(String text) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingSupportScreen(initialText: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final palette = settings.contrastPreset.palette;
    final fontFamily = settings.fontFamily;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        title: Row(
          children: [
            const AppAssetIcon(
              assetPath: AppUiAssets.featSimplify,
              size: 26,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Texte simplifié',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: palette.textPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isFavorite ? Colors.amber.shade700 : palette.textSecondary,
            ),
            tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded, color: palette.textSecondary),
            tooltip: 'Réglages de lecture',
            onPressed: () => ReadingSettingsSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Section 1 : Le Résumé condensé ──────────────────────────────
            _buildCardContainer(
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_stories_rounded,
                                size: 16, color: Color(0xFF0284C7)),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'RÉSUMÉ EN 3 PHRASES',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildAudioButton(
                        text: widget.result.summary,
                        color: const Color(0xFF0284C7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.result.summary,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: (settings.fontSize * 0.95).clamp(15.0, 22.0),
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section 2 : Le Texte Simplifié (Syntaxe FALC) ────────────────
            _buildCardContainer(
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 16, color: Color(0xFF047857)),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'TEXTE FACILE À LIRE (FALC)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildAudioButton(
                        text: widget.result.simplifiedText,
                        color: const Color(0xFF047857),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.result.simplifiedText,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: settings.fontSize.clamp(16.0, 24.0),
                      height: settings.lineHeight.clamp(1.5, 2.2),
                      letterSpacing: settings.letterSpacing,
                      wordSpacing: settings.wordSpacing,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: palette.border),
                  const SizedBox(height: 12),

                  // Actions row: Copy text & Open in M'aider à lire
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: widget.result.simplifiedText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Texte simplifié copié ! 📋'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copier'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.textSecondary,
                          side: BorderSide(color: palette.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openInReadingSupport(
                            widget.result.simplifiedText),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: const Text('Lire avec les syllabes ✨'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section 3 : Glossaire des mots difficiles ────────────────────
            if (widget.result.glosses.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mots difficiles expliqués (${widget.result.glosses.length})',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...widget.result.glosses.map((gloss) {
                return _buildGlossItemCard(gloss, palette, fontFamily);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required Widget child,
    required ReadingPalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGlossItemCard(
    SimplifyWordGloss gloss,
    ReadingPalette palette,
    String fontFamily,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${gloss.word} : ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          fontFamily: fontFamily,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      TextSpan(
                        text: gloss.definitionSimple,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontFamily: fontFamily,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 20),
                tooltip: 'Écouter la définition',
                color: const Color(0xFFB45309),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () =>
                    _speakText('${gloss.word}. ${gloss.definitionSimple}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioButton({required String text, required Color color}) {
    final isSpeaking = _isPlaying && _currentlySpeakingText == text;

    return InkWell(
      onTap: () => _speakText(text),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSpeaking ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSpeaking
                  ? Icons.stop_circle_rounded
                  : Icons.volume_up_rounded,
              size: 16,
              color: isSpeaking ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              isSpeaking ? 'Arrêter' : 'Écouter',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isSpeaking ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
