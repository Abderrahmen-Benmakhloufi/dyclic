import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'tts_platform_bridge.dart';

TtsPlatformBridge createPlatformBridge() => TtsBridgeWeb();

@JS('aideLectureTtsSetCallbacks')
external void _jsSetCallbacks(
  JSFunction onStart,
  JSFunction onSentenceStart,
  JSFunction onSentenceDone,
  JSFunction onDone,
  JSFunction onError,
);

@JS('aideLectureTtsSpeak')
external void _jsSpeak(
  JSString text,
  JSArray<JSString> sentences,
  JSNumber rate,
);

@JS('aideLectureTtsStop')
external void _jsStop();

@JS('aideLectureTtsIsReady')
external JSBoolean _jsIsReady();

@JS('aideLectureTtsGetLanguages')
external JSArray<JSString> _jsGetLanguages();

class TtsBridgeWeb implements TtsPlatformBridge {
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

    try {
      final jsOnStart = (() {
        _onStart?.call();
      }).toJS;

      final jsOnSentenceStart = ((JSNumber idx, JSNumber dur) {
        _onSentenceStart?.call(idx.toDartInt, dur.toDartInt);
      }).toJS;

      final jsOnSentenceDone = ((JSNumber idx) {
        _onSentenceDone?.call(idx.toDartInt);
      }).toJS;

      final jsOnDone = (() {
        _onDone?.call();
      }).toJS;

      final jsOnError = ((JSString err) {
        _onError?.call(err.toDart);
      }).toJS;

      _jsSetCallbacks(
        jsOnStart,
        jsOnSentenceStart,
        jsOnSentenceDone,
        jsOnDone,
        jsOnError,
      );
    } catch (e) {
      debugPrint('TtsBridgeWeb initialize error: $e');
    }
  }

  @override
  Future<bool> speak(
    String text, {
    List<String>? sentences,
    double rate = 0.92,
  }) async {
    try {
      final jsSentences = (sentences ?? [text])
          .map((s) => s.toJS)
          .toList()
          .toJS;
      _jsSpeak(text.toJS, jsSentences, rate.toJS);
      return true;
    } catch (e) {
      debugPrint('TtsBridgeWeb speak error: $e');
      _onError?.call(e.toString());
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      _jsStop();
    } catch (e) {
      debugPrint('TtsBridgeWeb stop error: $e');
    }
  }

  @override
  Future<List<String>> getLanguages() async {
    try {
      final jsLangs = _jsGetLanguages().toDart;
      return jsLangs.map((s) => s.toDart).toList();
    } catch (e) {
      return ['fr-FR (Web Speech API)'];
    }
  }

  @override
  Future<bool> isReady() async {
    try {
      return _jsIsReady().toDart;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<Map<String, dynamic>> getDiagnostics() async {
    final langs = await getLanguages();
    return {
      'engine': 'Web Speech API (SpeechSynthesis)',
      'platform': 'Web Browser (iOS Safari / Chrome / Web)',
      'frenchVoices': langs,
      'isReady': await isReady(),
    };
  }

  @override
  Future<List<Map<String, String>>> getEngines() async {
    return [
      {'name': 'WebSpeechSynthesis', 'label': 'Web Speech API (Navigateur)'}
    ];
  }

  @override
  Future<bool> setEngine(String engineName) async => true;

  @override
  Future<bool> openTtsSettings() async => false;

  @override
  Future<bool> installVoiceData() async => false;

  @override
  Future<Map<String, dynamic>> reinitialize() async {
    return {'success': true, 'message': 'Web TTS reinitialized'};
  }
}
