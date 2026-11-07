import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/ai/gemini_config.dart';
import '../models/instruction_model.dart';

/// Exception thrown when the Gemini API cannot be reached (offline).
class GeminiOfflineException implements Exception {
  const GeminiOfflineException([this.message = 'Pas de connexion internet.']);
  final String message;
  @override
  String toString() => 'GeminiOfflineException: $message';
}

/// Exception thrown when the AI response cannot be parsed.
class GeminiParseException implements Exception {
  const GeminiParseException([this.message = 'Réponse invalide de l\'IA.']);
  final String message;
  @override
  String toString() => 'GeminiParseException: $message';
}

/// Encapsulates all Gemini API communication for the instruction explainer.
class GeminiService {
  GeminiService() {
    _model = GenerativeModel(
      model: GeminiConfig.model,
      apiKey: GeminiConfig.apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.3,
        maxOutputTokens: 1024,
      ),
    );
  }

  late final GenerativeModel _model;

  /// Maps [LearnerLevel] code to cycle values expected by [InstructionItem].
  static String _cycleFromLearnerCode(String learnerCode) {
    switch (learnerCode.toLowerCase()) {
      case 'primaire':
        return 'primaire';
      case 'secondaire':
        return 'lycee';
      case 'moyen':
      default:
        return 'college';
    }
  }

  /// Builds a human-friendly cycle label for the prompt.
  static String _cycleLabelFr(String cycle) {
    switch (cycle) {
      case 'primaire':
        return 'primaire (élève de 7 à 11 ans)';
      case 'lycee':
        return 'lycée (élève de 15 à 18 ans)';
      case 'college':
      default:
        return 'collège (élève de 11 à 15 ans)';
    }
  }

  /// Analyses an exam instruction and returns a fully populated [InstructionItem].
  ///
  /// [learnerLevelCode] must be one of `'primaire'`, `'moyen'`, `'secondaire'`.
  /// Throws [GeminiOfflineException] on network errors.
  /// Throws [GeminiParseException] when the AI response is not valid JSON.
  Future<InstructionItem> analyzeInstruction({
    required String questionText,
    required String learnerLevelCode,
  }) async {
    final cycle = _cycleFromLearnerCode(learnerLevelCode);
    final cycleLabel = _cycleLabelFr(cycle);

    final levelLabel = switch (cycle) {
      'primaire' => 'Primaire',
      'lycee' => 'Lycée',
      _ => 'Collège',
    };

    final prompt = '''
Tu es un assistant pédagogique francophone expert en didactique du français.
Analyse cette consigne d'examen pour un élève de $cycleLabel.

Consigne : "$questionText"

Génère UNIQUEMENT un objet JSON valide, sans explication ni texte autour.
Le JSON doit respecter exactement ce format :
{
  "id": "AI-01",
  "title": "[titre court de 3-6 mots décrivant la consigne]",
  "cycle": "$cycle",
  "level": "$levelLabel",
  "domain": "[une valeur parmi : Compréhension de l'écrit | Langue & Grammaire | Production écrite]",
  "questionType": "[une valeur parmi : comprehension | langue | production]",
  "originalFr": "$questionText",
  "steps": [
    {"stepNumber": 1, "textFr": "[première étape concrète, verbe à l'impératif, langage adapté au niveau]"},
    {"stepNumber": 2, "textFr": "[deuxième étape]"},
    {"stepNumber": 3, "textFr": "[troisième étape]"},
    {"stepNumber": 4, "textFr": "[quatrième étape si nécessaire]"},
    {"stepNumber": 5, "textFr": "[cinquième étape si nécessaire]"}
  ]
}

Règles :
- Fournis 3 à 5 étapes selon la complexité.
- Les étapes doivent être actionnables et progressives.
- Pour le primaire : vocabulaire très simple, phrases courtes, exemples concrets.
- Pour le collège : langage clair, termes scolaires de base.
- Pour le lycée : langage scolaire précis, démarche analytique.
- domain et questionType doivent être cohérents entre eux.
- Réponds UNIQUEMENT avec le JSON, rien d'autre.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';
      if (raw.isEmpty) throw const GeminiParseException('Réponse vide.');

      // Strip potential markdown code fences
      final cleaned = raw
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();

      final Map<String, dynamic> json =
          jsonDecode(cleaned) as Map<String, dynamic>;

      return InstructionItem.fromJson(json);
    } on GenerativeAIException catch (e) {
      // Network / auth errors from the SDK
      throw GeminiOfflineException(e.message);
    } on FormatException catch (e) {
      throw GeminiParseException('JSON invalide : ${e.message}');
    } catch (e) {
      if (e is GeminiOfflineException || e is GeminiParseException) rethrow;
      // Treat unknown errors (SocketException, etc.) as offline
      throw GeminiOfflineException(e.toString());
    }
  }
}
