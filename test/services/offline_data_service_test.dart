import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/offline_data_service.dart';

/// Tests for OfflineDataService (previously zero-covered): init() must copy
/// the bundled Quran into Hive so the offline-first cache serves data without
/// any network. API-fetch paths are not exercised (they need the network).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_offline_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('init bundles the full Quran into the offline cache', () async {
    await OfflineDataService.init();

    final stats = OfflineDataService.getCacheStats();
    // 114 surah entries + 'surahs' + 'initialized' keys.
    expect(stats['quran_items'], greaterThanOrEqualTo(116));

    final surahs = await OfflineDataService.getSurahs();
    expect(surahs.length, 114);
  });

  test('getSurah serves the cached bundled surah without network', () async {
    await OfflineDataService.init();

    final surah = await OfflineDataService.getSurah(1);
    expect(surah, isNotNull);
    final verses = surah!['verses'] as List;
    expect(verses.length, 7);
  });

  test('cached verses carry no fabricated metadata', () async {
    await OfflineDataService.init();

    final surah = await OfflineDataService.getSurah(2);
    final verse = (surah!['verses'] as List).first as Map;

    expect(verse['numberInSurah'], 1);
    expect(verse['text'], isNotEmpty);
    // These used to be written as 0/`false` placeholders, which any consumer
    // would read as real juz/page/sajda data.
    expect(verse.containsKey('juz'), isFalse);
    expect(verse.containsKey('page'), isFalse);
    expect(verse.containsKey('sajda'), isFalse);
  });

  test('offline fallback returns all 114 surahs, not an excerpt', () async {
    await OfflineDataService.init();
    // Force the cache miss: the test HTTP client cannot reach the API, so this
    // exercises the fallback that used to return a hand-kept five-surah list.
    await OfflineDataService.clearCache();

    final surahs = await OfflineDataService.getSurahs();

    expect(surahs, hasLength(114));
    expect(surahs.first['number'], 1);
    expect(surahs.last['number'], 114);
  });

  test('a second init reuses the existing cache', () async {
    await OfflineDataService.init();
    final before = OfflineDataService.getCacheStats();
    await OfflineDataService.init();
    expect(
      OfflineDataService.getCacheStats()['quran_items'],
      before['quran_items'],
    );
  });

  test('clearCache empties the offline boxes', () async {
    await OfflineDataService.init();
    expect(OfflineDataService.getCacheStats()['quran_items'], greaterThan(0));

    await OfflineDataService.clearCache();
    expect(OfflineDataService.getCacheStats()['quran_items'], 0);
  });
}
