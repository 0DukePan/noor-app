import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';
import 'package:noor_app/core/data/data_sources/hadith_db_builder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Data-integrity tests for HadithDatabase.full-text search (FTS5) and the
/// query API, against a small real corpus (nawawi40) built via
/// `openWithBooks`.
///
/// Regression focus: the documented "FTS5 index was never aligned with the
/// content" bug. The FTS table is external-content (`content='hadiths'`,
/// `content_rowid='rowid'`), so the index rowids must be realigned with the
/// content table after import via `rebuildFts` — otherwise the
/// `h.rowid = fts.rowid` JOIN returns nothing or, worse, the wrong rows.
/// These tests assert that search results actually *contain* the query term,
/// which is exactly what an alignment regression would break.
void main() {
  late Directory tempDir;
  late Database db;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_fts_test');
    db = await HadithDatabase.openWithBooks(
      ['nawawi40'],
      directory: tempDir.path,
    );
  });

  tearDown(() async {
    await db.close();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  group('HadithDatabase.search (FTS5)', () {
    test('returns hadiths that actually contain the query (rowid alignment)',
        () async {
      // A distinctive word that must appear in nawawi40.
      final results = await HadithDatabase.search('الصلاة', db: db, limit: 20);
      expect(results, isNotEmpty, reason: 'FTS search should hit hadiths');
      final norm = HadithDatabase.normalizeForSearch('الصلاة');
      for (final r in results) {
        final text = r['arabic_norm'] as String? ?? '';
        expect(
          text,
          contains(norm),
          reason: 'returned hadith must actually match the query '
              '(guards against FTS/content rowid misalignment)',
        );
      }
    });

    test('searches with or without diacritics via the normalized column',
        () async {
      // Diacritized query.
      final diacritized = await HadithDatabase.search(
        'صَلَاة',
        db: db,
        limit: 10,
      );
      // Un-diacritized query.
      final plain = await HadithDatabase.search('صلاة', db: db, limit: 10);
      expect(diacritized, isNotEmpty);
      expect(plain, isNotEmpty);
    });

    test('scoping by collectionId returns only that book', () async {
      final results = await HadithDatabase.search(
        'الصلاة',
        collectionId: 'nawawi40',
        db: db,
        limit: 20,
      );
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r['collection_id'], 'nawawi40');
      }
    });

    test('a term absent from the corpus returns an empty list', () async {
      final results = await HadithDatabase.search(
        'مصطلحغيرموجودقط',
        db: db,
        limit: 20,
      );
      expect(results, isEmpty);
    });

    test('empty / whitespace query returns an empty list', () async {
      expect(await HadithDatabase.search('', db: db), isEmpty);
      expect(await HadithDatabase.search('   ', db: db), isEmpty);
    });

    test('FTS special characters fall back to LIKE without crashing',
        () async {
      // These are invalid FTS5 MATCH syntax; search must not throw.
      final results = await HadithDatabase.search('"-"', db: db, limit: 5);
      expect(results, isA<List<Map<String, dynamic>>>());
    });
  });

  group('HadithDatabase.normalizeForSearch', () {
    test('strips diacritics and hamza variants', () {
      expect(HadithDatabase.normalizeForSearch('صَلَاة'), 'صلاة');
      expect(HadithDatabase.normalizeForSearch('مُحَمَّد'), 'محمد');
    });

    test('collapses whitespace and trims', () {
      expect(HadithDatabase.normalizeForSearch('  a   b  '), 'a b');
    });
  });

  group('HadithDatabase detail API', () {
    test('getHadiths paginates ordered by id_in_book', () async {
      final page1 =
          await HadithDatabase.getHadiths(collectionId: 'nawawi40', db: db);
      expect(page1, isNotEmpty);
      final page2 = await HadithDatabase.getHadiths(
        collectionId: 'nawawi40',
        limit: page1.length,
        offset: page1.length,
        db: db,
      );
      // Pagination offset must not repeat page 1's first id.
      expect(page2.map((r) => r['id']), isNot(contains(page1.first['id'])));
    });

    test('getHadithById returns the same row as getHadiths', () async {
      final rows =
          await HadithDatabase.getHadiths(collectionId: 'nawawi40', db: db);
      final id = rows.first['id'] as int;
      final byId =
          await HadithDatabase.getHadithById('nawawi40', id, db: db);
      expect(byId, isNotNull);
      expect(byId!['id'], id);
      expect(byId['id_in_book'], rows.first['id_in_book']);
      expect(byId['arabic'], rows.first['arabic']);
    });

    test('getHadithById returns null for a missing hadith', () async {
      expect(
        await HadithDatabase.getHadithById('nawawi40', 999999, db: db),
        isNull,
      );
    });

    test('getChapterHadithCounts is consistent with getHadiths', () async {
      final counts =
          await HadithDatabase.getChapterHadithCounts('nawawi40', db: db);
      expect(counts, isNotEmpty);
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      final all =
          await HadithDatabase.getHadiths(collectionId: 'nawawi40', db: db);
      expect(
        total,
        all.length,
        reason: 'chapter counts must sum to the full collection size',
      );
    });

    test('searchByNarrator filters hadiths by the narrator field', () async {
      final byNarrator =
          await HadithDatabase.searchByNarrator('Imam', db: db);
      expect(byNarrator, isA<List<Map<String, dynamic>>>());
      for (final r in byNarrator) {
        final narrator = (r['english_narrator'] as String? ?? '').toLowerCase();
        expect(narrator, contains('imam'));
      }
    });
  });

  group('FTS5 ↔ content rowid alignment (regression)', () {
    // Tokenizes exactly as FTS5's unicode61 does over the normalized text:
    // any run of letters/digits is one token. Both the index and this scan
    // see the same arabic_norm strings, so the token sets must agree.
    List<String> tokens(String text) => text
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((t) => t.isNotEmpty)
        .toList();

    test('FTS hits are exactly the content rows containing the query token',
        () async {
      const query = 'الصلاة';
      final ftsHits = await HadithDatabase.search(query, db: db);
      expect(
        ftsHits,
        isNotEmpty,
        reason: 'precondition: the FTS path must hit, not the LIKE fallback',
      );

      final norm = HadithDatabase.normalizeForSearch(query);
      final expected = <String>{};
      final all = await db
          .query('hadiths', columns: ['collection_id', 'id_in_book', 'arabic_norm']);
      for (final row in all) {
        if (tokens(row['arabic_norm'] as String? ?? '').contains(norm)) {
          expected.add('${row['collection_id']}:${row['id_in_book']}');
        }
      }
      expect(expected, isNotEmpty);

      final actual =
          ftsHits.map((r) => '${r['collection_id']}:${r['id_in_book']}').toSet();
      expect(
        actual,
        expected,
        reason: 'the FTS rowid JOIN must return exactly the documents whose '
            'normalized text contains the query token — a shifted, duplicated '
            'or stale index (the documented "FTS never aligned with content" '
            'bug class) breaks this identity even when counts still match',
      );
    });

    test('every raw FTS rowid resolves to a real content row containing the term',
        () async {
      const query = 'الصلاة';
      final ftsRowids = await db.rawQuery(
        'SELECT rowid FROM hadiths_fts WHERE hadiths_fts MATCH ?',
        [query],
      );
      expect(ftsRowids, isNotEmpty);
      final norm = HadithDatabase.normalizeForSearch(query);
      for (final fts in ftsRowids) {
        final rowid = (fts['rowid'] as int?)!;
        final content = await db.query(
          'hadiths',
          columns: ['rowid', 'arabic_norm'],
          where: 'rowid = ?',
          whereArgs: [rowid],
        );
        expect(
          content,
          isNotEmpty,
          reason: 'FTS rowid $rowid has no content row — a phantom index entry',
        );
        expect(
          tokens(content.first['arabic_norm'] as String? ?? ''),
          contains(norm),
        );
      }
    });

    test('INSERT OR REPLACE without rebuildFts leaves the index stale', () async {
      // External-content FTS has no triggers: replacing a row deletes the old
      // rowid and inserts at a NEW rowid, silently desynchronizing the index
      // until rebuildFts runs. This locks in the importer's rebuild contract.
      final original = (await db.query('hadiths', limit: 1)).first;
      const uniqueTerm = 'توافقاختبارنور';
      final normTerm = HadithDatabase.normalizeForSearch(uniqueTerm);
      await db.insert(
        'hadiths',
        {
          'id': original['id'],
          'id_in_book': original['id_in_book'],
          'collection_id': original['collection_id'],
          'chapter_id': original['chapter_id'],
          'arabic': '$uniqueTerm نص اختبار',
          'arabic_norm': '$normTerm نص اختبار',
          'english_narrator': original['english_narrator'],
          'english_text': original['english_text'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Stale index: the new content is invisible to FTS until a rebuild.
      final beforeRebuild = await db.rawQuery(
        'SELECT rowid FROM hadiths_fts WHERE hadiths_fts MATCH ?',
        [uniqueTerm],
      );
      expect(
        beforeRebuild,
        isEmpty,
        reason: 'content changed without rebuildFts must NOT appear in the '
            'index (guards the "every writer ends with rebuildFts" contract)',
      );

      await HadithDbImporter.rebuildFts(db);

      final afterRebuild = await db.rawQuery(
        'SELECT rowid FROM hadiths_fts WHERE hadiths_fts MATCH ?',
        [uniqueTerm],
      );
      expect(afterRebuild, hasLength(1));
      final joined = await db.query(
        'hadiths',
        columns: ['id', 'collection_id', 'arabic_norm'],
        where: 'rowid = ?',
        whereArgs: [afterRebuild.first['rowid']],
      );
      expect(joined, hasLength(1));
      expect(
        tokens(joined.first['arabic_norm'] as String? ?? ''),
        contains(normTerm),
      );
      expect(joined.first['id'], original['id']);
      expect(joined.first['collection_id'], original['collection_id']);
    });

    test('an FTS search hit resolves through the id-based detail API', () async {
      final hits = await HadithDatabase.search('الصلاة', db: db, limit: 5);
      expect(hits, isNotEmpty);
      for (final hit in hits) {
        final detail = await HadithDatabase.getHadithById(
          hit['collection_id'] as String,
          hit['id'] as int,
          db: db,
        );
        expect(
          detail,
          isNotNull,
          reason: 'every FTS hit must resolve via getHadithById (the reader '
              'detail path used by the search pages)',
        );
        expect(detail!['id_in_book'], hit['id_in_book']);
        expect(detail['arabic'], hit['arabic']);
      }
    });
  });
}
