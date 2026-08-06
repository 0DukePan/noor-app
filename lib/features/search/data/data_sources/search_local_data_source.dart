import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // for compute

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
        // source: 'quran' or 'hadith'
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

  Future<void> ensureIndexed(List<String> quranPaths, List<String> hadithPaths) async {
    if (_db == null) await init();

    final count = Sqflite.firstIntValue(await _db!.rawQuery('SELECT COUNT(*) FROM search_index'));
    if (count != null && count > 0) return; // Already indexed

    // Indexing needed
    await _indexQuran(quranPaths);
    // await _indexHadith(hadithPaths); // Todo: Implement hadith indexing later to save time for now
  }

  Future<void> _indexQuran(List<String> paths) async {
    // We assume paths contain the full Quran JSON path
    // Parsing needs to happen in Isolate
    final quranJson = await rootBundle.loadString('assets/quran/quran_uthmani.json');
    
    // Process in Isolate
    final records = await compute(_parseQuranForIndex, quranJson);
    
    final batch = _db!.batch();
    for (final record in records) {
      batch.insert('search_index', record);
    }
    await batch.commit(noResult: true);
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
         final simpleText = _simplifyArabic(text); // Remove diacritics for better search
         
         records.add({
           'text': simpleText,
           'source': 'quran',
           'reference': jsonEncode({'surah': surahId, 'verse': verseId, 'original': text}),
         });
      }
    });
    return records;
  }
  
  static String _simplifyArabic(String text) {
     // Basic normalization
     return text
         .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'), '') // Tashkeel
         .replaceAll('أ', 'ا')
         .replaceAll('إ', 'ا')
         .replaceAll('آ', 'ا')
         .replaceAll('ة', 'ه')
         .replaceAll('ى', 'ي');
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    if (_db == null) await init();
    
    // Normalize query
    final simplified = _simplifyArabic(query);
    
    // Match query
    // We use NEAR() or just match
    return await _db!.rawQuery('''
      SELECT * FROM search_index 
      WHERE text MATCH ? 
      ORDER BY rank 
      LIMIT 50
    ''', [simplified]);
  }
}
