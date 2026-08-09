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
  static const int _dbVersion = 1;
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
    } catch (e) {
      debugPrint('HadithDatabase warmUp failed: $e');
    }
  }

  static Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    _wasCached = await File(dbPath).exists();

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
        // Add future migrations here as _dbVersion is bumped.
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

    // FTS5 virtual table for full-text search
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS hadiths_fts USING fts5(
        arabic, 
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
  static final ValueNotifier<double> importProgress = ValueNotifier(0.0);

  /// Whether the database file already existed (import skipped on launch).
  static bool _wasCached = false;
  static bool get isDbCached => _wasCached;

  static Future<void> _importAllBooks(Database db) async {
    final totalBooks = _nineBooks.length + _otherBooks.length;
    var completed = 0;

    // Import the 9 major books
    for (final bookId in _nineBooks) {
      final path = 'assets/hadith/by_book/the_9_books/$bookId.json';
      await _importBook(db, bookId, path);
      completed++;
      importProgress.value = completed / totalBooks;
    }
    // Import forties and other books
    for (final book in _otherBooks) {
      final path = 'assets/hadith/by_book/${book['path']}';
      await _importBook(db, book['id']!, path);
      completed++;
      importProgress.value = completed / totalBooks;
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
    } catch (e) {
      debugPrint('❌ FTS rebuild failed: $e');
    }
  }

  static Future<void> _importBook(Database db, String bookId, String assetPath) async {
    try {
      debugPrint('📖 Importing $bookId...');
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> json = jsonDecode(jsonString);

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
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // --- Chapters ---
      final chaptersList = (json['chapters'] as List?) ?? [];
      final chapterBatch = db.batch();
      for (final c in chaptersList) {
        chapterBatch.insert('chapters', {
          'id': c['id'],
          'collection_id': bookId,
          'title_arabic': c['arabic'] ?? '',
          'title_english': c['english'] ?? '',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await chapterBatch.commit(noResult: true);

      // --- Hadiths ---
      // Process in batches of 500 to avoid memory spikes
      const batchSize = 500;
      for (int i = 0; i < hadithsList.length; i += batchSize) {
        final end = (i + batchSize > hadithsList.length) ? hadithsList.length : i + batchSize;
        final batch = db.batch();

        for (int j = i; j < end; j++) {
          final h = hadithsList[j] as Map<String, dynamic>;
          final engMap = h['english'] as Map<String, dynamic>? ?? {};

          batch.insert('hadiths', {
            'id': h['id'] ?? j,
            'id_in_book': h['idInBook'] ?? h['id'] ?? j,
            'collection_id': bookId,
            'chapter_id': h['chapterId'] ?? 0,
            'arabic': h['arabic'] ?? '',
            'english_narrator': engMap['narrator'] ?? '',
            'english_text': engMap['text'] ?? '',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        await batch.commit(noResult: true);
      }

      debugPrint('  ✅ $bookId: ${hadithsList.length} hadiths imported.');
    } catch (e) {
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
    String where = 'collection_id = ?';
    List<dynamic> args = [collectionId];

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
    return {for (final r in results) r['chapter_id'] as int: r['cnt'] as int};
  }

  /// Full-text search across the entire corpus
  static Future<List<Map<String, dynamic>>> search(String query, {String? collectionId, int limit = 50}) async {
    final db = await database;

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

      final results = await db.rawQuery(sql, args);
      if (results.isNotEmpty) return results;

      // FTS found nothing (e.g. an unusual tokenization) → fall through to LIKE.
    } catch (_) {
      // Invalid FTS syntax (special characters) → fall through to LIKE.
    }

    // Fallback: normalized LIKE search across Arabic and English text.
    final normalizedQuery = normalizeForSearch(query);
    String where = '(arabic LIKE ? OR english_text LIKE ? OR english_narrator LIKE ?)';
    List<dynamic> args = ['%$normalizedQuery%', '%$normalizedQuery%', '%$normalizedQuery%'];

    if (collectionId != null) {
      where += ' AND collection_id = ?';
      args.add(collectionId);
    }

    return db.query('hadiths', where: where, whereArgs: args, limit: limit);
  }

  /// Strips characters that are useless for LIKE matching (diacritics, hamza
  /// variants, tatweel) and collapses whitespace, so searches still hit even
  /// when the user omits diacritics.
  static String normalizeForSearch(String input) {
    const diacritics =
        '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653\u0654\u0655\u0656';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      if (diacritics.contains(ch)) continue;
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
