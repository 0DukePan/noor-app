import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🎨 Noor Design System — Islamic Super App
/// HSL-based palette aligned with UX architecture spec.
class NoorDesignSystem {
  // ═══════════════════════════════════════════════════════════════════════════
  // DARK MODE BACKGROUNDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Near-black with green undertone — HSL(160, 15%, 8%)
  static const bgDark = Color(0xFF111D18);
  /// Elevated cards — HSL(160, 10%, 12%)
  static const surfaceDark = Color(0xFF1C2B24);
  /// Modals, drawers — HSL(160, 8%, 16%)
  static const surfaceElevatedDark = Color(0xFF263529);
  /// Separator — HSL(160, 10%, 18%)
  static const separatorDark = Color(0xFF2B3D33);

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE BACKGROUNDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pearl paper — HSL(40, 20%, 97%)
  static const bgLight = Color(0xFFF8F6F2);
  /// Sepia for long reading — HSL(35, 30%, 90%)
  static const bgSepia = Color(0xFFE8DDCB);
  /// Light surface (cards)
  static const surfaceLight = Colors.white;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY PALETTE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Main actions — HSL(155, 45%, 25%)
  static const primaryGreen = Color(0xFF235C3E);
  /// Hover/active — HSL(155, 40%, 35%)
  static const primaryLight = Color(0xFF367A55);
  /// Container tint
  static const primaryContainer = Color(0xFFD4EEE0);

  // Legacy aliases (for incremental migration)
  static const emeraldGreen = primaryGreen;
  static const deepTeal = Color(0xFF1A4D3A);
  static const sageGreen = primaryLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // GOLD ACCENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Highlights, progress, badges — HSL(42, 75%, 55%)
  static const goldAccent = Color(0xFFD4A843);
  /// Secondary gold — HSL(42, 40%, 35%)
  static const goldMuted = Color(0xFF7D6B33);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Main text (light theme)
  static const textPrimary = Color(0xFF1A1A1A);
  /// Dark black for Naskh text (legacy alias)
  static const naskhBlack = Color(0xFF212121);
  /// Muted text (light theme)
  static const textSecondary = Color(0xFF757575);
  /// Main text (dark theme) — HSL(40, 20%, 92%)
  static const textPrimaryDark = Color(0xFFF0E8D8);
  /// Muted text (dark theme) — HSL(40, 10%, 60%)
  static const textSecondaryDark = Color(0xFF9E9685);
  /// Gold verse markers — HSL(42, 75%, 55%)
  static const textVerseNumber = goldAccent;

  // ═══════════════════════════════════════════════════════════════════════════
  // HADITH GRADING COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sahih (Authentic) — HSL(155, 50%, 40%)
  static const gradeSahih = Color(0xFF339966);
  /// Hasan (Good) — gold
  static const gradeHasan = goldAccent;
  /// Da'if (Weak) — muted red HSL(0, 50%, 50%)
  static const gradeDaif = Color(0xFFBF4040);
  /// Mawdu (Fabricated)
  static const gradeMawdu = Color(0xFFC62828);

  // ═══════════════════════════════════════════════════════════════════════════
  // FUNCTIONAL / ERROR
  // ═══════════════════════════════════════════════════════════════════════════

  static const error = Color(0xFFB00020);
  static const surface = surfaceLight;
  static const background = bgLight;
  static const creamWhite = bgLight;

  // ═══════════════════════════════════════════════════════════════════════════
  // ADHKAR CATEGORY COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const morningColor = Color(0xFFF9A825);  // Amber / sunrise
  static const eveningColor = Color(0xFF5C6BC0);   // Indigo / evening sky
  static const sleepColor = Color(0xFF7E57C2);     // Purple
  static const prayerColor = primaryGreen;
  static const mosqueColor = Color(0xFFFF9800);    // Orange
  static const wakeupColor = Color(0xFF26C6DA);    // Cyan
  static const quranColor = goldAccent;
  static const starColor = Color(0xFF3F51B5);      // Indigo

  // ═══════════════════════════════════════════════════════════════════════════
  // HADITH BOOK COLORS
  // ═══════════════════════════════════════════════════════════════════════════

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
      fontSize: 32, fontWeight: FontWeight.bold,
      color: textPrimary, height: 1.2,
    ),
    displayMedium: GoogleFonts.cairo(
      fontSize: 28, fontWeight: FontWeight.bold,
      color: textPrimary, height: 1.2,
    ),
    displaySmall: GoogleFonts.cairo(
      fontSize: 24, fontWeight: FontWeight.bold,
      color: textPrimary, height: 1.2,
    ),
    // Titles (Cairo)
    titleLarge: GoogleFonts.cairo(
      fontSize: 22, fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    titleMedium: GoogleFonts.cairo(
      fontSize: 18, fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    titleSmall: GoogleFonts.cairo(
      fontSize: 16, fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    // Body (Cairo for UI)
    bodyLarge: GoogleFonts.cairo(
      fontSize: 16, fontWeight: FontWeight.normal,
      color: textPrimary,
    ),
    bodyMedium: GoogleFonts.cairo(
      fontSize: 14, fontWeight: FontWeight.normal,
      color: textSecondary,
    ),
    // Quran/Hadith Content (Amiri)
    headlineMedium: GoogleFonts.amiri(
      fontSize: 28, fontWeight: FontWeight.bold,
      color: textPrimary, height: 2.2,
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SHAPES & SPACING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Buttons, badges
  static const double radiusSmall = 8.0;
  /// Cards
  static const double radiusMedium = 12.0;
  /// Modals, sheets
  static const double radiusLarge = 16.0;
  /// Pills, avatars
  static const double radiusFull = 999.0;

  // Spacing scale: 4-8-12-16-24-32-48-64-96
  static const double spacingXXS = 4.0;
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingSM = 12.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacing3XL = 64.0;
  static const double spacing4XL = 96.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOWS — Minimal, use surface color differences
  // ═══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Only for floating audio player
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: primaryGreen.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
