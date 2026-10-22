import 'package:flutter/material.dart';

/// App color palette matching the pedagogical and accessible guidelines
/// specified by the project owner and client.
class AppColors {
  AppColors._();

  // Primary brand & theme tokens
  static const Color background = Color(0xFFF8F7F4); // Warm calm cream/off-white
  static const Color primary = Color(0xFF6B5B95);    // Calm pedagogical purple
  static const Color secondary = Color(0xFFA8C3B0);  // Soft sage green
  static const Color textPrimary = Color(0xFF252525);// Soft off-black (never pure #000000)
  static const Color textSecondary = Color(0xFF666666);
  static const Color surfaceCard = Color(0xFFFFFFFF);// Clean white for cards
  static const Color cardBorder = Color(0xFFE8E5DF); // Subtle 1px boundary
  static const Color errorRed = Color(0xFFD9534F);
  static const Color successGreen = Color(0xFF5CB85C);
  static const Color highlightYellow = Color(0xFFFFF3CD); // Spoken word / span highlight

  // Alternative contrast presets for visual ergonomics
  static const Color darkBackground = Color(0xFF121826);
  static const Color darkSurface = Color(0xFF1E2638);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static const Color bluePastelBackground = Color(0xFFF0F4F8);
  static const Color bluePastelSurface = Color(0xFFFFFFFF);
}
