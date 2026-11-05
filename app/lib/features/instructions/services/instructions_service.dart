import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/instruction_model.dart';

/// Service responsible for loading, parsing, caching and querying
/// the 17 standardized decomposed exam instructions offline.
class InstructionsService {
  InstructionsService._();
  static final InstructionsService instance = InstructionsService._();

  static const String assetPath = 'assets/data/consignes.json';

  List<InstructionItem>? _cachedInstructions;

  /// Loads the instructions list from assets (cached in-memory after first load)
  Future<List<InstructionItem>> loadInstructions() async {
    if (_cachedInstructions != null) {
      return _cachedInstructions!;
    }

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is List) {
        _cachedInstructions = decoded
            .map((item) =>
                InstructionItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _cachedInstructions = [];
      }
    } catch (_) {
      _cachedInstructions = [];
    }

    return _cachedInstructions!;
  }

  /// Synchronous getter if already loaded
  List<InstructionItem> get cachedItems => _cachedInstructions ?? [];

  /// Filters a list of instructions by cycle, questionType, actionVerb, and search query
  List<InstructionItem> filterAndSearch({
    required List<InstructionItem> items,
    String cycle = 'all', // 'all' | 'primaire' | 'college' | 'lycee'
    String questionType = 'all', // 'all' | 'comprehension' | 'langue' | 'production'
    String actionVerb = 'all', // 'all' | 'relever' | 'justifier' | 'identifier' | 'transformer' | 'rediger'
    String query = '',
  }) {
    return items.where((item) {
      // 1. Cycle filter
      if (cycle != 'all' && item.cycle.toLowerCase() != cycle.toLowerCase()) {
        return false;
      }

      // 2. Question type filter
      if (questionType != 'all' &&
          item.questionType.toLowerCase() != questionType.toLowerCase()) {
        return false;
      }

      // 3. Action verb filter
      if (actionVerb != 'all' && !item.matchesActionVerb(actionVerb)) {
        return false;
      }

      // 4. Search query filter
      if (query.trim().isNotEmpty && !item.matchesQuery(query)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Clear in-memory cache (useful for testing)
  void clearCache() {
    _cachedInstructions = null;
  }
}
