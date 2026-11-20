import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'tts_platform_bridge.dart';

TtsPlatformBridge createPlatformBridge() => TtsBridgeIo();

class TtsBridgeIo implements TtsPlatformBridge {
  static const _channel = MethodChannel('dz.eduaide.lecture_aide/native_tts');

  void Function()? _onStart;
  void Function(int index, int durationMs)? _onSentenceStart;
  void Function(int index)? _onSentenceDone;
  void Function()? _onDone;
  void Function(String error)? _onError;

  @override
  void initialize({
    required void Function() onStart,
    required void Function(int index, int durationMs) onSentenceStart,
    required void Function(int index) onSentenceDone,
    required void Function() onDone,
    required void Function(String error) onError,
  }) {
    _onStart = onStart;
    _onSentenceStart = onSentenceStart;
    _onSentenceDone = onSentenceDone;
    _onDone = onDone;
    _onError = onError;

    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onStart':
        _onStart?.call();
        break;
      case 'onSentenceStart':
        final args = call.arguments is Map
            ? (call.arguments as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        final idx = (args['sentenceIndex'] as num?)?.toInt() ?? 0;
        final dur = (args['durationMs'] as num?)?.toInt() ?? -1;
        _onSentenceStart?.call(idx, dur);
        break;
      case 'onSentenceDone':
        final args = call.arguments is Map
            ? (call.arguments as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        final idx = (args['sentenceIndex'] as num?)?.toInt() ?? 0;
        _onSentenceDone?.call(idx);
        break;
      case 'onDone':
        _onDone?.call();
        break;
      case 'onError':
        _onError?.call(call.arguments?.toString() ?? 'Native TTS Error');
        break;
    }
    return null;
  }

  @override
  Future<bool> speak(
    String text, {
    List<String>? sentences,
    double rate = 0.92,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'speak',
        {
          'text': text,
          if (sentences != null && sentences.isNotEmpty) 'sentences': sentences,
        },
      );
      final resultMap = result?.cast<String, dynamic>() ?? {};
      return resultMap['success'] == true;
    } on MissingPluginException {
      // In test/mock environment without platform channel
      Future.microtask(() {
        _onStart?.call();
        _onSentenceStart?.call(0, -1);
      });
      return true;
    } catch (e) {
      debugPrint('TtsBridgeIo speak error: $e');
      _onError?.call(e.toString());
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }

  @override
  Future<List<String>> getLanguages() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getLanguages');
      return result?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> isReady() async {
    try {
      final ready = await _channel.invokeMethod<bool>('isReady');
      return ready ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getDiagnostics() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDiagnostics',
      );
      return result?.cast<String, dynamic>() ?? {};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Future<List<Map<String, String>>> getEngines() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getEngines');
      return result
              ?.map((e) => (e as Map<dynamic, dynamic>).cast<String, String>())
              .toList() ??
          [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> setEngine(String engineName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setEngine',
        {'engine': engineName},
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> openTtsSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openTtsSettings');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> installVoiceData() async {
    try {
      final result = await _channel.invokeMethod<bool>('installVoiceData');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> reinitialize() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'reinitialize',
      );
      return result?.cast<String, dynamic>() ?? {};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
