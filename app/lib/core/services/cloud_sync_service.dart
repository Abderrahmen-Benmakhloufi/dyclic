import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../reading_settings/reading_settings_model.dart';
import '../reading_settings/reading_settings_notifier.dart';
import 'supabase_service.dart';

/// Provider stockant en cache le résumé des erreurs récurrentes pour l'injection IA.
final cachedLearnerMistakesSummaryProvider =
    StateProvider<String>((ref) => '');

/// Service de synchronisation bidirectionnelle entre l'application et Supabase.
class CloudSyncService {
  /// Synchronise les données depuis Supabase vers l'état local Riverpod.
  /// À appeler à la connexion et au démarrage si une session existe.
  static Future<void> syncFromCloud(WidgetRef ref) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      debugPrint('🔄 Synchronisation Cloud Supabase pour ${user.email}...');

      // 1. Charger le profil (niveau scolaire / cycle)
      final profile = await SupabaseService.loadUserProfile();
      if (profile != null) {
        final cycleStr = profile['cycle']?.toString();
        if (cycleStr != null && cycleStr.isNotEmpty) {
          LearnerLevel? level;
          if (cycleStr.contains('primaire') || cycleStr.contains('cycle3')) {
            level = LearnerLevel.primaire;
          } else if (cycleStr.contains('secondaire') || cycleStr.contains('lycee')) {
            level = LearnerLevel.secondaire;
          } else {
            level = LearnerLevel.moyen;
          }
          await ref.read(readingSettingsProvider.notifier).setLearnerLevel(level);
        }
      }

      // 2. Charger les réglages de lecture DYS
      final settings = await SupabaseService.loadReadingSettings();
      if (settings != null) {
        final notifier = ref.read(readingSettingsProvider.notifier);
        if (settings['font_size'] != null) {
          await notifier.setFontSize((settings['font_size'] as num).toDouble());
        }
        if (settings['line_spacing'] != null) {
          await notifier.setLineHeight((settings['line_spacing'] as num).toDouble());
        }
        if (settings['letter_spacing'] != null) {
          await notifier.setLetterSpacing((settings['letter_spacing'] as num).toDouble());
        }
        if (settings['word_spacing'] != null) {
          await notifier.setWordSpacing((settings['word_spacing'] as num).toDouble());
        }
      }

      // 3. Charger le résumé synthétique des erreurs pour l'IA
      final mistakesSummary = await SupabaseService.getTopMistakesSummaryForAi();
      ref.read(cachedLearnerMistakesSummaryProvider.notifier).state = mistakesSummary;

      debugPrint('✅ Synchronisation Cloud terminée avec succès.');
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la synchronisation Cloud: $e');
    }
  }

  /// Sauvegarde l'état local actuel vers Supabase.
  static Future<void> syncToCloud(WidgetRef ref) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final currentSettings = ref.read(readingSettingsProvider);

      // Sauvegarde du cycle
      await SupabaseService.updateLearnerCycle(currentSettings.learnerLevel.code);

      // Sauvegarde des réglages DYS
      await SupabaseService.saveReadingSettings(
        fontFamily: currentSettings.fontFamily,
        fontSize: currentSettings.fontSize,
        lineSpacing: currentSettings.lineHeight,
        letterSpacing: currentSettings.letterSpacing,
        wordSpacing: currentSettings.wordSpacing,
        highContrast: currentSettings.contrastPreset != ContrastPreset.creme,
        highlightMode: currentSettings.syllableColorCount.toString(),
      );
    } catch (e) {
      debugPrint('⚠️ Erreur synchronisation vers le Cloud: $e');
    }
  }
}
