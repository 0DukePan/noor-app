import 'dart:convert';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../data_sources/search_local_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {

  SearchRepositoryImpl(this._dataSource);
  final SearchLocalDataSource _dataSource;

  @override
  Future<void> initializeIndex() async {
    // Indexes Quran, hadith, and adhkar once; persisted in noor_search.db.
    await _dataSource.ensureIndexed([], []);
  }

  @override
  Future<List<SearchResult>> search(String query) async {
    final results = await _dataSource.search(query);
    
    return results.map((row) {
      final ref = jsonDecode(row['reference'] as String) as Map<String, dynamic>;
      // We can use the original text from reference if available, or the indexed text
      final displayText = ref['original'] as String? ?? row['text'] as String;
      
      return SearchResult(
        text: displayText,
        source: row['source'] as String,
        metadata: Map<String, dynamic>.from(ref as Map),
      );
    }).toList();
  }
}
