import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised Gemini API configuration loaded from the .env file.
class GeminiConfig {
  GeminiConfig._();

  /// The Gemini API key (read from GEMINI_API_KEY in .env).
  static String get apiKey {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty || key == 'YOUR_API_KEY_HERE') {
      throw StateError(
        'GEMINI_API_KEY is not set. Add it to app/.env as:\n'
        'GEMINI_API_KEY=your_key_here',
      );
    }
    return key;
  }

  /// Primary model to use — gemini-3.5-flash for fastest speed and high availability.
  static const String model = 'gemini-3.5-flash';

  /// Fallback models in case the primary experiences temporary rate-limits or spikes.
  static const List<String> fallbackModels = [
    'gemini-3.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
  ];
}
