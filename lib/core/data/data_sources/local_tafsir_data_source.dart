import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/entities/tafsir.dart';
import '../../utils/isolate_parser.dart';

class LocalTafsirDataSource {
  // Cache structure: Map<"bookId-surahId", Map<verseId, TafsirVerse>>
  final Map<String, Map<int, TafsirVerse>> _cache = {};

  /// Gets tafsir for a specific verse from a specific book.
  Future<TafsirVerse?> getTafsir({
    required int surahId,
    required int verseId,
    String bookId = 'muyassar',
  }) async {
    final cacheKey = '$bookId-$surahId';

    if (!_cache.containsKey(cacheKey)) {
      await _loadSurahTafsir(surahId, bookId);
    }

    return _cache[cacheKey]?[verseId];
  }

  /// Loads and parses the JSON file for a specific surah and tafsir book.
  Future<void> _loadSurahTafsir(int surahId, String bookId) async {
    try {
      final book = TafsirBook.values.firstWhere(
        (b) => b.id == bookId,
        orElse: () => TafsirBook.muyassar,
      );

      // Path construction: assets/tafsir/[id]/[folderName]/[surahId].json
      final path = 'assets/tafsir/${book.id}/${book.folderName}/$surahId.json';

      final tafsirMap = await IsolateParser.parseInBackground(
        assetPath: path,
        parser: (json) => _parseTafsirJson(json, surahId, bookId),
      );

      _cache['$bookId-$surahId'] = tafsirMap;
    } catch (e) {
      debugPrint('Error loading tafsir ($bookId) for surah $surahId: $e');
      _cache['$bookId-$surahId'] = {};
    }
  }

  static Map<int, TafsirVerse> _parseTafsirJson(String jsonString, int surahId, String bookId) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final Map<int, TafsirVerse> result = {};

    if (json.containsKey('ayahs')) {
      final ayahs = json['ayahs'] as List;
      for (var item in ayahs) {
        final verseId = item['ayah'] as int;
        final text = item['text'] as String;
        
        result[verseId] = TafsirVerse(
          surahId: surahId,
          verseId: verseId,
          text: text,
          source: bookId,
        );
      }
    }
    
    return result;
  }
  
  /// Clears cache to free memory if needed (e.g. when switching surahs excessively)
  void clearCache() {
    _cache.clear();
  }
}

