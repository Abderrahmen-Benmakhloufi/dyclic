import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/instruction_model.dart';

/// Service managing locally cached and previously analyzed instructions (History).
class InstructionCacheService {
  static const String _kHistoryKey = 'ai_instructions_history';
  static const int _kMaxHistoryItems = 25;

  final SharedPreferences _prefs;

  InstructionCacheService(this._prefs);

  /// Normalized key for matching: lowercase, alphanumeric and spaces only
  static String normalizeKey(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Get all cached instruction items (newest first)
  List<InstructionItem> getHistory() {
    final rawList = _prefs.getStringList(_kHistoryKey) ?? [];
    final items = <InstructionItem>[];
    for (final raw in rawList) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        items.add(InstructionItem.fromJson(json));
      } catch (_) {
        // Skip corrupted entries
      }
    }
    return items;
  }

  /// Check if an identical or near-identical question was already analyzed
  InstructionItem? findInCache(String questionText, [String? cycle]) {
    final queryNorm = normalizeKey(questionText);
    if (queryNorm.isEmpty) return null;

    final history = getHistory();
    for (final item in history) {
      if (cycle != null &&
          cycle.isNotEmpty &&
          item.cycle.toLowerCase() != cycle.toLowerCase()) {
        continue;
      }
      final itemNorm = normalizeKey(item.originalFr);
      if (itemNorm == queryNorm) {
        return item;
      }
    }
    return null;
  }

  /// Save an instruction to history (moves to top if already exists)
  Future<void> saveInstruction(InstructionItem item) async {
    final history = getHistory();

    // Remove duplicates by normalized text
    final itemNorm = normalizeKey(item.originalFr);
    history.removeWhere((existing) =>
        normalizeKey(existing.originalFr) == itemNorm ||
        existing.id == item.id);

    // Insert at front
    history.insert(0, item);

    // Trim to maximum count
    if (history.length > _kMaxHistoryItems) {
      history.removeRange(_kMaxHistoryItems, history.length);
    }

    final rawList = history.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_kHistoryKey, rawList);
  }

  /// Delete a single entry by ID
  Future<void> deleteInstruction(String id) async {
    final history = getHistory();
    history.removeWhere((item) => item.id == id);
    final rawList = history.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_kHistoryKey, rawList);
  }

  /// Clear entire history
  Future<void> clearHistory() async {
    await _prefs.remove(_kHistoryKey);
  }
}
