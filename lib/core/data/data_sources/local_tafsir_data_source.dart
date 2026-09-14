import 'package:flutter/foundation.dart';
import '../../domain/entities/tafsir.dart';
import 'tafsir_database.dart';

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

  /// Loads a surah's tafsir with one indexed query against the prebuilt
  /// `tafsir.db` (see `tool/build_tafsir_db.dart`).
  ///
  /// Unknown book IDs fall back to Muyassar's data under the requested label
  /// — the long-standing contract the fallback test pins. Row order is the
  /// corpus order, so the last-wins overwrite behavior for duplicate ayah
  /// keys matches the old JSON loader exactly.
  Future<void> _loadSurahTafsir(int surahId, String bookId) async {
    try {
      final dbSource = switch (bookId) {
        'muyassar' => 'muyassar',
        'saadi' => 'saadi',
        'tabari' => 'tabari',
        // DB keys use the enum name; the book id uses snake_case.
        'ibn_kathir' => 'ibnKathir',
        _ => 'muyassar',
      };
      final rows = await TafsirDatabase.querySurahEntries(
        source: dbSource,
        surah: surahId,
      );
      final tafsirMap = <int, TafsirVerse>{};
      for (final row in rows) {
        final ayah = row['ayah'];
        final text = row['text'];
        if (ayah is! int || text is! String) continue;
        tafsirMap[ayah] = TafsirVerse(
          surahId: surahId,
          verseId: ayah,
          text: text,
          source: bookId,
        );
      }
      _cache['$bookId-$surahId'] = tafsirMap;
    } on Exception catch (e) {
      debugPrint('Error loading tafsir ($bookId) for surah $surahId: $e');
      _cache['$bookId-$surahId'] = {};
    }
  }

  /// Clears cache to free memory if needed (e.g. when switching surahs excessively)
  void clearCache() {
    _cache.clear();
  }
}
