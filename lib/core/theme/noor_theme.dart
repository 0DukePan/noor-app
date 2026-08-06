import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_system.dart';

/// نظام تصميم الخشوع - Khushu Design System
/// Calm, spiritual, distraction-free visual language
class NoorTheme {
  NoorTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKWARD-COMPATIBLE COLOR ALIASES
  // Maps old NoorTheme.xxx references to new NoorDesignSystem tokens
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color primaryDark = NoorDesignSystem.deepTeal;
  static const Color primary = NoorDesignSystem.primaryGreen;
  static const Color primaryLight = NoorDesignSystem.primaryLight;
  static const Color accentGold = NoorDesignSystem.goldAccent;
  static const Color accentCream = Color(0xFFF5F0E8);
  static const Color bgDark = NoorDesignSystem.bgDark;
  static const Color bgLight = NoorDesignSystem.bgLight;
  static const Color bgMushaf = Color(0xFFFFFBF0);
  static const Color surfaceLight = NoorDesignSystem.surfaceLight;
  static const Color surfaceDark = NoorDesignSystem.surfaceDark;
  static const Color textPrimary = NoorDesignSystem.textPrimary;
  static const Color textSecondary = NoorDesignSystem.textSecondary;
  static const Color textArabic = Color(0xFF2A2A2A);
  static const Color textOnDark = NoorDesignSystem.textPrimaryDark;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS - Gentle, never jarring
  // ═══════════════════════════════════════════════════════════════════════════

  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationBreathing = Duration(milliseconds: 1000);

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING (delegated to NoorDesignSystem for single source of truth)
  // ═══════════════════════════════════════════════════════════════════════════

