import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';
import 'package:noor_app/core/services/hadith_search_engine.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tests the refined hadith-grades dataset (grades.json): dataset lookup,
/// per-book fallback, and scholar attribution.
void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_grades_test');
    Hive.init(tempDir.path);
    final db = await HadithDatabase.openWithBooks(
      ['nawawi40'],
      directory: tempDir.path,
    );
    await HadithSearchEngine.init(forTesting: db);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('dataset loads with scholar attribution', () {
    expect(HadithSearchEngine.gradeFor('tirmidhi', 2675), 'صحيح');
    expect(HadithSearchEngine.gradeScholarFor('tirmidhi', 2675), 'الألباني');
    expect(HadithSearchEngine.gradeFor('abudawud', 4781), 'صحيح');
    expect(HadithSearchEngine.gradeFor('ibnmajah', 4252), 'حسن');
  });

  test('unlisted hadiths fall back to the per-book grade', () {
    expect(HadithSearchEngine.gradeFor('tirmidhi', 99999), 'من المصدر');
    expect(HadithSearchEngine.gradeScholarFor('tirmidhi', 99999), isNull);
  });

  test('Sahihain keep their whole-book grade', () {
    expect(HadithSearchEngine.gradeFor('bukhari', 1), 'صحيح');
    expect(HadithSearchEngine.gradeFor('muslim', 1), 'صحيح');
  });

  test('index entries carry the refined grade and scholar', () async {
    final results = await HadithSearchEngine.search('عن', limit: 20);
    // Nawawi 40 is not in the dataset → per-book fallback applies.
    for (final r in results) {
      expect(r.entry.grade, isNotEmpty);
      if (r.entry.book == 'nawawi40') {
        expect(r.entry.grade, 'من المصدر');
      }
    }
  });
}
