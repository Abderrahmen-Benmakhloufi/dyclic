import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/ai/gemini_config.dart';
import '../../../core/learner_profile/learner_profile_model.dart';
import '../../instructions/services/gemini_service.dart';
import '../models/writing_error_profile.dart';
import '../models/writing_feedback_model.dart';

/// Service communicating with Gemini API to analyze a student's written French text,
/// classify mistakes according to DYS learning difficulties, explain why, and offer tips.
class WritingGeminiService {
  final GenerationConfig _generationConfig = GenerationConfig(
    responseMimeType: 'application/json',
    temperature: 0.3,
    maxOutputTokens: 2048,
  );

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

  static String _buildProfileDirectives(LearnerProfile? profile) {
    if (profile == null || !profile.isDiagnosticDone) {
      return '';
    }

    final directives = <String>[];
    if (profile.mirrorLetterConfusion) {
      directives.add(
          '- Attention particulière aux confusions visuelles de lettres (b/d, p/q, m/n) et aux inversions de lettres.');
    }
    if (profile.poorWordDecoding) {
      directives.add(
          '- L\'élève a un déchiffrage difficile : explique les règles phonétiques (g/ge, c/ç, ph, eau) avec des mots simples et visuels.');
    }
    if (profile.overwhelmedByText) {
      directives.add(
          '- L\'élève est vite submergé par les textes longs : fais des explications TRÈS COURTES (1 à 2 phrases simples par erreur) et bienveillantes.');
    }
    if (profile.cognitiveFatigueHigh) {
      directives.add(
          '- Fatigue cognitive élevée : privilégie les astuces mémotechniques simples et rapides.');
    }
    if (profile.b2SpellingWritingScore >= 50) {
      directives.add(
          '- Difficulté importante en orthographe (dysorthographie) : valorise beaucoup les efforts et explique chaque règle sans jugement.');
    }

    if (directives.isEmpty) return '';

    return '''
Profil diagnostique de l'élève (troubles DYS) :
${directives.join('\n')}
''';
  }

  /// Evaluates [studentText] with optional [subjectPrompt] and returns structured DYS-aware feedback.
  Future<WritingFeedbackResult> analyzeWriting({
    required String studentText,
    String subjectPrompt = '',
    required String learnerLevelCode,
    LearnerProfile? profile,
    WritingErrorProfile? errorProfile,
  }) async {
    final cycle = _cycleFromLearnerCode(learnerLevelCode);
    final cycleLabel = _cycleLabelFr(cycle);
    final profileDirectives = _buildProfileDirectives(profile);
    final errorHistorySection = errorProfile?.toCompactPromptSummary() ?? '';

    final subjectSection = subjectPrompt.trim().isNotEmpty
        ? 'Sujet / Consigne donnée par le professeur : "$subjectPrompt"\n'
        : 'Aucun sujet spécifique fourni.\n';

    final prompt = '''
Tu es un professeur de français bienveillant et spécialiste en orthophonie / troubles DYS (dyslexie, dysorthographie).
Tu accompagnes un élève de niveau $cycleLabel qui vient d'écrire un texte par lui-même.
Ton objectif N'EST PAS juste de corriger à sa place, mais de l'aider à COMPRENDRE chaque erreur, son origine et comment l'éviter la prochaine fois.

$profileDirectives
$errorHistorySection
$subjectSection
Texte écrit par l'élève :
"""
$studentText
"""

Analyse ce texte et réponds UNIQUEMENT en JSON valide respectant exactement cette structure :
{
  "encouragementFr": "[1 phrase courte et chaleureuse valorisant son effort]",
  "strengthsFr": "[1 à 2 points positifs précis dans son texte : bonnes idées, vocabulaire, organisation, etc.]",
  "topicRelevanceFr": "[Si un sujet a été fourni, dis en 1 phrase si le texte répond bien au sujet ou ce qu'il pourrait ajouter. Sinon laisse une chaîne vide]",
  "correctedFullText": "[Le texte complet de l'élève entièrement corrigé, en gardant son style et ses idées d'origine]",
  "errors": [
    {
      "wrongText": "[le mot ou groupe de mots exactement tel qu'écrit avec l'erreur]",
      "correctedText": "[la correction exacte]",
      "sentenceContext": "[la courte phrase ou bout de phrase où apparaît l'erreur]",
      "category": "[EXACTEMENT une valeur parmi : inversion | phonetique | regle_lecture | grammaire | ponctuation]",
      "explanationFr": "[Explication simple, bienveillante et claire du POURQUOI c'est une erreur, adaptée au niveau]",
      "tipFr": "[Une astuce courte et concrète pour ne plus refaire cette erreur]"
    }
  ]
}

Guide strict pour choisir "category" (en lien avec les troubles DYS) :
- "inversion" : lettres inversées dans un mot (ex: chavel/cheval), confusion visuelle de lettres miroirs (b/d, p/q, m/n, u/n), ou lettre oubliée/ajoutée visuellement.
- "phonetique" : erreur d'orthographe phonétique (ex: écrire "bato" pour "bateau", "famasie" pour "pharmacie") ou lettre muette finale oubliée ("gran" pour "grand", "tapis" sans s).
- "regle_lecture" : règle contextuelle des lettres/sons (ex: g devant e/i vs gu, c devant e/i vs ç, s entre voyelles vs ss, ch, ph, eau/au, on/om, an/am).
- "grammaire" : accords pluriel (-s/-x/-nt), accords féminin (-e), conjugaison des verbes, homophones grammaticaux (a/à, et/est, son/sont, ces/ses, ou/où).
- "ponctuation" : majuscule manquante en début de phrase ou nom propre, point/virgule manquant, phrase trop longue ou coupée.

Règles importantes :
- S'il n'y a aucune erreur dans le texte, retourne une liste "errors": [] vide et félicite l'élève.
- Ne modifie pas les idées de l'élève dans correctedFullText, corrige uniquement la langue.
- Réponds UNIQUEMENT avec l'objet JSON valide, sans texte ni balises markdown autour.
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

        // Attach original fields & metadata cleanly
        json['id'] = 'WR-${DateTime.now().millisecondsSinceEpoch}';
        json['originalText'] = studentText;
        json['subjectPrompt'] = subjectPrompt;
        json['cycle'] = cycle;
        json['createdAtMs'] = DateTime.now().millisecondsSinceEpoch;

        return WritingFeedbackResult.fromJson(json);
      } on TimeoutException {
        debugPrint('WritingGeminiService timeout on $modelName');
        lastErrorMsg = 'Délai dépassé (connexion lente ou serveur occupé).';
      } on GenerativeAIException catch (e) {
        debugPrint('WritingGeminiService AI error on $modelName: ${e.message}');
        lastAiException = e;
      } on FormatException catch (e) {
        debugPrint('WritingGeminiService JSON error on $modelName: ${e.message}');
        lastFormatException = e;
      } catch (e) {
        debugPrint('WritingGeminiService error on $modelName: $e');
        lastErrorMsg = e.toString();
      }
    }

    if (lastFormatException != null) {
      throw GeminiParseException(
          'JSON invalide : ${lastFormatException.message}');
    }
    if (lastAiException != null) {
      throw GeminiOfflineException(lastAiException.message);
    }
    throw GeminiOfflineException(
        lastErrorMsg ?? 'Impossible d\'analyser ton texte avec l\'IA.');
  }
}