  static const double spacingXs = NoorDesignSystem.spacingXS;
  static const double spacingSm = NoorDesignSystem.spacingS;
  static const double spacingMd = NoorDesignSystem.spacingM;
  static const double spacingLg = NoorDesignSystem.spacingL;
  static const double spacingXl = NoorDesignSystem.spacingXL;
  static const double spacingXxl = NoorDesignSystem.spacingXXL;

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double radiusSm = NoorDesignSystem.radiusSmall;
  static const double radiusMd = NoorDesignSystem.radiusMedium;
  static const double radiusLg = NoorDesignSystem.radiusLarge;
  static const double radiusXl = 24.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // HADITH GRADING (kept for backward compat)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color hadithSahih = NoorDesignSystem.gradeSahih;
  static const Color hadithHasan = NoorDesignSystem.gradeHasan;
  static const Color hadithDaif = NoorDesignSystem.gradeDaif;
  static const Color hadithMawdu = NoorDesignSystem.gradeMawdu;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME — Day mode, warm paper feel
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: NoorDesignSystem.bgLight,
    colorScheme: const ColorScheme.light(
      primary: NoorDesignSystem.primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: NoorDesignSystem.primaryContainer,
      onPrimaryContainer: NoorDesignSystem.deepTeal,
      secondary: NoorDesignSystem.goldAccent,
      onSecondary: Colors.white,
      surface: NoorDesignSystem.surfaceLight,
      onSurface: NoorDesignSystem.textPrimary,
      surfaceContainerHighest: Color(0xFFF2F0EB),
      error: NoorDesignSystem.error,
    ),
    textTheme: NoorDesignSystem.textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: NoorDesignSystem.bgLight,
      foregroundColor: NoorDesignSystem.textPrimary,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardTheme(
      color: NoorDesignSystem.surfaceLight,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        side: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NoorDesignSystem.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: NoorDesignSystem.spacingL,
          vertical: NoorDesignSystem.spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        borderSide: const BorderSide(color: NoorDesignSystem.primaryGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(NoorDesignSystem.spacingM),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.black.withOpacity(0.05),
      thickness: 1,
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME — Night mode for late-night Quran reading
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NoorDesignSystem.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: NoorDesignSystem.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: NoorDesignSystem.surfaceElevatedDark,
      onPrimaryContainer: NoorDesignSystem.textPrimaryDark,
      secondary: NoorDesignSystem.goldAccent,
      onSecondary: Colors.black,
      surface: NoorDesignSystem.surfaceDark,
      onSurface: NoorDesignSystem.textPrimaryDark,
      surfaceContainerHighest: NoorDesignSystem.surfaceElevatedDark,
      error: NoorDesignSystem.gradeMawdu,
    ),
    textTheme: _buildTextTheme(Brightness.dark),
    appBarTheme: AppBarTheme(
      backgroundColor: NoorDesignSystem.bgDark,
      foregroundColor: NoorDesignSystem.textPrimaryDark,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: NoorDesignSystem.textPrimaryDark,
      ),
    ),
    cardTheme: CardTheme(
      color: NoorDesignSystem.surfaceDark,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NoorDesignSystem.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: NoorDesignSystem.spacingL,
          vertical: NoorDesignSystem.spacingM,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NoorDesignSystem.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        borderSide: const BorderSide(color: NoorDesignSystem.primaryLight, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(NoorDesignSystem.spacingM),
    ),
    dividerTheme: DividerThemeData(
      color: NoorDesignSystem.separatorDark,
      thickness: 1,
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SEPIA THEME — Long reading sessions
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get sepia => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: NoorDesignSystem.bgSepia,
    colorScheme: const ColorScheme.light(
      primary: NoorDesignSystem.primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: NoorDesignSystem.primaryContainer,
      onPrimaryContainer: NoorDesignSystem.deepTeal,
      secondary: NoorDesignSystem.goldAccent,
      onSecondary: Colors.white,
      surface: Color(0xFFF0E5D3),
      onSurface: Color(0xFF3D3226),
      surfaceContainerHighest: Color(0xFFE8DDC8),
      error: NoorDesignSystem.error,
    ),
    textTheme: _buildTextTheme(Brightness.light, baseColor: const Color(0xFF3D3226)),
    appBarTheme: const AppBarTheme(
      backgroundColor: NoorDesignSystem.bgSepia,
      foregroundColor: Color(0xFF3D3226),
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFFF0E5D3),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        side: BorderSide(color: Colors.brown.withOpacity(0.08)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.brown.withOpacity(0.1),
      thickness: 1,
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY — Arabic-first with Latin fallback
  // ═══════════════════════════════════════════════════════════════════════════

  static TextTheme _buildTextTheme(Brightness brightness, {Color? baseColor}) {
    final Color color = baseColor ??
        (brightness == Brightness.light
            ? NoorDesignSystem.textPrimary
            : NoorDesignSystem.textPrimaryDark);

    return TextTheme(
      // Display — Quran verses (Amiri)
      displayLarge: GoogleFonts.amiri(
        fontSize: 32, fontWeight: FontWeight.normal,
        color: color, height: 2.2,
      ),
      displayMedium: GoogleFonts.amiri(
        fontSize: 28, fontWeight: FontWeight.normal,
        color: color, height: 2.1,
      ),
      displaySmall: GoogleFonts.amiri(
        fontSize: 24, fontWeight: FontWeight.normal,
        color: color, height: 2.0,
      ),
      // Headlines — Section titles (Cairo)
      headlineLarge: GoogleFonts.cairo(
        fontSize: 26, fontWeight: FontWeight.bold,
        color: color, height: 1.3,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: color, height: 1.3,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: color, height: 1.3,
      ),
      // Titles (Cairo)
      titleLarge: GoogleFonts.cairo(
        fontSize: 18, fontWeight: FontWeight.w700, color: color,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 16, fontWeight: FontWeight.w600, color: color,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14, fontWeight: FontWeight.w600, color: color,
      ),
      // Body (Cairo)
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16, fontWeight: FontWeight.normal,
        color: color, height: 1.6,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14, fontWeight: FontWeight.normal,
        color: color, height: 1.6,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12, fontWeight: FontWeight.normal,
        color: color.withOpacity(0.7), height: 1.5,
      ),
      // Labels (Cairo)
      labelLarge: GoogleFonts.cairo(
        fontSize: 14, fontWeight: FontWeight.w600, color: color,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12, fontWeight: FontWeight.w500, color: color,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 10, fontWeight: FontWeight.w500,
        color: color.withOpacity(0.7),
      ),
    );
  }
}
