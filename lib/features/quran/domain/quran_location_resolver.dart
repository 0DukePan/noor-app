/// Shared resolver backed by the approved verse-count table and an
/// ayah-to-page index (QUR-08, Phase 3.3).
///
/// Screens never hand-build partial Qur'an URLs; they ask the resolver to
/// validate a location and derive the Mushaf page.
library;

import '../../../core/utils/verse_counts.dart';
import 'entities/quran_location.dart';

class QuranLocationResolver {
  QuranLocationResolver({Map<String, int>? ayahToPageIndex})
    : _ayahToPageIndex = ayahToPageIndex ?? const {};

  /// Immutable (surah, ayah) -> page index built once at page-map load.
  final Map<String, int> _ayahToPageIndex;

  static String _key(int surah, int ayah) => '$surah:$ayah';

  /// Build the index from a page map of `page -> [{surah, ayah}]`.
  static Map<String, int> buildIndex(
    Map<String, List<Map<String, int>>> pageMap,
  ) {
    final index = <String, int>{};
    pageMap.forEach((pageKey, entries) {
      final page = int.tryParse(pageKey);
      if (page == null || !isValidPage(page)) return;
      for (final e in entries) {
        final surah = e['surah'];
        final ayah = e['ayah'];
        if (surah == null || ayah == null) continue;
        index.putIfAbsent(_key(surah, ayah), () => page);
      }
    });
    return Map.unmodifiable(index);
  }

  /// Page for (surah, ayah), or null when unknown.
  int? pageForAyah(int surah, int ayah) => _ayahToPageIndex[_key(surah, ayah)];

  /// Validate and attach the derived page when the caller did not supply one.
  QuranLocation? resolve({required int surah, required int ayah, int? page}) {
    if (!isValidAyah(surah, ayah)) return null;
    if (page != null && !isValidPage(page)) return null;
    return QuranLocation(
      surah: surah,
      ayah: ayah,
      page: page ?? pageForAyah(surah, ayah),
    );
  }

  Map<String, int> get index => _ayahToPageIndex;
}
