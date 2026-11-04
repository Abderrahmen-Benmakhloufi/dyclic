import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tts/tts_service.dart';

/// Écran de Diagnostic TTS — Permet de vérifier le moteur, les langues,
/// le volume, et d'installer les données vocales si nécessaire.
class TtsDiagnosticsScreen extends ConsumerStatefulWidget {
  const TtsDiagnosticsScreen({super.key});

  @override
  ConsumerState<TtsDiagnosticsScreen> createState() =>
      _TtsDiagnosticsScreenState();
}

class _TtsDiagnosticsScreenState
    extends ConsumerState<TtsDiagnosticsScreen> {
  Map<String, dynamic> _diagnostics = {};
  bool _loading = true;
  String _testResult = '';
  String _speakLog = '';

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _loading = true);
    try {
      final tts = ref.read(ttsServiceProvider);
      final diag = await tts.getDiagnostics();
      if (mounted) {
        setState(() {
          _diagnostics = diag;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _diagnostics = {'error': e.toString()};
          _loading = false;
        });
      }
    }
  }

  Future<void> _testSpeak(String text) async {
    final tts = ref.read(ttsServiceProvider);
    setState(() {
      _speakLog = 'Lecture en cours : "$text"...';
      _testResult = '';
    });
    await tts.speakText(text);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _testResult =
            'lastError: ${tts.lastError ?? "aucun"}\n'
            'isPlaying: ${tts.isPlaying}\n'
            'isReady: ${tts.isReady}';
      });
    }
  }

  Future<void> _reinitTts() async {
    final tts = ref.read(ttsServiceProvider);
    setState(() => _speakLog = 'Réinitialisation en cours...');
    final result = await tts.reinitialize();
    if (mounted) {
      setState(() => _speakLog = 'Résultat : $result');
      await _loadDiagnostics();
    }
  }

  Future<void> _openSettings() async {
    final tts = ref.read(ttsServiceProvider);
    final ok = await tts.openTtsSettings();
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir les paramètres TTS du système.'),
        ),
      );
    }
  }

  Future<void> _installVoiceData() async {
    final tts = ref.read(ttsServiceProvider);
    final ok = await tts.installVoiceData();
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action non supportée par le système.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Vocal (TTS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiagnostics,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status card
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Moteur Vocal Hybride Prêt ✓',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Audio MP3 natif studio + 43 mots intégrés hors-ligne + synthèse française.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Actions rapides
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paramètres système Android',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _openSettings,
                                icon: const Icon(Icons.settings_voice_rounded, size: 18),
                                label: const Text('Paramètres TTS Android'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _installVoiceData,
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: const Text('Installer voix française'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _reinitTts,
                                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                                label: const Text('Réinitialiser'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Diagnostics details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations détaillées',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          ..._diagnostics.entries
                              .where((e) =>
                                  e.key != 'engines' && e.key != 'languages')
                              .map(
                                (e) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          e.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${e.value}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _getValueColor(
                                                e.key, e.value),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Engines
                  if (_diagnostics['engines'] != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Moteurs TTS disponibles',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            ...(_diagnostics['engines'] as List<dynamic>)
                                .map(
                                  (e) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.speaker_notes, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$e',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Tests d'écoute
                  const Text(
                    'Tester la lecture à voix haute',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _testSpeak('gare'),
                        icon: const Icon(Icons.volume_up, size: 18),
                        label: const Text('gare (intégré)'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _testSpeak('soleil'),
                        icon: const Icon(Icons.volume_up, size: 18),
                        label: const Text('soleil (intégré)'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _testSpeak('Bonjour'),
                        icon: const Icon(Icons.volume_up, size: 18),
                        label: const Text('Bonjour'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _testSpeak('Le chat dort sur la table.'),
                        icon: const Icon(Icons.volume_up, size: 18),
                        label: const Text('Phrase complète'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _testSpeak('garçon'),
                        icon: const Icon(Icons.volume_up, size: 18),
                        label: const Text('garçon'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Logs
                  if (_speakLog.isNotEmpty || _testResult.isNotEmpty)
                    Card(
                      color: Colors.grey.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Résultat du test en direct',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_speakLog.isNotEmpty)
                              Text(
                                _speakLog,
                                style: const TextStyle(fontSize: 13),
                              ),
                            if (_testResult.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _testResult,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Color? _getValueColor(String key, dynamic value) {
    if (key == 'frenchAvailability') {
      final v = value.toString();
      if (v.contains('AVAILABLE')) return Colors.green.shade700;
      if (v.contains('MISSING')) return Colors.orange.shade700;
      if (v.contains('NOT_SUPPORTED')) return Colors.red.shade700;
    }
    if (key == 'mediaVolume') {
      final parts = value.toString().split('/');
      if (parts.length == 2) {
        final current = int.tryParse(parts[0]) ?? 0;
        if (current == 0) return Colors.red.shade700;
      }
    }
    return null;
  }
}
