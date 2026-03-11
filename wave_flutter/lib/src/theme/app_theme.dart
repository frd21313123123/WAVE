import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    const seed = Color(0xFF0A84FF);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: const Color(0xFFF7FBFF),
    );

    final bodyTextTheme = GoogleFonts.manropeTextTheme();
    final heading = GoogleFonts.spaceGrotesk(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: const Color(0xFF0068FF),
        secondary: const Color(0xFF0E9F8A),
        tertiary: const Color(0xFF57A6FF),
        surfaceContainerHighest: const Color(0xFFE6EEF8),
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F7FC),
      textTheme: bodyTextTheme.copyWith(
        headlineLarge: heading.copyWith(fontSize: 40),
        headlineMedium: heading.copyWith(fontSize: 28),
        titleLarge: heading.copyWith(fontSize: 22),
        titleMedium: heading.copyWith(fontSize: 18),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF101A2B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: heading.copyWith(
          color: const Color(0xFF101A2B),
          fontSize: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.84),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: const Color(0xFFCAD7E5).withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 1.5,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE9F3FF),
        side: BorderSide.none,
        selectedColor: const Color(0xFFD4E8FF),
        labelStyle: bodyTextTheme.labelMedium,
      ),
    );
  }
}
