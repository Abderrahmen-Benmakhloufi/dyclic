import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/tts/tts_service.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'instruction_detail_screen.dart';
import 'models/instruction_model.dart';
import 'services/instructions_service.dart';

class InstructionsScreen extends ConsumerStatefulWidget {
  const InstructionsScreen({super.key});

  @override
  ConsumerState<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends ConsumerState<InstructionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final TtsService _ttsService;
  bool _isPlaying = false;
  String? _currentlySpeakingText;

  List<InstructionItem> _allInstructions = [];
  bool _isLoading = true;

  String _selectedCycle = 'all'; // 'all' | 'primaire' | 'college' | 'lycee'
  String _selectedType = 'all'; // 'all' | 'comprehension' | 'langue' | 'production'
  String _selectedActionVerb = 'all'; // 'all' | 'relever' | 'justifier' | 'identifier' | 'transformer' | 'rediger'

  @override
  void initState() {
    super.initState();

    _ttsService = ref.read(ttsServiceProvider);
    _ttsService.isPlayingNotifier.addListener(_onTtsStateChanged);

    _searchController.addListener(() {
      setState(() {});
    });

    _loadData();
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

  Future<void> _loadData() async {
    final items = await InstructionsService.instance.loadInstructions();
    if (mounted) {
      setState(() {
        _allInstructions = items;
        _isLoading = false;
      });
    }
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

  @override
  void dispose() {
    _ttsService.isPlayingNotifier.removeListener(_onTtsStateChanged);
    _ttsService.stop();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<InstructionItem> get _filteredInstructions {
    return InstructionsService.instance.filterAndSearch(
      items: _allInstructions,
      cycle: _selectedCycle,
      questionType: _selectedType,
      actionVerb: _selectedActionVerb,
      query: _searchController.text,
    );
  }

  int _countForCycle(String cycle) {
    if (cycle == 'all') return _allInstructions.length;
    return _allInstructions
        .where((i) => i.cycle.toLowerCase() == cycle.toLowerCase())
        .length;
  }

  int _countForType(String type) {
    if (type == 'all') return _allInstructions.length;
    return _allInstructions
        .where((i) => i.questionType.toLowerCase() == type.toLowerCase())
        .length;
  }

  int _countForActionVerb(String verbKey) {
    if (verbKey == 'all') return _allInstructions.length;
    return _allInstructions.where((i) => i.matchesActionVerb(verbKey)).length;
  }

  void _navigateToDetail(InstructionItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InstructionDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final filteredList = _filteredInstructions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Comprendre les consignes 💡',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: settings.fontFamily,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            tooltip: 'Réglages de lecture',
            onPressed: () => ReadingSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // 1. Hallmark Canvas Header: Natural breathing room, no artificial box border
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                      child: _buildCanvasHeader(settings.fontFamily),
                    ),
                  ),

                  // 2. Primary Question Type Filter Tabs (Visual Coding Signal)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _buildTypeTabs(settings.fontFamily),
                    ),
                  ),

