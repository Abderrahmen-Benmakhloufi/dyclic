import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'data/decoding_rules_data.dart';
import 'decoding_quiz_screen.dart';
import 'models/decoding_rule_model.dart';

class DecodingScreen extends ConsumerStatefulWidget {
  const DecodingScreen({super.key});

  @override
  ConsumerState<DecodingScreen> createState() => _DecodingScreenState();
}

class _DecodingScreenState extends ConsumerState<DecodingScreen> {
  String? _selectedFilterId;
  String? _currentlySpeakingWord;
  Timer? _speakingTimer;
  late final TtsService _ttsService;

  @override
  void initState() {
    super.initState();
    _ttsService = ref.read(ttsServiceProvider);
  }

  @override
  void dispose() {
    _speakingTimer?.cancel();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _playWordAudio(String word) async {
    _speakingTimer?.cancel();
    await _ttsService.stop();
    if (!mounted) return;
    setState(() => _currentlySpeakingWord = word);
    await _ttsService.speakWord(word);
    if (mounted) {
      _speakingTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && _currentlySpeakingWord == word) {
          setState(() => _currentlySpeakingWord = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);

    final filteredRules = _selectedFilterId == null
        ? decodingRulesCatalog
        : decodingRulesCatalog
            .where((rule) => rule.id == _selectedFilterId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Row(
          children: [
            Hero(
              tag: 'hero_${AppUiAssets.featDecoding}',
              child: AppAssetIcon(
                assetPath: AppUiAssets.featDecoding,
                size: 26,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aide au décodage',
                overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quiz Banner / Card prominent
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8E24AA).withAlpha(45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DecodingQuizScreen(ruleId: _selectedFilterId),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quiz d\'écoute et décodage',
                                  style: TextStyle(
                                    fontFamily: settings.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Entraîne-toi à reconnaître les sons et les lettres',
                                  style: TextStyle(
                                    fontFamily: settings.fontFamily,
                                    fontSize: 12.5,
                                    color: Colors.white.withAlpha(230),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Jouer',
                                  style: TextStyle(
                                    color: Color(0xFF8E24AA),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.play_arrow_rounded,
                                  size: 16,
                                  color: Color(0xFF8E24AA),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Filter Selector Chips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Toutes',
                      isSelected: _selectedFilterId == null,
                      onTap: () => setState(() => _selectedFilterId = null),
                    ),
                    const SizedBox(width: 8),
                    ...decodingRulesCatalog.map((rule) {
                      final isSelected = _selectedFilterId == rule.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          label: rule.letter,
                          isSelected: isSelected,
                          onTap: () =>
                              setState(() => _selectedFilterId = rule.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Rules Content List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: filteredRules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildRuleCard(
                    context,
                    filteredRules[index],
                    settings.fontFamily,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: ValueKey('filter_$label'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRuleCard(
    BuildContext context,
    DecodingRule rule,
    String fontFamily,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rule Header
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  rule.letter,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.titleFr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overview Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              rule.overviewFr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: fontFamily,
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subrules and Example Words
          ...rule.subRules.map((subRule) => _buildSubRuleSection(
                context,
                subRule,
                fontFamily,
              )),
        ],
      ),
    );
  }

  Widget _buildSubRuleSection(
    BuildContext context,
    DecodingSubRule subRule,
    String fontFamily,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sound badge & condition
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subRule.soundIpa,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subRule.conditionFr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: fontFamily,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Word Examples
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: subRule.examples
                .map((example) => _buildWordPill(context, example, fontFamily))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWordPill(
    BuildContext context,
    ExampleWord example,
    String fontFamily,
  ) {
    final isSpeaking = _currentlySpeakingWord == example.word;
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      key: ValueKey('word_${example.word}'),
      onTap: () => _playWordAudio(example.word),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: screenWidth > 80 ? screenWidth - 72 : 260,
        ),
        decoration: BoxDecoration(
          color: isSpeaking
              ? AppColors.primary.withValues(alpha: 0.18)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSpeaking
                ? AppColors.primary
                : const Color(0xFFE2E8F0),
            width: isSpeaking ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHighlightedWordSpans(example, fontFamily),
                const SizedBox(width: 8),
                Icon(
                  isSpeaking
                      ? Icons.volume_up_rounded
                      : Icons.volume_down_rounded,
                  size: 18,
                  color: isSpeaking ? AppColors.primary : AppColors.textSecondary,
                ),
              ],
            ),
            if (example.note != null) ...[
              const SizedBox(height: 3),
              Text(
                example.note!,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedWordSpans(ExampleWord example, String fontFamily) {
    final word = example.word;
    final highlightSet = example.highlightIndices.toSet();

    final spans = <TextSpan>[];
    for (int i = 0; i < word.length; i++) {
      final isHighlighted = highlightSet.contains(i);
      spans.add(
        TextSpan(
          text: word[i],
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 17,
            fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w600,
            color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
            decoration:
                isHighlighted ? TextDecoration.underline : TextDecoration.none,
            decorationColor: AppColors.primary.withValues(alpha: 0.5),
            decorationThickness: 2,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}
