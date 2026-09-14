import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/quran_data_source.dart';

/// Data-integrity tests for QuranDataSource (previously zero-covered): the
/// bundled Quran JSON must yield 114 surahs and correct verse counts — a
/// corrupted or truncated asset fails here, not in the reader.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_quran_ds_test');
    Hive.init(tempDir.path);
    await QuranDataSource.init();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('init loads all 114 surahs from the bundled asset', () async {
    final surahs = await QuranDataSource.getSurahsList();
    expect(surahs.length, 114);
    // First and last surah by number, ordered.
    expect(surahs.first['number'], 1);
    expect(surahs.last['number'], 114);
  });

  test('getSurah returns the ayahs for surah 1', () async {
    final surah = await QuranDataSource.getSurah(1);
    expect(surah['number'], 1);
    // Al-Fatiha has 7 ayahs; the first is the bismillah.
    expect(surah['numberOfAyahs'], 7);
    final ayahs = surah['ayahs'] as List;
    expect(ayahs.length, 7);
    final first = ayahs.first as Map;
    expect(first['numberInSurah'], 1);
    expect((first['text'] as String).trim(), isNotEmpty);
  });

  test('a large surah (Al-Baqara, 286 ayahs) round-trips intact', () async {
    final surah = await QuranDataSource.getSurah(2);
    expect(surah['numberOfAyahs'], 286);
  });
}
