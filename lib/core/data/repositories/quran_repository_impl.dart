import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../data_sources/local_quran_data_source.dart';

class QuranRepositoryImpl implements QuranRepository {
  final LocalQuranDataSource _dataSource;
  final Box _prefsBox; // Using Hive for preferences

  QuranRepositoryImpl(this._dataSource, this._prefsBox);

  @override
  Future<List<Surah>> getAllSurahs() async {
    return _dataSource.getAllSurahs();
  }

  @override
  Future<Surah> getSurah(int surahNumber) async {
    return _dataSource.getSurah(surahNumber);
  }

  @override
  Future<List<Verse>> searchVerses(String query) async {
    // Basic search implementation: Scan all provided Surah data
    // Optimally, this needs an inverted index or full text search in SQLite.
    // For now, we search in the currently loaded Surah if any, or warn strict limitation.
    // Or we scan the full text map if loaded.

    // Note: Implementing full quran search efficiently without SQLite FTS is hard.
    // With `LocalQuranDataSource` having `_fullQuranMap`, we CAN iterate it.
    
    // For this phase, we might return empty or implement a brute-force on fullTextMap
    // if access is exposed.
    // Let's defer full global search to Phase 6 (Bonus).
    return [];
  }

  @override
  Future<void> saveLastReadPosition(int surah, int verse) async {
    await _prefsBox.put('last_surah', surah);
    await _prefsBox.put('last_verse', verse);
  }

  @override
  Future<Map<String, int>?> getLastReadPosition() async {
    final surah = _prefsBox.get('last_surah');
    final verse = _prefsBox.get('last_verse');

    if (surah != null && verse != null) {
      return {'surah': surah, 'verse': verse};
    }
    return null;
  }
}
