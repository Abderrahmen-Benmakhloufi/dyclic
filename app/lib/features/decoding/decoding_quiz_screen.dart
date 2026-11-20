import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../../core/widgets/app_audio_pulse_aura.dart';
import 'data/decoding_quiz_data.dart';
import 'models/decoding_quiz_model.dart';

// ─── Entry Point ─────────────────────────────────────────────────────────────

class DecodingQuizScreen extends ConsumerStatefulWidget {
  /// If provided, the quiz is restricted to questions from this rule.
  final String? ruleId;

  /// Pre-selected difficulty.  When null the difficulty-selector intro shows.
  final QuizDifficulty? initialDifficulty;

  const DecodingQuizScreen({
    super.key,
    this.ruleId,
    this.initialDifficulty,
  });

  @override
  ConsumerState<DecodingQuizScreen> createState() => _DecodingQuizScreenState();
}

// ─── State machine ───────────────────────────────────────────────────────────

enum _QuizPhase { selectDifficulty, question, result }

class _DecodingQuizScreenState extends ConsumerState<DecodingQuizScreen> {
  late final TtsService _ttsService;

  _QuizPhase _phase = _QuizPhase.selectDifficulty;
  QuizDifficulty _difficulty = QuizDifficulty.decouverte;

  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;

  // Per-question answer state
  int? _selectedChoiceIndex;
  bool _answered = false;

  // Session tracking
  int _correctCount = 0;
  final List<bool> _answerHistory = [];
  // Store word+hint per question for the results recap
  final List<_AnswerRecord> _records = [];

  Timer? _autoPlayTimer;
  bool _isSpeaking = false;

  // ── lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ttsService = ref.read(ttsServiceProvider);
    if (widget.initialDifficulty != null) {
      _difficulty = widget.initialDifficulty!;
      _startQuiz();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _ttsService.stop();
    super.dispose();
  }

  // ── quiz flow ───────────────────────────────────────────────────────────────

  void _startQuiz() {
    final pool = widget.ruleId != null
        ? _buildPoolForRule(widget.ruleId!, _difficulty)
        : _buildPoolAll(_difficulty);

    setState(() {
      _questions = pool;
      _currentIndex = 0;
      _selectedChoiceIndex = null;
      _answered = false;
      _correctCount = 0;
      _answerHistory.clear();
      _records.clear();
      _phase = _QuizPhase.question;
    });

    _scheduleAutoPlay();
  }

  /// Builds question pool for a specific rule based on difficulty tier.
  List<QuizQuestion> _buildPoolForRule(String ruleId, QuizDifficulty diff) {
    final all = getQuestionsForRule(ruleId);
    return _filterByTier(all, diff)..shuffle();
  }

  /// Builds a mixed question pool from all rules based on difficulty tier.
  List<QuizQuestion> _buildPoolAll(QuizDifficulty diff) {
    final all = List<QuizQuestion>.from(kDecodingQuizBank);
    return _filterByTier(all, diff)..shuffle();
  }

  /// Découverte → only Découverte questions.
  /// Discrimination → Découverte + Discrimination.
  /// Défi → all difficulties.
  List<QuizQuestion> _filterByTier(
      List<QuizQuestion> src, QuizDifficulty diff) {
    switch (diff) {
      case QuizDifficulty.decouverte:
        return src
            .where((q) => q.difficulty == QuizDifficulty.decouverte)
            .toList();
      case QuizDifficulty.discrimination:
        return src
            .where((q) =>
                q.difficulty == QuizDifficulty.decouverte ||
                q.difficulty == QuizDifficulty.discrimination)
            .toList();
      case QuizDifficulty.defi:
        return src.toList();
    }
  }

