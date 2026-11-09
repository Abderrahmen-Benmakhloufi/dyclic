import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learner_profile/learner_profile_notifier.dart';
import '../../core/reading_settings/reading_settings_model.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme/app_colors.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'instruction_detail_screen.dart';
import 'instructions_screen.dart';
import 'models/instruction_model.dart';
import 'services/gemini_service.dart';
import 'services/instruction_cache_service.dart';
import 'services/instruction_matching_service.dart';

/// Quick example instructions shown as chip buttons below the text field.
const _kExamples = [
  'Relève du texte les phrases qui décrivent le personnage.',
  'Justifie en t\'appuyant sur le texte si cette affirmation est vraie ou fausse.',
  'Réécris le paragraphe en remplaçant les verbes au présent par le passé composé.',
  'Rédige un court texte pour convaincre un ami de protéger l\'environnement.',
];

/// Main AI-powered "Expliquer une consigne" screen.
/// Includes:
/// - Instant local matching against the 17 catalog instructions
/// - Local cache & history for instant re-access without internet or API calls
/// - Learner profile integration to tailor pedagogical guidance to DYS needs
class InstructionAiScreen extends ConsumerStatefulWidget {
  const InstructionAiScreen({super.key});

  @override
  ConsumerState<InstructionAiScreen> createState() =>
      _InstructionAiScreenState();
}

