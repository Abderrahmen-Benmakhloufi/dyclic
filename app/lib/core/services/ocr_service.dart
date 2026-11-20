import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../widgets/app_asset_icon.dart';

/// Centralized offline OCR service for scanning text from exam sheets or books
/// using on-device Google ML Kit (100% offline, privacy-safe, zero network delay).
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final ImagePicker _picker = ImagePicker();

  /// Prompts the user to choose between Camera or Gallery, then performs on-device OCR.
  /// Returns the extracted French text or null if cancelled/failed.
  Future<String?> scanTextWithPicker(BuildContext context) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _ImageSourceSheet(),
    );

    if (source == null) return null;
    return extractTextFromSource(source);
  }

  /// Takes a photo or picks an image, runs Latin text recognition, and returns cleaned text.
  Future<String?> extractTextFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );

      if (image == null) return null;

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      try {
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        final buffer = StringBuffer();
        for (final block in recognizedText.blocks) {
          for (final line in block.lines) {
            final trimmed = line.text.trim();
            if (trimmed.isNotEmpty) {
              buffer.writeln(trimmed);
            }
          }
        }

        final result = buffer.toString().trim();
        return result.isNotEmpty ? result : null;
      } finally {
        await textRecognizer.close();
      }
    } catch (e) {
      debugPrint('OCR extraction error: $e');
      return null;
    }
  }
}

/// Kid-friendly bottom sheet to select Camera or Gallery
class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: AppAssetIcon(
                assetPath: AppUiAssets.scannerCamera,
                size: 44,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scanner un texte',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Prends une photo nette de ta feuille d\'examen ou de ton livre.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    assetPath: AppUiAssets.scannerCamera,
                    icon: Icons.camera_alt_rounded,
                    label: 'Appareil photo',
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galerie',
                    color: const Color(0xFF0284C7),
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    this.assetPath,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String? assetPath;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            assetPath != null
                ? AppAssetIcon(assetPath: assetPath!, size: 28)
                : Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
