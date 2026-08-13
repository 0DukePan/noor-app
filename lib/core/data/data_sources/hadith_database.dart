import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


/// مدير قاعدة بيانات الحديث - Hadith SQLite Database Manager
///
/// Builds and caches an SQLite database from JSON assets on first launch.
/// Subsequent launches use the pre-built database for instant queries.
class HadithDatabase {
  static const int _dbVersion = 2;
  static const String _dbName = 'hadith_v1.db';

  /// Book IDs that map to `assets/hadith/by_book/the_9_books/`
  static const List<String> _nineBooks = [
    'bukhari', 'muslim', 'abudawud', 'tirmidhi',
    'nasai', 'ibnmajah', 'malik', 'ahmed', 'darimi',
  ];

  /// Other books in `forties/` and `other_books/`
  static const List<Map<String, String>> _otherBooks = [
    {'id': 'nawawi40', 'path': 'forties/nawawi40.json'},
    {'id': 'qudsi40', 'path': 'forties/qudsi40.json'},
    {'id': 'shahwaliullah40', 'path': 'forties/shahwaliullah40.json'},
    {'id': 'riyad_assalihin', 'path': 'other_books/riyad_assalihin.json'},
    {'id': 'bulugh_almaram', 'path': 'other_books/bulugh_almaram.json'},
    {'id': 'aladab_almufrad', 'path': 'other_books/aladab_almufrad.json'},
    {'id': 'mishkat_almasabih', 'path': 'other_books/mishkat_almasabih.json'},
    {'id': 'shamail_muhammadiyah', 'path': 'other_books/shamail_muhammadiyah.json'},
  ];

  /// Returns the singleton database instance, building it on first call.
  ///
  /// Memoized on a future so concurrent callers (e.g. the search index build
  /// racing the first hadith page visit) share a single initialization.
  static Future<Database>? _dbFuture;

  static Future<Database> get database => _dbFuture ??= _initDatabase();

  /// Kick off database creation in the background so the first frame is not
  /// blocked by the one-time 17-book import.
  static Future<void> warmUp() async {
    try {
      await database;
    } on Exception catch (e) {
      debugPrint('HadithDatabase warmUp failed: $e');
    }
  }

  /// Test hook: point the database at a writable directory so tests can avoid
  /// path_provider (which needs platform channels).
  static String debugDatabaseDirectory = '';

