import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/arabic_text.dart';
import '../../../../core/utils/isolate_parser.dart';
import '../../domain/entities/mushaf.dart';
import 'quran_datasources.dart'; // Abstract class and Models

class LocalQuranDataSourceImpl implements QuranLocalDataSource {
  // In-memory cache
  final Map<int, SurahModel> _surahCache = {};

  static Map<String, dynamic>? _fullQuranMap;
  static List<SurahModel>? _surahMetadata;

  @override
  Future<List<SurahModel>> getAllSurahs() async {
    if (_surahMetadata == null) {
      await _loadMetadata();
    }
    return _surahMetadata!;
  }

  Future<void> _loadMetadata() async {
    final jsonList = await IsolateParser.parseInBackground(
      assetPath: 'assets/quran/surahs.json',
      parser: (json) =>
          List<Map<String, dynamic>>.from(jsonDecode(json) as List),
    );

    _surahMetadata = jsonList.map(SurahModel.fromJson).toList();
  }

  @override
  Future<SurahModel> getSurahWithVerses(int surahNumber) async {
    if (_surahCache.containsKey(surahNumber)) {
      return _surahCache[surahNumber]!;
    }

    if (_surahMetadata == null) {
      await _loadMetadata();
    }

    _fullQuranMap ??= await IsolateParser.parseInBackground(
      assetPath: 'assets/quran/quran_uthmani.json',
      parser: (json) => jsonDecode(json) as Map<String, dynamic>,
    );

    final surah = await compute(
      _buildSurahObject,
      _BuildSurahArgs(
        surahNumber: surahNumber,
        fullText: _fullQuranMap!,
        metadata: _surahMetadata!,
      ),
    );

    _surahCache[surahNumber] = surah;
    return surah;
  }

  static Map<String, dynamic>? _pagesMap;

  /// Decoded deterministic token asset (Phase 1 reviewed path).
  static Map<String, dynamic>? _tokensMap;

  /// Parsed page-verse cache with a small neighbour prefetch window
  /// (Phase 2.2): the requested page plus its immediate neighbours are
  /// built and cached; the window is capped so memory stays bounded across
  /// pages 1..604.
  static final Map<int, List<VerseModel>> _pageVerseCache = {};
  static const int _prefetchRadius = 1;
  static const int _pageCacheCap = 25;

  /// Immutable (surah, ayah) -> page index (QUR-08): built once at page-map
  /// load time instead of scanning every page on each lookup.
  static Map<String, int>? _ayahToPageIndex;

  static void _ensureIndexLocked() {
    if (_ayahToPageIndex != null || _pagesMap == null) return;
    final index = <String, int>{};
    _pagesMap!.forEach((pageKey, value) {
      final page = int.tryParse(pageKey);
      if (page == null) return;
      for (final v in (value as List? ?? [])) {
        final map = v as Map;
        index.putIfAbsent('${map['surah']}:${map['ayah']}', () => page);
      }
    });
    _ayahToPageIndex = Map.unmodifiable(index);
  }

  @override
  Future<List<VerseModel>> getVersesByPage(int pageNumber) async {
    // QUR-04: out-of-range pages are a typed empty, never a crash upstream.
    if (pageNumber < 1 || pageNumber > 604) return [];

    // Preferred reviewed path (Phase 1): the deterministic token asset.
    // Content-bearing tokens concatenate to the approved display text, so
    // verses built here are identical in content to the legacy page map.
    try {
      _tokensMap ??= await IsolateParser.parseInBackground(
        assetPath: 'assets/quran/mushaf_tokens.json',
        parser: (json) => jsonDecode(json) as Map<String, dynamic>,
      );
      _fillPageCache(pageNumber);
      final fromTokens = _pageVerseCache[pageNumber];
      if (fromTokens != null && fromTokens.isNotEmpty) return fromTokens;
    } on Object {
      // Fall through to the legacy page map (asset missing in older
      // bundles, test doubles, or a corrupt token file).
    }

    _pagesMap ??= await IsolateParser.parseInBackground(
      assetPath: 'assets/quran/quran_pages.json',
      parser: (json) => jsonDecode(json) as Map<String, dynamic>,
    );
    _ensureIndexLocked();

    final pageKey = pageNumber.toString();
    final versesRaw = _pagesMap![pageKey] as List?;
    if (versesRaw == null || versesRaw.isEmpty) return [];

    return versesRaw.map((v) {
      final map = v as Map<String, dynamic>;
      return VerseModel(
        number: 0,
        numberInSurah: map['ayah'] as int,
        textUthmani: map['text'] as String,
        page: pageNumber,
        juz: map['juz'] as int? ?? 0,
        hizb: map['hizb'] as int? ?? 0,
        quarter: 0,
        surahNumber: map['surah'] as int? ?? 0,
        surahName: map['surah_name'] as String?,
      );
    }).toList();
  }

