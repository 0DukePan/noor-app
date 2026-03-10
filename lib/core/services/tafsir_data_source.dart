import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/tafsir_models.dart';

/// 📖 TafsirDataSource - مصدر بيانات التفسير
/// 
/// Offline-First: Assets → Cache → API
/// - التفسير الميسر: كامل محلياً
/// - السعدي: كامل محلياً
/// - الطبري: كامل محلياً
/// - ابن كثير: API + Cache
class TafsirDataSource {
  static const String _cacheBoxName = 'tafsir_cache';
  static const String _settingsBoxName = 'tafsir_settings';
  static const String _bookmarksBoxName = 'tafsir_bookmarks';
  static const String _historyBoxName = 'tafsir_history';

  static Box? _cacheBox;
  static Box? _settingsBox;
  static Box? _bookmarksBox;
  static Box? _historyBox;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// تهيئة المصدر
  static Future<void> init() async {
    _cacheBox = await Hive.openBox(_cacheBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _bookmarksBox = await Hive.openBox(_bookmarksBoxName);
    _historyBox = await Hive.openBox(_historyBoxName);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN API - تحميل التفسير
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحميل تفسير آية واحدة
  static Future<TafsirEntry?> getAyahTafsir({
    required int surah,
    required int ayah,
    TafsirSourceId source = TafsirSourceId.muyassar,
  }) async {
    // 1. جرب من Cache أولاً
    final cached = _getCachedEntry(surah, ayah, source);
    if (cached != null) return cached;

    // 2. حمّل السورة كاملة (أكثر كفاءة)
    final surahTafsir = await getSurahTafsir(surah: surah, source: source);
    return surahTafsir?.getAyah(ayah);
  }

  /// تحميل تفسير سورة كاملة
  static Future<SurahTafsir?> getSurahTafsir({
    required int surah,
    TafsirSourceId source = TafsirSourceId.muyassar,
  }) async {
    final sourceInfo = TafsirSource.get(source);

    // 1. جرب من Assets
    if (sourceInfo.isFullyBundled) {
      final fromAssets = await _loadFromAssets(surah, source);
      if (fromAssets != null) {
        // Cache للوصول السريع
        await _cacheSurah(fromAssets);
        return fromAssets;
      }
    }

    // 2. جرب من Cache
    final fromCache = _getCachedSurah(surah, source);
    if (fromCache != null) return fromCache;

    // 3. جرب من API (لابن كثير)
    if (sourceInfo.apiEndpoint != null) {
      final fromApi = await _loadFromApi(surah, source);
      if (fromApi != null) {
        await _cacheSurah(fromApi);
        return fromApi;
      }
    }

    return null;
  }

  /// تحميل التفسيرات المتعددة للمقارنة
  static Future<Map<TafsirSourceId, TafsirEntry>> getCompareTafsir({
    required int surah,
    required int ayah,
    required List<TafsirSourceId> sources,
  }) async {
    final results = <TafsirSourceId, TafsirEntry>{};
    
    for (final source in sources) {
      final entry = await getAyahTafsir(surah: surah, ayah: ayah, source: source);
      if (entry != null) {
        results[source] = entry;
      }
    }
    
    return results;
  }

  /// التحميل المسبق للآيات القريبة
  static Future<void> preloadNearby({
    required int surah,
    required int ayah,
    TafsirSourceId source = TafsirSourceId.muyassar,
    int range = 5,
  }) async {
    // تحميل السورة كاملة أكثر كفاءة
    await getSurahTafsir(surah: surah, source: source);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ASSETS LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<SurahTafsir?> _loadFromAssets(
    int surah,
    TafsirSourceId source,
  ) async {
    try {
      final sourceInfo = TafsirSource.get(source);
      final path = '${sourceInfo.assetPath}/$surah.json';
      
      final jsonString = await rootBundle.loadString(path);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return SurahTafsir.fromJson(json, source);
    } catch (e) {
      // File not found or parse error
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static TafsirEntry? _getCachedEntry(int surah, int ayah, TafsirSourceId source) {
    final key = '${source.name}:$surah:$ayah';
    final cached = _cacheBox?.get(key);
    
    if (cached != null) {
      return TafsirEntry(
        surah: surah,
        ayah: ayah,
        text: cached['text'],
        source: source,
        cachedAt: DateTime.tryParse(cached['cachedAt'] ?? ''),
      );
    }
    return null;
  }

  static SurahTafsir? _getCachedSurah(int surah, TafsirSourceId source) {
    final key = 'surah:${source.name}:$surah';
    final cached = _cacheBox?.get(key);
    
    if (cached != null) {
      final entries = (cached['entries'] as List).map((e) => TafsirEntry(
        surah: e['surah'],
        ayah: e['ayah'],
        text: e['text'],
        source: source,
      )).toList();
      
      return SurahTafsir(surah: surah, source: source, entries: entries);
    }
    return null;
  }

  static Future<void> _cacheSurah(SurahTafsir tafsir) async {
    // Cache كل آية بشكل فردي
    for (final entry in tafsir.entries) {
      final key = '${entry.source.name}:${entry.surah}:${entry.ayah}';
      await _cacheBox?.put(key, {
        'text': entry.text,
        'cachedAt': DateTime.now().toIso8601String(),
      });
    }
    
    // Cache السورة كاملة للوصول السريع
    final surahKey = 'surah:${tafsir.source.name}:${tafsir.surah}';
    await _cacheBox?.put(surahKey, {
      'entries': tafsir.entries.map((e) => {
        'surah': e.surah,
        'ayah': e.ayah,
        'text': e.text,
      }).toList(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // API LOADING (for Ibn Kathir)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<SurahTafsir?> _loadFromApi(
    int surah,
    TafsirSourceId source,
  ) async {
    // TODO: Implement API fetching for Ibn Kathir
    // For now, return null (offline only)
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKMARKS
  // ═══════════════════════════════════════════════════════════════════════════

  /// إضافة علامة
  static Future<void> addBookmark({
    required int surah,
    required int ayah,
    TafsirSourceId source = TafsirSourceId.muyassar,
    String? note,
  }) async {
    final bookmark = TafsirBookmark(
      surah: surah,
      ayah: ayah,
      source: source,
      createdAt: DateTime.now(),
      note: note,
    );
    await _bookmarksBox?.put(bookmark.key, bookmark.toJson());
  }

  /// حذف علامة
  static Future<void> removeBookmark({
    required int surah,
    required int ayah,
    TafsirSourceId source = TafsirSourceId.muyassar,
  }) async {
    final key = '${source.name}:$surah:$ayah';
    await _bookmarksBox?.delete(key);
  }

  /// هل توجد علامة؟
  static bool isBookmarked({
    required int surah,
    required int ayah,
    TafsirSourceId source = TafsirSourceId.muyassar,
  }) {
    final key = '${source.name}:$surah:$ayah';
    return _bookmarksBox?.containsKey(key) ?? false;
  }

  /// كل العلامات
  static List<TafsirBookmark> getAllBookmarks() {
    final all = <TafsirBookmark>[];
    _bookmarksBox?.keys.forEach((key) {
      final json = _bookmarksBox?.get(key);
      if (json != null) {
        all.add(TafsirBookmark.fromJson(Map<String, dynamic>.from(json)));
      }
    });
    return all..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // READING HISTORY
  // ═══════════════════════════════════════════════════════════════════════════

  /// تسجيل القراءة
  static Future<void> recordReading({
    required int surah,
    required int ayah,
    TafsirSourceId source = TafsirSourceId.muyassar,
  }) async {
    final key = '${source.name}:$surah:$ayah';
    final existing = _historyBox?.get(key);
    
    final history = TafsirReadingHistory(
      surah: surah,
      ayah: ayah,
      source: source,
      lastRead: DateTime.now(),
      readCount: existing != null ? (existing['readCount'] ?? 0) + 1 : 1,
    );
    
    await _historyBox?.put(key, {
      'surah': surah,
      'ayah': ayah,
      'source': source.name,
      'lastRead': history.lastRead.toIso8601String(),
      'readCount': history.readCount,
    });
  }

  /// آخر تفسير قُرأ
  static TafsirReadingHistory? getLastRead() {
    if (_historyBox == null || _historyBox!.isEmpty) return null;
    
    TafsirReadingHistory? latest;
    DateTime? latestTime;
    
    _historyBox!.values.forEach((json) {
      final lastRead = DateTime.tryParse(json['lastRead'] ?? '');
      if (lastRead != null && (latestTime == null || lastRead.isAfter(latestTime!))) {
        latestTime = lastRead;
        latest = TafsirReadingHistory(
          surah: json['surah'],
          ayah: json['ayah'],
          source: TafsirSourceId.values.firstWhere(
            (e) => e.name == json['source'],
            orElse: () => TafsirSourceId.muyassar,
          ),
          lastRead: lastRead,
          readCount: json['readCount'] ?? 1,
        );
      }
    });
    
    return latest;
  }

  /// سجل القراءة الأخيرة
  static List<TafsirReadingHistory> getRecentHistory({int limit = 20}) {
    final all = <TafsirReadingHistory>[];
    
    _historyBox?.values.forEach((json) {
      all.add(TafsirReadingHistory(
        surah: json['surah'],
        ayah: json['ayah'],
        source: TafsirSourceId.values.firstWhere(
          (e) => e.name == json['source'],
          orElse: () => TafsirSourceId.muyassar,
        ),
        lastRead: DateTime.parse(json['lastRead']),
        readCount: json['readCount'] ?? 1,
      ));
    });
    
    all.sort((a, b) => b.lastRead.compareTo(a.lastRead));
    return all.take(limit).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// حفظ الإعدادات
  static Future<void> saveSettings(TafsirDisplaySettings settings) async {
    await _settingsBox?.put('display_settings', {
      'primarySource': settings.primarySource.name,
      'compareSources': settings.compareSources.map((s) => s.name).toList(),
      'showReferences': settings.showReferences,
      'fontSize': settings.fontSize,
      'displayMode': settings.displayMode.name,
    });
  }

  /// تحميل الإعدادات
  static TafsirDisplaySettings getSettings() {
    final json = _settingsBox?.get('display_settings');
    if (json == null) return const TafsirDisplaySettings();
    
    return TafsirDisplaySettings(
      primarySource: TafsirSourceId.values.firstWhere(
        (e) => e.name == json['primarySource'],
        orElse: () => TafsirSourceId.muyassar,
      ),
      compareSources: (json['compareSources'] as List?)?.map((s) =>
        TafsirSourceId.values.firstWhere(
          (e) => e.name == s,
          orElse: () => TafsirSourceId.muyassar,
        )
      ).toList() ?? [],
      showReferences: json['showReferences'] ?? true,
      fontSize: (json['fontSize'] ?? 18.0).toDouble(),
      displayMode: TafsirDisplayMode.values.firstWhere(
        (e) => e.name == json['displayMode'],
        orElse: () => TafsirDisplayMode.inline,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════════════════

  /// البحث في التفسير
  static Future<List<TafsirEntry>> search({
    required String query,
    TafsirSourceId source = TafsirSourceId.muyassar,
    int? surah, // حدد سورة معينة
    int limit = 50,
  }) async {
    final results = <TafsirEntry>[];
    final searchQuery = query.toLowerCase();
    
    // نطاق البحث
    final startSurah = surah ?? 1;
    final endSurah = surah ?? 114;
    
    for (int s = startSurah; s <= endSurah && results.length < limit; s++) {
      final surahTafsir = await getSurahTafsir(surah: s, source: source);
      if (surahTafsir != null) {
        for (final entry in surahTafsir.entries) {
          if (entry.text.toLowerCase().contains(searchQuery)) {
            results.add(entry);
            if (results.length >= limit) break;
          }
        }
      }
    }
    
    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// مسح الكاش
  static Future<void> clearCache() async {
    await _cacheBox?.clear();
  }

  /// حجم الكاش
  static int get cacheSize => _cacheBox?.length ?? 0;

  /// المصادر المتاحة
  static List<TafsirSource> get availableSources => TafsirSource.all;
}
