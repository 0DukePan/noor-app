
import '../../domain/entities/quran_entities.dart';
import 'quran_datasources.dart';

/// Stub implementation for Remote Data Source
class RemoteQuranDataSourceImpl implements QuranRemoteDataSource {
  @override
  Future<List<SurahModel>> fetchAllSurahs() async {
    // Offline-first: return empty list as graceful fallback
    return [];
  }

  @override
  Future<TafsirModel> fetchTafsir(int surahNumber, int verseNumber, String source) async {
    // Offline-first: return a placeholder tafsir indicating unavailability
    return TafsirModel(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      briefText: 'التفسير غير متوفر بدون اتصال بالإنترنت',
      source: source,
      author: '',
    );
  }

  @override
  Future<RevelationCauseModel?> fetchRevelationCause(int surahNumber, int verseNumber) async {
    // Offline-first: return null as graceful fallback
    return null;
  }

  @override
  Future<void> syncQuranData() async {
    // No-op in offline mode
  }
}
