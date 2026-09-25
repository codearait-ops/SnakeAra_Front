import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// Refined dark theme configuration for the Snake game.
/// Uses a deep-space dark palette with neon green accents and Vazirmatn font.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(brightness: Brightness.dark);
    final textTheme = GoogleFonts.vazirmatnTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: const Color(0xFF0A0E14),
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00E676),
        secondary: Color(0xFF00B0FF),
        surface: Color(0xFF161B22),
        error: kGameOverRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.vazirmatn(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.vazirmatn(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          shadowColor: kPrimaryColor.withValues(alpha: 0.4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white54,
          textStyle: GoogleFonts.vazirmatn(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22),
        elevation: 8,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF21262D), width: 1),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white70, size: 24),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D1117),
      ),
      dividerColor: const Color(0xFF21262D),
      focusColor: kPrimaryColor,
    );
  }
}
