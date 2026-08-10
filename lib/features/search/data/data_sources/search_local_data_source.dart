import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for compute

import '../../../../core/utils/arabic_text.dart';
import '../../../../core/data/data_sources/hadith_database.dart';

class SearchLocalDataSource {
  static const String _dbName = 'noor_search.db';
  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create FTS5 virtual table
        // content: text to search
        // source: 'quran' or 'hadith' or 'adhkar'
        // reference: JSON string (e.g. {surah: 1, verse: 1} or {book: 'bukhari', id: 1})
        await db.execute('''
          CREATE VIRTUAL TABLE search_index USING fts5(
            text, 
            source UNINDEXED, 
            reference UNINDEXED, 
            tokenize = "unicode61 remove_diacritics 1"
          )
        ''');
      },
    );
  }

  /// Deletes the search index so it is rebuilt lazily on the next search
  /// (used by the "clear cache" action).
  static Future<void> clearIndex() async {
    final dbPath = await getDatabasesPath();
    final file = File(join(dbPath, _dbName));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> ensureIndexed(
    List<String> quranPaths,
    List<String> hadithPaths, {
    Database? hadithDb,
  }) async {
    if (_db == null) await init();

    // Index each source independently so installs that already have a
    // Quran-only index also get hadith and adhkar entries.
    Future<bool> hasSource(String source) async {
      final count = Sqflite.firstIntValue(await _db!.rawQuery(
        "SELECT COUNT(*) FROM search_index WHERE source = ?",
        [source],
      ),);
      return (count ?? 0) > 0;
    }

    if (!await hasSource('quran')) {
      await _indexQuran(quranPaths);
    }
    if (!await hasSource('hadith')) {
      await _indexHadith(hadithDb);
    }
    if (!await hasSource('adhkar')) {
      await _indexAdhkar();
    }
  }

  Future<void> _indexQuran(List<String> paths) async {
    // We assume paths contain the full Quran JSON path
    // Parsing needs to happen in Isolate
    final quranJson = await rootBundle.loadString('assets/quran/quran_uthmani.json');
    
    // Process in Isolate
    final records = await compute(_parseQuranForIndex, quranJson);
    
    await _insertRecords(records);
  }

  /// Index all hadiths from the SQLite hadith corpus (same data the reader
  /// uses), so the unified search finds hadith too.
  Future<void> _indexHadith([Database? overrideDb]) async {
    final db = overrideDb ?? await HadithDatabase.database;
    final rows = await db.query('hadiths', columns: [
      'id',
      'collection_id',
      'arabic',
    ],);

    final records = <Map<String, dynamic>>[];
    for (final row in rows) {
      final text = row['arabic'] as String? ?? '';
      if (text.trim().isEmpty) continue;
      records.add({
        'text': normalizeArabic(text),
        'source': 'hadith',
        'reference': jsonEncode({
          'book': row['collection_id'],
          'id': row['id'],
        }),
      });
    }

    await _insertRecords(records);
  }

  /// Index the bundled adhkar collections.
  Future<void> _indexAdhkar() async {
    const files = [
      'assets/adhkar/morning.json',
      'assets/adhkar/evening.json',
      'assets/adhkar/after_prayer.json',
    ];

    final records = <Map<String, dynamic>>[];
    for (final path in files) {
      try {
        final json = jsonDecode(await rootBundle.loadString(path))
            as Map<String, dynamic>;
        final content = json['content'] as List? ?? [];
        for (final item in content) {
          final text = (item as Map)['zekr'] as String? ?? '';
          if (text.trim().isEmpty) continue;
          records.add({
            'text': normalizeArabic(text),
            'source': 'adhkar',
            'reference': jsonEncode({'file': path}),
          });
        }
      } catch (e) {
        debugPrint('Adhkar indexing failed for $path: $e');
      }
    }

    await _insertRecords(records);
  }

  Future<void> _insertRecords(List<Map<String, dynamic>> records) async {
    const batchSize = 500;
    for (int i = 0; i < records.length; i += batchSize) {
      final end = (i + batchSize > records.length) ? records.length : i + batchSize;
      final batch = _db!.batch();
      for (int j = i; j < end; j++) {
        batch.insert('search_index', records[j]);
      }
      await batch.commit(noResult: true);
    }
  }
  
  static List<Map<String, dynamic>> _parseQuranForIndex(String jsonStr) {
    final Map<String, dynamic> data = jsonDecode(jsonStr);
    final List<Map<String, dynamic>> records = [];
    
    // Schema: "1": [ { "verse": 1, "text": "..." } ]
    data.forEach((surahNum, verses) {
      final surahId = int.parse(surahNum);
      for (final v in (verses as List)) {
         final verseId = v['verse'] as int;
         final text = v['text'] as String;
         final simpleText = normalizeArabic(text); // Remove diacritics for better search
         
         records.add({
           'text': simpleText,
           'source': 'quran',
           'reference': jsonEncode({'surah': surahId, 'verse': verseId, 'original': text}),
         });
      }
    });
    return records;
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    if (_db == null) await init();
    
    // Normalize query
    final simplified = normalizeArabic(query);

    try {
      // Quote the phrase so FTS special characters cannot break MATCH.
      final safeQuery = simplified.replaceAll('"', ' ');
      return await _db!.rawQuery('''
        SELECT * FROM search_index 
        WHERE text MATCH ? 
        ORDER BY rank 
        LIMIT 50
      ''', ['"$safeQuery"'],);
    } catch (e) {
      // Fallback: substring search (robust against odd tokenization).
      return _db!.rawQuery('''
        SELECT * FROM search_index 
        WHERE text LIKE ? 
        LIMIT 50
      ''', ['%$simplified%'],);
    }
  }
}
