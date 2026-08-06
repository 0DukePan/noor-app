import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'noor_theme.dart';

/// خدمة السمات - Theme Service
/// Manages app themes and user preferences
class ThemeService {
  static const _boxName = 'theme_settings';
  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  // Available Khushu color palettes
  static final List<ThemePalette> palettes = [
    ThemePalette(
      id: 'default',
      nameArabic: 'الأساسي',
      nameEnglish: 'Default',
      primary: NoorTheme.primary,
      accent: NoorTheme.accentGold,
      background: NoorTheme.bgMushaf,
    ),
    ThemePalette(
      id: 'ocean',
      nameArabic: 'المحيط',
      nameEnglish: 'Ocean',
      primary: const Color(0xFF0D47A1),
      accent: const Color(0xFF4FC3F7),
      background: const Color(0xFFF5F9FC),
    ),
    ThemePalette(
      id: 'forest',
      nameArabic: 'الغابة',
      nameEnglish: 'Forest',
      primary: const Color(0xFF2E7D32),
      accent: const Color(0xFF81C784),
      background: const Color(0xFFF5F8F5),
    ),
    ThemePalette(
      id: 'sunset',
      nameArabic: 'الغروب',
      nameEnglish: 'Sunset',
      primary: const Color(0xFFBF360C),
      accent: const Color(0xFFFFAB91),
      background: const Color(0xFFFFF8F5),
    ),
    ThemePalette(
      id: 'lavender',
      nameArabic: 'اللافندر',
      nameEnglish: 'Lavender',
      primary: const Color(0xFF6A1B9A),
      accent: const Color(0xFFCE93D8),
      background: const Color(0xFFFAF5FC),
    ),
    ThemePalette(
      id: 'midnight',
      nameArabic: 'منتصف الليل',
      nameEnglish: 'Midnight',
      primary: const Color(0xFF1A237E),
      accent: const Color(0xFFFFD54F),
      background: const Color(0xFFF5F5FA),
    ),
  ];

  /// Get current palette ID
  static String getCurrentPaletteId() {
    return _box?.get('palette_id', defaultValue: 'default') ?? 'default';
  }

  /// Get current palette
  static ThemePalette getCurrentPalette() {
    final id = getCurrentPaletteId();
    return palettes.firstWhere(
      (p) => p.id == id,
      orElse: () => palettes.first,
    );
  }

  /// Set palette
  static Future<void> setPalette(String paletteId) async {
    await _box?.put('palette_id', paletteId);
  }

  /// Get theme mode
  static ThemeMode getThemeMode() {
    final mode = _box?.get('theme_mode', defaultValue: 'system');
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode
  static Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      default:
        value = 'system';
    }
    await _box?.put('theme_mode', value);
  }

  /// Get haptic enabled
  static bool isHapticEnabled() {
    return _box?.get('haptic_enabled', defaultValue: true) ?? true;
  }

  /// Set haptic enabled
  static Future<void> setHapticEnabled(bool enabled) async {
    await _box?.put('haptic_enabled', enabled);
  }

  /// Get font scale
  static double getFontScale() {
    return _box?.get('font_scale', defaultValue: 1.0) ?? 1.0;
  }

  /// Set font scale
  static Future<void> setFontScale(double scale) async {
    await _box?.put('font_scale', scale);
  }

  /// Generate theme data from palette
  static ThemeData generateLightTheme(ThemePalette palette) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: palette.primary,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        secondary: palette.accent,
        surface: Colors.white,
        background: palette.background,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.primary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      fontFamily: 'Cairo',
    );
  }

  static ThemeData generateDarkTheme(ThemePalette palette) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: palette.primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        secondary: palette.accent,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: palette.accent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      fontFamily: 'Cairo',
    );
  }
}

/// Theme palette model
class ThemePalette {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final Color primary;
  final Color accent;
  final Color background;

  ThemePalette({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.primary,
    required this.accent,
    required this.background,
  });
}

/// Riverpod providers for theme
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeService.getThemeMode();
});

final themePaletteProvider = StateProvider<ThemePalette>((ref) {
  return ThemeService.getCurrentPalette();
});

final hapticEnabledProvider = StateProvider<bool>((ref) {
  return ThemeService.isHapticEnabled();
});

final fontScaleProvider = StateProvider<double>((ref) {
  return ThemeService.getFontScale();
});
