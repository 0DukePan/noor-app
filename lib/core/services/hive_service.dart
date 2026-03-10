import 'package:hive_flutter/hive_flutter.dart';

/// خدمة Hive للتخزين المحلي - Hive Storage Service
class HiveService {
  static const String _surahsBox = 'surahs';
  static const String _versesBox = 'verses';
  static const String _tafsirBox = 'tafsir';
  static const String _hadithsBox = 'hadiths';
  static const String _adhkarBox = 'adhkar';
  static const String _progressBox = 'reading_progress';
  static const String _bookmarksBox = 'bookmarks';
  static const String _tadabburBox = 'tadabbur';
  static const String _settingsBox = 'settings';
  static const String _qadaBox = 'qada';

  /// Initialize all Hive boxes
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Open all boxes
    await Future.wait([
      Hive.openBox<Map>(_surahsBox),
      Hive.openBox<Map>(_versesBox),
      Hive.openBox<Map>(_tafsirBox),
      Hive.openBox<Map>(_hadithsBox),
      Hive.openBox<Map>(_adhkarBox),
      Hive.openBox<Map>(_progressBox),
      Hive.openBox<Map>(_bookmarksBox),
      Hive.openBox<Map>(_tadabburBox),
      Hive.openBox<Map>(_settingsBox),
      Hive.openBox<Map>(_qadaBox),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QURAN STORAGE
  // ═══════════════════════════════════════════════════════════════════════════

  static Box<Map> get surahsBox => Hive.box<Map>(_surahsBox);
  static Box<Map> get versesBox => Hive.box<Map>(_versesBox);
  static Box<Map> get tafsirBox => Hive.box<Map>(_tafsirBox);

  /// Cache all surahs
  static Future<void> cacheSurahs(List<Map<String, dynamic>> surahs) async {
    final box = surahsBox;
    await box.clear();
    for (final surah in surahs) {
      await box.put(surah['number'].toString(), surah);
    }
  }

  /// Get all cached surahs
  static List<Map<String, dynamic>> getCachedSurahs() {
    return surahsBox.values.map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
  }

  /// Cache verses for a surah
  static Future<void> cacheVerses(int surahNumber, List<Map<String, dynamic>> verses) async {
    await versesBox.put(surahNumber.toString(), {'verses': verses});
  }

  /// Get cached verses for a surah
  static List<Map<String, dynamic>>? getCachedVerses(int surahNumber) {
    final data = versesBox.get(surahNumber.toString());
    if (data == null) return null;
    return (data['verses'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Cache tafsir
  static Future<void> cacheTafsir(int surahNumber, int verseNumber, Map<String, dynamic> tafsir) async {
    final key = '$surahNumber:$verseNumber';
    await tafsirBox.put(key, tafsir);
  }

  /// Get cached tafsir
  static Map<String, dynamic>? getCachedTafsir(int surahNumber, int verseNumber) {
    final key = '$surahNumber:$verseNumber';
    final data = tafsirBox.get(key);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HADITH STORAGE
  // ═══════════════════════════════════════════════════════════════════════════

  static Box<Map> get hadithsBox => Hive.box<Map>(_hadithsBox);

  /// Cache hadiths by category
  static Future<void> cacheHadiths(String categoryId, List<Map<String, dynamic>> hadiths) async {
    await hadithsBox.put(categoryId, {'hadiths': hadiths});
  }

  /// Get cached hadiths
  static List<Map<String, dynamic>>? getCachedHadiths(String categoryId) {
    final data = hadithsBox.get(categoryId);
    if (data == null) return null;
    return (data['hadiths'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADHKAR STORAGE
  // ═══════════════════════════════════════════════════════════════════════════

  static Box<Map> get adhkarBox => Hive.box<Map>(_adhkarBox);

  /// Cache adhkar by category
  static Future<void> cacheAdhkar(String category, List<Map<String, dynamic>> adhkar) async {
    await adhkarBox.put(category, {'adhkar': adhkar});
  }

  /// Get cached adhkar
  static List<Map<String, dynamic>>? getCachedAdhkar(String category) {
    final data = adhkarBox.get(category);
    if (data == null) return null;
    return (data['adhkar'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER DATA STORAGE
  // ═══════════════════════════════════════════════════════════════════════════

  static Box<Map> get progressBox => Hive.box<Map>(_progressBox);
  static Box<Map> get bookmarksBox => Hive.box<Map>(_bookmarksBox);
  static Box<Map> get tadabburBox => Hive.box<Map>(_tadabburBox);
  static Box<Map> get settingsBox => Hive.box<Map>(_settingsBox);
  static Box<Map> get qadaBox => Hive.box<Map>(_qadaBox);

  /// Save reading progress
  static Future<void> saveReadingProgress(Map<String, dynamic> progress) async {
    await progressBox.put('last', progress);
  }

  /// Get reading progress
  static Map<String, dynamic>? getReadingProgress() {
    final data = progressBox.get('last');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Save bookmark
  static Future<void> saveBookmark(String type, String itemId) async {
    final key = '$type:$itemId';
    await bookmarksBox.put(key, {
      'type': type,
      'itemId': itemId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Remove bookmark
  static Future<void> removeBookmark(String type, String itemId) async {
    final key = '$type:$itemId';
    await bookmarksBox.delete(key);
  }

  /// Check if bookmarked
  static bool isBookmarked(String type, String itemId) {
    final key = '$type:$itemId';
    return bookmarksBox.containsKey(key);
  }

  /// Get all bookmarks by type
  static List<Map<String, dynamic>> getBookmarksByType(String type) {
    return bookmarksBox.values
        .where((e) => e['type'] == type)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Save tadabbur (encrypted note)
  static Future<void> saveTadabbur(Map<String, dynamic> tadabbur) async {
    final key = '${tadabbur['surahNumber']}:${tadabbur['verseNumber']}:${tadabbur['id']}';
    await tadabburBox.put(key, tadabbur);
  }

  /// Get tadabbur for verse
  static List<Map<String, dynamic>> getTadabburForVerse(int surahNumber, int verseNumber) {
    final prefix = '$surahNumber:$verseNumber:';
    return tadabburBox.keys
        .where((k) => k.toString().startsWith(prefix))
        .map((k) => Map<String, dynamic>.from(tadabburBox.get(k)!))
        .toList();
  }

  /// Get all tadabbur
  static List<Map<String, dynamic>> getAllTadabbur() {
    return tadabburBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Delete tadabbur
  static Future<void> deleteTadabbur(String id) async {
    final keyToDelete = tadabburBox.keys.firstWhere(
      (k) => k.toString().endsWith(':$id'),
      orElse: () => null,
    );
    if (keyToDelete != null) {
      await tadabburBox.delete(keyToDelete);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save setting
  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, {'value': value});
  }

  /// Get setting
  static T? getSetting<T>(String key, {T? defaultValue}) {
    final data = settingsBox.get(key);
    return data != null ? data['value'] as T? : defaultValue;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QADA RECORDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save qada record
  static Future<void> saveQadaRecord(Map<String, dynamic> record) async {
    await qadaBox.put(record['id'], record);
  }

  /// Get all qada records
  static List<Map<String, dynamic>> getAllQadaRecords() {
    return qadaBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Delete qada record
  static Future<void> deleteQadaRecord(String id) async {
    await qadaBox.delete(id);
  }

  /// Clear all data
  static Future<void> clearAll() async {
    await Future.wait([
      surahsBox.clear(),
      versesBox.clear(),
      tafsirBox.clear(),
      hadithsBox.clear(),
      adhkarBox.clear(),
      progressBox.clear(),
      bookmarksBox.clear(),
      tadabburBox.clear(),
      qadaBox.clear(),
    ]);
  }
}
