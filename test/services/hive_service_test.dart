import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/hive_service.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';

/// Exercises the Hive storage wrapper: the getters read via Hive.box, so the
/// boxes are opened directly (initialize() calls Hive.initFlutter, a plugin
/// path unavailable in tests).
void main() {
  late Directory tempDir;

  const boxNames = [
    'surahs', 'verses', 'tafsir', 'hadiths', 'adhkar', 'reading_progress',
    'bookmarks', 'tadabbur', 'settings', 'qada',
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_hive_test');
    Hive.init(tempDir.path);
    for (final name in boxNames) {
      await Hive.openBox<Map<dynamic, dynamic>>(name);
    }
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('surah cache round-trips and sorts by number', () async {
    await HiveService.cacheSurahs([
      {'number': 2, 'name': 'البقرة'},
      {'number': 1, 'name': 'الفاتحة'},
    ]);
    final cached = HiveService.getCachedSurahs();
    expect(cached.length, 2);
    expect(cached.first['number'], 1);
    expect(cached.last['name'], 'البقرة');
  });

  test('verse and tafsir caches round-trip', () async {
    await HiveService.cacheVerses(1, [
      {'numberInSurah': 1, 'text': 'بسم الله'},
    ]);
    final verses = HiveService.getCachedVerses(1);
    expect(verses, isNotNull);
    expect(verses!.first['text'], 'بسم الله');
    expect(HiveService.getCachedVerses(2), isNull);

    await HiveService.cacheTafsir(1, 1, {'text': 'تفسير'});
    expect(HiveService.getCachedTafsir(1, 1)!['text'], 'تفسير');
  });

  test('hadith and adhkar caches round-trip', () async {
    await HiveService.cacheHadiths('bukhari', [
      {'arabic': 'نص حديث'},
    ]);
    await HiveService.cacheAdhkar('morning', [
      {'text': 'ذكر'},
    ]);
    expect(HiveService.getCachedHadiths('bukhari')!.first['arabic'], 'نص حديث');
    expect(HiveService.getCachedAdhkar('morning')!.first['text'], 'ذكر');
  });

  test('bookmarks and reading progress persist', () async {
    await HiveService.saveBookmark('quran', '2:255');
    await HiveService.saveBookmark('hadith', '1');
    expect(HiveService.isBookmarked('quran', '2:255'), isTrue);
    expect(HiveService.getBookmarksByType('quran').length, 1);
    await HiveService.removeBookmark('quran', '2:255');
    expect(HiveService.isBookmarked('quran', '2:255'), isFalse);

    await HiveService.saveReadingProgress({'surah': 2});
    expect(HiveService.getReadingProgress()!['surah'], 2);
  });

  test('tadabbur notes save, list, and delete', () async {
    await HiveService.saveTadabbur({
      'id': 'n1',
      'surahNumber': 1,
      'verseNumber': 1,
      'text': 'تدبر',
    });
    final forVerse = HiveService.getTadabburForVerse(1, 1);
    expect(forVerse.length, 1);
    expect(HiveService.getAllTadabbur().length, 1);
    await HiveService.deleteTadabbur('n1');
    expect(HiveService.getAllTadabbur(), isEmpty);
  });

  test('settings, onboarding and calculation method persist', () async {
    expect(HiveService.isOnboardingSeen, isFalse);
    await HiveService.setOnboardingSeen();
    expect(HiveService.isOnboardingSeen, isTrue);

    await HiveService.setCalculationMethod(CalculationMethod.egyptian);
    expect(HiveService.getCalculationMethod(), CalculationMethod.egyptian);
    expect(HiveService.getCalculationMethod(), isNotNull);
  });

  test('qada records persist and clearAll wipes user data', () async {
    await HiveService.saveQadaRecord({'id': 'q1', 'count': 3});
    expect(HiveService.getAllQadaRecords().length, 1);
    await HiveService.deleteQadaRecord('q1');
    expect(HiveService.getAllQadaRecords(), isEmpty);

    await HiveService.saveQadaRecord({'id': 'q2'});
    await HiveService.clearAll();
    expect(HiveService.getAllQadaRecords(), isEmpty);
  });
}
