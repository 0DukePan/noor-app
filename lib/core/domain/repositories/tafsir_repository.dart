import '../entities/tafsir.dart';

abstract class TafsirRepository {
  Future<TafsirVerse?> getTafsir(
    int surahId,
    int verseId, {
    String source = 'muyassar',
  });
  
  Future<List<String>> getAvailableSources();
}
