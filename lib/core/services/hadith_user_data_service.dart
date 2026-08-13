import 'package:hive_flutter/hive_flutter.dart';

import '../domain/entities/hadith.dart';

/// Service for managing user-specific Hadith data:
/// - Continue Reading (last read position)
/// - Bookmarked Hadiths
class HadithUserDataService {
  static const String _progressBoxName = 'hadith_progress';
  static const String _bookmarksBoxName = 'hadith_bookmarks';

  static Box<dynamic>? _progressBox;
  static Box<dynamic>? _bookmarksBox;

  /// Initialize Hive boxes
  static Future<void> init() async {
    _progressBox = await Hive.openBox<dynamic>(_progressBoxName);
    _bookmarksBox = await Hive.openBox<dynamic>(_bookmarksBoxName);
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONTINUE READING
  // ═══════════════════════════════════════════════════════════════════

  /// Save reading progress. `chapterId` + `hadithNumber` let the resume
  /// flow rebuild the exact same chapter-scoped list the user was in
  /// (previously only a list index was saved, which pointed at the wrong
  /// hadith when applied to the whole book).
  static Future<void> saveReadingProgress({
    required String bookId,
    required String bookTitle,
    required int colorValue,
    required int hadithIndex,
    required int totalHadiths,
    int? chapterId,
    int? hadithNumber,
  }) async {
    final box = _progressBox;
    if (box == null) return;
    await box.put('lastRead', {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'colorValue': colorValue,
      'hadithIndex': hadithIndex,
      'totalHadiths': totalHadiths,
      'chapterId': chapterId,
      'hadithNumber': hadithNumber,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get last reading position
  static Map<String, dynamic>? getLastReadingProgress() {
    final box = _progressBox;
    if (box == null) return null;
    final data = box.get('lastRead');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOOKMARKS
  // ═══════════════════════════════════════════════════════════════════

  /// Bookmark a hadith
  static Future<void> bookmarkHadith({
    required int hadithId,
    required String collectionId,
    required String arabic,
    required String englishText,
    required String narrator,
    required int idInBook,
  }) async {
    final box = _bookmarksBox;
    if (box == null) return;
    final key = '${collectionId}_$hadithId';
    await box.put(key, {
      'hadithId': hadithId,
      'collectionId': collectionId,
      'arabic': arabic,
      'englishText': englishText,
      'narrator': narrator,
      'idInBook': idInBook,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Remove a bookmark
  static Future<void> removeBookmark(String collectionId, int hadithId) async {
    final box = _bookmarksBox;
    if (box == null) return;
    final key = '${collectionId}_$hadithId';
    await box.delete(key);
  }

  /// Check if a hadith is bookmarked
  static bool isBookmarked(String? collectionId, int hadithId) {
    final box = _bookmarksBox;
    if (box == null || collectionId == null) return false;
    final key = '${collectionId}_$hadithId';
    return box.containsKey(key);
  }

  /// Toggle bookmark
  static Future<bool> toggleBookmark(Hadith hadith) async {
    final collectionId = hadith.collectionId ?? '';
    if (isBookmarked(collectionId, hadith.id)) {
      await removeBookmark(collectionId, hadith.id);
      return false;
    } else {
      await bookmarkHadith(
        hadithId: hadith.id,
        collectionId: collectionId,
        arabic: hadith.arabic,
        englishText: hadith.englishText,
        narrator: hadith.narratorEnglish,
        idInBook: hadith.idInBook,
      );
      return true;
    }
  }

  /// Get all bookmarked hadiths
  static List<Map<String, dynamic>> getAllBookmarks() {
    final box = _bookmarksBox;
    if (box == null) return [];
    final bookmarks = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        bookmarks.add(Map<String, dynamic>.from(data as Map));
      }
    }
    // Sort by most recently added
    bookmarks.sort((a, b) => (b['timestamp'] as int? ?? 0).compareTo(a['timestamp'] as int? ?? 0));
    return bookmarks;
  }

  /// Get bookmark count
  static int get bookmarkCount => _bookmarksBox?.length ?? 0;
}
