import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_aide/core/reading_settings/reading_settings_model.dart';
import 'package:lecture_aide/core/theme/reading_palette.dart';
import 'package:lecture_aide/features/reading_support/services/french_phoneme_service.dart';

void main() {
  group('ReadingPalette Distinct Colors Tests', () {
    test('All presets ensure syllable colors NEVER match default font color', () {
      for (final preset in ContrastPreset.values) {
        final palette = preset.palette;

        // Syllable 1, 2, 3, 4 must not match textPrimary
        expect(
          palette.syllableColor1 != palette.textPrimary,
          isTrue,
          reason: 'Syllable 1 matches textPrimary in ${preset.name}',
        );
        expect(
          palette.syllableColor2 != palette.textPrimary,
          isTrue,
          reason: 'Syllable 2 matches textPrimary in ${preset.name}',
        );
        expect(
          palette.syllableColor3 != palette.textPrimary,
          isTrue,
          reason: 'Syllable 3 matches textPrimary in ${preset.name}',
        );
        expect(
          palette.syllableColor4 != palette.textPrimary,
          isTrue,
          reason: 'Syllable 4 matches textPrimary in ${preset.name}',
        );

        // Syllable 1, 2, 3, 4 must all be distinct from each other
        final colors = palette.getSyllableColors(4);
        expect(colors.length, 4);
        expect(colors.toSet().length, 4, reason: 'Duplicate syllable colors in ${preset.name}');

        // Mirror letters b, d, p, and q must not match default font color
        expect(palette.mirrorColorB != palette.textPrimary, isTrue);
        expect(palette.mirrorColorD != palette.textPrimary, isTrue);
        expect(palette.mirrorColorP != palette.textPrimary, isTrue);
        expect(palette.mirrorColorQ != palette.textPrimary, isTrue);
      }
    });

    test('Phoneme highlights are vibrant and do not match default font color in light or dark presets', () {
      for (final isDark in [false, true]) {
        final defaultColor = isDark ? ContrastPreset.sombre.palette.textPrimary : ContrastPreset.creme.palette.textPrimary;

        expect(FrenchPhonemeService.colorCH(isDark) != defaultColor, isTrue);
        expect(FrenchPhonemeService.colorPH(isDark) != defaultColor, isTrue);
        expect(FrenchPhonemeService.colorOU(isDark) != defaultColor, isTrue);
        expect(FrenchPhonemeService.colorON(isDark) != defaultColor, isTrue);
        expect(FrenchPhonemeService.colorEFerme(isDark) != defaultColor, isTrue);
        expect(FrenchPhonemeService.colorEOuvert(isDark) != defaultColor, isTrue);
        expect(FrenchPhonemeService.colorGSoft(isDark) != defaultColor, isTrue);
        expect(FrenchPhonemeService.colorGHard(isDark) != defaultColor, isTrue);
        expect(FrenchPhonemeService.colorCSoft(isDark) != defaultColor, isTrue);
        expect(FrenchPhonemeService.colorSVoiced(isDark) != defaultColor, isTrue);
      }
    });
  });
}
