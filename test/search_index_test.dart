import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';
import 'package:noor_app/features/search/data/data_sources/search_local_data_source.dart';
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
    tempDir = await Directory.systemTemp.createTemp('noor_search_db_test');
    Hive.init(tempDir.path);
    // The ffi factory keeps a fixed default db path; remove any stale index
    // from a previous run so ensureIndexed rebuilds it.
    await SearchLocalDataSource.clearIndex();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('indexes quran, hadith and adhkar; query returns all sources',
      () async {
    final hadithDb = await HadithDatabase.openWithBooks(
      ['nawawi40'],
      directory: tempDir.path,
    );

    final dataSource = SearchLocalDataSource();
    await dataSource.ensureIndexed([], [], hadithDb: hadithDb);

    // Verify each source was indexed.
    final db = await dataSource.db;
    final counts = <String, int>{};
    for (final source in ['quran', 'hadith', 'adhkar']) {
      final row = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM search_index WHERE source = ?',
        [source],
      );
      counts[source] = Sqflite.firstIntValue(row) ?? 0;
    }
    expect(counts['quran'], greaterThan(0));
    expect(counts['hadith'], greaterThan(0));
    expect(counts['adhkar'], greaterThan(0));

    // A de-diacritized query must find Quranic text (incl. alef-wasla).
    final quran = await dataSource.search('الرحمن');
    expect(quran, isNotEmpty);
    expect(quran.any((r) => r['source'] == 'quran'), isTrue);

    // Adhkar text (e.g. from the authored sleep collection) must be findable.
    final adhkar = await dataSource.search('أعوذ برب الناس');
    expect(adhkar.any((r) => r['source'] == 'adhkar'), isTrue);

    // clearIndex removes the file so it can rebuild.
    final path = await dataSource.databasePath;
    expect(File(path).existsSync(), isTrue);
    await SearchLocalDataSource.clearIndex();
    expect(File(path).existsSync(), isFalse);
  });
}
