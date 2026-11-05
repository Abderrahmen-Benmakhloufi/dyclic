import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/reading_palette.dart';
import '../../core/tts/tts_service.dart';
import '../reading_settings/reading_settings_sheet.dart';
import 'models/instruction_model.dart';

/// Hallmark-Crafted Instruction Detail Screen:
/// - Question is the prominent HERO of the screen (larger than title)
/// - Question type only (level badge removed for focus)
/// - Distinctive pedagogical transition from Question to Answer/Method
/// - No celebration emoji on completion button
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
              // 1. Question Hero Card: Question stands out with maximum prominence
              _buildQuestionHeroCard(item, fontFamily, palette),

              // 2. Distinctive Transition Bridge from Question to Answer
              _buildTransitionBridge(item, fontFamily),

              // 3. Numbered Steps Sequence (The Answer / Method)
              ...item.steps.map((step) => _buildStepCard(step, fontFamily, palette)),

              const SizedBox(height: 24),

              // 4. Completion Action Button (without celebration emoji)
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text('J\'ai bien compris cette consigne'),
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
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  /// Question Hero Card:
  /// - Only Question Type badge (school level removed)
  /// - Listen Button is firmly INSIDE the card (top-right corner)
  /// - Question is the prominent center-piece
  Widget _buildQuestionHeroCard(
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
        border: Border.all(
          color: isSpeakingOriginal ? typeColor : palette.border,
          width: isSpeakingOriginal ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSpeakingOriginal
                ? typeColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Bar INSIDE the card: Question Type Badge + Listen Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Question Type Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: typeBg,
                  borderRadius: BorderRadius.circular(9),
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

              // Listen Button INSIDE the card
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _speakText(item.originalFr),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSpeakingOriginal
                        ? typeColor
                        : typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSpeakingOriginal
                          ? typeColor
                          : typeColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeakingOriginal
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                        size: 15,
                        color: isSpeakingOriginal ? Colors.white : typeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSpeakingOriginal ? 'Arrêter' : 'Écouter',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSpeakingOriginal ? Colors.white : typeColor,
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

          // 2. Title Context
          Text(
            item.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 12),

          // 3. Question Text (The star of the screen)
          Text(
            '« ${item.originalFr} »',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: palette.textPrimary,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 12),

          // 4. Official Exam Badge inside the card
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                color: typeColor,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                'Énoncé officiel d\'examen',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                  fontFamily: fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Distinctive Transition Bridge:
  /// Clearly separates the Question (Énoncé) from the Answer/Method (Les Étapes)
  Widget _buildTransitionBridge(InstructionItem item, String? fontFamily) {
    final typeColor = item.questionTypeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          // Visual Downward Arrow Indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_downward_rounded,
              color: typeColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),

          // Transition Banner: Clear Shift from Question to Method/Answer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: typeColor.withValues(alpha: 0.4),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: typeColor.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('💡', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comment répondre ? — La méthode pas à pas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                          fontFamily: fontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Que dois-tu faire ? Suis ces ${item.steps.length} étapes pour réussir :',
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
          // Step indicator: Character holding number for Primaire & Collège, circle for Lycée
          _buildStepIndicator(step, typeColor, widget.item.cycle),
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

  /// Builds step indicator:
  /// - Character holding number (1.png ... 5.png) for Primaire & Collège
  /// - Minimalist numbered circle for Lycée
  Widget _buildStepIndicator(
    InstructionStep step,
    Color typeColor,
    String cycle,
  ) {
    final useCharacter = (cycle.toLowerCase() == 'primaire' ||
            cycle.toLowerCase() == 'college') &&
        step.stepNumber >= 1 &&
        step.stepNumber <= 5;

    if (useCharacter) {
      return Container(
        width: 48,
        height: 50,
        margin: const EdgeInsets.only(top: 1),
        child: Image.asset(
          'assets/images/characters/${step.stepNumber}.png',
          width: 48,
          height: 50,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackCircle(step, typeColor),
        ),
      );
    }

    return _buildFallbackCircle(step, typeColor);
  }

  Widget _buildFallbackCircle(InstructionStep step, Color typeColor) {
    return Container(
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
    );
  }
}
