import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'data/diagnostic_questions.dart';
import 'diagnostic_review_screen.dart';

// ---------------------------------------------------------------------------
// DiagnosticQuestionScreen — Screen 2: one question at a time, 24 total
// ---------------------------------------------------------------------------

class DiagnosticQuestionScreen extends StatefulWidget {
  const DiagnosticQuestionScreen({super.key});

  @override
  State<DiagnosticQuestionScreen> createState() =>
      _DiagnosticQuestionScreenState();
}

class _DiagnosticQuestionScreenState extends State<DiagnosticQuestionScreen> {
  int _currentIndex = 0;

  /// Maps questionId → raw int score
  final Map<String, int> _answers = {};

  DiagnosticQuestion get _current =>
      diagnosticQuestions[_currentIndex];

  bool get _isAnswered => _answers.containsKey(_current.id);

  double get _progress =>
      (_currentIndex + 1) / diagnosticQuestions.length;

  // ── navigation ─────────────────────────────────────────────────────────

  void _goBack() {
    if (_currentIndex == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _currentIndex--);
    }
  }

  void _goNext() {
    if (!_isAnswered) return;
    if (_currentIndex < diagnosticQuestions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DiagnosticReviewScreen(answers: _answers),
      ),
    );

    if (result == 'restart' && mounted) {
      setState(() {
        _answers.clear();
        _currentIndex = 0;
      });
    }
  }

  // ── answer handlers ─────────────────────────────────────────────────────

  void _onYesNo(bool isYes) {
    setState(() => _answers[_current.id] = yesNoScore(isYes));
  }

  void _onFrequency(int index) {
    setState(() => _answers[_current.id] = frequencyScore(index));
  }

  void _onMultiChoice(int index) {
    setState(() => _answers[_current.id] = multiChoiceScore(index));
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isLast = _currentIndex == diagnosticQuestions.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
            _buildAppBar(context),
            // ── Progress bar ─────────────────────────────────────────────
            _buildProgressBar(),
            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    _CategoryBadge(
                      emoji: _current.categoryEmoji,
                      name: _current.categoryName,
                    ),
                    const SizedBox(height: 16),
                    // Question text
                    Text(
                      _current.text,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.7,
                            letterSpacing: 0.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choisis la réponse qui te correspond le mieux.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Answer options
                    _buildAnswerOptions(),
                    const SizedBox(height: 100), // space for nav bar
                  ],
                ),
              ),
            ),
            // ── Navigation bar ───────────────────────────────────────────
            _buildNavBar(context, isLast),
          ],
        ),
      ),
    );
  }

  // ── sub-builders ────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.textPrimary),
            tooltip: 'Question précédente',
          ),
          Expanded(
            child: Text(
              'Évaluation',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          // Counter badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBorder.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_currentIndex + 1} / ${diagnosticQuestions.length}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 6,
      color: AppColors.background,
      child: LinearProgressIndicator(
        value: _progress,
        backgroundColor: AppColors.cardBorder,
        valueColor:
            const AlwaysStoppedAnimation<Color>(AppColors.primary),
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  Widget _buildAnswerOptions() {
    switch (_current.type) {
      case QuestionType.yesNo:
        return _buildYesNo();
      case QuestionType.frequency:
        return _buildFrequency();
      case QuestionType.multiChoice:
        return _buildMultiChoice();
    }
  }

  Widget _buildYesNo() {
    final current = _answers[_current.id];
    return Row(
      children: [
        Expanded(
          child: _YesNoCard(
            label: 'Oui',
            isSelected: current == 2,
            onTap: () => _onYesNo(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _YesNoCard(
            label: 'Non',
            isSelected: current == 0 && _answers.containsKey(_current.id),
            onTap: () => _onYesNo(false),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequency() {
    final current = _answers[_current.id];
    return Column(
      children: List.generate(frequencyLabels.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FrequencyOption(
            label: frequencyLabels[i],
            isSelected: current == i,
            onTap: () => _onFrequency(i),
          ),
        );
      }),
    );
  }

  Widget _buildMultiChoice() {
    final choices = _current.choices ?? [];
    // Score map for Q4: index 0→0, 1→1, 2→3, 3→4
    final scores = [0, 1, 3, 4];
    final current = _answers[_current.id];
    return Column(
      children: List.generate(choices.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FrequencyOption(
            label: choices[i],
            isSelected: current == scores[i],
            onTap: () => _onMultiChoice(i),
          ),
        );
      }),
    );
  }

  Widget _buildNavBar(BuildContext context, bool isLast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: const Border(
            top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          // Back button
          SizedBox(
            width: 52,
            height: 52,
            child: Material(
              color: const Color(0xFFEDE9F6),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _goBack,
                borderRadius: BorderRadius.circular(14),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Next / Finish button
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isAnswered ? _goNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(
                  isLast ? 'Terminer ✓' : 'Question suivante →',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CategoryBadge
// ---------------------------------------------------------------------------

class _CategoryBadge extends StatelessWidget {
  final String emoji;
  final String name;

  const _CategoryBadge({required this.emoji, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F6),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FrequencyOption — radio-style option card
// ---------------------------------------------------------------------------

class _FrequencyOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEDE9F6)
                : AppColors.surfaceCard,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Radio dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.cardBorder,
                    width: 2,
                  ),
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check,
                            size: 10, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _YesNoCard — large side-by-side choice card
// ---------------------------------------------------------------------------

class _YesNoCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _YesNoCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 120,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEDE9F6)
                : AppColors.surfaceCard,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Check / circle icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBorder.withValues(alpha: 0.5),
                ),
                child: Center(
                  child: Icon(
                    isSelected ? Icons.check : Icons.remove,
                    size: 20,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
