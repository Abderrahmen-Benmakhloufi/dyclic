import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reading_settings/reading_settings_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/tts/tts_service.dart';
import '../diagnostics/tts_diagnostics_screen.dart';
import '../reading_settings/reading_settings_sheet.dart';

class TtsScreen extends ConsumerStatefulWidget {
  const TtsScreen({super.key});

  @override
  ConsumerState<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends ConsumerState<TtsScreen> {
  final TextEditingController _controller = TextEditingController();
  late final TtsService _ttsService;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ttsService = ref.read(ttsServiceProvider);
    _ttsService.isPlayingNotifier.addListener(_onTtsChanged);
  }

  void _onTtsChanged() {
    if (mounted) {
      setState(() {
        _isPlaying = _ttsService.isPlayingNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    _ttsService.isPlayingNotifier.removeListener(_onTtsChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleSpeak() async {
    if (_isPlaying) {
      await _ttsService.stop();
    } else {
      final text = _controller.text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Écris ou colle d’abord un texte à écouter.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await _ttsService.speakText(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(readingSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Écouter le texte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services_outlined),
            tooltip: 'Diagnostic vocal',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TtsDiagnosticsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Réglages de lecture',
            onPressed: () => ReadingSettingsSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🔊', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Synthèse Vocale Directe',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Écoute n’importe quel texte à voix haute en français.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons (Coller, Effacer)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null && data!.text!.isNotEmpty) {
                          _controller.text = data.text!;
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.content_paste_rounded, size: 20),
                      label: const Text('Coller'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_controller.text.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      label: const Text('Effacer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Text Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  minLines: 6,
                  maxLines: 12,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: settings.fontSize.clamp(16.0, 22.0),
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Colle ou écris ton texte ici pour l’écouter...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Speak Button
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _toggleSpeak,
                  icon: Icon(
                    _isPlaying
                        ? Icons.stop_circle_rounded
                        : Icons.volume_up_rounded,
                    size: 24,
                  ),
                  label: Text(
                    _isPlaying ? 'Arrêter la lecture' : 'Écouter à voix haute',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying
                        ? AppColors.errorRed
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Diagnostic link card
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TtsDiagnosticsScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Un problème de son ? Ouvre le diagnostic vocal.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
