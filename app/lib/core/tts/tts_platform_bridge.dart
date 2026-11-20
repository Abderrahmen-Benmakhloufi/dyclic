import 'tts_bridge_io.dart'
    if (dart.library.js_interop) 'tts_bridge_web.dart';

abstract class TtsPlatformBridge {
  void initialize({
    required void Function() onStart,
    required void Function(int index, int durationMs) onSentenceStart,
    required void Function(int index) onSentenceDone,
    required void Function() onDone,
    required void Function(String error) onError,
  });

  Future<bool> speak(
    String text, {
    List<String>? sentences,
    double rate = 0.92,
  });

  Future<void> stop();

  Future<List<String>> getLanguages();

  Future<bool> isReady();

  Future<Map<String, dynamic>> getDiagnostics();

  Future<List<Map<String, String>>> getEngines();

  Future<bool> setEngine(String engineName);

  Future<bool> openTtsSettings();

  Future<bool> installVoiceData();

  Future<Map<String, dynamic>> reinitialize();

  static TtsPlatformBridge create() => createPlatformBridge();
}
