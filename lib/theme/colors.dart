import 'package:flutter/material.dart';

/// Centralized QuizFlow Color Tokens
class AppColors {
  AppColors._();

  /// Primary canvas background (#FBF8F2)
  static const Color canvas = Color(0xFFFBF8F2);

  /// Cards, panels, forms (#FFFDF9)
  static const Color paper = Color(0xFFFFFDF9);

  /// Navigation rail, headings, primary buttons (#173F5F)
  static const Color inkBlue = Color(0xFF173F5F);

  /// Selected navigation item (#245473)
  static const Color activeBlue = Color(0xFF245473);

  /// Approved, live, selected, progress (#3C8D89)
  static const Color teal = Color(0xFF3C8D89);

  /// Teal text and icons (#246D6A)
  static const Color darkTeal = Color(0xFF246D6A);

  /// Draft, scheduled, focus, active marker (#D99A2B)
  static const Color saffron = Color(0xFFD99A2B);

  /// Card and field borders (#E8E1D7)
  static const Color border = Color(0xFFE8E1D7);
  static const Color line = Color(0xFFE8E1D7);

  /// Notes, criteria, filters (#F4F0E8)
  static const Color warmSurface = Color(0xFFF4F0E8);

  /// Error states (#B42318)
  static const Color error = Color(0xFFB42318);

  // Fallback text colors to support clean visual hierarchy
  static const Color ink = Color(0xFF173F5F);
  static const Color muted = Color(0xFF6B7280); // Muted slate-gray for supporting metadata

  // Compatibility getters for legacy screens and custom widgets
  static const Color primary = inkBlue;
  static const Color secondary = teal;
  static const Color accent = saffron;
  static const Color background = canvas;
  static const Color surface = paper;
  static const Color textPrimary = ink;
  static const Color textSecondary = muted;
  static const Color textLight = muted;
  static const Color textOnPrimary = Colors.white;
  static const Color backgroundDark = inkBlue;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [inkBlue, teal],
  );
}
