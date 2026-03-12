import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    return _buildTheme(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF3F7FC),
      appBarForegroundColor: const Color(0xFF101A2B),
      cardColor: Colors.white.withValues(alpha: 0.84),
      fieldFillColor: Colors.white.withValues(alpha: 0.92),
      fieldBorderColor: const Color(0xFFCAD7E5).withValues(alpha: 0.5),
      surface: const Color(0xFFF7FBFF),
      primary: const Color(0xFF0068FF),
      secondary: const Color(0xFF0E9F8A),
      tertiary: const Color(0xFF57A6FF),
      surfaceContainerHighest: const Color(0xFFE6EEF8),
      chipBackgroundColor: const Color(0xFFE9F3FF),
      chipSelectedColor: const Color(0xFFD4E8FF),
    );
  }

  static ThemeData dark() {
    return _buildTheme(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF09111F),
      appBarForegroundColor: const Color(0xFFE9F2FF),
      cardColor: const Color(0xFF13233D).withValues(alpha: 0.86),
      fieldFillColor: const Color(0xFF102037).withValues(alpha: 0.98),
      fieldBorderColor: const Color(0xFF4C6487).withValues(alpha: 0.55),
      surface: const Color(0xFF0F1B2E),
      primary: const Color(0xFF6AA8FF),
      secondary: const Color(0xFF37C4AF),
      tertiary: const Color(0xFF8ABEFF),
      surfaceContainerHighest: const Color(0xFF1D304B),
      chipBackgroundColor: const Color(0xFF143153),
      chipSelectedColor: const Color(0xFF1D4676),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required Color appBarForegroundColor,
    required Color cardColor,
    required Color fieldFillColor,
    required Color fieldBorderColor,
    required Color surface,
    required Color primary,
    required Color secondary,
    required Color tertiary,
    required Color surfaceContainerHighest,
    required Color chipBackgroundColor,
    required Color chipSelectedColor,
  }) {
    const seed = Color(0xFF0A84FF);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: surface,
    );

    final bodyTextTheme = GoogleFonts.manropeTextTheme();
    final heading = GoogleFonts.spaceGrotesk(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surfaceContainerHighest: surfaceContainerHighest,
      ),
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: bodyTextTheme.copyWith(
        headlineLarge: heading.copyWith(fontSize: 40),
        headlineMedium: heading.copyWith(fontSize: 28),
        titleLarge: heading.copyWith(fontSize: 22),
        titleMedium: heading.copyWith(fontSize: 18),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: heading.copyWith(
          color: appBarForegroundColor,
          fontSize: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: fieldBorderColor),
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
        backgroundColor: chipBackgroundColor,
        side: BorderSide.none,
        selectedColor: chipSelectedColor,
        labelStyle: bodyTextTheme.labelMedium,
      ),
    );
  }
}
