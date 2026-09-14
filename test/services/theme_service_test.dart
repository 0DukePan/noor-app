import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/theme/theme_service.dart';

/// ThemeService (previously 15% incidental): Hive-backed prefs round-trips,
/// unknown-id fallbacks, and theme generation mapping. Plain tests; the box
/// is cleared in setUp so tests are order-independent.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_theme_test');
    Hive.init(tempDir.path);
    await ThemeService.init();
  });

  setUp(() async {
    await Hive.box<dynamic>('theme_settings').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('fresh box yields documented defaults', () {
    expect(ThemeService.getCurrentPaletteId(), 'default');
    expect(ThemeService.getCurrentPalette().id, 'default');
    expect(ThemeService.getThemeMode(), ThemeMode.system);
    expect(ThemeService.isHapticEnabled(), isTrue);
    expect(ThemeService.getFontScale(), 1.0);
  });

  test('palette round-trips; unknown ids fall back to default', () async {
    final other = ThemeService.palettes[1];
    await ThemeService.setPalette(other.id);
    expect(ThemeService.getCurrentPaletteId(), other.id);
    expect(ThemeService.getCurrentPalette().id, other.id);
    await ThemeService.setPalette('no_such_palette');
    expect(ThemeService.getCurrentPaletteId(), 'no_such_palette');
    expect(ThemeService.getCurrentPalette().id, 'default');
    expect(ThemeService.palettes, hasLength(6));
  });

  test('theme mode round-trips light/dark/system', () async {
    await ThemeService.setThemeMode(ThemeMode.dark);
    expect(ThemeService.getThemeMode(), ThemeMode.dark);
    await ThemeService.setThemeMode(ThemeMode.light);
    expect(ThemeService.getThemeMode(), ThemeMode.light);
    await ThemeService.setThemeMode(ThemeMode.system);
    expect(ThemeService.getThemeMode(), ThemeMode.system);
  });

  test('haptic and font-scale prefs persist', () async {
    await ThemeService.setHapticEnabled(enabled: false);
    expect(ThemeService.isHapticEnabled(), isFalse);
    await ThemeService.setHapticEnabled(enabled: true);
    expect(ThemeService.isHapticEnabled(), isTrue);
    await ThemeService.setFontScale(1.5);
    expect(ThemeService.getFontScale(), 1.5);
  });

  test('generated themes map the palette and brightness', () {
    final palette = ThemeService.getCurrentPalette();
    final light = ThemeService.generateLightTheme(palette);
    expect(light.brightness, Brightness.light);
    expect(light.useMaterial3, isTrue);
    expect(light.colorScheme.primary, palette.primary);
    expect(light.colorScheme.secondary, palette.accent);
    expect(light.scaffoldBackgroundColor, palette.background);

    final dark = ThemeService.generateDarkTheme(palette);
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.primary, palette.primary);
  });
}
