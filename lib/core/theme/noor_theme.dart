import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_system.dart';

/// نظام تصميم الخشوع - Khushu Design System
/// Calm, spiritual, distraction-free visual language
class NoorTheme {
  NoorTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // COLOR PALETTE - Calm, spiritual tones (Modernized)
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary - Deep, calming colors
  static const Color primaryDark = Color(0xFF152630); // Deeper, more expansive
  static const Color primary = Color(0xFF203845);     // Rich Teal/Slate
  static const Color primaryLight = Color(0xFF4A7C7A); // Soft Sage

  // Accent - Warm, welcoming
  static const Color accentGold = Color(0xFFD4AF37);  // Metallic Gold
  static const Color accentCream = Color(0xFFF5F0E8);

  // Backgrounds
  static const Color bgDark = Color(0xFF0F171A);      // Midnight
  static const Color bgLight = Color(0xFFFDFCF9);     // Pearl Paper
  static const Color bgMushaf = Color(0xFFFFFBF0);    // Warm Paper

  // Surfaces (New)
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1A262C);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5A5A5A);
  static const Color textArabic = Color(0xFF2A2A2A);
  static const Color textOnDark = Color(0xFFF5F0E8);

  // Hadith Grading Colors
  static const Color hadithSahih = Color(0xFF2E7D32);   // Green - Authentic
  static const Color hadithHasan = Color(0xFF1976D2);   // Blue - Good
  static const Color hadithDaif = Color(0xFFE65100);    // Orange - Weak
  static const Color hadithMawdu = Color(0xFFC62828);   // Red - Fabricated

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS - Gentle, never jarring
  // ═══════════════════════════════════════════════════════════════════════════

  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationBreathing = Duration(milliseconds: 1000); // Khushu mode entry

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING
  // ═══════════════════════════════════════════════════════════════════════════

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS - Softer, more organic
  // ═══════════════════════════════════════════════════════════════════════════

  static const double radiusSm = 12.0;
  static const double radiusMd = 20.0; // Increased for modern look
  static const double radiusLg = 28.0;
  static const double radiusXl = 32.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME - Day mode, paper-like
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: NoorDesignSystem.creamWhite,
        colorScheme: const ColorScheme.light(
          primary: NoorDesignSystem.emeraldGreen,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFE8F5E9),
          onPrimaryContainer: NoorDesignSystem.deepTeal,
          secondary: NoorDesignSystem.goldAccent,
          onSecondary: Colors.white,
          surface: NoorDesignSystem.surface,
          onSurface: NoorDesignSystem.textPrimary,
          surfaceContainerHighest: Color(0xFFF7F9F7), // For cards/containers
          error: NoorDesignSystem.error,
        ),
        textTheme: NoorDesignSystem.textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: NoorDesignSystem.creamWhite,
          foregroundColor: NoorDesignSystem.textPrimary,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardTheme(
          color: NoorDesignSystem.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: NoorDesignSystem.emeraldGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: NoorDesignSystem.spacingL,
              vertical: NoorDesignSystem.spacingM,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium)),
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
            borderSide: const BorderSide(color: NoorDesignSystem.emeraldGreen, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(NoorDesignSystem.spacingM),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.black.withOpacity(0.05),
          thickness: 1,
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME - Night mode for late night Quran reading
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(
          primary: primaryLight,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF253B45),
          onPrimaryContainer: Color(0xFFCFE1E1),
          secondary: accentGold,
          onSecondary: Colors.black,
          surface: surfaceDark,
          onSurface: textOnDark,
          surfaceContainerHighest: Color(0xFF1E2C33), // For cards
          error: hadithMawdu,
        ),
        textTheme: _buildTextTheme(Brightness.dark),
        appBarTheme: AppBarTheme(
          backgroundColor: bgDark,
          foregroundColor: textOnDark,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textOnDark,
          ),
        ),
        cardTheme: CardTheme(
          color: surfaceDark,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryLight,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: spacingLg,
              vertical: spacingMd,
            ),
            shape: const StadiumBorder(),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: primaryLight, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(spacingMd),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.05),
          thickness: 1,
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY - Arabic-first with Latin fallback
  // ═══════════════════════════════════════════════════════════════════════════

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color baseColor =
        brightness == Brightness.light ? textPrimary : textOnDark;

    return TextTheme(
      // Display - For Quran verses
      displayLarge: GoogleFonts.amiri(
        fontSize: 32,
        fontWeight: FontWeight.normal,
        color: baseColor,
        height: 2.2, // Improved line height for comfortable reading
      ),
      displayMedium: GoogleFonts.amiri(
        fontSize: 28,
        fontWeight: FontWeight.normal,
        color: baseColor,
        height: 2.1,
      ),
      displaySmall: GoogleFonts.amiri(
        fontSize: 24,
        fontWeight: FontWeight.normal,
        color: baseColor,
        height: 2.0,
      ),

      // Headlines - For section titles
      headlineLarge: GoogleFonts.cairo(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: baseColor,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),

      // Titles
      titleLarge: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),

      // Body text
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: baseColor,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: baseColor,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: baseColor.withOpacity(0.7),
        height: 1.5,
      ),

      // Labels
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: baseColor.withOpacity(0.7),
      ),
    );
  }
}
