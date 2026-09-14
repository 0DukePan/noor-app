import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/data/data_sources/local_tafsir_data_source.dart';

import '../test_utils/tafsir_test_db.dart';

/// Tests LocalTafsirDataSource against the prebuilt tafsir database, so a
/// missing/corrupt database or a query regression fails here rather than at
/// runtime in the reader.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await setUpTafsirTestDb();
  });

  tearDownAll(() async {
    await tearDownTafsirTestDb(tempDir);
  });

  setUp(() async {
    // Fresh DB connection per test (see tafsir_test_db.dart zone note).
    await resetTafsirTestDb();
  });

  test('loads Muyassar tafsir for surah 1 from the database', () async {
    final ds = LocalTafsirDataSource();
    final verse = await ds.getTafsir(surahId: 1, verseId: 1);
    expect(verse, isNotNull, reason: 'surah 1 ayah 1 tafsir must exist');
    expect(verse!.surahId, 1);
    expect(verse.verseId, 1);
    expect(verse.source, 'muyassar');
    expect(verse.text, isNotEmpty);
  });

  test('each book id resolves to its own source label', () async {
    final ds = LocalTafsirDataSource();
    for (final bookId in ['muyassar', 'ibn_kathir', 'saadi', 'tabari']) {
      final verse = await ds.getTafsir(surahId: 1, verseId: 1, bookId: bookId);
      expect(verse, isNotNull, reason: 'surah 1 ayah 1 in $bookId');
      expect(verse!.source, bookId);
    }
  });

  test('an unknown book id falls back to muyassar data', () async {
    final ds = LocalTafsirDataSource();
    // Unknown id keeps the passed label but loads Muyassar's bundled data
    // (its folder is used for the asset path).
    final unknown = await ds.getTafsir(surahId: 1, verseId: 1, bookId: 'nope');
    final muyassar = await ds.getTafsir(surahId: 1, verseId: 1);
    expect(unknown, isNotNull);
    expect(
      unknown!.text,
      muyassar!.text,
      reason: 'fallback must load the Muyassar data',
    );
  });

  test('a missing verse returns null rather than throwing', () async {
    final ds = LocalTafsirDataSource();
    final verse = await ds.getTafsir(surahId: 1, verseId: 9999);
    expect(verse, isNull);
  });

  test('clearCache empties the cache and reloads', () async {
    final ds = LocalTafsirDataSource();
    expect(await ds.getTafsir(surahId: 2, verseId: 1), isNotNull);
    ds.clearCache();
    expect(await ds.getTafsir(surahId: 2, verseId: 1), isNotNull);
  });
}
