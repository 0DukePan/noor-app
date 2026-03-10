import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🎨 Noor Design System
/// Islamic Minimalism based on deep emerald greens, warm gold, and clean whites.
class NoorDesignSystem {
  // ═══════════════════════════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary Palette
  static const emeraldGreen = Color(0xFF2E7D32);   // Primary Brand Color
  static const deepTeal = Color(0xFF00695C);       // Darker Shade
  static const sageGreen = Color(0xFF4CAF50);      // Lighter/Success
  static const goldAccent = Color(0xFFD4AF37);     // Accent/Premium
  static const creamWhite = Color(0xFFFFFBF5);     // Background (Warm)

  // Functional Colors
  static const surface = Colors.white;
  static const background = creamWhite;
  static const error = Color(0xFFB00020);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const naskhBlack = Color(0xFF212121); // Dark black for Naskh text

  // Adhkar Category Colors
  static const morningColor = Color(0xFF8BC34A);   // Light Green
  static const eveningColor = Color(0xFF42A5F5);   // Blue
  static const sleepColor = Color(0xFF9C27B0);     // Purple
  static const prayerColor = Color(0xFF4CAF50);    // Green
  static const mosqueColor = Color(0xFFFF9800);    // Orange
  static const wakeupColor = Color(0xFF00BCD4);    // Cyan
  static const quranColor = Color(0xFFFFB300);     // Amber
  static const starColor = Color(0xFF3F51B5);      // Indigo

  // Hadith Book Colors
  static const bukhariColor = Color(0xFF2E7D32);
  static const muslimColor = Color(0xFF1565C0);
  static const abuDawudColor = Color(0xFF00796B);
  static const tirmidhiColor = Color(0xFF795548);
  static const nasaiColor = Color(0xFFC62828);
  static const ibnMajahColor = Color(0xFF6A1B9A);
  static const malikColor = Color(0xFFFF8F00);
  static const darimiColor = Color(0xFF880E4F);
  static const ahmadColor = Color(0xFF827717);

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY
  // ═══════════════════════════════════════════════════════════════════════════

  static TextTheme get textTheme => TextTheme(
    // Headlines (Cairo)
    displayLarge: GoogleFonts.cairo(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      height: 1.2,
    ),
    displayMedium: GoogleFonts.cairo(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      height: 1.2,
    ),
    displaySmall: GoogleFonts.cairo(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      height: 1.2,
    ),
    
    // Titles (Cairo)
    titleLarge: GoogleFonts.cairo(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    titleMedium: GoogleFonts.cairo(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    titleSmall: GoogleFonts.cairo(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),

    // Body (Cairo for UI, Amiri for Content)
    bodyLarge: GoogleFonts.cairo(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: textPrimary,
    ),
    bodyMedium: GoogleFonts.cairo(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: textSecondary,
    ),
    
    // Quran/Hadith Content (Amiri)
    headlineMedium: GoogleFonts.amiri( // Used for Reading Text
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      height: 2.2,
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SHAPES & SPACING
  // ═══════════════════════════════════════════════════════════════════════════

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: emeraldGreen.withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
