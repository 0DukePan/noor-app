import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';
import 'package:noor_app/core/services/hadith_search_engine.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Regression tests for the index derivation fixes: companion/topic
/// extraction on the fully-vocalized corpus and per-book grades.
void main() {
  late Directory tempDir;
  late Database db;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_index_fix_test');
    Hive.init(tempDir.path);
    db = await HadithDatabase.openWithBooks(
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

  test('companions are extracted from the vocalized corpus', () {
    // The corpus is fully diacritized («عَنْ»); the regex «عن» can only
    // match after normalization — this test guards that regression.
    final companions = HadithSearchEngine.getCompanions();
    expect(companions, isNotEmpty,
        reason: 'companion extraction must work on vocalized text',);
  });

  test('topics are extracted from the vocalized corpus', () {
    final topics = HadithSearchEngine.getTopics();
    expect(topics, isNotEmpty,
        reason: 'topic extraction must work on vocalized text',);
    final counts = HadithSearchEngine.getTopicCounts();
    expect(counts.values.every((c) => c > 0), isTrue);
  });

  test('companion and topic filters return results', () async {
    final companions = HadithSearchEngine.getCompanions();
    if (companions.isEmpty) return; // covered by the tests above
    final byCompanion = await HadithSearchEngine.getByCompanion(companions.first);
    expect(byCompanion, isNotEmpty);

    final topics = HadithSearchEngine.getTopics();
    if (topics.isEmpty) return;
    final byTopic = await HadithSearchEngine.getByTopic(topics.first);
    expect(byTopic, isNotEmpty);
  });

  test('grades are per-book: Sahihain = صحيح, others = من المصدر', () {
    expect(HadithSearchEngine.gradeForBook('bukhari'), 'صحيح');
    expect(HadithSearchEngine.gradeForBook('muslim'), 'صحيح');
    expect(HadithSearchEngine.gradeForBook('tirmidhi'), 'من المصدر');
    expect(HadithSearchEngine.gradeForBook('ahmed'), 'من المصدر');
  });

  test('grade filter finds Sahihain hadiths only', () async {
    final sahih = await HadithSearchEngine.search(
      'عن',
      grade: 'صحيح',
      limit: 10,
    );
    // Nawawi 40 is not a Sahihain collection → its hadiths have 'من المصدر'.
    expect(sahih, isEmpty);

    final sourced = await HadithSearchEngine.search('عن', limit: 10);
    expect(sourced, isNotEmpty);
    expect(sourced.every((r) => r.entry.grade == 'من المصدر'), isTrue);
  });
}
