import 'package:flutter/material.dart';

/// 5 DYS-aligned error categories matching the app's diagnostic dimensions.
enum WritingErrorCategory {
  inversion,    // Confusions b/d, inversions de lettres (Q9, Q10)
  phonetique,   // Sons & lettres muettes (Q16)
  regleLecture, // Règles contextuelles g/c/s/ph/ch (Q22 + Decoding rules)
  grammaire,    // Grammaire, accords, conjugaison, homophones (Q20)
  ponctuation,  // Ponctuation, majuscules, structure (Charge cognitive)
}

extension WritingErrorCategoryX on WritingErrorCategory {
  String get code {
    switch (this) {
      case WritingErrorCategory.inversion:
        return 'inversion';
      case WritingErrorCategory.phonetique:
        return 'phonetique';
      case WritingErrorCategory.regleLecture:
        return 'regle_lecture';
      case WritingErrorCategory.grammaire:
        return 'grammaire';
      case WritingErrorCategory.ponctuation:
        return 'ponctuation';
    }
  }

  String get labelFr {
    switch (this) {
      case WritingErrorCategory.inversion:
        return 'Inversion & Confusion';
      case WritingErrorCategory.phonetique:
        return 'Sons & Lettres muettes';
      case WritingErrorCategory.regleLecture:
        return 'Règles (g/c/s/ph)';
      case WritingErrorCategory.grammaire:
        return 'Grammaire & Accords';
      case WritingErrorCategory.ponctuation:
        return 'Ponctuation & Structure';
    }
  }

  String get emoji {
    switch (this) {
      case WritingErrorCategory.inversion:
        return '🔄';
      case WritingErrorCategory.phonetique:
        return '🔇';
      case WritingErrorCategory.regleLecture:
        return '🔤';
      case WritingErrorCategory.grammaire:
        return '📐';
      case WritingErrorCategory.ponctuation:
        return '✏️';
    }
  }

  Color get color {
    switch (this) {
      case WritingErrorCategory.inversion:
        return const Color(0xFFDC2626); // Crimson Red
      case WritingErrorCategory.phonetique:
        return const Color(0xFFD97706); // Warm Amber
      case WritingErrorCategory.regleLecture:
        return const Color(0xFF7C3AED); // Amethyst Purple
      case WritingErrorCategory.grammaire:
        return const Color(0xFF0284C7); // Ocean Blue
      case WritingErrorCategory.ponctuation:
        return const Color(0xFF0D9488); // Teal Green
    }
  }

  Color get lightColor => color.withValues(alpha: 0.12);

  static WritingErrorCategory fromCode(String? code) {
    switch (code?.toLowerCase().trim()) {
      case 'inversion':
        return WritingErrorCategory.inversion;
      case 'phonetique':
        return WritingErrorCategory.phonetique;
      case 'regle_lecture':
        return WritingErrorCategory.regleLecture;
      case 'ponctuation':
        return WritingErrorCategory.ponctuation;
      case 'grammaire':
      default:
        return WritingErrorCategory.grammaire;
    }
  }
}

/// A single classified writing mistake with its pedagogical explanation and tip.
@immutable
class WritingErrorItem {
  final String wrongText;
  final String correctedText;
  final String sentenceContext;
  final WritingErrorCategory category;
  final String explanationFr;
  final String tipFr;

  const WritingErrorItem({
    required this.wrongText,
    required this.correctedText,
    this.sentenceContext = '',
    required this.category,
    required this.explanationFr,
    required this.tipFr,
  });

  factory WritingErrorItem.fromJson(Map<String, dynamic> json) {
    return WritingErrorItem(
      wrongText: json['wrongText'] as String? ?? '',
      correctedText: json['correctedText'] as String? ?? '',
      sentenceContext: json['sentenceContext'] as String? ?? '',
      category: WritingErrorCategoryX.fromCode(json['category'] as String?),
      explanationFr: json['explanationFr'] as String? ?? '',
      tipFr: json['tipFr'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'wrongText': wrongText,
        'correctedText': correctedText,
        'sentenceContext': sentenceContext,
        'category': category.code,
        'explanationFr': explanationFr,
        'tipFr': tipFr,
      };
}

/// Complete pedagogical feedback report generated for a student's written text.
@immutable
class WritingFeedbackResult {
  final String id;
  final String originalText;
  final String subjectPrompt;
  final String cycle; // 'primaire' | 'college' | 'lycee'
  final String encouragementFr;
  final String strengthsFr;
  final String topicRelevanceFr;
  final String correctedFullText;
  final List<WritingErrorItem> errors;
  final int createdAtMs;

  const WritingFeedbackResult({
    required this.id,
    required this.originalText,
    this.subjectPrompt = '',
    required this.cycle,
    required this.encouragementFr,
    required this.strengthsFr,
    this.topicRelevanceFr = '',
    required this.correctedFullText,
    required this.errors,
    required this.createdAtMs,
  });

  factory WritingFeedbackResult.fromJson(Map<String, dynamic> json) {
    final rawErrors = json['errors'] as List<dynamic>? ?? [];
    return WritingFeedbackResult(
      id: json['id'] as String? ??
          'WR-${DateTime.now().millisecondsSinceEpoch}',
      originalText: json['originalText'] as String? ?? '',
      subjectPrompt: json['subjectPrompt'] as String? ?? '',
      cycle: json['cycle'] as String? ?? 'college',
      encouragementFr: json['encouragementFr'] as String? ??
          'Bravo pour ton effort d\'écriture !',
      strengthsFr: json['strengthsFr'] as String? ?? '',
      topicRelevanceFr: json['topicRelevanceFr'] as String? ?? '',
      correctedFullText: json['correctedFullText'] as String? ?? '',
      errors: rawErrors
          .map((e) => WritingErrorItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAtMs: json['createdAtMs'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalText': originalText,
        'subjectPrompt': subjectPrompt,
        'cycle': cycle,
        'encouragementFr': encouragementFr,
        'strengthsFr': strengthsFr,
        'topicRelevanceFr': topicRelevanceFr,
        'correctedFullText': correctedFullText,
        'errors': errors.map((e) => e.toJson()).toList(),
        'createdAtMs': createdAtMs,
      };
}
