import '../models/instruction_model.dart';
import 'instruction_cache_service.dart';
import 'instructions_service.dart';

/// Result of matching user query against official catalog instructions
class LocalMatchResult {
  final InstructionItem item;
  final double confidence; // 0.0 to 1.0
  final bool isExact;

  const LocalMatchResult({
    required this.item,
    required this.confidence,
    required this.isExact,
  });
}

/// Service to match user-entered exam queries instantly against the 17 official catalog items
class InstructionMatchingService {
  InstructionMatchingService._();

  /// Stop words in French to exclude from token comparison
  static const Set<String> _kFrenchStopWords = {
    'le', 'la', 'les', 'l', 'un', 'une', 'des', 'du', 'de', 'd',
    'ce', 'cet', 'cette', 'ces', 'dans', 'en', 'sur', 'sous', 'par',
    'pour', 'avec', 'sans', 'qui', 'que', 'quoi', 'dont', 'ou',
    'et', 'au', 'aux', 'a', 'ta', 'ton', 'tes', 'sa', 'son', 'ses',
    'notre', 'votre', 'leur', 'leurs', 'est', 'sont', 'texte'
  };

  /// Tokenize and filter stop words
  static Set<String> _extractKeywords(String text) {
    final norm = InstructionCacheService.normalizeKey(text);
    final words = norm.split(' ');
    return words
        .where((w) => w.length > 2 && !_kFrenchStopWords.contains(w))
        .toSet();
  }

  /// Calculates Jaccard similarity between two keyword sets
  static double _calculateSimilarity(Set<String> setA, Set<String> setB) {
    if (setA.isEmpty || setB.isEmpty) return 0.0;
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }

  /// Attempt to find a high-confidence match in the official catalog
  static Future<LocalMatchResult?> findBestMatch({
    required String query,
    String? cycle,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    final catalog = await InstructionsService.instance.loadInstructions();
    if (catalog.isEmpty) return null;

    final queryNorm = InstructionCacheService.normalizeKey(cleanQuery);
    final queryKeywords = _extractKeywords(cleanQuery);

    LocalMatchResult? bestResult;
    double maxConfidence = 0.0;

    for (final item in catalog) {
      // If cycle is specified, prioritize matching cycle
      final cycleMatches = cycle == null ||
          cycle.isEmpty ||
          item.cycle.toLowerCase() == cycle.toLowerCase();

      final itemNorm = InstructionCacheService.normalizeKey(item.originalFr);

      // 1. Exact normalized match
      if (queryNorm == itemNorm) {
        return LocalMatchResult(
          item: item,
          confidence: 1.0,
          isExact: true,
        );
      }

      // 2. Query contains the item text or item text contains query (substring)
      if (queryNorm.length > 15 && itemNorm.contains(queryNorm)) {
        final confidence = (queryNorm.length / itemNorm.length).clamp(0.85, 0.99);
        if (confidence > maxConfidence) {
          maxConfidence = confidence;
          bestResult = LocalMatchResult(
            item: item,
            confidence: confidence,
            isExact: false,
          );
        }
        continue;
      }

      if (itemNorm.length > 15 && queryNorm.contains(itemNorm)) {
        final confidence = (itemNorm.length / queryNorm.length).clamp(0.85, 0.99);
        if (confidence > maxConfidence) {
          maxConfidence = confidence;
          bestResult = LocalMatchResult(
            item: item,
            confidence: confidence,
            isExact: false,
          );
        }
        continue;
      }

      // 3. Keyword / semantic token similarity
      final itemKeywords = _extractKeywords(item.originalFr);
      final similarity = _calculateSimilarity(queryKeywords, itemKeywords);

      // Boost if cycle matches
      final score = cycleMatches ? similarity : similarity * 0.85;

      // Threshold: at least 65% keyword overlap to consider a confident match
      if (score >= 0.65 && score > maxConfidence) {
        maxConfidence = score;
        bestResult = LocalMatchResult(
          item: item,
          confidence: score,
          isExact: false,
        );
      }
    }

    return bestResult;
  }
}