  void _scheduleAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _phase == _QuizPhase.question) {
        _speak(_questions[_currentIndex].word);
      }
    });
  }

  Future<void> _speak(String word) async {
    if (_isSpeaking) return;
    setState(() => _isSpeaking = true);
    await _ttsService.speakWord(word);
    if (mounted) setState(() => _isSpeaking = false);
  }

  void _onChoiceTap(int choiceIndex) {
    if (_answered) return;
    final q = _questions[_currentIndex];
    final isCorrect = choiceIndex == q.correctChoiceIndex;

    if (!isCorrect) {
      SupabaseService.recordMistake(
        category: 'decoding',
        mistakeType: 'confusion_${q.testedLetter}',
        contextText: q.word,
        userInput: q.choices[choiceIndex],
        expectedInput: q.correctChoice,
      );
    }

    setState(() {
      _selectedChoiceIndex = choiceIndex;
      _answered = true;
      if (isCorrect) _correctCount++;
      _answerHistory.add(isCorrect);
      _records.add(_AnswerRecord(
        word: q.word,
        testedLetter: q.testedLetter,
        hint: q.hintFr,
        correct: isCorrect,
        chosenLabel: q.choices[choiceIndex],
        correctLabel: q.correctChoice,
      ));
    });
  }

  void _onNext() {
    if (_currentIndex + 1 >= _questions.length) {
      _finishQuiz();
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedChoiceIndex = null;
      _answered = false;
    });
    _scheduleAutoPlay();
  }

  void _finishQuiz() {
    setState(() => _phase = _QuizPhase.result);
    _ttsService.stop();
    SupabaseService.saveQuizResult(
      quizType: 'decoding',
      difficulty: _difficulty.name,
      score: _correctCount,
      totalQuestions: _questions.length,
    );
  }

  void _restart() {
    setState(() => _phase = _QuizPhase.selectDifficulty);
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readingSettingsProvider);
    final fontFamily = settings.fontFamily;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz d\'écoute'),
        centerTitle: false,
        leading: BackButton(
          onPressed: () {
            if (_phase == _QuizPhase.question || _phase == _QuizPhase.result) {
              _restart();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: switch (_phase) {
            _QuizPhase.selectDifficulty =>
              _DifficultySelector(
                key: const ValueKey('difficulty'),
                fontFamily: fontFamily,
                onSelected: (diff) {
                  setState(() => _difficulty = diff);
                  _startQuiz();
                },
              ),
            _QuizPhase.question => _QuestionView(
                key: ValueKey('q_$_currentIndex'),
                question: _questions[_currentIndex],
                questionNumber: _currentIndex + 1,
                totalQuestions: _questions.length,
                selectedChoiceIndex: _selectedChoiceIndex,
                answered: _answered,
                fontFamily: fontFamily,
                isSpeaking: _isSpeaking,
                onSpeak: () => _speak(_questions[_currentIndex].word),
                onChoiceTap: _onChoiceTap,
                onNext: _answered ? _onNext : null,
              ),
            _QuizPhase.result => _ResultView(
                key: const ValueKey('result'),
                result: QuizSessionResult(
                  totalQuestions: _questions.length,
                  correctAnswers: _correctCount,
                  answerHistory: List.unmodifiable(_answerHistory),
                ),
                records: List.unmodifiable(_records),
                fontFamily: fontFamily,
                onRestart: _restart,
                onExit: () => Navigator.of(context).pop(),
              ),
          },
        ),
      ),
    );
  }
}

// ─── Difficulty Selector Screen ───────────────────────────────────────────────

class _DifficultySelector extends StatelessWidget {
  final String fontFamily;
  final void Function(QuizDifficulty) onSelected;

  const _DifficultySelector({
    super.key,
    required this.fontFamily,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header illustration
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const AppAssetIcon(
                  assetPath: AppUiAssets.quizAudioHeadset,
                  size: 68,
                  fallbackEmoji: '🎧',
                ),
                const SizedBox(height: 12),
                Text(
                  'Quiz d\'écoute',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Écoute le mot et identifie le bon son',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 15,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Choisis un niveau',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...QuizDifficulty.values.map((diff) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DifficultyCard(
                  difficulty: diff,
                  fontFamily: fontFamily,
                  onTap: () => onSelected(diff),
                ),
              )),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final QuizDifficulty difficulty;
  final String fontFamily;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.fontFamily,
    required this.onTap,
  });

  Color get _accentColor {
    switch (difficulty) {
      case QuizDifficulty.decouverte:
        return const Color(0xFF22C55E); // green
      case QuizDifficulty.discrimination:
        return const Color(0xFFF59E0B); // amber
      case QuizDifficulty.defi:
        return const Color(0xFFEF4444); // red
    }
  }

