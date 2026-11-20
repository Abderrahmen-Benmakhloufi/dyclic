import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tts_platform_bridge.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Represents a sentence speech event emitted by the TTS engine (Android Native or Web Speech API).
class TtsSentenceEvent {
  final int sentenceIndex;
  final int totalSentences;
  final String sentenceText;
  final int durationMs;

  const TtsSentenceEvent({
    required this.sentenceIndex,
    this.totalSentences = 1,
    this.sentenceText = '',
    this.durationMs = -1,
  });
}

/// Universal French TTS Service
///
/// Automatically uses:
/// - Android: Custom Kotlin MethodChannel implementation with Google Translate TTS / system fallback.
/// - Web / iOS: Browser Web Speech API (`window.speechSynthesis`) with native French voices (Siri, Thomas, etc.).
class TtsService {
  final TtsPlatformBridge _bridge = TtsPlatformBridge.create();

  bool _isPlaying = false;
  bool _isReady = false;
  String? _lastError;
  Map<String, dynamic>? _lastDiagnostics;

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  void Function(TtsSentenceEvent event)? onSentenceStart;
  void Function(int sentenceIndex)? onSentenceDone;

  final _sentenceStartController =
      StreamController<TtsSentenceEvent>.broadcast();
  final _sentenceDoneController = StreamController<int>.broadcast();

  Stream<TtsSentenceEvent> get sentenceStartStream =>
      _sentenceStartController.stream;
  Stream<int> get sentenceDoneStream => _sentenceDoneController.stream;

  bool get isPlaying => _isPlaying;
  bool get isReady => _isReady;
  String? get lastError => _lastError;
  Map<String, dynamic>? get lastDiagnostics => _lastDiagnostics;

  TtsService() {
    _bridge.initialize(
      onStart: () {
        _isPlaying = true;
        isPlayingNotifier.value = true;
        debugPrint('TTS: onStart');
      },
      onSentenceStart: (idx, durationMs) {
        final ev = TtsSentenceEvent(
          sentenceIndex: idx,
          totalSentences: 1,
          sentenceText: '',
          durationMs: durationMs,
        );
        _sentenceStartController.add(ev);
        onSentenceStart?.call(ev);
        debugPrint('TTS: onSentenceStart = $idx ($durationMs ms)');
      },
      onSentenceDone: (idx) {
        _sentenceDoneController.add(idx);
        onSentenceDone?.call(idx);
        debugPrint('TTS: onSentenceDone = $idx');
      },
      onDone: () {
        _isPlaying = false;
        isPlayingNotifier.value = false;
        debugPrint('TTS: onDone');
      },
      onError: (err) {
        _isPlaying = false;
        isPlayingNotifier.value = false;
        _lastError = err;
        debugPrint('TTS: onError = $err');
      },
    );
    _checkReady();
  }

  Future<void> _checkReady() async {
    try {
      _isReady = await _bridge.isReady();
      debugPrint('TTS: isReady = $_isReady');
    } catch (e) {
      _isReady = true;
      debugPrint('TTS: _checkReady error: $e');
    }
  }

  /// Speaks a single word with clear French pronunciation.
  Future<void> speakWord(String word) async {
    final clean =
        word.replaceAll(RegExp(r"[^\p{L}\p{M}\-']", unicode: true), '').trim();
    if (clean.isEmpty) return;
    await _speak(clean, sentences: [clean]);
  }

  /// Speaks a phrase or full text.
  Future<void> speakText(String text, {List<String>? sentences}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _speak(clean, sentences: sentences);
  }

  Future<Map<String, dynamic>> _speak(
    String text, {
    List<String>? sentences,
  }) async {
    _isPlaying = true;
    isPlayingNotifier.value = true;
    _lastError = null;

    final success = await _bridge.speak(text, sentences: sentences);
    if (!success) {
      _isPlaying = false;
      isPlayingNotifier.value = false;
    }
    return {'success': success};
  }

  /// Gets full diagnostics from the active TTS engine.
  Future<Map<String, dynamic>> getDiagnostics() async {
    _lastDiagnostics = await _bridge.getDiagnostics();
    return _lastDiagnostics ?? {};
  }

  /// Gets available TTS engines.
  Future<List<Map<String, String>>> getEngines() async {
    return _bridge.getEngines();
  }

  /// Selects a specific TTS engine by package name.
  Future<bool> setEngine(String engineName) async {
    return _bridge.setEngine(engineName);
  }

  /// Gets available languages.
  Future<List<String>> getLanguages() async {
    return _bridge.getLanguages();
  }

  /// Opens Android TTS Settings screen.
  Future<bool> openTtsSettings() async {
    return _bridge.openTtsSettings();
  }

  /// Prompts Android to download / install voice data.
  Future<bool> installVoiceData() async {
    return _bridge.installVoiceData();
  }

  /// Reinitializes the active TTS engine.
  Future<Map<String, dynamic>> reinitialize() async {
    return _bridge.reinitialize();
  }

  /// Stops any ongoing audio speech immediately.
  Future<void> stop() async {
    _isPlaying = false;
    isPlayingNotifier.value = false;
    await _bridge.stop();
  }

  void dispose() {
    _isPlaying = false;
    isPlayingNotifier.value = false;
    _sentenceStartController.close();
    _sentenceDoneController.close();
    isPlayingNotifier.dispose();
    _bridge.stop();
  }
}