class _InstructionAiScreenState extends ConsumerState<InstructionAiScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  InstructionCacheService? _cacheService;
  List<InstructionItem> _history = [];
  List<InstructionItem> _favorites = [];
  bool _showFavoritesTab = false;

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _cacheService = InstructionCacheService(prefs);
    _history = _cacheService!.getHistory();
    _favorites = _cacheService!.getFavorites();
  }

  Future<void> _openDetail(InstructionItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstructionDetailScreen(item: item),
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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final settings = ref.read(readingSettingsProvider);
    final profile = ref.read(learnerProfileProvider);
    final learnerCode = _learnerCode(settings);
    final cycle = _cycleString(settings);

    // ── 1. Option 4: Instant match with official 17 catalog instructions ───
    final localMatch = await InstructionMatchingService.findBestMatch(
      query: text,
      cycle: cycle,
    );

    if (localMatch != null && (localMatch.isExact || localMatch.confidence >= 0.70)) {
      if (_cacheService != null) {
        await _cacheService!.saveInstruction(localMatch.item);
      }
      if (!mounted) return;
      setState(() {
        if (_cacheService != null) {
          _history = _cacheService!.getHistory();
        }
        _isLoading = false;
        _hasError = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localMatch.isExact
                      ? 'Consigne officielle trouvée instantanément ⚡'
                      : 'Correspondance trouvée dans le catalogue officiel ⚡',
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _openDetail(localMatch.item);
      return;
    }

    // ── 2. Option 3: Check cached history (instant result without API) ───
    if (_cacheService != null) {
      final cached = _cacheService!.findInCache(text, cycle);
      if (cached != null) {
        await _cacheService!.saveInstruction(cached); // bump to top
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
                  child: Text('Récupéré depuis vos consignes récentes ⚡'),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _openDetail(cached);
        return;
      }
    }

    // ── 3. Call Gemini AI with student diagnostic profile ────────────────
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final service = GeminiService();
      final item = await service.analyzeInstruction(
        questionText: text,
        learnerLevelCode: learnerCode,
        profile: profile,
      );

      if (_cacheService != null) {
        await _cacheService!.saveInstruction(item);
      }

      if (!mounted) return;
      setState(() {
        if (_cacheService != null) {
          _history = _cacheService!.getHistory();
        }
        _isLoading = false;
      });

      await _openDetail(item);
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
              Text('Texte extrait avec succès ! 📷'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openCatalog() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InstructionsScreen()),
    );
  }

  void _fillExample(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() {
      _hasError = false;
    });
    _focusNode.requestFocus();
  }

  void _clearInput() {
    _controller.clear();
    setState(() {
      _hasError = false;
    });
    _focusNode.requestFocus();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final theme = Theme.of(context);

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
          'Expliquer une consigne 💡',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Paramètres de lecture',
            onPressed: () => ReadingSettingsSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Banner Card: catalog ─────────────────────────────────
            _CatalogBannerCard(onTap: _openCatalog),
            const SizedBox(height: 20),

            // ── 2. Cycle chip (read-only display, opens settings) ───────
            _CyclePill(
              label: _cycleLabel(settings),
              onTap: () => ReadingSettingsSheet.show(context),
            ),
            const SizedBox(height: 18),

            // ── 3. Text input area ───────────────────────────────────────
            _InputSection(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (_) => setState(() {}),
              onClear: _clearInput,
              onScan: _scanText,
              theme: theme,
            ),
            const SizedBox(height: 12),

            // ── 4. Quick examples ────────────────────────────────────────
            _ExamplesRow(onSelect: _fillExample),
            const SizedBox(height: 20),

            // ── 5. Offline / parse error banner ─────────────────────────
            if (_hasError) ...[
              _ErrorBanner(
                message: _errorMessage,
                onOpenCatalog: _openCatalog,
                onRetry: _submit,
              ),
              const SizedBox(height: 16),
            ],

            // ── 6. Submit button ─────────────────────────────────────────
            _SubmitButton(
              isLoading: _isLoading,
              isEnabled: _controller.text.trim().isNotEmpty && !_isLoading,
              onPressed: _submit,
            ),

            // ── 7. Option 3: Recent History & Favorites ─────────────────
            if (_history.isNotEmpty || _favorites.isNotEmpty) ...[
              const SizedBox(height: 28),
              _HistoryAndFavoritesSection(
                history: _history,
                favorites: _favorites,
                showFavoritesTab: _showFavoritesTab,
                onTabChanged: (isFav) {
                  setState(() {
                    _showFavoritesTab = isFav;
                  });
                },
                onSelect: _openDetail,
                onClearHistory: () async {
                  if (_cacheService != null) {
                    await _cacheService!.clearHistory();
                  }
                  setState(() {
                    _history = [];
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ════════════════════════════════════════════════════════════════════════════

/// Banner card linking to the 17-instruction catalog.
class _CatalogBannerCard extends StatelessWidget {
  const _CatalogBannerCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('📚', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '17 consignes types d\'examen',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Consulter des exemples officiels prêts à l\'emploi',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF0284C7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only chip showing the learner's current cycle, tappable to change it.
class _CyclePill extends StatelessWidget {
  const _CyclePill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                  label,
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
    );
  }
}

/// Multi-line text field with clear & OCR buttons.
class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onScan,
    required this.theme,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onScan;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ta consigne',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            // OCR Scan button
            GestureDetector(
              onTap: onScan,
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
            if (hasText) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClear,
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
                            fontWeight: FontWeight.w600),
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
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            minLines: 4,
            maxLines: 10,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText:
                  'Colle ou écris ta consigne ici…\nex: Relève du texte les mots qui…',
              hintStyle: TextStyle(
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
}

/// Horizontal scrollable row of quick-example chips.
class _ExamplesRow extends StatelessWidget {
  const _ExamplesRow({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exemples rapides',
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
            children: _kExamples.map((ex) {
              final short = ex.length > 30 ? '${ex.substring(0, 30)}…' : ex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelect(ex),
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
                      short,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
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
}

/// Error / offline banner shown below examples.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onOpenCatalog,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onOpenCatalog;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isOffline =
        message.toLowerCase().contains('connexion') ||
        message.toLowerCase().contains('socket') ||
        message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('offline');

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
                      : 'L\'IA n\'a pas pu analyser ta consigne',
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
                ? 'Consulte les 17 consignes types pendant ce temps.'
                : 'Essaie à nouveau ou consulte le catalogue.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onOpenCatalog,
                icon: const Icon(Icons.menu_book_rounded, size: 15),
                label: const Text('Voir le catalogue'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange, width: 1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                  minimumSize: Size.zero,
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Réessayer'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Large primary CTA button with loading state.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading
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
                    'L\'IA analyse ta consigne…',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : const Text(
                'Expliquer ma consigne ✨',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

/// Option 3: Recent history & Favorites of analyzed instructions.
class _HistoryAndFavoritesSection extends StatelessWidget {
  const _HistoryAndFavoritesSection({
    required this.history,
    required this.favorites,
    required this.showFavoritesTab,
    required this.onTabChanged,
    required this.onSelect,
    required this.onClearHistory,
  });

  final List<InstructionItem> history;
  final List<InstructionItem> favorites;
  final bool showFavoritesTab;
  final ValueChanged<bool> onTabChanged;
  final ValueChanged<InstructionItem> onSelect;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    final activeList = showFavoritesTab ? favorites : history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs Header: Récents vs Favoris
        Row(
          children: [
            // Recents Tab Chip
            GestureDetector(
              onTap: () => onTabChanged(false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: !showFavoritesTab
                      ? AppColors.primary
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: !showFavoritesTab
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
                      color: !showFavoritesTab
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Récents (${history.length})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: !showFavoritesTab
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Favorites Tab Chip
            GestureDetector(
              onTap: () => onTabChanged(true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: showFavoritesTab
                      ? Colors.amber.shade700
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: showFavoritesTab
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
                      color: showFavoritesTab
                          ? Colors.white
                          : Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Favoris (${favorites.length})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: showFavoritesTab
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Clear history button (only when on recents tab)
            if (!showFavoritesTab && history.isNotEmpty)
              TextButton(
                onPressed: onClearHistory,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: const Text(
                  'Effacer',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Content
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
                showFavoritesTab
                    ? 'Aucune consigne dans les favoris pour le moment.\nTouche l\'étoile ⭐ sur une consigne pour la garder ici !'
                    : 'Aucune consigne récente.',
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
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(item),
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
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.questionTypeLightColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.questionTypeEmoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title.isNotEmpty
                                    ? item.title
                                    : item.originalFr,
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
                                item.originalFr,
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
                        if (showFavoritesTab)
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Colors.amber,
                          )
                        else
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
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
    );
  }
}