                  // 3. Fast Action Verbs Strip (Direct match with exam command verbs)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildActionVerbsRow(settings.fontFamily),
                    ),
                  ),

                  // 4. Search Bar + School Level Chips Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _buildSearchAndLevelRow(settings.fontFamily),
                    ),
                  ),

                  // 5. Instructions Counter & Reset Action (Hairline seam)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${filteredList.length} consigne${filteredList.length > 1 ? 's' : ''} disponible${filteredList.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                fontFamily: settings.fontFamily,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty ||
                              _selectedCycle != 'all' ||
                              _selectedType != 'all' ||
                              _selectedActionVerb != 'all')
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedCycle = 'all';
                                  _selectedType = 'all';
                                  _selectedActionVerb = 'all';
                                });
                              },
                              child: Text(
                                'Réinitialiser',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontFamily: settings.fontFamily,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 5. Hallmark Cards List (Editorial presentation without nested cards)
                  if (filteredList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(settings.fontFamily),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filteredList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildInstructionCard(
                                item: item,
                                fontFamily: settings.fontFamily,
                              ),
                            );
                          },
                          childCount: filteredList.length,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  /// Hallmark Canvas Header: Sits directly on the background canvas with proper breathing room
  Widget _buildCanvasHeader(String? fontFamily) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Single Tulip inside large intentional circular container
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🌷', style: TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '17 consignes d’examens expliquées pas à pas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                  color: AppColors.textPrimary,
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Choisis une question pour découvrir sa méthode.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontFamily: fontFamily,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Primary Visual Coding Tabs: Clear signal colors with high contrast active states
  Widget _buildTypeTabs(String? fontFamily) {
    final types = [
      {
        'key': 'all',
        'label': 'Tous les types (${_countForType('all')})',
        'color': AppColors.primary,
      },
      {
        'key': 'comprehension',
        'label': '🔍 Compréhension (${_countForType('comprehension')})',
        'color': const Color(0xFF0284C7), // Sky/Ocean Blue
      },
      {
        'key': 'langue',
        'label': '📝 Langue & Grammaire (${_countForType('langue')})',
        'color': const Color(0xFF7C3AED), // Amethyst Purple
      },
      {
        'key': 'production',
        'label': '✍️ Production écrite (${_countForType('production')})',
        'color': const Color(0xFFEA580C), // Sunset Orange
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: types.map((t) {
          final isSelected = _selectedType == t['key'];
          final typeColor = t['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                setState(() {
                  _selectedType = t['key'] as String;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? typeColor : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? typeColor : AppColors.cardBorder,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: typeColor.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  t['label'] as String,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Quick Action Verbs Row:
  /// Allows students to filter by the exact command verb on their exam paper
  Widget _buildActionVerbsRow(String? fontFamily) {
    final verbs = [
      (key: 'all', label: 'Tous les verbes', emoji: '✨'),
      (key: 'relever', label: 'Relever', emoji: '🔍'),
      (key: 'justifier', label: 'Justifier / Vrai-Faux', emoji: '⚖️'),
      (key: 'identifier', label: 'Identifier / Dégager', emoji: '🏷️'),
      (key: 'transformer', label: 'Transformer', emoji: '🔄'),
      (key: 'rediger', label: 'Rédiger / Raconter', emoji: '✍️'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          child: Row(
            children: [
              Text(
                'Verbe de la consigne :',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFamily: fontFamily,
                ),
              ),
              if (_selectedActionVerb != 'all') ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _selectedActionVerb = 'all'),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Effacer',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontFamily: fontFamily,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 5),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: verbs.map((v) {
              final isSelected = _selectedActionVerb == v.key;
              final count = _countForActionVerb(v.key);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _selectedActionVerb =
                          isSelected && v.key != 'all' ? 'all' : v.key;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.14)
                          : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(v.emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          '${v.label} ($count)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
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

  /// Compact Search bar + School Level Selector Row
  Widget _buildSearchAndLevelRow(String? fontFamily) {
    final cycles = [
      {'key': 'all', 'label': 'Tous les niveaux (${_countForCycle('all')})'},
      {'key': 'primaire', 'label': '🎒 Primaire (${_countForCycle('primaire')})'},
      {'key': 'college', 'label': '📚 Collège (${_countForCycle('college')})'},
      {'key': 'lycee', 'label': '🎓 Lycée (${_countForCycle('lycee')})'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input with clear styling
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1.1),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontFamily: fontFamily,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              hintText: 'Rechercher une consigne (ex: argument, verbe, vrai...)',
              hintStyle: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.65),
                fontFamily: fontFamily,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 18, color: AppColors.textSecondary),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // School Level Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: cycles.map((c) {
              final isSelected = _selectedCycle == c['key'];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _selectedCycle = c['key']!;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      c['label']!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontFamily: fontFamily,
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

  /// Hallmark-Grade Card Architecture:
  /// - NO nested card inside card (The Floor § 11, Craft § 3)
  /// - Clear Typographic Hierarchy (Craft § 1)
  /// - The Accent is a Signal, Not a Fill (Craft § 2)
  /// - Complete exam question text with generous line spacing
  Widget _buildInstructionCard({
    required InstructionItem item,
    required String? fontFamily,
  }) {
    final typeColor = item.questionTypeColor;
    final typeBg = item.questionTypeLightColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _navigateToDetail(item),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Metadata Header Row (Clean, unnested tags)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // School Cycle Badge ONLY (الطور فقط: 🎒 Primaire, 📚 Collège, 🎓 Lycée)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            item.cycleEmojiLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: fontFamily,
                            ),
                          ),
                        ),

                        // Question Type Badge (Quiet signal tint)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: typeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.questionTypeEmoji} ${item.questionTypeLabel}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                              fontFamily: fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Quick Audio Listen Button (Écoute rapide 🔊)
                  _buildQuickAudioButton(item, fontFamily),

                  const SizedBox(width: 6),

                  // Forward Navigation Chevron
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: typeColor,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Title: Strong, crisp display
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: AppColors.textPrimary,
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 8),

              // 3. Question Text: Direct typographic presentation (NO nested bordered box)
              Text(
                '« ${item.originalFr} »',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary.withValues(alpha: 0.88),
                  fontStyle: FontStyle.italic,
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 14),

              // 4. Subtle Hairline Seam (Surface Ladder)
              const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
              const SizedBox(height: 10),

              // 5. Bottom Action Row
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    '${item.steps.length} étapes décortiquées',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: fontFamily,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Voir la méthode',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                          fontFamily: fontFamily,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: typeColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick Audio Button on each card:
  /// Allows students to instantly listen to the exam question text without opening the detail page
  Widget _buildQuickAudioButton(InstructionItem item, String? fontFamily) {
    final isThisPlaying =
        _isPlaying && _currentlySpeakingText == item.originalFr;
    final typeColor = item.questionTypeColor;

    return Semantics(
      button: true,
      label: isThisPlaying
          ? 'Arrêter la lecture'
          : 'Écouter la consigne',
      child: Tooltip(
        message: isThisPlaying ? 'Arrêter la lecture' : 'Écouter la consigne',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _speakText(item.originalFr),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
            decoration: BoxDecoration(
              color: isThisPlaying
                  ? typeColor.withValues(alpha: 0.16)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isThisPlaying
                    ? typeColor.withValues(alpha: 0.6)
                    : AppColors.cardBorder,
                width: isThisPlaying ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isThisPlaying
                      ? Icons.stop_rounded
                      : Icons.volume_up_rounded,
                  size: 15,
                  color: isThisPlaying ? typeColor : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  isThisPlaying ? 'Stop' : 'Écouter',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        isThisPlaying ? FontWeight.bold : FontWeight.w600,
                    color:
                        isThisPlaying ? typeColor : AppColors.textSecondary,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String? fontFamily) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(
              'Aucune consigne trouvée',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: fontFamily,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Essaie de modifier tes mots-clés ou de changer de filtre.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                fontFamily: fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réinitialiser la recherche'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCycle = 'all';
                  _selectedType = 'all';
                  _selectedActionVerb = 'all';
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