  Widget _buildDifficultyIcon(QuizDifficulty diff) {
    switch (diff) {
      case QuizDifficulty.decouverte:
        return const AppAssetIcon(
          assetPath: AppUiAssets.sproutDiscovery,
          size: 30,
          fallbackEmoji: '🌱',
        );
      case QuizDifficulty.defi:
        return const AppAssetIcon(
          assetPath: AppUiAssets.trophyAchievement,
          size: 30,
          fallbackEmoji: '🏆',
        );
      case QuizDifficulty.discrimination:
        return const Text('🎯', style: TextStyle(fontSize: 26));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x07000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: _buildDifficultyIcon(difficulty),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.label.split(' ').sublist(1).join(' '),
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    difficulty.description,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _accentColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Question View ───────────────────────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  final QuizQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final int? selectedChoiceIndex;
  final bool answered;
  final String fontFamily;
  final bool isSpeaking;
  final VoidCallback onSpeak;
  final void Function(int) onChoiceTap;
  final VoidCallback? onNext;

  const _QuestionView({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selectedChoiceIndex,
    required this.answered,
    required this.fontFamily,
    required this.isSpeaking,
    required this.onSpeak,
    required this.onChoiceTap,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final progress = questionNumber / totalQuestions;

    return Column(
      children: [
        // ── Progress bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question $questionNumber / $totalQuestions',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    question.difficulty.label,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedVal, _) {
                    return LinearProgressIndicator(
                      value: animatedVal,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Main scrollable content ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Word card
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Quel son fait la lettre en couleur ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Highlighted word
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: _buildHighlightedSpans(fontFamily),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // TTS button
                      _SpeakButton(
                        isSpeaking: isSpeaking,
                        onTap: onSpeak,
                        fontFamily: fontFamily,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Instruction label
                Text(
                  'Choisis le bon son :',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Choice buttons
                ...List.generate(question.choices.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ChoiceButton(
                      label: question.choices[i],
                      index: i,
                      selectedIndex: selectedChoiceIndex,
                      correctIndex: question.correctChoiceIndex,
                      answered: answered,
                      fontFamily: fontFamily,
                      onTap: () => onChoiceTap(i),
                    ),
                  );
                }),

                // Hint after wrong answer
                if (answered &&
                    selectedChoiceIndex != null &&
                    selectedChoiceIndex != question.correctChoiceIndex)
                  _HintBanner(hint: question.hintFr, fontFamily: fontFamily),

                const SizedBox(height: 20),

                // Next button
                if (onNext != null)
                  _NextButton(
                    isLast: questionNumber == totalQuestions,
                    fontFamily: fontFamily,
                    onTap: onNext!,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildHighlightedSpans(String fontFamily) {
    final chars = question.word.split('');
    final spans = <TextSpan>[];

    for (int i = 0; i < chars.length; i++) {
      final isHighlighted = question.testedIndices.contains(i);
      spans.add(TextSpan(
        text: chars[i],
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 46,
          fontWeight: FontWeight.bold,
          color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
          backgroundColor: isHighlighted
              ? AppColors.primary.withValues(alpha: 0.10)
              : null,
          letterSpacing: 2,
        ),
      ));
    }

    return spans;
  }
}

// ─── Speak Button ─────────────────────────────────────────────────────────────

class _SpeakButton extends StatelessWidget {
  final bool isSpeaking;
  final VoidCallback onTap;
  final String fontFamily;

  const _SpeakButton({
    required this.isSpeaking,
    required this.onTap,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return AppAudioPulseAura(
      isPulsing: isSpeaking,
      maxScale: 1.03,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton.icon(
          onPressed: isSpeaking ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSpeaking ? const Color(0xFF64748B) : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: isSpeaking ? 0 : 2,
          ),
          icon: Icon(
            isSpeaking ? Icons.volume_up_rounded : Icons.hearing_rounded,
            size: 22,
          ),
          label: Text(
            isSpeaking ? 'En cours…' : 'Écouter le mot',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Choice Button ───────────────────────────────────────────────────────────

class _ChoiceButton extends StatelessWidget {
  final String label;
  final int index;
  final int? selectedIndex;
  final int correctIndex;
  final bool answered;
  final String fontFamily;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.answered,
    required this.fontFamily,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final isCorrect = index == correctIndex;

    Color borderColor = AppColors.cardBorder;
    Color bgColor = AppColors.surfaceCard;
    Color textColor = AppColors.textPrimary;
    IconData? trailingIcon;

    if (answered) {
      if (isCorrect) {
        borderColor = AppColors.successGreen;
        bgColor = AppColors.successGreen.withValues(alpha: 0.08);
        textColor = AppColors.successGreen;
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected) {
        borderColor = AppColors.errorRed;
        bgColor = AppColors.errorRed.withValues(alpha: 0.08);
        textColor = AppColors.errorRed;
        trailingIcon = Icons.cancel_rounded;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      child: InkWell(
        onTap: answered ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.6),
          ),
          child: Row(
            children: [
              // Index badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: answered && isCorrect
                      ? AppColors.successGreen.withValues(alpha: 0.15)
                      : answered && isSelected
                          ? AppColors.errorRed.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: answered && isCorrect
                        ? AppColors.successGreen
                        : answered && isSelected
                            ? AppColors.errorRed
                            : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 15,
                    fontWeight:
                        answered && (isCorrect || isSelected)
                            ? FontWeight.bold
                            : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, color: textColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hint Banner ─────────────────────────────────────────────────────────────

class _HintBanner extends StatelessWidget {
  final String hint;
  final String fontFamily;

  const _HintBanner({required this.hint, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFBBF24), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 13,
                color: const Color(0xFF78350F),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Next Button ─────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final bool isLast;
  final String fontFamily;
  final VoidCallback onTap;

  const _NextButton({
    required this.isLast,
    required this.fontFamily,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        icon: Icon(
          isLast ? Icons.flag_rounded : Icons.navigate_next_rounded,
          size: 22,
        ),
        label: Text(
          isLast ? 'Voir les résultats' : 'Question suivante',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── Result View ─────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final QuizSessionResult result;
  final List<_AnswerRecord> records;
  final String fontFamily;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _ResultView({
    super.key,
    required this.result,
    required this.records,
    required this.fontFamily,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Score card ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.80),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.2, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: result.medal == '🏆'
                      ? const AppAssetIcon(
                          assetPath: AppUiAssets.trophyAchievement,
                          size: 64,
                          fallbackEmoji: '🏆',
                        )
                      : Text(
                          result.medal,
                          style: const TextStyle(fontSize: 56),
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${result.correctAnswers} / ${result.totalQuestions}',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  result.feedbackFr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.90),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Stats row ──
          Row(
            children: [
              _StatChip(
                icon: Icons.check_circle_rounded,
                label: '${result.correctAnswers} corrects',
                color: AppColors.successGreen,
                fontFamily: fontFamily,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.cancel_rounded,
                label: '${result.wrongAnswers} erreurs',
                color: AppColors.errorRed,
                fontFamily: fontFamily,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Per-question recap ──
          Text(
            'Récapitulatif',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...records.asMap().entries.map((entry) {
            final i = entry.key;
            final rec = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecapCard(
                number: i + 1,
                record: rec,
                fontFamily: fontFamily,
              ),
            );
          }),

          const SizedBox(height: 24),

          // ── Action buttons ──
          ElevatedButton.icon(
            onPressed: onRestart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            icon: const Icon(Icons.replay_rounded, size: 22),
            label: Text(
              'Recommencer',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onExit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.cardBorder, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            label: Text(
              'Retour au décodage',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String fontFamily;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapCard extends StatelessWidget {
  final int number;
  final _AnswerRecord record;
  final String fontFamily;

  const _RecapCard({
    required this.number,
    required this.record,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        record.correct ? AppColors.successGreen : AppColors.errorRed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number circle
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      record.word,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.testedLetter,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      record.correct
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: color,
                      size: 18,
                    ),
                  ],
                ),
                if (!record.correct) ...[
                  const SizedBox(height: 4),
                  Text(
                    '✓ ${record.correctLabel}',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.hint,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Internal data record ────────────────────────────────────────────────────

class _AnswerRecord {
  final String word;
  final String testedLetter;
  final String hint;
  final bool correct;
  final String chosenLabel;
  final String correctLabel;

  const _AnswerRecord({
    required this.word,
    required this.testedLetter,
    required this.hint,
    required this.correct,
    required this.chosenLabel,
    required this.correctLabel,
  });
}
