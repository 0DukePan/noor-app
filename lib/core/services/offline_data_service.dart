import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'api_fetcher_service.dart';
import 'hive_box_registry.dart';

/// خدمة البيانات غير المتصلة - Offline Data Service
/// Manages bundled assets and cached API data for offline-first experience
class OfflineDataService {
  static const _quranBoxName = HiveBoxes.offlineQuran;
  static const _hadithBoxName = HiveBoxes.offlineHadith;
  static const _lastSyncKey = 'last_sync';
  static const _surahsAsset = 'assets/quran/surahs.json';

  static Box<dynamic>? _quranBox;
  static Box<dynamic>? _hadithBox;
  static final ApiFetcherService _api = ApiFetcherService();

  /// Initialize offline storage
  static Future<void> init() async {
    _quranBox = await Hive.openBox<dynamic>(_quranBoxName);
    _hadithBox = await Hive.openBox<dynamic>(_hadithBoxName);

    // Load bundled data on first run
    if (!_quranBox!.containsKey('initialized')) {
      await _loadBundledQuran();
      await _quranBox!.put('initialized', true);
    }

    if (!_hadithBox!.containsKey('initialized')) {
      await _loadBundledHadith();
      await _hadithBox!.put('initialized', true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUNDLED DATA LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load pre-bundled Quran data from assets
  static Future<void> _loadBundledQuran() async {
    try {
      // Load surahs metadata
      final surahsJson = await rootBundle.loadString(_surahsAsset);
      final surahs =
          List<Map<String, dynamic>>.from(jsonDecode(surahsJson) as List);
      await _quranBox!.put('surahs', surahs);

      // Load full Quran text (Uthmani)
      try {
        final quranTextJson =
            await rootBundle.loadString('assets/quran/quran_uthmani.json');
        final quranText = jsonDecode(quranTextJson) as Map<String, dynamic>;

        // Process and store each surah
        for (var i = 1; i <= 114; i++) {
          final surahNum = i.toString();
          if (quranText.containsKey(surahNum)) {
            final verses = quranText[surahNum] as List;

            // Find metadata
            final metadata = surahs.firstWhere(
              (s) => s['number'] == i,
              orElse: () => {'number': i, 'name': 'Surah $i'},
            );

            // Construct full surah object
            final surahData = {
              ...metadata,
              'verses': verses
                  .map(
                    (v) => {
                      'number': (v as Map)['verse'],
                      'text': v['text'],
                      'numberInSurah': v['verse'],
                    },
                  )
                  .toList(),
            };

            await _quranBox!.put('surah_$i', surahData);
          }
        }
      } on Exception catch (e) {
        debugPrint('Failed to load quran_uthmani.json: $e');
      }
    } on Exception catch (e) {
      debugPrint('Failed to load bundled Quran: $e');
    }
  }

  /// Load pre-bundled data from assets. (The hadith corpus now lives in the
  /// prebuilt SQLite database — see HadithDatabase; nothing to load here.)
  static Future<void> _loadBundledHadith() async {
    // Intentionally empty: hadith content is served by the SQLite database.
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QURAN DATA ACCESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all surahs (offline-first)
  static Future<List<Map<String, dynamic>>> getSurahs() async {
    // Try cache first
    final cached = _quranBox?.get('surahs');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached as List);
    }

    // Fetch from API
    try {
      final surahs = await _api.fetchAllSurahs();
      await _quranBox?.put('surahs', surahs);
      return surahs;
    } on Exception {
      return _readBundledSurahIndex();
    }
  }

  /// Get surah with verses (offline-first)
  static Future<Map<String, dynamic>?> getSurah(int surahNumber) async {
    // Try cache first
    final cached = _quranBox?.get('surah_$surahNumber');
    if (cached != null) {
      return Map<String, dynamic>.from(cached as Map);
    }

    // Fetch from API
    try {
      final surah = await _api.fetchSurah(surahNumber);
      await _quranBox?.put('surah_$surahNumber', surah);
      return surah;
    } on Exception {
      return null;
    }
  }

  /// Get tafsir for verse (cache with TTL)
  static Future<Map<String, dynamic>?> getTafsir(int surah, int verse) async {
    final key = 'tafsir_${surah}_$verse';
    final cached = _quranBox?.get(key);

    if (cached != null) {
      return Map<String, dynamic>.from(cached as Map);
    }

    try {
      final tafsir = await _api.fetchTafsir(
        surahNumber: surah,
        verseNumber: verse,
      );
      await _quranBox?.put(key, tafsir);
      return tafsir;
    } on Exception {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELTA UPDATES / SYNC
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync data with server (delta updates)
  static Future<void> syncIfNeeded() async {
    final lastSync = _quranBox?.get(_lastSyncKey) as DateTime?;
    final now = DateTime.now();

    // Sync if last sync was more than 24 hours ago
    if (lastSync == null || now.difference(lastSync).inHours > 24) {
      await _performSync();
    }
  }

  static Future<void> _performSync() async {
    try {
      // Refresh surahs metadata
      final surahs = await _api.fetchAllSurahs();
      await _quranBox?.put('surahs', surahs);

      await _quranBox?.put(_lastSyncKey, DateTime.now());
    } on Exception {
      // Sync failed, will retry later
    }
  }

  /// Force sync all data
  static Future<void> forceSync() async {
    await _performSync();
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    await _quranBox?.clear();
    await _hadithBox?.clear();
  }

  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    return {
      'quran_items': _quranBox?.length ?? 0,
      'hadith_items': _hadithBox?.length ?? 0,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT DATA (Fallback when offline and no cache)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reads the bundled surah index — the same asset that seeds the cache.
  ///
  /// This used to be a hand-kept five-surah excerpt ending in a
  /// "... more surahs would be here" comment, so a failed cache and a failed
  /// fetch showed five surahs. The asset is already on the device; reading it
  /// costs nothing and yields all 114. Returns an empty list if the asset is
  /// unreadable.
  static Future<List<Map<String, dynamic>>> _readBundledSurahIndex() async {
    try {
      final json = await rootBundle.loadString(_surahsAsset);
      return List<Map<String, dynamic>>.from(jsonDecode(json) as List);
    } on Exception catch (e) {
      debugPrint('Failed to read $_surahsAsset: $e');
      return const [];
    }
  }
}
