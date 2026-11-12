import 'package:flutter/foundation.dart';
import 'writing_feedback_model.dart';

/// Compact cumulative profile of a student's writing mistakes across essays.
/// Used to give Gemini AI concise historical context without token bloat.
@immutable
class WritingErrorProfile {
  static const int _kMaxStoredPairs = 25;
  static const int _kMaxPromptPairs = 8;

  final int totalEssays;
  final Map<String, int> categoryCounts;
  final Map<String, int> recurringErrors; // e.g. "chavel -> cheval": 3

  const WritingErrorProfile({
    this.totalEssays = 0,
    this.categoryCounts = const {},
    this.recurringErrors = const {},
  });

  factory WritingErrorProfile.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categoryCounts'] as Map<String, dynamic>? ?? {};
    final rawPairs = json['recurringErrors'] as Map<String, dynamic>? ?? {};

    return WritingErrorProfile(
      totalEssays: json['totalEssays'] as int? ?? 0,
      categoryCounts:
          rawCats.map((k, v) => MapEntry(k, (v as num).toInt())),
      recurringErrors:
          rawPairs.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalEssays': totalEssays,
        'categoryCounts': categoryCounts,
        'recurringErrors': recurringErrors,
      };

  /// Returns a new [WritingErrorProfile] updated with mistakes from [result].
  WritingErrorProfile recordFeedback(WritingFeedbackResult result) {
    final nextCats = Map<String, int>.from(categoryCounts);
    final nextPairs = Map<String, int>.from(recurringErrors);

    for (final err in result.errors) {
      final catKey = err.category.code;
      nextCats[catKey] = (nextCats[catKey] ?? 0) + 1;

      final wrong = err.wrongText.trim().toLowerCase();
      final correct = err.correctedText.trim().toLowerCase();
      if (wrong.isNotEmpty && correct.isNotEmpty && wrong != correct) {
        final pairKey = '$wrong -> $correct';
        nextPairs[pairKey] = (nextPairs[pairKey] ?? 0) + 1;
      }
    }

    // Keep only top [_kMaxStoredPairs] entries sorted by frequency descending
    if (nextPairs.length > _kMaxStoredPairs) {
      final sorted = nextPairs.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      nextPairs
        ..clear()
        ..addEntries(sorted.take(_kMaxStoredPairs));
    }

    return WritingErrorProfile(
      totalEssays: totalEssays + 1,
      categoryCounts: nextCats,
      recurringErrors: nextPairs,
    );
  }

  /// Generates a compact, token-efficient summary (~60-100 tokens) for Gemini.
  String toCompactPromptSummary() {
    if (totalEssays <= 0) return '';

    final sortedCats = categoryCounts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCatsText = sortedCats.take(3).map((e) {
      final cat = WritingErrorCategoryX.fromCode(e.key);
      return '${cat.labelFr} (${e.value})';
    }).join(', ');

    final repeatedPairs = recurringErrors.entries
        .where((e) => e.value >= 2)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pairsToInclude = repeatedPairs.isNotEmpty
        ? repeatedPairs.take(_kMaxPromptPairs).toList()
        : (recurringErrors.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(4)
            .toList();

    final pairsText = pairsToInclude
        .map((e) => '"${e.key}" (${e.value}x)')
        .join(', ');

    final buffer = StringBuffer()
      ..writeln(
          'Historique des erreurs de l\'élève (sur $totalEssays production${totalEssays > 1 ? 's' : ''}) :');

    if (topCatsText.isNotEmpty) {
      buffer.writeln('- Catégories les plus fréquentes : $topCatsText.');
    }
    if (pairsText.isNotEmpty) {
      buffer.writeln('- Erreurs déjà rencontrées : $pairsText.');
    }
    buffer.writeln(
        'Consigne historique : Si l\'élève répète une erreur déjà rencontrée, signale-le avec bienveillance et donne une nouvelle astuce plus visuelle. S\'il a évité ses erreurs habituelles, félicite-le !');

    return buffer.toString();
  }
}
