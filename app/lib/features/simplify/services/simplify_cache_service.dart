import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simplify_model.dart';

/// Manages local caching of simplified texts (History and Favorites) for offline access.
class SimplifyCacheService {
  static const String _kHistoryKey = 'ai_simplify_history';
  static const String _kFavoritesKey = 'ai_simplify_favorites';
  static const int _kMaxHistoryItems = 25;

  final SharedPreferences _prefs;

  SimplifyCacheService(this._prefs);

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

  /// Get all cached simplified items (newest first)
  List<SimplifyResult> getHistory() {
    final rawList = _prefs.getStringList(_kHistoryKey) ?? [];
    final items = <SimplifyResult>[];
    for (final raw in rawList) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        items.add(SimplifyResult.fromJson(json));
      } catch (_) {
        // Skip corrupted entries
      }
    }
    return items;
  }

  /// Get all favorited items
  List<SimplifyResult> getFavorites() {
    final rawList = _prefs.getStringList(_kFavoritesKey) ?? [];
    final items = <SimplifyResult>[];
    for (final raw in rawList) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        items.add(SimplifyResult.fromJson(json));
      } catch (_) {
        // Skip corrupted entries
      }
    }
    return items;
  }

  /// Check if a specific result is marked as favorite
  bool isFavorite(String id, String originalText) {
    final favs = getFavorites();
    final norm = normalizeKey(originalText);
    return favs.any((item) =>
        item.id == id || (norm.isNotEmpty && normalizeKey(item.originalText) == norm));
  }

  /// Toggle favorite status of a result
  Future<bool> toggleFavorite(SimplifyResult result) async {
    final favs = getFavorites();
    final norm = normalizeKey(result.originalText);
    final index = favs.indexWhere((item) =>
        item.id == result.id || (norm.isNotEmpty && normalizeKey(item.originalText) == norm));

    bool isNowFav;
    if (index >= 0) {
      favs.removeAt(index);
      isNowFav = false;
    } else {
      favs.insert(0, result);
      isNowFav = true;
    }

    final rawList = favs.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_kFavoritesKey, rawList);
    return isNowFav;
  }

  /// Check if an identical text was already analyzed (for instant local recovery)
  SimplifyResult? findInCache(String text, [String? cycle]) {
    final queryNorm = normalizeKey(text);
    if (queryNorm.isEmpty) return null;

    final history = getHistory();
    for (final item in history) {
      if (cycle != null &&
          cycle.isNotEmpty &&
          item.cycle.toLowerCase() != cycle.toLowerCase()) {
        continue;
      }
      final itemNorm = normalizeKey(item.originalText);
      if (itemNorm == queryNorm) {
        return item;
      }
    }
    return null;
  }

  /// Save a simplification result to history (moves to top if already exists)
  Future<void> saveResult(SimplifyResult item) async {
    final history = getHistory();

    // Remove duplicate by normalized text
    final itemNorm = normalizeKey(item.originalText);
    history.removeWhere(
        (existing) => normalizeKey(existing.originalText) == itemNorm);

    // Insert at front
    history.insert(0, item);

    // Limit size
    if (history.length > _kMaxHistoryItems) {
      history.removeRange(_kMaxHistoryItems, history.length);
    }

    final rawList = history.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_kHistoryKey, rawList);
  }

  /// Delete a single entry from history
  Future<void> deleteFromHistory(String id) async {
    final history = getHistory();
    history.removeWhere((item) => item.id == id);
    final rawList = history.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_kHistoryKey, rawList);
  }

  /// Clear all history entries (preserves favorites)
  Future<void> clearHistory() async {
    await _prefs.remove(_kHistoryKey);
  }
}
