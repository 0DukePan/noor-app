import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/data_sources/search_local_data_source.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';

final searchLocalDataSourceProvider = Provider<SearchLocalDataSource>((ref) {
  return SearchLocalDataSource();
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(ref.watch(searchLocalDataSourceProvider));
});

final searchResultsProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<SearchResult>>>((ref) {
  return SearchNotifier(ref.watch(searchRepositoryProvider));
});

class SearchNotifier extends StateNotifier<AsyncValue<List<SearchResult>>> {
  final SearchRepository _repository;

  SearchNotifier(this._repository) : super(const AsyncValue.data([])) {
    _init();
  }

  Future<void> _init() async {
    // Background init
    await _repository.initializeIndex();
  }

  Future<void> search(String query) async {
    if (query.length < 2) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final results = await _repository.search(query);
      state = AsyncValue.data(results);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
