import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary & Backgrounds
  static const Color primary = Color(0xFFf4f1e9); // warm off-white background
  static const Color cardBg = Color(0xFFffffff); // white cards

  // Accent & Actions
  static const Color accent = Color(0xFFff6036); // coral orange

  // Text Colors
  static const Color textPrimary = Color(0xFF1a1a1a); // near black
  static const Color textMuted = Color(0xFF6b6b6b); // gray secondary text

  // Semantic & Severity
  static const Color severityHigh = Color(0xFFef4444); // red
  static const Color severityMedium = Color(0xFFf59e0b); // amber
  static const Color severityLow = Color(0xFF22c55e); // green
  
  static const Color successGreen = Color(0xFF22c55e);
  static const Color dangerRed = Color(0xFFef4444);
}

class AppTextStyles {
  // Headings
  static TextStyle get h1 => GoogleFonts.poppins(
    fontWeight: FontWeight.bold,
    fontSize: 24,
    color: AppColors.textPrimary,
  );

  static TextStyle get h2 => GoogleFonts.poppins(
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 18,
    color: AppColors.textPrimary,
  );

  // Body
  static TextStyle get body => GoogleFonts.inter(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMuted => GoogleFonts.inter(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: AppColors.textMuted,
  );

  // Labels
  static TextStyle get label => GoogleFonts.inter(
    fontWeight: FontWeight.w500, // Medium
    fontSize: 12,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelMuted => GoogleFonts.inter(
    fontWeight: FontWeight.w500, // Medium
    fontSize: 12,
    color: AppColors.textMuted,
  );

  // Monospace (for logs)
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontWeight: FontWeight.normal,
    fontSize: 12,
    color: AppColors.textPrimary,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.primary,
      textTheme: GoogleFonts.interTextTheme(),
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: AppColors.cardBg,
        error: AppColors.dangerRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.h2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Gives about 52px height
      ),
    );
  }
}
