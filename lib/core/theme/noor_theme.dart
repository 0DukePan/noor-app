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
  static const double radiusXl = 24;

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

  static ThemeData get light => _withComponents(ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: NoorDesignSystem.bgLight,
    colorScheme: const ColorScheme.light(
      primary: NoorDesignSystem.primaryGreen,
      primaryContainer: NoorDesignSystem.primaryContainer,
      onPrimaryContainer: NoorDesignSystem.deepTeal,
      secondary: NoorDesignSystem.goldAccent,
      onSecondary: Colors.white,
      onSurface: NoorDesignSystem.textPrimary,
      surfaceContainerHighest: Color(0xFFF2F0EB),
    ),
    textTheme: NoorDesignSystem.textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: NoorDesignSystem.bgLight,
      foregroundColor: NoorDesignSystem.textPrimary,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: NoorDesignSystem.surfaceLight,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
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
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        borderSide: const BorderSide(color: NoorDesignSystem.primaryGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(NoorDesignSystem.spacingM),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.black.withValues(alpha: 0.05),
      thickness: 1,
    ),
  ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME — Night mode for late-night Quran reading
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get dark => _withComponents(ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NoorDesignSystem.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: NoorDesignSystem.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: NoorDesignSystem.surfaceElevatedDark,
      onPrimaryContainer: NoorDesignSystem.textPrimaryDark,
      secondary: NoorDesignSystem.goldAccent,
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
    cardTheme: CardThemeData(
      color: NoorDesignSystem.surfaceDark,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
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
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        borderSide: const BorderSide(color: NoorDesignSystem.primaryLight, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(NoorDesignSystem.spacingM),
    ),
    dividerTheme: const DividerThemeData(
      color: NoorDesignSystem.separatorDark,
      thickness: 1,
    ),
  ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SEPIA THEME — Long reading sessions
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get sepia => _withComponents(ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: NoorDesignSystem.bgSepia,
    colorScheme: const ColorScheme.light(
      primary: NoorDesignSystem.primaryGreen,
      primaryContainer: NoorDesignSystem.primaryContainer,
      onPrimaryContainer: NoorDesignSystem.deepTeal,
      secondary: NoorDesignSystem.goldAccent,
      onSecondary: Colors.white,
      surface: Color(0xFFF0E5D3),
      onSurface: Color(0xFF3D3226),
      surfaceContainerHighest: Color(0xFFE8DDC8),
    ),
    textTheme: _buildTextTheme(Brightness.light, baseColor: const Color(0xFF3D3226)),
    appBarTheme: const AppBarTheme(
      backgroundColor: NoorDesignSystem.bgSepia,
      foregroundColor: Color(0xFF3D3226),
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFF0E5D3),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        side: BorderSide(color: Colors.brown.withValues(alpha: 0.08)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.brown.withValues(alpha: 0.1),
      thickness: 1,
    ),
  ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY — one type system, shared with the design system
  // ═══════════════════════════════════════════════════════════════════════════

  static TextTheme _buildTextTheme(Brightness brightness, {Color? baseColor}) =>
      NoorDesignSystem.buildTextTheme(brightness, baseColor: baseColor);

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENT THEMES — the surfaces Material would otherwise default
  // ═══════════════════════════════════════════════════════════════════════════

  /// Without these, chips, sheets, snackbars, list tiles, dialogs and tab bars
  /// fall back to stock Material defaults, which is what made a fully themed
  /// app still read as a Material demo. Applied to light, dark and sepia alike
  /// so the three stay one system.
  static ThemeData _withComponents(ThemeData base) {
    final isLight = base.brightness == Brightness.light;
    final scheme = base.colorScheme;
    final text = base.textTheme;
    final pageSurface = isLight
        ? NoorDesignSystem.surfaceLight
        : NoorDesignSystem.surfaceDark;
    final hairline = (isLight ? Colors.black : Colors.white)
        .withValues(alpha: isLight ? 0.06 : 0.08);
    final onSurface = isLight ? text.bodyLarge?.color : NoorDesignSystem.textPrimaryDark;

    return base.copyWith(
      chipTheme: ChipThemeData(
        backgroundColor: isLight
            ? NoorDesignSystem.primaryContainer.withValues(alpha: 0.5)
            : NoorDesignSystem.surfaceElevatedDark,
        side: BorderSide(color: hairline),
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: NoorDesignSystem.spacingSM,
          vertical: NoorDesignSystem.spacingXS,
        ),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? NoorDesignSystem.deepTeal
            : NoorDesignSystem.surfaceElevatedDark,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isLight ? Colors.white : NoorDesignSystem.textPrimaryDark,
        ),
        actionTextColor: isLight
            ? NoorDesignSystem.goldAccent
            : NoorDesignSystem.goldAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: pageSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NoorDesignSystem.radiusLarge),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: pageSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(NoorDesignSystem.radiusLarge),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NoorDesignSystem.spacingM,
          vertical: NoorDesignSystem.spacingXXS,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: onSurface?.withValues(alpha: 0.6),
        indicatorColor: scheme.primary,
        dividerColor: Colors.transparent,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(
            horizontal: NoorDesignSystem.spacingL,
            vertical: NoorDesignSystem.spacingSM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: hairline,
      ),
    );
  }
}