  /// Returns the mushaf page for a given (surah, ayah), or null if unknown.
  /// `quran_uthmani.json` has no page field, so this maps via quran_pages.json.
  /// Uses the immutable index (QUR-08) — no per-lookup full scan.
  Future<int?> getPageForAyah(int surah, int ayah) async {
    _pagesMap ??= await IsolateParser.parseInBackground(
      assetPath: 'assets/quran/quran_pages.json',
      parser: (json) => jsonDecode(json) as Map<String, dynamic>,
    );
    _ensureIndexLocked();
    final hit = _ayahToPageIndex?['$surah:$ayah'];
    if (hit != null) return hit;
    for (final entry in _pagesMap!.entries) {
      final verses = entry.value as List? ?? [];
      for (final v in verses) {
        final map = v as Map;
        if (map['surah'] == surah && map['ayah'] == ayah) {
          return int.tryParse(entry.key);
        }
      }
    }
    return null;
  }

  /// Builds verses from the deterministic token asset through the typed
  /// [MushafPageModel] (Phase 1 reviewed path + Phase 2 model). Fills the
  /// requested page plus its immediate neighbours (prefetch window), then
  /// trims the cache to its cap so memory stays bounded across pages 1..604.
  void _fillPageCache(int pageNumber) {
    final tokensDoc = _tokensMap;
    if (tokensDoc == null) return;
    final pages = tokensDoc['pages'] as Map<String, dynamic>?;
    if (pages == null) return;
    for (var page = pageNumber - _prefetchRadius;
        page <= pageNumber + _prefetchRadius;
        page++) {
      if (page < 1 || page > 604 || _pageVerseCache.containsKey(page)) {
        continue;
      }
      final raw = pages[page.toString()] as Map<String, dynamic>?;
      if (raw == null) continue;
      final model = MushafPageModel.fromJson(
        page.toString(),
        Map<String, dynamic>.from(raw),
      );
      _pageVerseCache[page] = model
          .verses()
          .map(
            (row) => VerseModel(
              number: 0,
              numberInSurah: row.ayah,
              textUthmani: row.text,
              page: page,
              juz: row.juz,
              hizb: row.hizb,
              quarter: 0,
              surahNumber: row.surah,
              surahName: row.surahName,
            ),
          )
          .toList();
    }
    while (_pageVerseCache.length > _pageCacheCap) {
      final evict = _pageVerseCache.keys.firstWhere(
        (page) => (page - pageNumber).abs() > _prefetchRadius,
        orElse: () => _pageVerseCache.keys.first,
      );
      _pageVerseCache.remove(evict);
    }
  }

  /// Test/contract hook: cached page numbers in the prefetch window.
  static List<int> debugCachedPages() =>
      _pageVerseCache.keys.toList()..sort();

  /// Test/contract hook: immutable snapshot of the ayah-to-page index.
  static Map<String, int>? debugAyahToPageIndex() => _ayahToPageIndex;

  @override
  Future<TafsirModel?> getTafsir(int surahNumber, int verseNumber) async {
    // Implementation for local tafsir
    // For now return null or implement if we have assets
    return null;
  }

  @override
  Future<RevelationCauseModel?> getRevelationCause(
    int surahNumber,
    int verseNumber,
  ) async {
    return null;
  }

  @override
  Future<List<VerseModel>> searchQuran(String query) async {
    if (query.trim().isEmpty) return [];

    _fullQuranMap ??= await IsolateParser.parseInBackground(
      assetPath: 'assets/quran/quran_uthmani.json',
      parser: (json) => jsonDecode(json) as Map<String, dynamic>,
    );

    // Normalize query for Arabic search (remove diacritics)
    final normalizedQuery = normalizeArabic(query);
    final results = <VerseModel>[];

    _fullQuranMap!.forEach((surahNum, verses) {
      for (final v in (verses as List)) {
        final map = v as Map;
        final text =
            map['text'] as String? ?? map['text_uthmani'] as String? ?? '';
        final normalizedText = normalizeArabic(text);
        if (normalizedText.contains(normalizedQuery)) {
          results.add(VerseModel.fromJson(Map<String, dynamic>.from(map)));
        }
      }
    });

    return results;
  }

  @override
  Future<void> cacheQuranData(List<SurahModel> surahs) async {
    // No-op for local json source
  }

  // --- Background Builder ---

  static SurahModel _buildSurahObject(_BuildSurahArgs args) {
    final meta = args.metadata.firstWhere((m) => m.number == args.surahNumber);
    final versesRaw = args.fullText[args.surahNumber.toString()] as List;

    final verses = versesRaw
        .map((v) => VerseModel.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();

    // Reconstruct SurahModel with verses
    return SurahModel(
      number: meta.number,
      nameArabic: meta.nameArabic,
      nameEnglish: meta.nameEnglish,
      englishNameTranslation: meta.englishNameTranslation,
      nameTransliteration: meta.nameTransliteration,
      versesCount: meta.versesCount,
      revelationType: meta.revelationType,
      page: meta.page,
      verses: verses,
    );
  }
}

class _BuildSurahArgs {
  _BuildSurahArgs({
    required this.surahNumber,
    required this.fullText,
    required this.metadata,
  });
  final int surahNumber;
  final Map<String, dynamic> fullText;
  final List<SurahModel> metadata;
}
