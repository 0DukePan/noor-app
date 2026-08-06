import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// TAFSIR PRO THEME — Premium Scholar-Grade Aesthetics
/// ═══════════════════════════════════════════════════════════════════════════

class TafsirTheme {
  TafsirTheme._();

  // ─────────────────────────────────────────────────────────────────────────
  // PALETTE
  // ─────────────────────────────────────────────────────────────────────────

  /// Ivory/Cream — light mode reading backgrounds
  static const Color ivoryBg = Color(0xFFF8F4ED);
  static const Color creamBg = Color(0xFFFDF9F3);
  static const Color warmWhite = Color(0xFFFFFBF5);

  /// Deep Charcoal — dark mode reading backgrounds
  static const Color charcoalBg = Color(0xFF1A1A1E);
  static const Color charcoalCard = Color(0xFF242428);
  static const Color charcoalSurface = Color(0xFF2C2C30);

  /// Accent colors for Ayah text
  static const Color ayahGold = Color(0xFFB8860B);       // Dark golden rod
  static const Color ayahGoldLight = Color(0xFFD4A843);   // Brighter for dark mode
  static const Color ayahGreen = Color(0xFF1B5E20);       // Deep green
  static const Color ayahGreenLight = Color(0xFF66BB6A);  // Lighter for dark mode

  /// Exegete accent colors
  static const Color sourceGreen = Color(0xFF2E7D32);
  static const Color sourceBlue = Color(0xFF1565C0);
  static const Color sourcePurple = Color(0xFF6A1B9A);
  static const Color sourceAmber = Color(0xFFBF360C);

  /// Get reading background based on brightness
  static Color readingBackground(Brightness brightness) =>
      brightness == Brightness.light ? creamBg : charcoalBg;

  static Color cardBackground(Brightness brightness) =>
      brightness == Brightness.light ? warmWhite : charcoalCard;

  static Color ayahColor(Brightness brightness) =>
      brightness == Brightness.light ? ayahGold : ayahGoldLight;

  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY
  // ─────────────────────────────────────────────────────────────────────────

  /// Ayah text — Amiri Quran style (golden/green)
  static TextStyle ayahStyle({
    required Brightness brightness,
    double fontSize = 22,
  }) => GoogleFonts.amiri(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: ayahColor(brightness),
    height: 1.8,
  );

  /// Tafsir body text — Cairo with high legibility
  static TextStyle tafsirBodyStyle({
    required Brightness brightness,
    double fontSize = 16,
  }) => GoogleFonts.cairo(
    fontSize: fontSize,
    height: 1.9,
    color: brightness == Brightness.light
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFE0E0E0),
  );

  /// Headers/Exegete names — Cairo Bold
  static TextStyle headerStyle({
    required Brightness brightness,
    double fontSize = 16,
    Color? color,
  }) => GoogleFonts.cairo(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: color ?? (brightness == Brightness.light
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF0F0F0)),
  );

  /// Source name / subtitle
  static TextStyle sourceStyle({
    required Brightness brightness,
    double fontSize = 13,
    Color? color,
  }) => GoogleFonts.cairo(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: color ?? (brightness == Brightness.light
        ? const Color(0xFF555555)
        : const Color(0xFFAAAAAA)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ARABESQUE DIVIDER — Elegant ornamental separator
// ═══════════════════════════════════════════════════════════════════════════

class ArabesqueDivider extends StatelessWidget {
  final double width;
  final Color? color;

  const ArabesqueDivider({super.key, this.width = 200, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = color ?? theme.colorScheme.primary.withOpacity(0.25);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWing(dividerColor, isLeft: true),
          const SizedBox(width: 8),
          // Center ornament — Islamic star/diamond
          Text(
            '✦',
            style: TextStyle(
              fontSize: 12,
              color: dividerColor,
            ),
          ),
          const SizedBox(width: 8),
          _buildWing(dividerColor, isLeft: false),
        ],
      ),
    );
  }

  Widget _buildWing(Color color, {required bool isLeft}) {
    return SizedBox(
      width: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLeft
                    ? [color.withOpacity(0.0), color]
                    : [color, color.withOpacity(0.0)],
              ),
            ),
          ),
          Positioned(
            left: isLeft ? null : 0,
            right: isLeft ? 0 : null,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Arabesque divider for tight spaces
class ArabesqueDividerCompact extends StatelessWidget {
  final Color? color;

  const ArabesqueDividerCompact({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary.withOpacity(0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 40, height: 0.5, color: c),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('❁', style: TextStyle(fontSize: 10, color: c)),
          ),
          Container(width: 40, height: 0.5, color: c),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FADE-THROUGH PAGE ROUTE — Smooth Mushaf → Tafsir transition
// ═══════════════════════════════════════════════════════════════════════════

class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeThroughPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Combined fade + scale for a premium spatial feel
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        );
}

// ═══════════════════════════════════════════════════════════════════════════
// READING SURFACE — Ivory/Cream wrapper for long reading content
// ═══════════════════════════════════════════════════════════════════════════

class TafsirReadingSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const TafsirReadingSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      color: TafsirTheme.readingBackground(brightness),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
