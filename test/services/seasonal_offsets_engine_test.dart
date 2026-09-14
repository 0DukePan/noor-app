import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/seasonal_offsets_engine.dart';

/// Tests SeasonalOffsetsEngine: default offsets, custom offsets, mosque
/// offsets, and applying offsets to prayer times.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_offsets_test');
    Hive.init(tempDir.path);
    await SeasonalOffsetsEngine.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('ships sensible per-prayer default offsets', () {
    // Dhuhr and maghrib carry a constant +5/+3 minute correction; fajr and
    // isha are winter-only (+2/+5); sunrise and asr are always zero.
    expect(
      SeasonalOffsetsEngine.getOffset('dhuhr', latitude: 21.4),
      const Duration(minutes: 5),
    );
    expect(
      SeasonalOffsetsEngine.getOffset('maghrib', latitude: 21.4),
      const Duration(minutes: 3),
    );
    expect(
      SeasonalOffsetsEngine.getOffset('sunrise', latitude: 21.4),
      Duration.zero,
    );
    expect(
      SeasonalOffsetsEngine.getOffset('asr', latitude: 21.4),
      Duration.zero,
    );
    final isWinter = SeasonalOffsetsEngine.isWinterSeason(latitude: 21.4);
    expect(
      SeasonalOffsetsEngine.getOffset('fajr', latitude: 21.4),
      isWinter ? const Duration(minutes: 2) : Duration.zero,
    );
    expect(
      SeasonalOffsetsEngine.getOffset('isha', latitude: 21.4),
      isWinter ? const Duration(minutes: 5) : Duration.zero,
    );
  });

  test('custom offsets round-trip and apply', () async {
    await SeasonalOffsetsEngine.setCustomOffset(
      prayer: 'fajr',
      summerMinutes: 2,
      winterMinutes: -1,
    );
    final isWinter = SeasonalOffsetsEngine.isWinterSeason(latitude: 21.4);
    expect(
      SeasonalOffsetsEngine.getOffset('fajr', latitude: 21.4),
      Duration(minutes: isWinter ? -1 : 2),
    );
  });

  test('mosque offsets are stored and applied', () async {
    await SeasonalOffsetsEngine.saveMosqueOffsets(
      mosqueId: 'mosque-1',
      mosqueName: 'المسجد الحرام',
      offsets: {
        'fajr': 3,
        'isha': 5,
      },
    );
    final mosque = SeasonalOffsetsEngine.getMosqueOffsets('mosque-1');
    expect(mosque, isNotNull);
    expect(mosque!.name, 'المسجد الحرام');
    expect(mosque.offsets['fajr'], 3);
    expect(mosque.offsets['isha'], 5);

    await SeasonalOffsetsEngine.applyMosqueOffsets('mosque-1');
    expect(SeasonalOffsetsEngine.activeMosqueId, 'mosque-1');
    // isha now has a 5-minute offset in both seasons.
    expect(
      SeasonalOffsetsEngine.getOffset('isha', latitude: 21.4),
      const Duration(minutes: 5),
    );
  });

  test('applyOffset shifts the prayer time', () async {
    await SeasonalOffsetsEngine.setCustomOffset(
      prayer: 'maghrib',
      summerMinutes: 4,
      winterMinutes: 0,
    );
    final base = DateTime(2026, 8, 1, 18, 30);
    final shifted = SeasonalOffsetsEngine.applyOffset(
      base,
      'maghrib',
      latitude: 21.4,
    );
    expect(shifted, base.add(const Duration(minutes: 4)));
  });

  test('season follows the prayer date, not today (regression)', () async {
    // Regression: applyOffset used DateTime.now() for the season, so the
    // same August prayer time got the summer offset in July but the winter
    // offset in September. The season must come from the prayer date.
    await SeasonalOffsetsEngine.setCustomOffset(
      prayer: 'maghrib',
      summerMinutes: 4,
      winterMinutes: 0,
    );
    final august = DateTime(2026, 8, 1, 18, 30);
    expect(
      SeasonalOffsetsEngine.applyOffset(august, 'maghrib', latitude: 21.4),
      august.add(const Duration(minutes: 4)),
    );
    final january = DateTime(2026, 1, 15, 18, 30);
    expect(
      SeasonalOffsetsEngine.applyOffset(january, 'maghrib', latitude: 21.4),
      january,
    );
    // getOffset honours an explicit date too.
    expect(
      SeasonalOffsetsEngine.getOffset('maghrib', latitude: 21.4, date: august),
      const Duration(minutes: 4),
    );
    expect(
      SeasonalOffsetsEngine.getOffset('maghrib', latitude: 21.4, date: january),
      Duration.zero,
    );
  });
}
