import '../../domain/entities/tafsir.dart';
import '../../domain/repositories/tafsir_repository.dart';
import '../data_sources/local_tafsir_data_source.dart';

class TafsirRepositoryImpl implements TafsirRepository {

  TafsirRepositoryImpl(this._dataSource);
  final LocalTafsirDataSource _dataSource;

  @override
  Future<TafsirVerse?> getTafsir(
    int surahId,
    int verseId, {
    String source = 'muyassar',
  }) async {
    return _dataSource.getTafsir(surahId: surahId, verseId: verseId, bookId: source);
  }

  @override
  Future<List<String>> getAvailableSources() async {
    return TafsirBook.values.map((e) => e.id).toList();
  }
}
