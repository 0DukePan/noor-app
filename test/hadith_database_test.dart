import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';
import 'package:noor_app/core/services/hadith_search_engine.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_hadith_db_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('imports a subset of books and full-text search finds hadith', () async {
    final db = await HadithDatabase.openWithBooks(
      ['bukhari'],
      directory: tempDir.path,
    );

    final collections = await db.query('collections');
    expect(collections.length, 1);
    expect(collections.first['id'], 'bukhari');

    final count = await db.rawQuery('SELECT COUNT(*) AS c FROM hadiths');
    final hadithCount = Sqflite.firstIntValue(count) ?? 0;
    expect(hadithCount, greaterThan(1000));

    // The FTS5 index must be aligned with the content table (the Phase-1 fix).
    final ftsCount = await db.rawQuery('SELECT COUNT(*) AS c FROM hadiths_fts');
    final indexed = Sqflite.firstIntValue(ftsCount) ?? 0;
    expect(indexed, hadithCount);

    // Search a word that appears in Bukhari.
    final results = await HadithDatabase.search('النبي', db: db, limit: 10);
    expect(results, isNotEmpty);

    await db.close();
  });

  test('search falls back to LIKE for unmatched terms', () async {
    final db = await HadithDatabase.openWithBooks(
      ['nawawi40'],
      directory: tempDir.path,
    );

    // A phrase unlikely to tokenize as an FTS phrase match, but present.
    final results = await HadithDatabase.search('إنما الأعمال', db: db, limit: 5);
    expect(results, isNotEmpty);

    await db.close();
  });

  test('hadith search engine builds an index from a subset DB', () async {
    final db = await HadithDatabase.openWithBooks(
      ['bukhari'],
      directory: tempDir.path,
    );

    await HadithSearchEngine.init(forTesting: db);

    expect(HadithSearchEngine.getSearchIndexCount(), greaterThan(1000));
    expect(HadithSearchEngine.getCompanions(), isNotEmpty);
    expect(HadithSearchEngine.getTopics(), isNotEmpty);

    final results = await HadithSearchEngine.search('النبي', limit: 5);
    expect(results, isNotEmpty);

    await db.close();
  });
}
