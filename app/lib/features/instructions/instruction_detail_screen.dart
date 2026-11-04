import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/reading_palette.dart';
import '../../core/tts/tts_service.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'models/instruction_model.dart';

/// Dedicated screen that shows the complete step-by-step deconstruction
/// of an exam instruction without visual clutter or accordion toggles.
class InstructionDetailScreen extends ConsumerStatefulWidget {
  final InstructionItem item;

  const InstructionDetailScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<InstructionDetailScreen> createState() =>
      _InstructionDetailScreenState();
}

class _InstructionDetailScreenState
    extends ConsumerState<InstructionDetailScreen> {
  late final TtsService _ttsService;
  bool _isPlaying = false;
  String? _currentlySpeakingText;

  @override
  void initState() {
    super.initState();
    _ttsService = ref.read(ttsServiceProvider);
    _ttsService.isPlayingNotifier.addListener(_onTtsStateChanged);
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final palette = settings.contrastPreset.palette;
    final fontFamily = settings.fontFamily;
    final item = widget.item;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: palette.textPrimary,
          ),
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Explication pas à pas',
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
              Icons.tune_rounded,
              color: palette.textPrimary,
            ),
            tooltip: 'Réglages de lecture',
            onPressed: () => ReadingSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Badges & Title
              _buildHeaderSection(item, fontFamily, palette),
              const SizedBox(height: 16),

              // 2. Official Exam Question Box
              _buildOfficialQuestionCard(item, fontFamily, palette),
              const SizedBox(height: 18),

              // 3. Goal Callout Banner ("Que dois-tu faire ?")
              _buildGoalBanner(fontFamily),
              const SizedBox(height: 18),

              // 4. Section Title
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Les étapes pour réussir (${item.steps.length} étapes) 📋',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Numbered Steps List
              ...item.steps.map((step) => _buildStepCard(step, fontFamily, palette)),

              const SizedBox(height: 20),

              // 6. Understood / Back Action Button
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text('J\'ai bien compris cette consigne ! 🎉'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  textStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontFamily,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    InstructionItem item,
    String? fontFamily,
    ReadingPalette palette,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges Wrap
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // ID
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.id,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: fontFamily,
                  ),
                ),
              ),

              // Level / Cycle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  item.level.isNotEmpty ? item.level : item.cycleEmojiLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                    fontFamily: fontFamily,
                  ),
                ),
              ),

              // Question Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: item.questionTypeLightColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.questionTypeEmoji} ${item.questionTypeLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.questionTypeColor,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            item.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.35,
              color: palette.textPrimary,
              fontFamily: fontFamily,
            ),
          ),
          if (item.domain.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Domaine : ${item.domain}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: fontFamily,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfficialQuestionCard(
    InstructionItem item,
    String? fontFamily,
    ReadingPalette palette,
  ) {
    final isSpeakingOriginal =
        _isPlaying && _currentlySpeakingText == item.originalFr;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E0D4), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Énoncé officiel d\'examen',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontFamily: fontFamily,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Listen button
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _speakText(item.originalFr),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSpeakingOriginal
                        ? AppColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSpeakingOriginal
                          ? AppColors.primary
                          : const Color(0xFFDED6C8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeakingOriginal
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                        size: 16,
                        color: isSpeakingOriginal
                            ? Colors.white
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSpeakingOriginal ? 'Arrêter' : 'Écouter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSpeakingOriginal
                              ? Colors.white
                              : AppColors.primary,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E0D4)),
            ),
            child: Text(
              item.originalFr,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textPrimary,
                fontFamily: fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalBanner(String? fontFamily) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.help_outline_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Que dois-tu faire ?',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: fontFamily,
                  ),
                ),
                Text(
                  'Suis les étapes ci-dessous une à une pour réussir.',
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

  Widget _buildStepCard(
    InstructionStep step,
    String? fontFamily,
    ReadingPalette palette,
  ) {
    final isSpeakingThisStep =
        _isPlaying && _currentlySpeakingText == step.textFr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSpeakingThisStep
              ? AppColors.primary
              : palette.border,
          width: isSpeakingThisStep ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSpeakingThisStep
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: isSpeakingThisStep ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: widget.item.questionTypeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Étape ${step.stepNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.item.questionTypeColor,
                    fontFamily: fontFamily,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.textFr,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.48,
                    color: palette.textPrimary,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Mini speaker button
          IconButton(
            icon: Icon(
              isSpeakingThisStep
                  ? Icons.stop_circle_rounded
                  : Icons.volume_up_outlined,
              size: 22,
              color: isSpeakingThisStep
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            tooltip: 'Écouter cette étape',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => _speakText(step.textFr),
          ),
        ],
      ),
    );
  }
}
