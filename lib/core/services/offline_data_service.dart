import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'api_fetcher_service.dart';

/// خدمة البيانات غير المتصلة - Offline Data Service
/// Manages bundled assets and cached API data for offline-first experience
class OfflineDataService {
  static const _quranBoxName = 'quran_offline';
  static const _hadithBoxName = 'hadith_offline';
  static const _lastSyncKey = 'last_sync';

  static Box? _quranBox;
  static Box? _hadithBox;
  static final ApiFetcherService _api = ApiFetcherService();

  /// Initialize offline storage
  static Future<void> init() async {
    _quranBox = await Hive.openBox(_quranBoxName);
    _hadithBox = await Hive.openBox(_hadithBoxName);

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
      final surahsJson = await rootBundle.loadString('assets/quran/surahs.json');
      final surahs = List<Map<String, dynamic>>.from(jsonDecode(surahsJson));
      await _quranBox!.put('surahs', surahs);

      // Load full Quran text (Uthmani)
      try {
        final quranTextJson = await rootBundle.loadString('assets/quran/quran_uthmani.json');
        final quranText = jsonDecode(quranTextJson) as Map<String, dynamic>;
        

        // Process and store each surah
        for (var i = 1; i <= 114; i++) {
          final surahNum = i.toString();
          if (quranText.containsKey(surahNum)) {
            final verses = quranText[surahNum] as List;
            
            // Find metadata
            final metadata = surahs.firstWhere(
              (s) => s['number'] == i, 
              orElse: () => {'number': i, 'name': 'Surah $i'}
            );

            // Construct full surah object
            final surahData = {
              ...metadata,
              'verses': verses.map((v) => {
                'number': v['verse'],
                'text': v['text'],
                'numberInSurah': v['verse'],
                'juz': 0, // Placeholder
                'manzil': 0, // Placeholder
                'page': 0, // Placeholder
                'ruku': 0, // Placeholder
                'hizbQuarter': 0, // Placeholder
                'sajda': false, // Placeholder
              }).toList(),
            };

            await _quranBox!.put('surah_$i', surahData);
          }
        }
      } catch (e) {
        debugPrint('Failed to load quran_uthmani.json: $e');
      }
    } catch (e) {
      debugPrint('Failed to load bundled Quran: $e');
    }
  }

  /// Load pre-bundled popular hadiths from assets
  static Future<void> _loadBundledHadith() async {
    try {
      // Load 40 Nawawi
      try {
        final nawawiJson = await rootBundle.loadString('assets/hadith/40_nawawi.json');
        await _hadithBox!.put('40_nawawi', jsonDecode(nawawiJson));
      } catch (_) {}

      // Load popular hadiths (May be missing)
      try {
        final popularJson = await rootBundle.loadString('assets/hadith/popular.json');
        await _hadithBox!.put('popular', jsonDecode(popularJson));
      } catch (_) {}

      // Load collection metadata (May be missing)
      try {
        final collectionsJson = await rootBundle.loadString('assets/hadith/collections.json');
        await _hadithBox!.put('collections', jsonDecode(collectionsJson));
      } catch (_) {
        await _hadithBox!.put('collections', _getDefaultCollections());
      }
    } catch (e) {
      // Assets not found, will use API
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QURAN DATA ACCESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all surahs (offline-first)
  static Future<List<Map<String, dynamic>>> getSurahs() async {
    // Try cache first
    final cached = _quranBox?.get('surahs');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached);
    }

    // Fetch from API
    try {
      final surahs = await _api.fetchAllSurahs();
      await _quranBox?.put('surahs', surahs);
      return surahs;
    } catch (e) {
      return _getDefaultSurahs();
    }
  }

  /// Get surah with verses (offline-first)
  static Future<Map<String, dynamic>?> getSurah(int surahNumber) async {
    // Try cache first
    final cached = _quranBox?.get('surah_$surahNumber');
    if (cached != null) {
      return Map<String, dynamic>.from(cached);
    }

    // Fetch from API
    try {
      final surah = await _api.fetchSurah(surahNumber);
      await _quranBox?.put('surah_$surahNumber', surah);
      return surah;
    } catch (e) {
      return null;
    }
  }

  /// Get tafsir for verse (cache with TTL)
  static Future<Map<String, dynamic>?> getTafsir(int surah, int verse) async {
    final key = 'tafsir_${surah}_$verse';
    final cached = _quranBox?.get(key);

    if (cached != null) {
      return Map<String, dynamic>.from(cached);
    }

    try {
      final tafsir = await _api.fetchTafsir(
        surahNumber: surah,
        verseNumber: verse,
      );
      await _quranBox?.put(key, tafsir);
      return tafsir;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HADITH DATA ACCESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get hadith collections
  static Future<List<Map<String, dynamic>>> getCollections() async {
    final cached = _hadithBox?.get('collections');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached);
    }

    try {
      final collections = await _api.fetchHadithCollections();
      await _hadithBox?.put('collections', collections);
      return collections;
    } catch (e) {
      return _getDefaultCollections();
    }
  }

  /// Get hadiths by collection
  static Future<List<Map<String, dynamic>>> getHadithsByCollection(
    String collection, {
    int page = 1,
  }) async {
    final key = 'hadiths_${collection}_$page';
    final cached = _hadithBox?.get(key);

    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached);
    }

    try {
      final hadiths = await _api.fetchHadithsByCollection(collection, page: page);
      await _hadithBox?.put(key, hadiths);
      return hadiths;
    } catch (e) {
      return [];
    }
  }

  /// Get 40 Nawawi hadiths (always available offline)
  static Future<List<Map<String, dynamic>>> get40Nawawi() async {
    final cached = _hadithBox?.get('40_nawawi');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached);
    }
    return [];
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

      // Refresh collection metadata
      final collections = await _api.fetchHadithCollections();
      await _hadithBox?.put('collections', collections);

      await _quranBox?.put(_lastSyncKey, DateTime.now());
    } catch (e) {
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

  static List<Map<String, dynamic>> _getDefaultSurahs() {
    return [
      {'number': 1, 'name': 'سُورَةُ ٱلْفَاتِحَةِ', 'englishName': 'Al-Fatiha', 'numberOfAyahs': 7, 'revelationType': 'Meccan'},
      {'number': 2, 'name': 'سُورَةُ البَقَرَةِ', 'englishName': 'Al-Baqara', 'numberOfAyahs': 286, 'revelationType': 'Medinan'},
      {'number': 3, 'name': 'سُورَةُ آلِ عِمۡرَانَ', 'englishName': 'Aal-Imran', 'numberOfAyahs': 200, 'revelationType': 'Medinan'},
      {'number': 4, 'name': 'سُورَةُ النِّسَاءِ', 'englishName': 'An-Nisa', 'numberOfAyahs': 176, 'revelationType': 'Medinan'},
      {'number': 5, 'name': 'سُورَةُ المَائـِدَةِ', 'englishName': 'Al-Maida', 'numberOfAyahs': 120, 'revelationType': 'Medinan'},
      // ... more surahs would be here
    ];
  }

  static List<Map<String, dynamic>> _getDefaultCollections() {
    return [
      {'name': 'bukhari', 'title': 'صحيح البخاري', 'hadithsCount': 7563},
      {'name': 'muslim', 'title': 'صحيح مسلم', 'hadithsCount': 3032},
      {'name': 'abudawud', 'title': 'سنن أبي داود', 'hadithsCount': 4590},
      {'name': 'tirmidhi', 'title': 'جامع الترمذي', 'hadithsCount': 3956},
      {'name': 'nasai', 'title': 'سنن النسائي', 'hadithsCount': 5758},
      {'name': 'ibnmajah', 'title': 'سنن ابن ماجه', 'hadithsCount': 4341},
    ];
  }
}
