import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizz_generator/theme/colors.dart';

/// Application Theme Configuration
/// Provides the customized theme for QuizFlow
class AppTheme {
  AppTheme._();

  /// Light Theme Configuration
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: AppColors.inkBlue,
      secondary: AppColors.teal,
      surface: AppColors.paper,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.ibmPlexSansArabicTextTheme().copyWith(
      // Desktop page title
      displaySmall: GoogleFonts.ibmPlexSansArabic(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.inkBlue,
      ),
      // Section title
      titleLarge: GoogleFonts.ibmPlexSansArabic(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.inkBlue,
      ),
      // Main card title / question prompt
      titleMedium: GoogleFonts.ibmPlexSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.inkBlue,
      ),
      // Body text / main list labels
      bodyLarge: GoogleFonts.ibmPlexSansArabic(
        fontSize: 15,
        height: 1.55,
        color: AppColors.ink,
      ),
      // Subtitles and metadata
      bodyMedium: GoogleFonts.ibmPlexSansArabic(
        fontSize: 13,
        height: 1.5,
        color: AppColors.muted,
      ),
      // Navigation labels, buttons, etc.
      labelLarge: GoogleFonts.ibmPlexSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.inkBlue,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.saffron, width: 1.5),
      ),
      labelStyle: TextStyle(color: AppColors.muted, fontSize: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.inkBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkBlue,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
