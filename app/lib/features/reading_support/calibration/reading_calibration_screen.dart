import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reading_settings/reading_settings_model.dart';
import '../../../core/reading_settings/reading_settings_notifier.dart';
import '../../../core/theme/reading_palette.dart';
import '../reading_support_screen.dart';

class ReadingCalibrationScreen extends ConsumerStatefulWidget {
  const ReadingCalibrationScreen({super.key});

  @override
  ConsumerState<ReadingCalibrationScreen> createState() =>
      _ReadingCalibrationScreenState();
}

class _ReadingCalibrationScreenState
    extends ConsumerState<ReadingCalibrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Live draft settings adjusted during calibration
  late double _fontSize;
  late double _lineHeight;
  late double _letterSpacing;
  late double _wordSpacing;
  late String _fontFamily;
  late ContrastPreset _contrastPreset;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(readingSettingsProvider);
    _fontSize = initial.fontSize;
    _lineHeight = initial.lineHeight;
    _letterSpacing = initial.letterSpacing;
    _wordSpacing = initial.wordSpacing;
    _fontFamily = initial.fontFamily;
    _contrastPreset = initial.contrastPreset;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeCalibration() async {
    final notifier = ref.read(readingSettingsProvider.notifier);
    await notifier.saveCalibrationSettings(
      fontSize: _fontSize,
      lineHeight: _lineHeight,
      letterSpacing: _letterSpacing,
      wordSpacing: _wordSpacing,
      fontFamily: _fontFamily,
      contrastPreset: _contrastPreset,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ReadingSupportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _contrastPreset.palette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Calibrage de lecture'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _completeCalibration,
            child: const Text('Passer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            _buildProgressIndicator(palette),

            // Live Interactive Preview Box (anchored at top)
            _buildLivePreviewBox(palette),

            const SizedBox(height: 8),

            // Wizard Step Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentStep = page),
                children: [
                  _buildStep1Typography(palette),
                  _buildStep2Spacing(palette),
                  _buildStep3Contrast(palette),
                ],
              ),
            ),

            // Bottom Navigation Controls
            _buildBottomBar(palette),
          ],
        ),
      ),
    );
  }

  // ── Step Progress Indicator ────────────────────────────────────────────────

  Widget _buildProgressIndicator(ReadingPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étape ${_currentStep + 1} sur 3',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: palette.primary,
                ),
              ),
              Text(
                _currentStep == 0
                    ? 'Taille & Police'
                    : _currentStep == 1
                        ? 'Espacements'
                        : 'Contraste & Couleur',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation(palette.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky Live Preview Box ────────────────────────────────────────────────

  Widget _buildLivePreviewBox(ReadingPalette palette) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Aperçu en direct',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
              ),
              Text(
                '${_fontSize.round()} pt  •  $_fontFamily',
                softWrap: true,
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: _fontSize,
              fontFamily: _fontFamily,
              height: _lineHeight,
              letterSpacing: _letterSpacing,
              wordSpacing: _wordSpacing,
              color: palette.textPrimary,
            ),
            child: const Text(
              'Les élèves découvrent une belle histoire en classe. Chaque mot devient plus clair et plus facile à lire avec les bons réglages.',
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  // ── Étape 1 : Taille & Police ──────────────────────────────────────────────

  Widget _buildStep1Typography(ReadingPalette palette) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '1. Taille du texte',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Règle la taille pour lire sans forcer sur tes yeux.',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.primary, width: 1.2),
                ),
                child: Text(
                  '${_fontSize.round()} pt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('A', style: TextStyle(fontSize: 14, color: palette.textSecondary)),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 14.0,
                  max: 28.0,
                  divisions: 14,
                  label: '${_fontSize.round()} pt',
                  activeColor: palette.primary,
                  onChanged: (val) => setState(() => _fontSize = val),
                ),
              ),
              Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: palette.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            '2. Police d\'écriture',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choisis le style de lettre qui t’évite les confusions.',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
          const SizedBox(height: 12),

          _buildFontOptionCard(
            title: 'Atkinson Hyperlegible',
            subtitle: 'Conçu médicalement pour distinguer chaque lettre',
            fontFamily: 'Atkinson Hyperlegible',
            palette: palette,
          ),
          const SizedBox(height: 8),
          _buildFontOptionCard(
            title: 'Lexend',
            subtitle: 'Espacements et formes optimisés pour la fluidité',
            fontFamily: 'Lexend',
            palette: palette,
          ),
          const SizedBox(height: 8),
          _buildFontOptionCard(
            title: 'Arial',
            subtitle: 'Police standard, neutre et familière',
            fontFamily: 'Arial',
            palette: palette,
          ),
          const SizedBox(height: 8),
          _buildFontOptionCard(
            title: 'OpenDyslexic',
            subtitle: 'Base des lettres plus lourde pour éviter les inversions',
            fontFamily: 'OpenDyslexic',
            palette: palette,
          ),
        ],
      ),
    );
  }

  Widget _buildFontOptionCard({
    required String title,
    required String subtitle,
    required String fontFamily,
    required ReadingPalette palette,
  }) {
    final isSelected = _fontFamily == fontFamily;

    return InkWell(
      onTap: () => setState(() => _fontFamily = fontFamily),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.primary.withValues(alpha: 0.12)
              : palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? palette.primary : palette.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    softWrap: true,
                    style: TextStyle(fontSize: 11, color: palette.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: palette.primary, size: 22)
            else
              Icon(Icons.radio_button_unchecked, color: palette.border, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Étape 2 : Espacements ──────────────────────────────────────────────────

  Widget _buildStep2Spacing(ReadingPalette palette) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Letter Spacing
          Text(
            '1. Espacement entre les lettres',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Éloigne les lettres pour éviter l\'encombrement visuel.',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.primary, width: 1.0),
                ),
                child: Text(
                  '${_letterSpacing.toStringAsFixed(1)} px',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _letterSpacing,
                  min: 0.0,
                  max: 3.0,
                  divisions: 6,
                  activeColor: palette.primary,
                  label: '${_letterSpacing.toStringAsFixed(1)} px',
                  onChanged: (val) => setState(() => _letterSpacing = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Word Spacing
          Text(
            '2. Espacement entre les mots',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Aide à repérer les limites de chaque mot clairement.',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.primary, width: 1.0),
                ),
                child: Text(
                  '${_wordSpacing.toStringAsFixed(1)} px',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _wordSpacing,
                  min: 0.0,
                  max: 6.0,
                  divisions: 6,
                  activeColor: palette.primary,
                  label: '${_wordSpacing.toStringAsFixed(1)} px',
                  onChanged: (val) => setState(() => _wordSpacing = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Line Height
          Text(
            '3. Hauteur des lignes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Évite de sauter une ligne ou de relire la même.',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.primary, width: 1.0),
                ),
                child: Text(
                  '${_lineHeight.toStringAsFixed(1)}x',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _lineHeight,
                  min: 1.4,
                  max: 2.2,
                  divisions: 8,
                  activeColor: palette.primary,
                  label: '${_lineHeight.toStringAsFixed(1)}x',
                  onChanged: (val) => setState(() => _lineHeight = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Étape 3 : Contraste & Couleurs ─────────────────────────────────────────

  Widget _buildStep3Contrast(ReadingPalette palette) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ambiance visuelle et contraste',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choisis la combinaison qui repose le mieux tes yeux.',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
          const SizedBox(height: 16),

          _buildContrastCard(
            title: 'Crème doux (Recommandé)',
            description: 'Fond papier chaud, réduit l\'éblouissement',
            preset: ContrastPreset.creme,
            bgColor: const Color(0xFFF8F7F4),
            textColor: const Color(0xFF1F2937),
            palette: palette,
          ),
          const SizedBox(height: 10),
          _buildContrastCard(
            title: 'Blanc pur (Contraste élevé)',
            description: 'Contraste maximal entre noir et blanc',
            preset: ContrastPreset.clair,
            bgColor: const Color(0xFFFFFFFF),
            textColor: const Color(0xFF000000),
            palette: palette,
          ),
          const SizedBox(height: 10),
          _buildContrastCard(
            title: 'Mode Sombre',
            description: 'Idéal en faible luminosité, grand repos oculaire',
            preset: ContrastPreset.sombre,
            bgColor: const Color(0xFF0F172A),
            textColor: const Color(0xFFF8FAFC),
            palette: palette,
          ),
          const SizedBox(height: 10),
          _buildContrastCard(
            title: 'Bleu reposant',
            description: 'Teinte pastel fraîche favorisant la concentration',
            preset: ContrastPreset.bleu,
            bgColor: const Color(0xFFEFF6FF),
            textColor: const Color(0xFF1E3A8A),
            palette: palette,
          ),
        ],
      ),
    );
  }

  Widget _buildContrastCard({
    required String title,
    required String description,
    required ContrastPreset preset,
    required Color bgColor,
    required Color textColor,
    required ReadingPalette palette,
  }) {
    final isSelected = _contrastPreset == preset;

    return InkWell(
      onTap: () => setState(() => _contrastPreset = preset),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? palette.primary : palette.border,
            width: isSelected ? 2.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Preview Circle showing contrast
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
              alignment: Alignment.center,
              child: Text(
                'Aa',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    softWrap: true,
                    style: TextStyle(fontSize: 11, color: palette.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: palette.primary, size: 24)
            else
              Icon(Icons.radio_button_unchecked, color: palette.border, size: 24),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation Controls ─────────────────────────────────────────────

  Widget _buildBottomBar(ReadingPalette palette) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                key: const ValueKey('calibration_prev_btn'),
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.textPrimary,
                  side: BorderSide(color: palette.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Précédent', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              key: ValueKey(_currentStep == 2
                  ? 'calibration_finish_btn'
                  : 'calibration_next_btn'),
              onPressed: _currentStep == 2 ? _completeCalibration : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == 2 ? 'Valider mes réglages' : 'Suivant',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _currentStep == 2
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
