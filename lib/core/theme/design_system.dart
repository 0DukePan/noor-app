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
  /// Muted text (light theme) — warm grey, 6.2:1 on [bgLight] and 6.7:1 on
  /// white. The previous #757575 measured 4.27:1 and was the default colour of
  /// `bodyMedium`, so the app's most common body text failed WCAG AA.
  static const textSecondary = Color(0xFF5C5852);
  /// De-emphasised text for large or non-essential copy only — 3.2:1 on
  /// [bgLight], which is below AA for body text. Do not use for 14px or less.
  static const textTertiary = Color(0xFF8A857D);
  /// Main text (dark theme) — HSL(40, 20%, 92%)
  static const textPrimaryDark = Color(0xFFF0E8D8);
  /// Muted text (dark theme) — HSL(40, 10%, 60%)
  static const textSecondaryDark = Color(0xFF9E9685);
  /// Gold for TEXT and small marks on light surfaces — 4.7:1 on [bgLight].
  /// [goldAccent] (2.05:1) is a fill/border colour only; gold text needs this.
  static const goldInk = Color(0xFF8A6A1F);
  /// Gold for verse numbers and other small marks. Currently unreferenced in
  /// `lib/` — the value is [goldInk] so that whoever wires it up gets a
  /// legible colour rather than the 2.05:1 [goldAccent].
  static const textVerseNumber = goldInk;

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

  static const morningColor = Color(0xFF8A6420);  // Deep amber — sunrise
  static const eveningColor = Color(0xFF3F4A73);  // Deep indigo — evening sky
  static const sleepColor = Color(0xFF4E3F73);    // Deep violet
  static const prayerColor = primaryGreen;
  static const mosqueColor = Color(0xFF8A5A1F);   // Deep amber-brown
  static const wakeupColor = Color(0xFF1F5F6B);   // Deep teal — first light
  static const quranColor = goldAccent;           // fill only; text uses goldInk
  static const starColor = Color(0xFF3A4273);     // Deep indigo

// ═══════════════════════════════════════════════════════════════════════════
// HADITH BOOK COLORS
// One tonal family: deep, desaturated jewel tones at a similar lightness, so
// the nine collections stay distinguishable without reading as nine unrelated
// Material swatches. Every value here clears 7:1 for white text, which is how
// the book cards and reader accents use them.
// ═══════════════════════════════════════════════════════════════════════════

  static const bukhariColor = Color(0xFF23614A);
  static const muslimColor = Color(0xFF23536E);
  static const abuDawudColor = Color(0xFF1E5A5C);
  static const tirmidhiColor = Color(0xFF6B4A2F);
  static const nasaiColor = Color(0xFF5E3550);
  static const ibnMajahColor = Color(0xFF3A3F73);
  static const malikColor = Color(0xFF6E5321);
  static const darimiColor = Color(0xFF6B2F3C);
  static const ahmadColor = Color(0xFF4F5426);
  /// Musnad Ahmad is the same collection as [ahmadColor]; the alias exists
  /// because the hadith browser keys on "ahmed".
  static const musnadColor = ahmadColor;

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY
  // ═══════════════════════════════════════════════════════════════════════════

  /// The single type system, used by light, dark and sepia alike.
  ///
  /// There used to be two: this file's `textTheme` for light mode and
  /// `NoorTheme._buildTextTheme` for dark/sepia. They disagreed on which roles
  /// use Amiri, and the light one omitted bodySmall/title/label roles entirely,
  /// so light mode silently fell back to Roboto for them — the same screen
  /// rendered in two different type systems depending on the theme.
  ///
  /// Amiri is reserved for scripture (Quran and hadith matn, the `display*`
  /// roles). Cairo carries the interface. Steps are >= 1.25 apart so the
  /// hierarchy actually reads as a hierarchy.
  static TextTheme buildTextTheme(Brightness brightness, {Color? baseColor}) {
    final isLight = brightness == Brightness.light;
    final color = baseColor ?? (isLight ? textPrimary : textPrimaryDark);
    final muted = baseColor != null
        ? baseColor.withValues(alpha: 0.75)
        : (isLight ? textSecondary : textSecondaryDark);

    return TextTheme(
      // Scripture — Amiri, generous line height for tashkeel.
      displayLarge: GoogleFonts.amiri(
        fontSize: 34, color: color, height: 2.1,
      ),
      displayMedium: GoogleFonts.amiri(
        fontSize: 28, color: color, height: 2,
      ),
      displaySmall: GoogleFonts.amiri(
        fontSize: 24, color: color, height: 1.9,
      ),
      // Interface headings — Cairo.
      headlineLarge: GoogleFonts.cairo(
        fontSize: 30, fontWeight: FontWeight.w700, color: color, height: 1.25,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 24, fontWeight: FontWeight.w700, color: color, height: 1.25,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 20, fontWeight: FontWeight.w600, color: color, height: 1.3,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: 18, fontWeight: FontWeight.w700, color: color, height: 1.3,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 16, fontWeight: FontWeight.w600, color: color, height: 1.35,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14, fontWeight: FontWeight.w600, color: color, height: 1.35,
      ),
      // Body — bodyMedium is no longer muted; that made every default
      // paragraph read as secondary text.
      bodyLarge: GoogleFonts.cairo(fontSize: 16, color: color, height: 1.6),
      bodyMedium: GoogleFonts.cairo(fontSize: 14, color: color, height: 1.6),
      bodySmall: GoogleFonts.cairo(fontSize: 12, color: muted, height: 1.5),
      labelLarge: GoogleFonts.cairo(
        fontSize: 14, fontWeight: FontWeight.w600, color: color,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12, fontWeight: FontWeight.w500, color: muted,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 11, fontWeight: FontWeight.w500, color: muted,
        letterSpacing: 0.2,
      ),
    );
  }

  static TextTheme get textTheme => buildTextTheme(Brightness.light);

  // ═══════════════════════════════════════════════════════════════════════════
  // SHAPES & SPACING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Buttons, badges
  static const double radiusSmall = 8;
  /// Cards
  static const double radiusMedium = 12;
  /// Modals, sheets
  static const double radiusLarge = 16;
  /// Pills, avatars
  static const double radiusFull = 999;

  // Spacing scale: 4-8-12-16-24-32-48-64-96
  static const double spacingXXS = 4;
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingSM = 12;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;
  static const double spacing3XL = 64;
  static const double spacing4XL = 96;

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOWS — Minimal, use surface color differences
  // ═══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Only for floating audio player
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: primaryGreen.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
