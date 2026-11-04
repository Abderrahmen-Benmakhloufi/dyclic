import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
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

  List<InstructionItem> _allInstructions = [];
  bool _isLoading = true;

  String _selectedCycle = 'all'; // 'all' | 'primaire' | 'college' | 'lycee'
  String _selectedType = 'all'; // 'all' | 'comprehension' | 'langue' | 'production'

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });

    _loadData();
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<InstructionItem> get _filteredInstructions {
    return InstructionsService.instance.filterAndSearch(
      items: _allInstructions,
      cycle: _selectedCycle,
      questionType: _selectedType,
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
                  // 1. Compact Reassuring Header Banner (with single flower in circle)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: _buildCompactBanner(settings.fontFamily),
                    ),
                  ),

                  // 2. Primary Question Type Filter Tabs (Proposal A - Visual Coding)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _buildTypeTabs(settings.fontFamily),
                    ),
                  ),

                  // 3. Search Bar + Level Filter row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                      child: _buildSearchAndLevelRow(settings.fontFamily),
                    ),
                  ),

                  // 4. Instructions Counter & Reset Action
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
                              _selectedType != 'all')
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedCycle = 'all';
                                  _selectedType = 'all';
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

                  // 5. Cards List or Empty State
                  if (filteredList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(settings.fontFamily),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
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

  Widget _buildCompactBanner(String? fontFamily) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Single Tulip in Large Circular Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌷', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '17 consignes d’examens expliquées pas à pas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choisis une question pour découvrir sa méthode.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Primary Visual Coding Tabs: Each question type has its own distinct color
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
        // Search TextField
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

        // School Level Chips
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

  /// Clean, de-cluttered card:
  /// - Left color stripe matching the question type
  /// - No cryptic IDs (like PRI-01)
  /// - Full question text (NOT truncated)
  /// - Step count badge and clear action link
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
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Distinct Question Type Left Color Stripe
                  Container(
                    width: 5,
                    color: typeColor,
                  ),

                  // Card Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Header Badges: Level & Question Type
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // Level badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Text(
                                        item.level.isNotEmpty
                                            ? item.level
                                            : item.cycleEmojiLabel,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                          fontFamily: fontFamily,
                                        ),
                                      ),
                                    ),

                                    // Type badge (colored distinctly)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
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

                              // Forward Chevron Button
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: typeBg,
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
                          const SizedBox(height: 10),

                          // 2. Title
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: AppColors.textPrimary,
                              fontFamily: fontFamily,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 3. COMPLETE Exam Question Text (NON-TRUNCATED)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF8F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE8E0D4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.format_quote_rounded,
                                      size: 16,
                                      color: typeColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Exemple officiel d\'examen',
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
                                const SizedBox(height: 5),
                                Text(
                                  item.originalFr,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary,
                                    height: 1.45,
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 4. Bottom action link: Step count + "Voir la méthode ➔"
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: typeBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.steps.length} étapes décortiquées',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: typeColor,
                                    fontFamily: fontFamily,
                                  ),
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
                ],
              ),
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
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
