import 'package:flutter/material.dart';
import '../../../core/widgets/app_asset_icon.dart';

/// Model representing a single decomposed instruction step (French only)
class InstructionStep {
  final int stepNumber;
  final String textFr;

  const InstructionStep({
    required this.stepNumber,
    required this.textFr,
  });

  factory InstructionStep.fromJson(Map<String, dynamic> json) {
    return InstructionStep(
      stepNumber: json['stepNumber'] as int? ?? 1,
      textFr: json['textFr'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'textFr': textFr,
      };
}

/// Model representing a complete exam instruction with its context and decomposed steps
class InstructionItem {
  final String id;
  final String title;
  final String cycle; // 'primaire' | 'college' | 'lycee'
  final String level;
  final String domain;
  final String questionType; // 'comprehension' | 'langue' | 'production'
  final String originalFr;
  final List<InstructionStep> steps;

  const InstructionItem({
    required this.id,
    required this.title,
    required this.cycle,
    required this.level,
    required this.domain,
    required this.questionType,
    required this.originalFr,
    required this.steps,
  });

  factory InstructionItem.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    return InstructionItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cycle: json['cycle'] as String? ?? 'primaire',
      level: json['level'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      questionType: json['questionType'] as String? ?? 'comprehension',
      originalFr: json['originalFr'] as String? ?? '',
      steps: rawSteps
          .map((s) => InstructionStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cycle': cycle,
        'level': level,
        'domain': domain,
        'questionType': questionType,
        'originalFr': originalFr,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  /// Cycle display pill label with kid-friendly emoji
  String get cycleEmojiLabel {
    switch (cycle.toLowerCase()) {
      case 'primaire':
        return '🎒 Primaire';
      case 'college':
        return '📚 Collège';
      case 'lycee':
        return '🎓 Lycée';
      default:
        return '📖 Général';
    }
  }

  /// Question type readable label
  String get questionTypeLabel {
    switch (questionType.toLowerCase()) {
      case 'comprehension':
        return 'Compréhension';
      case 'langue':
        return 'Langue & Grammaire';
      case 'production':
        return 'Production écrite';
      default:
        return 'Général';
    }
  }

  /// Question type badge with kid-friendly icon
  String get questionTypeEmoji {
    switch (questionType.toLowerCase()) {
      case 'comprehension':
        return '🔍';
      case 'langue':
        return '📝';
      case 'production':
        return '✍️';
      default:
        return '💡';
    }
  }

  /// Asset illustration path for this question type
  String get questionTypeAssetPath {
    switch (questionType.toLowerCase()) {
      case 'comprehension':
        return AppUiAssets.qtypeComprehension;
      case 'langue':
        return AppUiAssets.qtypeLangue;
      case 'production':
        return AppUiAssets.qtypeProduction;
      default:
        return AppUiAssets.featInstructions;
    }
  }

  /// Distinct brand color for this question type
  Color get questionTypeColor {
    switch (questionType.toLowerCase()) {
      case 'comprehension':
        return const Color(0xFF0284C7); // Sky/Ocean Blue
      case 'langue':
        return const Color(0xFF7C3AED); // Amethyst Purple
      case 'production':
        return const Color(0xFFEA580C); // Warm Sunset Orange
      default:
        return const Color(0xFF6B5B95);
    }
  }

  /// Soft background tint for this question type
  Color get questionTypeLightColor {
    return questionTypeColor.withValues(alpha: 0.12);
  }

  /// Checks whether this instruction matches an action verb filter
  bool matchesActionVerb(String verbKey) {
    if (verbKey == 'all' || verbKey.isEmpty) return true;
    final text = '$originalFr $title'.toLowerCase();
    switch (verbKey.toLowerCase()) {
      case 'relever':
        return text.contains('relèv') || text.contains('relev');
      case 'justifier':
        return text.contains('justifi') ||
            text.contains('vrai') ||
            text.contains('faux') ||
            text.contains('démontr');
      case 'identifier':
        return text.contains('identifi') ||
            text.contains('dégag') ||
            text.contains('soulign') ||
            text.contains('visée');
      case 'transformer':
        return text.contains('réécri') ||
            text.contains('transpos') ||
            text.contains('remplaç') ||
            text.contains('transform');
      case 'rediger':
        return text.contains('rédig') ||
            text.contains('racont') ||
            text.contains('plaidoyer') ||
            text.contains('compte-rendu');
      default:
        return true;
    }
  }

  /// Check whether this instruction matches a search query
  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();

    if (id.toLowerCase().contains(q)) return true;
    if (title.toLowerCase().contains(q)) return true;
    if (level.toLowerCase().contains(q)) return true;
    if (domain.toLowerCase().contains(q)) return true;
    if (questionTypeLabel.toLowerCase().contains(q)) return true;
    if (originalFr.toLowerCase().contains(q)) return true;

    for (final s in steps) {
      if (s.textFr.toLowerCase().contains(q)) return true;
    }

    return false;
  }
}