  static Future<Database> _initDatabase() async {
    final dir = debugDatabaseDirectory.isNotEmpty
        ? debugDatabaseDirectory
        : (await getApplicationDocumentsDirectory()).path;
    final dbPath = p.join(dir, _dbName);
    _wasCached = File(dbPath).existsSync();

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        debugPrint('🗄️ Creating Hadith database...');
        await _createTables(db);
        await _importAllBooks(db);
        debugPrint('✅ Hadith database created successfully.');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('🗄️ Upgrading Hadith database $oldVersion → $newVersion');
        if (oldVersion < 2) {
          // v1 → v2: add the normalized Arabic column (diacritics stripped)
          // and rebuild the FTS index over it so de-diacritized searches work.
          await _migrateToV2(db);
        }
      },
    );
  }

  /// v1 → v2: `arabic_norm` holds the de-diacritized text for FTS indexing.
  static Future<void> _migrateToV2(Database db) async {
    try {
      await db.execute('ALTER TABLE hadiths ADD COLUMN arabic_norm TEXT');
    } on Exception catch (_) {
      // Column may already exist on partially migrated databases.
    }

    // Backfill normalized text in batches.
    const batchSize = 1000;
    var offset = 0;
    while (true) {
      final rows = await db.query(
        'hadiths',
        columns: ['rowid', 'arabic'],
        limit: batchSize,
        offset: offset,
      );
      if (rows.isEmpty) break;
      final batch = db.batch();
      for (final row in rows) {
        batch.update(
          'hadiths',
          {'arabic_norm': normalizeForSearch(row['arabic'] as String? ?? '')},
          where: 'rowid = ?',
          whereArgs: [row['rowid']],
        );
      }
      await batch.commit(noResult: true);
      offset += rows.length;
    }

    // Recreate the FTS table over arabic_norm and rebuild it.
    try {
      await db.execute('DROP TABLE hadiths_fts');
    } on Exception catch (_) {}
    await db.execute('''
      CREATE VIRTUAL TABLE hadiths_fts USING fts5(
        arabic_norm,
        english_text,
        english_narrator,
        content='hadiths',
        content_rowid='rowid'
      )
    ''');
    await _rebuildFts(db);
  }

  /// Opens a FRESH database importing only [bookIds] — used by tests so the
  /// suite doesn't re-import the full 17-book corpus on every run.
  static Future<Database> openWithBooks(
    List<String> bookIds, {
    String? directory,
  }) async {
    final dir = directory ??
        (debugDatabaseDirectory.isNotEmpty ? debugDatabaseDirectory : (await getApplicationDocumentsDirectory()).path);
    final dbPath = p.join(dir, 'hadith_test_${bookIds.join('_')}.db');
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
        await _importBooks(db, bookIds);
        await _rebuildFts(db);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCHEMA
  // ═══════════════════════════════════════════════════════════════════

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS collections (
        id TEXT PRIMARY KEY,
        title_arabic TEXT NOT NULL,
        title_english TEXT,
        author_arabic TEXT,
        author_english TEXT,
        introduction TEXT,
        hadith_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chapters (
        id INTEGER,
        collection_id TEXT NOT NULL,
        title_arabic TEXT NOT NULL,
        title_english TEXT,
        PRIMARY KEY (id, collection_id),
        FOREIGN KEY (collection_id) REFERENCES collections(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS hadiths (
        id INTEGER,
        id_in_book INTEGER,
        collection_id TEXT NOT NULL,
        chapter_id INTEGER,
        arabic TEXT NOT NULL,
        arabic_norm TEXT,
        english_narrator TEXT,
        english_text TEXT,
        PRIMARY KEY (id, collection_id),
        FOREIGN KEY (collection_id) REFERENCES collections(id)
      )
    ''');

    // Indices for fast lookups
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hadiths_collection ON hadiths(collection_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hadiths_chapter ON hadiths(collection_id, chapter_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_chapters_collection ON chapters(collection_id)');

    // FTS5 virtual table for full-text search.
    // arabic_norm is the de-diacritized Arabic text (see _importBook), so
    // searches work whether or not the user types diacritics.
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS hadiths_fts USING fts5(
        arabic_norm, 
        english_text, 
        english_narrator,
        content='hadiths',
        content_rowid='rowid'
      )
    ''');
  }

  // ═══════════════════════════════════════════════════════════════════
  // IMPORT
  // ═══════════════════════════════════════════════════════════════════

  /// Import progress for the one-time first-launch build (0.0 → 1.0).
  static final ValueNotifier<double> importProgress = ValueNotifier(0);

  /// Whether the database file already existed (import skipped on launch).
  static bool _wasCached = false;
  static bool get isDbCached => _wasCached;

  static Future<void> _importAllBooks(Database db) {
    final all = [..._nineBooks, ..._otherBooks.map((b) => b['id']!)];
    return _importBooks(db, all);
  }

  /// Imports the given books (by id) into [db], updating import progress.
  static Future<void> _importBooks(Database db, List<String> bookIds) async {
    final totalBooks = bookIds.length;
    var completed = 0;

    for (final bookId in bookIds) {
      final book = _otherBooks.where((b) => b['id'] == bookId).firstOrNull;
      final path = book != null
          ? 'assets/hadith/by_book/${book['path']}'
          : 'assets/hadith/by_book/the_9_books/$bookId.json';
      await _importBook(db, bookId, path);
      completed++;
      importProgress.value = totalBooks == 0 ? 1 : completed / totalBooks;
    }

    // Rebuild the FTS5 index from the content table. External-content FTS
    // tables must be rebuilt after the content rows are inserted, otherwise
    // the rowids in the index do not match the content table and search
    // silently returns nothing.
    await _rebuildFts(db);
    importProgress.value = 1.0;
  }

  /// Rebuilds the `hadiths_fts` external-content index so its rowids align
  /// with the `hadiths` content table.
  static Future<void> _rebuildFts(Database db) async {
    try {
      await db.execute("INSERT INTO hadiths_fts(hadiths_fts) VALUES('rebuild')");
      debugPrint('✅ FTS index rebuilt.');
    } on Exception catch (e) {
      debugPrint('❌ FTS rebuild failed: $e');
    }
  }

  static Future<void> _importBook(Database db, String bookId, String assetPath) async {
    try {
      debugPrint('📖 Importing $bookId...');
      final jsonString = await rootBundle.loadString(assetPath);
      final json = Map<String, dynamic>.from(jsonDecode(jsonString) as Map);

      // --- Collection metadata ---
      final meta = json['metadata'] as Map<String, dynamic>;
      final arabicMeta = meta['arabic'] as Map<String, dynamic>? ?? {};
      final englishMeta = meta['english'] as Map<String, dynamic>? ?? {};
      final hadithsList = (json['hadiths'] as List?) ?? [];

      await db.insert('collections', {
        'id': bookId,
        'title_arabic': arabicMeta['title'] ?? bookId,
        'title_english': englishMeta['title'] ?? bookId,
        'author_arabic': arabicMeta['author'] ?? '',
        'author_english': englishMeta['author'] ?? '',
        'introduction': arabicMeta['introduction'] ?? '',
        'hadith_count': hadithsList.length,
      }, conflictAlgorithm: ConflictAlgorithm.replace,);

      // --- Chapters ---
      final chaptersList = (json['chapters'] as List?) ?? [];
      final chapterBatch = db.batch();
      for (final c in chaptersList) {
        chapterBatch.insert('chapters', {
          'id': (c as Map)['id'],
          'collection_id': bookId,
          'title_arabic': c['arabic'] ?? '',
          'title_english': c['english'] ?? '',
        }, conflictAlgorithm: ConflictAlgorithm.replace,);
      }
      await chapterBatch.commit(noResult: true);

      // --- Hadiths ---
      // Process in batches of 500 to avoid memory spikes
      const batchSize = 500;
      for (var i = 0; i < hadithsList.length; i += batchSize) {
        final end = (i + batchSize > hadithsList.length) ? hadithsList.length : i + batchSize;
        final batch = db.batch();

        for (var j = i; j < end; j++) {
          final h = hadithsList[j] as Map<String, dynamic>;
          final engMap = h['english'] as Map<String, dynamic>? ?? {};

          batch.insert('hadiths', {
            'id': h['id'] ?? j,
            'id_in_book': h['idInBook'] ?? h['id'] ?? j,
            'collection_id': bookId,
            'chapter_id': h['chapterId'] ?? 0,
            'arabic': h['arabic'] ?? '',
            'arabic_norm': normalizeForSearch((h['arabic'] ?? '') as String),
            'english_narrator': engMap['narrator'] ?? '',
            'english_text': engMap['text'] ?? '',
          }, conflictAlgorithm: ConflictAlgorithm.replace,);
        }

        await batch.commit(noResult: true);
      }

      debugPrint('  ✅ $bookId: ${hadithsList.length} hadiths imported.');
    } on Exception catch (e) {
      debugPrint('  ❌ Error importing $bookId: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUERY API
  // ═══════════════════════════════════════════════════════════════════

  /// Get all collections metadata
  static Future<List<Map<String, dynamic>>> getCollections() async {
    final db = await database;
    return db.query('collections', orderBy: 'hadith_count DESC');
  }

  /// Get chapters for a specific collection
  static Future<List<Map<String, dynamic>>> getChapters(String collectionId) async {
    final db = await database;
    return db.query(
      'chapters',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      orderBy: 'id ASC',
    );
  }

  /// Get paginated hadiths from a collection
  static Future<List<Map<String, dynamic>>> getHadiths({
    required String collectionId,
    int? chapterId,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    var where = 'collection_id = ?';
    final args = <dynamic>[collectionId];

    if (chapterId != null) {
      where += ' AND chapter_id = ?';
      args.add(chapterId);
    }

    return db.query(
      'hadiths',
      where: where,
      whereArgs: args,
      orderBy: 'id_in_book ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// Get a single hadith
  static Future<Map<String, dynamic>?> getHadithById(String collectionId, int hadithId) async {
    final db = await database;
    final results = await db.query(
      'hadiths',
      where: 'collection_id = ? AND id = ?',
      whereArgs: [collectionId, hadithId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Count hadiths per chapter (for display)
  static Future<Map<int, int>> getChapterHadithCounts(String collectionId) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT chapter_id, COUNT(*) as cnt FROM hadiths WHERE collection_id = ? GROUP BY chapter_id',
      [collectionId],
    );
    return {for (final r in results) r['chapter_id']! as int: r['cnt']! as int};
  }

  /// Full-text search across the entire corpus.
  ///
  /// [db] is for tests (a subset database via [openWithBooks]); production
  /// callers use the singleton [database].
  static Future<List<Map<String, dynamic>>> search(
    String query, {
    String? collectionId,
    int limit = 50,
    Database? db,
  }) async {
    final database = db ?? await HadithDatabase.database;

    if (query.trim().isEmpty) return [];

    // Use FTS5 for fast matching
    try {
      String sql;
      List<dynamic> args;

      if (collectionId != null) {
        sql = '''
          SELECT h.* FROM hadiths h
          INNER JOIN hadiths_fts fts ON h.rowid = fts.rowid
          WHERE hadiths_fts MATCH ? AND h.collection_id = ?
          LIMIT ?
        ''';
        args = ['"$query"', collectionId, limit];
      } else {
        sql = '''
          SELECT h.* FROM hadiths h
          INNER JOIN hadiths_fts fts ON h.rowid = fts.rowid
          WHERE hadiths_fts MATCH ?
          LIMIT ?
        ''';
        args = ['"$query"', limit];
      }

      final results = await database.rawQuery(sql, args);
      if (results.isNotEmpty) return results;

      // FTS found nothing (e.g. an unusual tokenization) → fall through to LIKE.
    } on Exception catch (_) {
      // Invalid FTS syntax (special characters) → fall through to LIKE.
    }

    // Fallback: normalized LIKE search against the de-diacritized text (the
    // raw arabic column keeps tashkeel, so a plain LIKE could never match a
    // user's un-diacritized query).
    final normalizedQuery = normalizeForSearch(query);
    var where =
        '(arabic_norm LIKE ? OR english_text LIKE ? OR english_narrator LIKE ?)';
    final args = <dynamic>['%$normalizedQuery%', '%$normalizedQuery%', '%$normalizedQuery%'];

    if (collectionId != null) {
      where += ' AND collection_id = ?';
      args.add(collectionId);
    }

    return database.query('hadiths', where: where, whereArgs: args, limit: limit);
  }

  /// Strips characters that are useless for LIKE matching (diacritics, hamza
  /// variants, tatweel) and collapses whitespace, so searches still hit even
  /// when the user omits diacritics.
  static String normalizeForSearch(String input) {
    const diacritics =
        '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653\u0654\u0655\u0656';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      var ch = String.fromCharCode(rune);
      if (diacritics.contains(ch)) continue;
      if (ch == 'ٱ') ch = 'ا'; // alef-wasla
      if (ch == ' ') {
        if (buffer.isEmpty || buffer.toString().endsWith(' ')) continue;
        buffer.write(' ');
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString().trim();
  }

  /// Search by narrator name
  static Future<List<Map<String, dynamic>>> searchByNarrator(String narrator, {int limit = 50}) async {
    final db = await database;
    return db.query(
      'hadiths',
      where: 'english_narrator LIKE ?',
      whereArgs: ['%$narrator%'],
      limit: limit,
      orderBy: 'collection_id, id_in_book',
    );
  }

  /// Get total hadith count
  static Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM hadiths');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get a random hadith (for "Hadith of the Day")
  static Future<Map<String, dynamic>?> getRandomHadith() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT * FROM hadiths ORDER BY RANDOM() LIMIT 1',
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Close the database
  static Future<void> close() async {
    final future = _dbFuture;
    _dbFuture = null;
    if (future != null) {
      await future;
      await (await future).close();
    }
  }
}
