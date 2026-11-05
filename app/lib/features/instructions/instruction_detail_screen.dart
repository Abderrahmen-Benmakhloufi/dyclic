import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/reading_palette.dart';
import '../../core/tts/tts_service.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'models/instruction_model.dart';

/// Hallmark-Crafted Instruction Detail Screen:
/// - Editorial clarity and unnested surfaces (The Floor § 11, Craft § 3)
/// - Question type visual coding as a purposeful signal (Craft § 2)
/// - Relaxed typographic hierarchy with high legibility for young learners (Craft § 1)
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
        scrolledUnderElevation: 1,
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
              // 1. Unified Hero Question Card (Hallmark unnested surface)
              _buildUnifiedQuestionCard(item, fontFamily, palette),
              const SizedBox(height: 16),

              // 2. Goal Callout Banner ("Que dois-tu faire ?")
              _buildGoalBanner(fontFamily),
              const SizedBox(height: 18),

              // 3. Section Title
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: item.questionTypeColor,
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

              // 4. Numbered Steps Sequence
              ...item.steps.map((step) => _buildStepCard(step, fontFamily, palette)),

              const SizedBox(height: 20),

              // 5. Completion Action Button
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

  /// Hallmark Unified Question Card: Combines title, tags, and official question
  /// onto a single cohesive surface with zero nested boxes
  Widget _buildUnifiedQuestionCard(
    InstructionItem item,
    String? fontFamily,
    ReadingPalette palette,
  ) {
    final typeColor = item.questionTypeColor;
    final typeBg = item.questionTypeLightColor;
    final isSpeakingOriginal =
        _isPlaying && _currentlySpeakingText == item.originalFr;

    return Container(
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata Tags Row
          Row(
            children: [
              // Level Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
              const SizedBox(width: 8),

              // Question Type Badge (Quiet signal tint)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: typeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.questionTypeEmoji} ${item.questionTypeLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
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
              fontSize: 18.5,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: palette.textPrimary,
              fontFamily: fontFamily,
            ),
          ),
          if (item.domain.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Domaine : ${item.domain}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: fontFamily,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Hairline Seam
          Divider(height: 1, thickness: 1, color: palette.border),
          const SizedBox(height: 14),

          // Official Question Header + Audio Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: typeColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Énoncé officiel d\'examen',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ),
              // Listen button
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _speakText(item.originalFr),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSpeakingOriginal
                        ? typeColor
                        : palette.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSpeakingOriginal
                          ? typeColor
                          : palette.border,
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
                            : typeColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSpeakingOriginal ? 'Arrêter' : 'Écouter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSpeakingOriginal
                              ? Colors.white
                              : typeColor,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Question Text (Direct, accessible typography with 1.5 line height)
          Text(
            '« ${item.originalFr} »',
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: palette.textPrimary,
              fontFamily: fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalBanner(String? fontFamily) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.45)),
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
    final typeColor = widget.item.questionTypeColor;
    final isSpeakingThisStep =
        _isPlaying && _currentlySpeakingText == step.textFr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeakingThisStep
              ? typeColor
              : palette.border,
          width: isSpeakingThisStep ? 1.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSpeakingThisStep
                ? typeColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: isSpeakingThisStep ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle in question type signal color
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: typeColor,
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                    fontFamily: fontFamily,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.textFr,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: palette.textPrimary,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Speaker Button
          IconButton(
            icon: Icon(
              isSpeakingThisStep
                  ? Icons.stop_circle_rounded
                  : Icons.volume_up_outlined,
              size: 22,
              color: isSpeakingThisStep
                  ? typeColor
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
