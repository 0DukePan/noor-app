import '../../domain/entities/hadith.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../data_sources/local_hadith_data_source.dart';

class HadithRepositoryImpl implements HadithRepository {
  final LocalHadithDataSource _dataSource;

  HadithRepositoryImpl(this._dataSource);

  @override
  Future<List<HadithCollection>> getCollections() async {
    return _dataSource.getCollections();
  }

  @override
  Future<HadithBook> getBook(String bookId) async {
    return _dataSource.loadBook(bookId);
  }

  @override
  Future<List<Hadith>> getHadiths(String bookId, {required int page, required int limit}) async {
    return _dataSource.getHadithsPage(bookId: bookId, page: page, limit: limit);
  }

  @override
  Future<List<Hadith>> searchHadiths(String query, String bookId) async {
    return _dataSource.searchHadiths(query, bookId: bookId);
  }

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async {
    return _dataSource.getChapters(bookId);
  }
}
