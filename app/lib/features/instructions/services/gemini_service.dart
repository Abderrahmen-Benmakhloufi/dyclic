import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/ai/gemini_config.dart';
import '../../../core/learner_profile/learner_profile_model.dart';
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
  final GenerationConfig _generationConfig = GenerationConfig(
    responseMimeType: 'application/json',
    temperature: 0.3,
    maxOutputTokens: 1024,
  );

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
        return 'moyen (collège, élève de 11 à 15 ans)';
    }
  }

  /// Builds personalized pedagogical directives from the learner's diagnostic profile.
  static String _buildProfileDirectives(LearnerProfile? profile) {
    if (profile == null || !profile.isDiagnosticDone) {
      return '';
    }

    final directives = <String>[];
    if (profile.overwhelmedByText) {
      directives.add(
          '- L\'élève a besoin d\'un découpage très aéré et progressif : formule des étapes détaillées mais avec des phrases courtes, limpides et bien espacées.');
    }
    if (profile.poorWordDecoding) {
      directives.add(
          '- L\'élève a des difficultés de déchiffrage (dyslexie) : utilise des mots très simples et concrets, évite les termes grammaticaux ardus.');
    }
    if (profile.cognitiveFatigueHigh) {
      directives.add(
          '- L\'élève subit une fatigue cognitive rapide : chaque étape doit contenir une seule action claire, sans phrases imbriquées.');
    }
    if (profile.slowReadingSpeed) {
      directives.add(
          '- Vitesse de lecture lente : formules concises et mots courts.');
    }
    if (profile.mirrorLetterConfusion) {
      directives.add(
          '- L\'élève présente des confusions visuelles de lettres (ex: b/d, p/q) : privilégie des formulations explicites.');
    }

    if (directives.isEmpty) return '';

    return '''
Profil personnalisé de l'élève (besoins DYS et accessibilité cognitive) :
${directives.join('\n')}
''';
  }

  /// Analyses an exam instruction and returns a fully populated [InstructionItem].
  ///
  /// [learnerLevelCode] must be one of `'primaire'`, `'moyen'`, `'secondaire'`.
  /// [profile] contains the student's initial questionnaire diagnostic results.
  /// Throws [GeminiOfflineException] on network errors.
  /// Throws [GeminiParseException] when the AI response is not valid JSON.
  Future<InstructionItem> analyzeInstruction({
    required String questionText,
    required String learnerLevelCode,
    LearnerProfile? profile,
    String? cloudMistakesSummary,
  }) async {
    final cycle = _cycleFromLearnerCode(learnerLevelCode);
    final cycleLabel = _cycleLabelFr(cycle);
    final profileDirectives = _buildProfileDirectives(profile);
    final cloudSection = (cloudMistakesSummary != null && cloudMistakesSummary.trim().isNotEmpty)
        ? '\n$cloudMistakesSummary\n'
        : '';

    final levelLabel = switch (cycle) {
      'primaire' => 'Primaire',
      'lycee' => 'Lycée',
      _ => 'Moyen',
    };

    final prompt = '''
Tu es un assistant pédagogique francophone expert en didactique du français et accompagnement des troubles DYS.
Analyse cette consigne d'examen pour un élève de $cycleLabel.

$profileDirectives
$cloudSection

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
    {"stepNumber": 1, "textFr": "[Étape 1 : repérer et surligner les mots-clés et le verbe d'action de la consigne pour bien comprendre ce qui est demandé]"},
    {"stepNumber": 2, "textFr": "[Étape 2 : identifier les indices, paragraphes ou outils de langue nécessaires dans le texte ou la leçon]"},
    {"stepNumber": 3, "textFr": "[Étape 3 : réfléchir au sens, formuler l'idée principale au brouillon ou dans sa tête]"},
    {"stepNumber": 4, "textFr": "[Étape 4 : rédiger la réponse de manière claire, avec une phrase complète et bien construite]"},
    {"stepNumber": 5, "textFr": "[Étape 5 : relire pour vérifier si la consigne est respectée et corriger les éventuelles erreurs d'accords]"}
  ]
}

Règles pédagogiques strictes :
- Fournis une démarche complète, détaillée et progressive en 4 à 6 étapes (ne te limite pas à 3 étapes courtes). L'objectif est d'expliquer en profondeur la méthode pour que l'élève comprenne exactement comment réussir.
- Chaque étape doit être concrète, actionnable et débuter par un verbe d'action clair à l'impératif ou à l'infinitif.
- Développe chaque étape avec des explications explicites (ex: donner un exemple de phrase de réponse ou préciser où chercher).
- Pour le primaire : vocabulaire simple, phrases courtes, explications imagées et concrètes.
- Pour le moyen : démarche méthodique, repérage précis des éléments du texte, justification attendue.
- Pour le lycée : démarche analytique rigoureuse, problématisation, argumentation et nuances.
- domain et questionType doivent être parfaitement cohérents.
- Réponds UNIQUEMENT avec le JSON, rien d'autre.
''';

    GenerativeAIException? lastAiException;
    FormatException? lastFormatException;
    String? lastErrorMsg;

    for (final modelName in GeminiConfig.fallbackModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: GeminiConfig.apiKey,
          generationConfig: _generationConfig,
        );

        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 20));
        final raw = response.text ?? '';
        if (raw.isEmpty) continue;

        // Strip potential markdown code fences
        var cleaned = raw
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
            .trim();

        final startIdx = cleaned.indexOf('{');
        final endIdx = cleaned.lastIndexOf('}');
        if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
          cleaned = cleaned.substring(startIdx, endIdx + 1);
        }

        final Map<String, dynamic> json =
            jsonDecode(cleaned) as Map<String, dynamic>;

        return InstructionItem.fromJson(json);
      } on TimeoutException {
        debugPrint('GeminiService timeout on $modelName');
        lastErrorMsg = 'Délai dépassé (connexion lente ou serveur occupé).';
      } on GenerativeAIException catch (e) {
        debugPrint('GeminiService AI error on $modelName: ${e.message}');
        lastAiException = e;
      } on FormatException catch (e) {
        debugPrint('GeminiService JSON error on $modelName: ${e.message}');
        lastFormatException = e;
      } catch (e) {
        debugPrint('GeminiService error on $modelName: $e');
        lastErrorMsg = e.toString();
      }
    }

    if (lastFormatException != null) {
      throw GeminiParseException('JSON invalide : ${lastFormatException.message}');
    }
    if (lastAiException != null) {
      throw GeminiOfflineException(lastAiException.message);
    }
    throw GeminiOfflineException(
        lastErrorMsg ?? 'Impossible d\'analyser la consigne avec l\'IA.');
  }
}
