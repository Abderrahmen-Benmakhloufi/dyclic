import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Native Android TTS via Platform Channel
///
/// Bypasses flutter_tts entirely and calls Android TextToSpeech API
/// directly through a custom Kotlin MethodChannel implementation.
/// This ensures maximum reliability, automatic unmute, and direct audio control.
class TtsService {
  static const _channel = MethodChannel('dz.eduaide.lecture_aide/native_tts');

  bool _isPlaying = false;
  bool _isReady = false;
  String? _lastError;
  Map<String, dynamic>? _lastDiagnostics;

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  bool get isPlaying => _isPlaying;
  bool get isReady => _isReady;
  String? get lastError => _lastError;
  Map<String, dynamic>? get lastDiagnostics => _lastDiagnostics;

  TtsService() {
    _channel.setMethodCallHandler(_handleNativeCall);
    _checkReady();
  }

  Future<void> _checkReady() async {
    try {
      final ready = await _channel.invokeMethod<bool>('isReady');
      _isReady = ready ?? false;
      debugPrint('NativeTTS: isReady = $_isReady');
    } catch (e) {
      debugPrint('NativeTTS: _checkReady error: $e');
    }
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onTtsReady':
        _isReady = call.arguments == true;
        debugPrint('NativeTTS: onTtsReady = $_isReady');
        break;
      case 'onStart':
        _isPlaying = true;
        isPlayingNotifier.value = true;
        debugPrint('NativeTTS: onStart');
        break;
      case 'onDone':
        _isPlaying = false;
        isPlayingNotifier.value = false;
        debugPrint('NativeTTS: onDone');
        break;
      case 'onError':
        _isPlaying = false;
        isPlayingNotifier.value = false;
        _lastError = call.arguments?.toString();
        debugPrint('NativeTTS: onError = $_lastError');
        break;
    }
    return null;
  }

  /// Speaks a single word with clear French pronunciation.
  Future<void> speakWord(String word) async {
    final clean =
        word.replaceAll(RegExp(r"[^\p{L}\p{M}\-']", unicode: true), '').trim();
    if (clean.isEmpty) return;
    await _speak(clean);
  }

  /// Speaks a phrase or full text.
  Future<void> speakText(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _speak(clean);
  }

  Future<Map<String, dynamic>> _speak(String text) async {
    try {
      _isPlaying = true;
      isPlayingNotifier.value = true;
      _lastError = null;

      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'speak',
        {'text': text},
      );

      final resultMap = result?.cast<String, dynamic>() ?? {};
      debugPrint('NativeTTS: speak result = $resultMap');

      if (resultMap['success'] != true) {
        _isPlaying = false;
        isPlayingNotifier.value = false;
        _lastError = resultMap['error']?.toString();
      }

      return resultMap;
    } catch (e) {
      _isPlaying = false;
      isPlayingNotifier.value = false;
      _lastError = e.toString();
      debugPrint('NativeTTS: speak error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Gets full diagnostics from the native TTS engine.
  Future<Map<String, dynamic>> getDiagnostics() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDiagnostics',
      );
      _lastDiagnostics = result?.cast<String, dynamic>();
      return _lastDiagnostics ?? {};
    } catch (e) {
      debugPrint('NativeTTS: getDiagnostics error: $e');
      return {'error': e.toString()};
    }
  }

  /// Gets available TTS engines.
  Future<List<Map<String, String>>> getEngines() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getEngines');
      return result
              ?.map((e) => (e as Map<dynamic, dynamic>).cast<String, String>())
              .toList() ??
          [];
    } catch (e) {
      debugPrint('NativeTTS: getEngines error: $e');
      return [];
    }
  }

  /// Selects a specific TTS engine by package name.
  Future<bool> setEngine(String engineName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setEngine',
        {'engine': engineName},
      );
      return result ?? false;
    } catch (e) {
      debugPrint('NativeTTS: setEngine error: $e');
      return false;
    }
  }

  /// Gets available languages.
  Future<List<String>> getLanguages() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getLanguages');
      return result?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      debugPrint('NativeTTS: getLanguages error: $e');
      return [];
    }
  }

  /// Opens Android TTS Settings screen.
  Future<bool> openTtsSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openTtsSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeTTS: openTtsSettings error: $e');
      return false;
    }
  }

  /// Prompts Android to download / install voice data.
  Future<bool> installVoiceData() async {
    try {
      final result = await _channel.invokeMethod<bool>('installVoiceData');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeTTS: installVoiceData error: $e');
      return false;
    }
  }

  /// Reinitializes the native TTS engine.
  Future<Map<String, dynamic>> reinitialize() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'reinitialize',
      );
      return result?.cast<String, dynamic>() ?? {};
    } catch (e) {
      debugPrint('NativeTTS: reinitialize error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Stops any ongoing audio speech immediately.
  Future<void> stop() async {
    try {
      _isPlaying = false;
      isPlayingNotifier.value = false;
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }

  void dispose() {
    _isPlaying = false;
    isPlayingNotifier.value = false;
    try {
      _channel.invokeMethod('stop');
    } catch (_) {}
  }
}
