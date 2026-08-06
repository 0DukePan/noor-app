import '../entities/search_result.dart';

abstract class SearchRepository {
  Future<void> initializeIndex();
  Future<List<SearchResult>> search(String query);
}
