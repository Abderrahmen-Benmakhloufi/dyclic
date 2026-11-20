import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/app_asset_icon.dart';
import '../../core/widgets/app_audio_pulse_aura.dart';
import '../decoding/decoding_screen.dart';
import '../diagnostics/tts_diagnostics_screen.dart';
import '../reading_settings/reading_settings_sheet.dart';

class TtsScreen extends ConsumerStatefulWidget {
  const TtsScreen({super.key});

  @override
  ConsumerState<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends ConsumerState<TtsScreen> {
  static const _kPrefKey = 'tts_last_text';

  final TextEditingController _controller = TextEditingController();
  late final TtsService _ttsService;
  bool _isPlaying = false;
  int? _speakingWordIndex;
  Timer? _wordSpeakingTimer;
  Timer? _sequenceTimer;
  StreamSubscription<TtsSentenceEvent>? _sentenceStartSub;
  StreamSubscription<int>? _sentenceDoneSub;
  Map<int, List<_TtsWordItem>> _sentenceWordMap = {};
  final List<TapGestureRecognizer> _wordRecognizers = [];

  @override
  void initState() {
    super.initState();
    _ttsService = ref.read(ttsServiceProvider);
    _ttsService.isPlayingNotifier.addListener(_onTtsChanged);
    _sentenceStartSub =
        _ttsService.sentenceStartStream.listen(_onSentenceStart);
    _sentenceDoneSub = _ttsService.sentenceDoneStream.listen(_onSentenceDone);
    _loadLastText();
  }

  /// Restores the last typed / pasted text from local storage.
  Future<void> _loadLastText() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kPrefKey) ?? '';
    if (saved.isNotEmpty && mounted) {
      _controller.text = saved;
      setState(() {});
    }
  }

  /// Persists the current text so it survives app restarts.
  Future<void> _saveText(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (text.isEmpty) {
      await prefs.remove(_kPrefKey);
    } else {
      await prefs.setString(_kPrefKey, text);
    }
  }

  void _onTtsChanged() {
    if (mounted) {
      final playing = _ttsService.isPlayingNotifier.value;
      setState(() {
        _isPlaying = playing;
        if (!playing) {
          _sequenceTimer?.cancel();
          _wordSpeakingTimer?.cancel();
          _speakingWordIndex = null;
        }
      });
    }
  }

  void _disposeWordRecognizers() {
    for (final r in _wordRecognizers) {
      r.dispose();
    }
    _wordRecognizers.clear();
  }

  @override
  void dispose() {
    _sentenceStartSub?.cancel();
    _sentenceDoneSub?.cancel();
    _sequenceTimer?.cancel();
    _wordSpeakingTimer?.cancel();
    _disposeWordRecognizers();
    _ttsService.isPlayingNotifier.removeListener(_onTtsChanged);
    _saveText(_controller.text.trim());
    _controller.dispose();
    super.dispose();
  }

  void _onSentenceStart(TtsSentenceEvent event) {
    if (!mounted || !_isPlaying) return;

    final words = _sentenceWordMap[event.sentenceIndex];
    if (words == null || words.isEmpty) {
      if (mounted) {
        setState(() {
          _speakingWordIndex = null;
        });
      }
      return;
    }

    _startSentenceWordSequence(words, event.durationMs);
  }

  void _onSentenceDone(int sentenceIndex) {
    if (!mounted) return;
    _sequenceTimer?.cancel();
    setState(() {
      _speakingWordIndex = null;
    });
  }

  /// Estimates the base duration of a French word. Inter-sentence pause is handled
  /// naturally by waiting for native sentence start events.
  int _estimateWordDurationMs(String word, String trailingPunctuation) {
    int baseMs;
    final len = word.length;
    if (len <= 3) {
      baseMs = 240;
    } else if (len <= 5) {
      baseMs = 320;
    } else if (len <= 7) {
      baseMs = 400;
    } else if (len <= 9) {
      baseMs = 480;
    } else {
      baseMs = 480 + (len - 9) * 45;
    }

    if (trailingPunctuation.contains(',') ||
        trailingPunctuation.contains(';') ||
        trailingPunctuation.contains(':')) {
      baseMs += 180;
    }

    return baseMs;
  }

  /// Extracts sentences and maps each word token to its sentence index and duration metrics.
  ({
    List<String> sentences,
    List<_TtsWordItem> words,
    Map<int, List<_TtsWordItem>> sentenceWordMap,
  }) _extractSentenceAndWordData(String text) {
    final rawSentences = <String>[];
    final sentenceRegex =
        RegExp(r'[^.!?;\n]+(?:[.!?;\n]+|$)', multiLine: true);
    for (final m in sentenceRegex.allMatches(text)) {
      final s = m.group(0)?.trim() ?? '';
      if (s.isNotEmpty) {
        rawSentences.add(s);
      }
    }
    if (rawSentences.isEmpty && text.trim().isNotEmpty) {
      rawSentences.add(text.trim());
    }

    final allWords = <_TtsWordItem>[];
    final sentenceWordMap = <int, List<_TtsWordItem>>{};

    final wordPattern =
        RegExp(r"([a-zA-ZÀ-ÿ]+(?:['’][a-zA-ZÀ-ÿ]+)?|[^a-zA-ZÀ-ÿ]+)");
    final matches = wordPattern.allMatches(text).toList();

    int currentSentenceIdx = 0;
    int currentSentenceEndOffset = rawSentences.isNotEmpty
        ? (text.indexOf(rawSentences[0]) + rawSentences[0].length)
        : text.length;

    int globalWordIdx = 0;
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final token = match.group(0) ?? '';
      if (RegExp(r"[a-zA-ZÀ-ÿ]").hasMatch(token)) {
        while (currentSentenceIdx < rawSentences.length - 1 &&
            match.start >= currentSentenceEndOffset) {
          currentSentenceIdx++;
          final nextSentence = rawSentences[currentSentenceIdx];
          final nextIdx = text.indexOf(nextSentence, match.start);
          currentSentenceEndOffset =
              (nextIdx >= 0 ? nextIdx : match.start) + nextSentence.length;
        }

        String trailing = '';
        if (i + 1 < matches.length) {
          final nextToken = matches[i + 1].group(0) ?? '';
          if (!RegExp(r"[a-zA-ZÀ-ÿ]").hasMatch(nextToken)) {
            trailing = nextToken;
          }
        }

        final duration = _estimateWordDurationMs(token, trailing);
        final item = _TtsWordItem(
          index: globalWordIdx++,
          word: token,
          durationMs: duration,
          sentenceIndex: currentSentenceIdx,
        );
        allWords.add(item);
        sentenceWordMap.putIfAbsent(currentSentenceIdx, () => []).add(item);
      }
    }

    return (
      sentences: rawSentences,
      words: allWords,
      sentenceWordMap: sentenceWordMap,
    );
  }

  /// Highlights words sequentially within the currently spoken sentence.
  void _startSentenceWordSequence(
      List<_TtsWordItem> words, int totalDurationMs) {
    _sequenceTimer?.cancel();

    final List<int> durations = [];
    if (totalDurationMs > 0 && words.isNotEmpty) {
      final totalWeight = words.fold<int>(0, (sum, w) => sum + w.durationMs);
      for (final w in words) {
        final dur = totalWeight > 0
            ? ((totalDurationMs * w.durationMs) / totalWeight).round()
            : (totalDurationMs / words.length).round();
        durations.add(dur.clamp(160, 2500));
      }
    } else {
      for (final w in words) {
        durations.add(w.durationMs);
      }
    }

    int step = 0;
    void stepNext() {
      if (!mounted || !_isPlaying || step >= words.length) {
        if (mounted) {
          setState(() {
            _speakingWordIndex = null;
          });
        }
        return;
      }

      final item = words[step];
      final dur = durations[step];
      setState(() {
        _speakingWordIndex = item.index;
      });

      step++;
      _sequenceTimer = Timer(Duration(milliseconds: dur), () {
        stepNext();
      });
    }

    stepNext();
  }

  Future<void> _speakSingleWord(String word, int wordIndex) async {
    final clean =
        word.replaceAll(RegExp(r"[^\p{L}\p{M}\-']", unicode: true), '').trim();
    if (clean.isEmpty) return;

    _sequenceTimer?.cancel();
    _wordSpeakingTimer?.cancel();
    await _ttsService.stop();

    if (!mounted) return;
    setState(() {
      _speakingWordIndex = wordIndex;
    });

    try {
      await _ttsService.speakWord(clean);
    } catch (_) {}

    if (mounted) {
      _wordSpeakingTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && _speakingWordIndex == wordIndex) {
          setState(() {
            _speakingWordIndex = null;
          });
        }
      });
    }
  }

  Future<void> _toggleSpeak() async {
    _sequenceTimer?.cancel();
    _wordSpeakingTimer?.cancel();

    if (_isPlaying) {
      setState(() {
        _isPlaying = false;
        _speakingWordIndex = null;
      });
      await _ttsService.stop();
    } else {
      final text = _controller.text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Écris ou colle d’abord un texte à écouter.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final data = _extractSentenceAndWordData(text);
      _sentenceWordMap = data.sentenceWordMap;

      setState(() {
        _isPlaying = true;
        _speakingWordIndex = null; // Do not highlight prematurely before speech starts
      });

      await _ttsService.speakText(text, sentences: data.sentences);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(readingSettingsProvider);

    return Scaffold(
      // يرفع الـ body تلقائياً عند ظهور الكيبورد
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: false,
        title: const Row(
          children: [
            Hero(
              tag: 'hero_${AppUiAssets.featTts}',
              child: AppAssetIcon(
                assetPath: AppUiAssets.featTts,
                size: 26,
              ),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Écouter le texte',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.spellcheck_rounded),
            tooltip: 'Aide au décodage',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DecodingScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Réglages de lecture',
            onPressed: () => ReadingSettingsSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.medical_services_outlined),
            tooltip: 'Diagnostic vocal',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TtsDiagnosticsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          // يمنع اختفاء المحتوى خلف الكيبورد
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    AppAudioPulseAura(
                      isPulsing: _isPlaying || _speakingWordIndex != null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🔊', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Synthèse Vocale Directe',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Écoute n’importe quel texte à voix haute en français.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons (Coller, Effacer)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null && data!.text!.isNotEmpty) {
                          _controller.text = data.text!;
                          _saveText(data.text!.trim());
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.content_paste_rounded, size: 20),
                      label: const Text('Coller'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        _controller.clear();
                        _saveText('');
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      label: const Text('Effacer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Text Field or Interactive Clickable Words Mode
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      minLines: 5,
                      maxLines: 10,
                      // يرفع الحقل فوق الكيبورد عند التركيز عليه
                      scrollPadding: const EdgeInsets.only(bottom: 140.0),
                      onChanged: (val) {
                        _saveText(val.trim());
                        setState(() {});
                      },
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                        fontSize: settings.fontSize.clamp(16.0, 22.0),
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Colle ou écris ton texte ici pour l’écouter...',
                        border: InputBorder.none,
                      ),
                    ),
                    if (_controller.text.trim().isNotEmpty) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(
                            _isPlaying
                                ? Icons.volume_up_rounded
                                : Icons.touch_app_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isPlaying
                                  ? 'Lecture en cours (suivi mot à mot) :'
                                  : 'Touche un mot pour l\'écouter individuellement :',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isPlaying
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isPlaying
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isPlaying
                                ? AppColors.primary.withValues(alpha: 0.35)
                                : const Color(0xFFE2E8F0),
                            width: _isPlaying ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: _buildInteractiveWordSpans(
                              text: _controller.text.trim(),
                              settings: settings,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Speak Button with subtle pulsing aura when active
              AppAudioPulseAura(
                isPulsing: _isPlaying,
                maxScale: 1.015,
                pulseColor: AppColors.errorRed,
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _toggleSpeak,
                    icon: Icon(
                      _isPlaying
                          ? Icons.stop_circle_rounded
                          : Icons.volume_up_rounded,
                      size: 24,
                    ),
                    label: Text(
                      _isPlaying ? 'Arrêter la lecture' : 'Écouter à voix haute',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying
                          ? AppColors.errorRed
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Diagnostic link card
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TtsDiagnosticsScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Un problème de son ? Ouvre le diagnostic vocal.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildInteractiveWordSpans({
    required String text,
    required dynamic settings,
  }) {
    _disposeWordRecognizers();

    final baseStyle = TextStyle(
      fontSize: settings.fontSize.clamp(16.0, 22.0),
      fontFamily: settings.fontFamily,
      height: 1.6,
      letterSpacing: settings.letterSpacing,
      wordSpacing: settings.wordSpacing,
      color: AppColors.textPrimary,
    );

    final spans = <InlineSpan>[];
    final pattern =
        RegExp(r"([a-zA-ZÀ-ÿ]+(?:['’][a-zA-ZÀ-ÿ]+)?|[^a-zA-ZÀ-ÿ]+)");
    final matches = pattern.allMatches(text);

    int wordIndex = 0;
    for (final match in matches) {
      final token = match.group(0) ?? '';
      if (token.isEmpty) continue;

      if (RegExp(r"[a-zA-ZÀ-ÿ]").hasMatch(token)) {
        final currentWordIndex = wordIndex++;
        final isSpeaking = _speakingWordIndex == currentWordIndex;

        final wordRecognizer = TapGestureRecognizer()
          ..onTap = () => _speakSingleWord(token, currentWordIndex);
        _wordRecognizers.add(wordRecognizer);

        spans.add(
          TextSpan(
            text: token,
            recognizer: wordRecognizer,
            style: baseStyle.copyWith(
              color: isSpeaking ? const Color(0xFF0F172A) : AppColors.textPrimary,
              fontWeight: isSpeaking ? FontWeight.w800 : FontWeight.w500,
              backgroundColor: isSpeaking
                  ? AppColors.highlightYellow.withValues(alpha: 0.85)
                  : null,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: token,
            style: baseStyle,
          ),
        );
      }
    }

    return spans;
  }
}

class _TtsWordItem {
  final int index;
  final String word;
  final int durationMs;
  final int sentenceIndex;

  const _TtsWordItem({
    required this.index,
    required this.word,
    required this.durationMs,
    this.sentenceIndex = 0,
  });
}
