import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/ai/gemini_config.dart';
import '../../../core/learner_profile/learner_profile_model.dart';
import '../models/simplify_model.dart';

/// Exception thrown when the Gemini API cannot be reached (offline).
class SimplifyOfflineException implements Exception {
  const SimplifyOfflineException([this.message = 'Pas de connexion internet.']);
  final String message;
  @override
  String toString() => 'SimplifyOfflineException: $message';
}

/// Exception thrown when the AI response cannot be parsed.
class SimplifyParseException implements Exception {
  const SimplifyParseException([this.message = 'Réponse invalide de l\'IA.']);
  final String message;
  @override
  String toString() => 'SimplifyParseException: $message';
}

/// Service managing AI-powered text simplification aligned with the French curriculum and FALC standards.
class SimplifyGeminiService {
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

  static String _cycleLabelFrenchCurriculum(String cycle) {
    switch (cycle) {
      case 'primaire':
        return 'Primaire (École primaire - élève de 7 à 11 ans)';
      case 'lycee':
        return 'Lycée (Enseignement secondaire - élève de 15 à 18 ans)';
      case 'college':
      default:
        return 'Moyen / Collège (Enseignement moyen - élève de 11 à 15 ans)';
    }
  }

  static String _buildProfileDirectives(LearnerProfile? profile) {
    if (profile == null || !profile.isDiagnosticDone) {
      return '';
    }

    final directives = <String>[];
    if (profile.overwhelmedByText) {
      directives.add(
          '- L\'élève est très vite submergé par les paragraphes denses : coupe les phrases très courtes (maximum 8 à 10 mots par phrase) et saute des lignes entre les idées.');
    }
    if (profile.mirrorLetterConfusion) {
      directives.add(
          '- L\'élève a des difficultés de confusion des lettres miroirs (b/d/p/q) : privilégie des structures simples et des mots limpides.');
    }
    if (profile.poorWordDecoding) {
      directives.add(
          '- L\'élève a des difficultés de décodage des mots : privilégie des structures transparentes et des mots aux correspondances graphème-phonème régulières.');
    }

    if (directives.isEmpty) return '';
    return '\nBESOINS SPÉCIFIQUES DU PROFIL DE L\'ÉLÈVE (DYS) :\n${directives.join('\n')}\n';
  }

