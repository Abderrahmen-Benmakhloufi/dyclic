import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/writing_feedback_model.dart';

/// Service managing locally saved writing evaluations (History) and Favorites.
class WritingCacheService {
  static const String _kHistoryKey = 'writing_feedback_history';
  static const String _kFavoritesKey = 'writing_feedback_favorites';
  static const int _kMaxHistoryItems = 25;

  final SharedPreferences _prefs;

  WritingCacheService(this._prefs);

  /// Normalized key for text comparison
  static String normalizeKey(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ── History Management ────────────────────────────────────────────────────

  List<WritingFeedbackResult> getHistory() {
    final rawList = _prefs.getStringList(_kHistoryKey) ?? [];
    final items = <WritingFeedbackResult>[];
    for (final raw in rawList) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        items.add(WritingFeedbackResult.fromJson(json));
      } catch (_) {
        // Skip corrupted entries
      }
    }
    return items;
  }

  /// Find an existing analysis if exact same text, subject, and cycle were already analyzed
  WritingFeedbackResult? findInCache(
    String text, {
    String subject = '',
    String? cycle,
  }) {
    final textNorm = normalizeKey(text);
    final subjectNorm = normalizeKey(subject);
    if (textNorm.isEmpty) return null;

    final history = getHistory();
    for (final item in history) {
      if (cycle != null &&
          cycle.isNotEmpty &&
          item.cycle.toLowerCase() != cycle.toLowerCase()) {
        continue;
      }
      if (normalizeKey(item.originalText) == textNorm &&
          normalizeKey(item.subjectPrompt) == subjectNorm) {
        return item;
      }
    }
    return null;
  }

  Future<void> saveResult(WritingFeedbackResult result) async {
    final history = getHistory();
    final textNorm = normalizeKey(result.originalText);
    final subjectNorm = normalizeKey(result.subjectPrompt);

    history.removeWhere((existing) =>
        existing.id == result.id ||
        (normalizeKey(existing.originalText) == textNorm &&
            normalizeKey(existing.subjectPrompt) == subjectNorm &&
            existing.cycle == result.cycle));

    history.insert(0, result);

    if (history.length > _kMaxHistoryItems) {
      history.removeRange(_kMaxHistoryItems, history.length);
    }

    final rawList = history.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_kHistoryKey, rawList);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_kHistoryKey);
  }

  // ── Favorites Management ──────────────────────────────────────────────────

  List<WritingFeedbackResult> getFavorites() {
    final rawList = _prefs.getStringList(_kFavoritesKey) ?? [];
    final items = <WritingFeedbackResult>[];
    for (final raw in rawList) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        items.add(WritingFeedbackResult.fromJson(json));
      } catch (_) {
        // Skip corrupted entries
      }
    }
    return items;
  }

  bool isFavorite(String id, [String? originalText]) {
    final favorites = getFavorites();
    final norm = originalText != null ? normalizeKey(originalText) : null;
    return favorites.any((f) =>
        f.id == id || (norm != null && normalizeKey(f.originalText) == norm));
  }

  Future<bool> toggleFavorite(WritingFeedbackResult item) async {
    final favorites = getFavorites();
    final itemNorm = normalizeKey(item.originalText);

    final existingIndex = favorites.indexWhere((f) =>
        f.id == item.id ||
        (itemNorm.isNotEmpty && normalizeKey(f.originalText) == itemNorm));

    bool isNowFavorite;
    if (existingIndex >= 0) {
      favorites.removeAt(existingIndex);
      isNowFavorite = false;
    } else {
      favorites.insert(0, item);
      isNowFavorite = true;
    }

    final rawList = favorites.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_kFavoritesKey, rawList);
    return isNowFavorite;
  }
}
