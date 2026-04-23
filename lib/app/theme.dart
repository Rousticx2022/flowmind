import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const bg = Color(0xFF080C1A);
  static const surface = Color(0xFF0F1628);
  static const card = Color(0xFF151D35);
  static const cardBorder = Color(0xFF1E2B4A);

  // Accents
  static const cyan = Color(0xFF00D4FF);
  static const cyanDim = Color(0xFF0088AA);
  static const coral = Color(0xFFFF6B6B);
  static const mint = Color(0xFF4DFFC3);
  static const gold = Color(0xFFFFD166);

  // Text
  static const textPrimary = Color(0xFFE8EEFF);
  static const textSecondary = Color(0xFF8899CC);
  static const textMuted = Color(0xFF445577);

  // Liquid palette (8 colors for game segments)
  static const List<Color> liquids = [
    Color(0xFFFF4D4D), // Red
    Color(0xFF4D9FFF), // Blue
    Color(0xFF4DFF91), // Green
    Color(0xFFFFD84D), // Yellow
    Color(0xFFBF4DFF), // Purple
    Color(0xFFFF914D), // Orange
    Color(0xFFFF4DB8), // Pink
    Color(0xFF4DFFE0), // Cyan
  ];
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.mint,
        surface: AppColors.surface,
        error: AppColors.coral,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }
}