  /// Simplifies a text according to French educational curriculum standards and FALC.
  Future<SimplifyResult> simplifyText({
    required String rawText,
    required String learnerLevelCode,
    LearnerProfile? profile,
    String? cloudMistakesSummary,
  }) async {
    final cleanText = rawText.trim();
    if (cleanText.isEmpty) {
      throw ArgumentError('Le texte à simplifier ne peut pas être vide.');
    }

    final cycle = _cycleFromLearnerCode(learnerLevelCode);
    final cycleLabel = _cycleLabelFrenchCurriculum(cycle);
    final profileDirectives = _buildProfileDirectives(profile);
    final cloudSection = (cloudMistakesSummary != null && cloudMistakesSummary.trim().isNotEmpty)
        ? '\n$cloudMistakesSummary\n'
        : '';

    final systemInstruction = '''
Tu es un professeur expert de l'Éducation Nationale française et un spécialiste reconnu des troubles des apprentissages (Dyslexie, Dysorthographie, TDAH).
Ta mission est d'adapter et simplifier des textes scolaires pour un élève du système éducatif français selon les normes FALC (Facile À Lire et à Comprendre).

NIVEAU SCOLAIRE DE L'ÉLÈVE : $cycleLabel.
$profileDirectives
$cloudSection

PRINCIPES PÉDAGOGIQUES FONDAMENTAUX (NON NÉGOCIABLES) :
1. RÉSIS-TANCE À L'APPAUVRISSEMENT LEXICAL :
   - Ne remplace JAMAIS le vocabulaire thématique ou littéraire riche par des mots puérils ou simplistes. Les notions du programme français doivent être apprises !
   - Conserve les mots clés importants et explique-les dans le glossaire.

2. ALLÈGEMENT SYNTAXIQUE RIGOUREUX (FALC) :
   - Découpe les longues phrases complexes en plusieurs phrases courtes et indépendantes.
   - Adopte l'ordre canonique : [Sujet] + [Verbe] + [Complément].
   - Évite la voix passive et les tournures impersonnelles ("Il est observé que...").
   - Supprime les doubles négations et les propositions subordonnées imbriquées.
   - Une seule idée principale par phrase.

3. LE RÉSUMÉ (SUMMARY) :
   - Rédige un résumé clair et direct en 2 à 4 phrases maximum, expliquant l'idée générale du texte.

4. LE GLOSSAIRE DU VOCABULAIRE (GLOSSES) :
   - Repère les 3 à 6 mots les plus difficiles ou spécifiques du texte.
   - Pour chaque mot, donne une définition brève, accessible et en contexte (1 phrase simple).

FORMAT DE SORTIE IMPÉRATIF :
Réponds UNIQUEMENT avec un objet JSON valide, sans texte additionnel ni markdown en dehors du bloc JSON.
Structure JSON attendue :
{
  "summary": "Résumé en 2 à 4 phrases claires...",
  "simplified_text": "Le texte simplifié avec syntaxe FALC aérée...",
  "key_vocabulary_with_glosses": [
    {
      "word": "mot_difficile",
      "definitionSimple": "Définition courte et accessible adaptée à l'âge..."
    }
  ]
}
''';

    final prompt = '''
Voici le texte à adapter pour cet élève :
"""
$cleanText
"""
''';

    for (final modelName in GeminiConfig.fallbackModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: GeminiConfig.apiKey,
          generationConfig: _generationConfig,
          systemInstruction: Content.system(systemInstruction),
        );

        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 20));

        final responseText = response.text?.trim() ?? '';
        if (responseText.isEmpty) {
          throw const SimplifyParseException('Réponse vide reçue de l\'IA.');
        }

        return _parseJsonResponse(responseText, cleanText, cycle);
      } on TimeoutException {
        debugPrint('Gemini model $modelName timed out, trying fallback...');
        continue;
      } on SimplifyParseException {
        rethrow;
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('socketexception') ||
            errStr.contains('failed host lookup') ||
            errStr.contains('network') ||
            errStr.contains('offline')) {
          throw const SimplifyOfflineException(
            'Pas de connexion internet. Vérifie ton réseau et réessaie.',
          );
        }
        debugPrint('Error with $modelName: $e');
      }
    }

    throw const SimplifyOfflineException(
      'Impossible de joindre le serveur d\'IA. Vérifie ta connexion.',
    );
  }

  SimplifyResult _parseJsonResponse(
    String raw,
    String originalText,
    String cycle,
  ) {
    try {
      String clean = raw.trim();
      if (clean.startsWith('```json')) {
        clean = clean.substring(7);
      } else if (clean.startsWith('```')) {
        clean = clean.substring(3);
      }
      if (clean.endsWith('```')) {
        clean = clean.substring(0, clean.length - 3);
      }
      clean = clean.trim();

      final decoded = jsonDecode(clean) as Map<String, dynamic>;

      final summary = decoded['summary'] as String? ?? '';
      final simplified = decoded['simplified_text'] as String? ??
          decoded['simplifiedText'] as String? ??
          '';
      final rawGlosses = (decoded['key_vocabulary_with_glosses'] as List<dynamic>?) ??
          (decoded['glosses'] as List<dynamic>?) ??
          [];

      final glosses = rawGlosses.map((g) {
        final map = g as Map<String, dynamic>;
        return SimplifyWordGloss(
          word: map['word'] as String? ?? '',
          definitionSimple: map['definitionSimple'] as String? ??
              map['definition'] as String? ??
              '',
        );
      }).toList();

      return SimplifyResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cycle: cycle,
        originalText: originalText,
        summary: summary,
        simplifiedText: simplified,
        glosses: glosses,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Failed to parse simplify JSON response: $e\nRaw: $raw');
      throw const SimplifyParseException(
        'Format de réponse inattendu. Merci de réessayer.',
      );
    }
  }
}
