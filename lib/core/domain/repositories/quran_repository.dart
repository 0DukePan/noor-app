import '../entities/surah.dart';

abstract class QuranRepository {
  Future<List<Surah>> getAllSurahs();
  Future<Surah> getSurah(int surahNumber);
  Future<List<Verse>> searchVerses(String query);
  
  // Last read functionality
  Future<void> saveLastReadPosition(int surah, int verse);
  Future<Map<String, int>?> getLastReadPosition();
}
