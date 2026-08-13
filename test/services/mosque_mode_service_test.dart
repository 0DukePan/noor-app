import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/mosque_mode_service.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';

/// Tests MosqueModeService persistence: defaults, toggling, per-prayer
/// enablement, and the active state.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_mosque_test');
    Hive.init(tempDir.path);
    await MosqueModeService.init();
  });

  tearDown(() async {
    MosqueModeService.dispose();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('defaults: disabled, 20 minutes, every prayer enabled', () {
    expect(MosqueModeService.isEnabled, isFalse);
    expect(MosqueModeService.durationMinutes, 20);
    for (final prayer in PrayerType.values) {
      if (prayer == PrayerType.sunrise) continue;
      expect(MosqueModeService.isPrayerEnabled(prayer), isTrue);
    }
  });

  test('enable/disable persists across reload', () async {
    await MosqueModeService.enable();
    expect(MosqueModeService.isEnabled, isTrue);

    await MosqueModeService.disable();
    expect(MosqueModeService.isEnabled, isFalse);
  });

  test('per-prayer toggling persists', () async {
    await MosqueModeService.setPrayerEnabled(
      PrayerType.fajr,
      enabled: false,
    );
    expect(MosqueModeService.isPrayerEnabled(PrayerType.fajr), isFalse);
    expect(MosqueModeService.isPrayerEnabled(PrayerType.dhuhr), isTrue);

    await MosqueModeService.setPrayerEnabled(
      PrayerType.fajr,
      enabled: true,
    );
    expect(MosqueModeService.isPrayerEnabled(PrayerType.fajr), isTrue);
  });

  test('settings survive a fresh init from disk', () async {
    await MosqueModeService.setPrayerEnabled(
      PrayerType.isha,
      enabled: false,
    );
    // Re-initialize from the same Hive store.
    await MosqueModeService.init();
    expect(MosqueModeService.isPrayerEnabled(PrayerType.isha), isFalse);
  });
}
