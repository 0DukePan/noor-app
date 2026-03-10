import 'dart:convert';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../data_sources/search_local_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchLocalDataSource _dataSource;

  SearchRepositoryImpl(this._dataSource);

  @override
  Future<void> initializeIndex() async {
    // For now we only index Quran. Hadith can be added later as it's large.
    await _dataSource.ensureIndexed([], []);
  }

  @override
  Future<List<SearchResult>> search(String query) async {
    final results = await _dataSource.search(query);
    
    return results.map((row) {
      final ref = jsonDecode(row['reference'] as String);
      // We can use the original text from reference if available, or the indexed text
      final displayText = ref['original'] as String? ?? row['text'] as String;
      
      return SearchResult(
        text: displayText,
        source: row['source'] as String,
        metadata: ref,
      );
    }).toList();
  }
}
