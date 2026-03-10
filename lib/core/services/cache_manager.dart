import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import 'api_fetcher_service.dart';
import 'hive_service.dart';
import 'offline_data_service.dart';

/// مدير التخزين المؤقت - Cache Manager
/// Implements offline-first with delta updates
class CacheManager {
  final ApiFetcherService _apiFetcher;
  
  static const _cacheMetaBox = 'cache_meta';
  static const _defaultTtl = Duration(hours: 24);

  CacheManager({required ApiFetcherService apiFetcher}) : _apiFetcher = apiFetcher;

  /// Initialize cache meta box
  static Future<void> initialize() async {
    await Hive.openBox<Map>(_cacheMetaBox);
  }

  Box<Map> get _metaBox => Hive.box<Map>(_cacheMetaBox);

  // ═══════════════════════════════════════════════════════════════════════════
  // QURAN CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all surahs (offline-first via OfflineDataService)
  Future<List<Map<String, dynamic>>> getSurahs({bool forceRefresh = false}) async {
    const cacheKey = 'surahs';

    // PRIORITY 1: OfflineDataService (bundled assets)
    try {
      final offlineSurahs = await OfflineDataService.getSurahs();
      if (offlineSurahs.isNotEmpty) {
        _updateCacheMeta(cacheKey);
        return offlineSurahs;
      }
    } catch (_) {}

    // PRIORITY 2: Return cached from HiveService if valid and not forcing refresh
    if (!forceRefresh && !_isStale(cacheKey)) {
      final cached = HiveService.getCachedSurahs();
      if (cached.isNotEmpty) return cached;
    }

    // PRIORITY 3: Fetch from API and cache
    try {
      final surahs = await _apiFetcher.fetchAllSurahs();
      await HiveService.cacheSurahs(surahs);
      _updateCacheMeta(cacheKey);
      return surahs;
    } catch (e) {
      // Return stale cache on error
      return HiveService.getCachedSurahs();
    }
  }

  /// Get surah with verses (offline-first via OfflineDataService)
  Future<Map<String, dynamic>?> getSurahWithVerses(
    int surahNumber, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'surah_$surahNumber';

    // PRIORITY 1: OfflineDataService (bundled assets)
    try {
      final offlineSurah = await OfflineDataService.getSurah(surahNumber);
      if (offlineSurah != null && offlineSurah.isNotEmpty) {
        _updateCacheMeta(cacheKey);
        return offlineSurah;
      }
    } catch (_) {}

    // PRIORITY 2: HiveService cache
    if (!forceRefresh && !_isStale(cacheKey)) {
      final cached = HiveService.getCachedVerses(surahNumber);
      if (cached != null) {
        return {'verses': cached};
      }
    }

    // PRIORITY 3: Fetch from API
    try {
      final surah = await _apiFetcher.fetchSurah(surahNumber);
      final verses = List<Map<String, dynamic>>.from(surah['ayahs'] ?? []);
      await HiveService.cacheVerses(surahNumber, verses);
      _updateCacheMeta(cacheKey);
      return surah;
    } catch (e) {
      final cached = HiveService.getCachedVerses(surahNumber);
      return cached != null ? {'verses': cached} : null;
    }
  }

  /// Get tafsir (cache-first)
  Future<Map<String, dynamic>?> getTafsir(
    int surahNumber,
    int verseNumber, {
    String edition = 'ar.muyassar',
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'tafsir_${surahNumber}_${verseNumber}_$edition';

    if (!forceRefresh && !_isStale(cacheKey, ttl: const Duration(days: 7))) {
      final cached = HiveService.getCachedTafsir(surahNumber, verseNumber);
      if (cached != null) return cached;
    }

    try {
      final tafsir = await _apiFetcher.fetchTafsir(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        tafsirEdition: edition,
      );
      await HiveService.cacheTafsir(surahNumber, verseNumber, tafsir);
      _updateCacheMeta(cacheKey);
      return tafsir;
    } catch (e) {
      return HiveService.getCachedTafsir(surahNumber, verseNumber);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HADITH CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get hadiths by category (cache-first)
  Future<List<Map<String, dynamic>>> getHadithsByCategory(
    String categoryId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'hadith_$categoryId';

    if (!forceRefresh && !_isStale(cacheKey)) {
      final cached = HiveService.getCachedHadiths(categoryId);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    try {
      final hadiths = await _apiFetcher.fetchHadithsByCollection(categoryId);
      await HiveService.cacheHadiths(categoryId, hadiths);
      _updateCacheMeta(cacheKey);
      return hadiths;
    } catch (e) {
      return HiveService.getCachedHadiths(categoryId) ?? [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRAYER TIMES CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get prayer times (short TTL)
  Future<Map<String, dynamic>?> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    int method = 4,
    bool forceRefresh = false,
  }) async {
    final dateKey = '${date.year}_${date.month}_${date.day}';
    final cacheKey = 'prayer_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}_$dateKey';

    if (!forceRefresh && !_isStale(cacheKey, ttl: const Duration(hours: 6))) {
      final cached = _getCachedData(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final times = await _apiFetcher.fetchPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: date,
        method: method,
      );
      _setCachedData(cacheKey, times);
      _updateCacheMeta(cacheKey);
      return times;
    } catch (e) {
      return _getCachedData(cacheKey);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADHKAR CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get adhkar by category (cache-first, long TTL)
  Future<List<Map<String, dynamic>>> getAdhkarByCategory(
    String category, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'adhkar_$category';

    if (!forceRefresh && !_isStale(cacheKey, ttl: const Duration(days: 30))) {
      final cached = HiveService.getCachedAdhkar(category);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    // Adhkar is pre-bundled, so we load from assets
    // In production, this would load from assets JSON
    return HiveService.getCachedAdhkar(category) ?? [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isStale(String cacheKey, {Duration ttl = _defaultTtl}) {
    final meta = _metaBox.get(cacheKey);
    if (meta == null) return true;

    final lastUpdate = DateTime.parse(meta['updated_at'] as String);
    return DateTime.now().difference(lastUpdate) > ttl;
  }

  void _updateCacheMeta(String cacheKey) {
    _metaBox.put(cacheKey, {
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic>? _getCachedData(String key) {
    final box = Hive.box<Map>('cache_data');
    final data = box.get(key);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> _setCachedData(String key, Map<String, dynamic> data) async {
    final box = await Hive.openBox<Map>('cache_data');
    await box.put(key, data);
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await HiveService.clearAll();
    await _metaBox.clear();
  }

  /// Get cache stats
  Map<String, dynamic> getCacheStats() {
    return {
      'entries': _metaBox.length,
      'surahs_cached': HiveService.surahsBox.length,
      'hadiths_cached': HiveService.hadithsBox.length,
      'adhkar_cached': HiveService.adhkarBox.length,
    };
  }

  /// Sync all data in background
  Future<void> backgroundSync() async {
    // Sync surahs
    await getSurahs(forceRefresh: true);

    // Sync commonly used hadiths
    await getHadithsByCategory('bukhari', forceRefresh: true);
    await getHadithsByCategory('muslim', forceRefresh: true);
  }
}
