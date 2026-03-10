import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 🕌 مصدر بيانات الأحاديث - Hadith Data Source
/// Hybrid Offline-First Architecture:
/// 1️⃣ assets/hadith/ ← المصدر الأساسي (Always Available)
/// 2️⃣ Hive Cache ← تحسين الأداء + التحديثات
/// 3️⃣ API ← بحث + توسع
class HadithDataSource {
  static const _cacheBoxName = 'hadith_cache';
  static Box? _cacheBox;

  // The 9 Major Books of Hadith
  static const Map<String, HadithBookInfo> majorBooks = {
    'bukhari': HadithBookInfo(
      id: 'bukhari',
      arabicName: 'صحيح البخاري',
      englishName: 'Sahih al-Bukhari',
      author: 'الإمام محمد بن إسماعيل البخاري',
      hadithCount: 7277,
    ),
    'muslim': HadithBookInfo(
      id: 'muslim',
      arabicName: 'صحيح مسلم',
      englishName: 'Sahih Muslim',
      author: 'الإمام مسلم بن الحجاج',
      hadithCount: 7563,
    ),
    'abudawud': HadithBookInfo(
      id: 'abudawud',
      arabicName: 'سنن أبي داود',
      englishName: 'Sunan Abu Dawud',
      author: 'الإمام أبو داود السجستاني',
      hadithCount: 5274,
    ),
    'tirmidhi': HadithBookInfo(
      id: 'tirmidhi',
      arabicName: 'جامع الترمذي',
      englishName: 'Jami at-Tirmidhi',
      author: 'الإمام محمد بن عيسى الترمذي',
      hadithCount: 3956,
    ),
    'nasai': HadithBookInfo(
      id: 'nasai',
      arabicName: 'سنن النسائي',
      englishName: "Sunan an-Nasa'i",
      author: 'الإمام أحمد بن شعيب النسائي',
      hadithCount: 5758,
    ),
    'ibnmajah': HadithBookInfo(
      id: 'ibnmajah',
      arabicName: 'سنن ابن ماجه',
      englishName: 'Sunan Ibn Majah',
      author: 'الإمام محمد بن يزيد ابن ماجه',
      hadithCount: 4341,
    ),
    'malik': HadithBookInfo(
      id: 'malik',
      arabicName: 'موطأ مالك',
      englishName: "Muwatta Malik",
      author: 'الإمام مالك بن أنس',
      hadithCount: 1832,
    ),
    'ahmed': HadithBookInfo(
      id: 'ahmed',
      arabicName: 'مسند أحمد',
      englishName: 'Musnad Ahmad',
      author: 'الإمام أحمد بن حنبل',
      hadithCount: 27647,
    ),
    'darimi': HadithBookInfo(
      id: 'darimi',
      arabicName: 'سنن الدارمي',
      englishName: 'Sunan ad-Darimi',
      author: 'الإمام عبد الله بن عبد الرحمن الدارمي',
      hadithCount: 3503,
    ),
  };

  // In-memory cache
  static Map<String, dynamic>? _booksInMemory;
  
  /// Initialize data source
  static Future<void> init() async {
    _cacheBox = await Hive.openBox(_cacheBoxName);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY: ASSETS (ALWAYS AVAILABLE - 100% OFFLINE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get list of all available books
  static List<HadithBookInfo> getAllBooks() {
    return majorBooks.values.toList();
  }

  /// Get complete book data with all hadiths
  /// Priority: Memory → Assets → Cache
  static Future<Map<String, dynamic>> getBook(String bookId) async {
    // 1️⃣ Check in-memory cache first (instant)
    if (_booksInMemory?.containsKey(bookId) == true) {
      return _booksInMemory![bookId]!;
    }

    // 2️⃣ Load from assets (PRIMARY - always available)
    try {
      final jsonString = await rootBundle.loadString(
        'assets/hadith/by_book/the_9_books/$bookId.json',
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Cache in memory
      _booksInMemory ??= {};
      _booksInMemory![bookId] = data;
      
      return data;
    } catch (e) {
      // Book not found in assets
      throw HadithDataException('كتاب الحديث غير موجود: $bookId');
    }
  }

  /// Get book metadata only (without hadiths - faster)
  static Future<Map<String, dynamic>> getBookMetadata(String bookId) async {
    final book = await getBook(bookId);
    return {
      'id': book['id'],
      'metadata': book['metadata'],
      'chapters': book['chapters'],
      'hadithCount': (book['hadiths'] as List?)?.length ?? 0,
    };
  }

  /// Get all chapters for a book
  static Future<List<Map<String, dynamic>>> getChapters(String bookId) async {
    final book = await getBook(bookId);
    final chapters = book['chapters'] as List?;
    if (chapters == null) return [];
    return chapters.map((c) => Map<String, dynamic>.from(c)).toList();
  }

  /// Get all hadiths for a specific chapter
  static Future<List<Map<String, dynamic>>> getHadithsByChapter(
    String bookId,
    int chapterId,
  ) async {
    final book = await getBook(bookId);
    final hadiths = book['hadiths'] as List?;
    if (hadiths == null) return [];
    
    return hadiths
        .where((h) => h['chapterId'] == chapterId)
        .map((h) => Map<String, dynamic>.from(h))
        .toList();
  }

  /// Get single hadith by ID
  static Future<Map<String, dynamic>?> getHadith(
    String bookId,
    int hadithId,
  ) async {
    final book = await getBook(bookId);
    final hadiths = book['hadiths'] as List?;
    if (hadiths == null) return null;
    
    final hadith = hadiths.firstWhere(
      (h) => h['id'] == hadithId,
      orElse: () => null,
    );
    
    return hadith != null ? Map<String, dynamic>.from(hadith) : null;
  }

  /// Get hadith by number in book
  static Future<Map<String, dynamic>?> getHadithByNumber(
    String bookId,
    int hadithNumber,
  ) async {
    final book = await getBook(bookId);
    final hadiths = book['hadiths'] as List?;
    if (hadiths == null) return null;
    
    final hadith = hadiths.firstWhere(
      (h) => h['idInBook'] == hadithNumber,
      orElse: () => null,
    );
    
    return hadith != null ? Map<String, dynamic>.from(hadith) : null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORTIES COLLECTIONS (ALWAYS OFFLINE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get 40 Nawawi hadiths
  static Future<List<Map<String, dynamic>>> get40Nawawi() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/hadith/40_nawawi.json',
      );
      final data = jsonDecode(jsonString);
      if (data is List) {
        return data.map((h) => Map<String, dynamic>.from(h)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH (OFFLINE IN ASSETS)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search hadiths in a specific book
  static Future<List<Map<String, dynamic>>> searchInBook(
    String bookId,
    String query, {
    bool searchArabic = true,
    bool searchEnglish = true,
    int limit = 50,
  }) async {
    if (query.isEmpty) return [];
    
    final book = await getBook(bookId);
    final hadiths = book['hadiths'] as List?;
    if (hadiths == null) return [];
    
    final queryLower = query.toLowerCase();
    final results = <Map<String, dynamic>>[];
    
    for (final hadith in hadiths) {
      if (results.length >= limit) break;
      
      bool matches = false;
      
      if (searchArabic) {
        final arabicText = hadith['arabic']?.toString() ?? '';
        if (arabicText.contains(query)) {
          matches = true;
        }
      }
      
      if (!matches && searchEnglish) {
        final englishText = hadith['english']?['text']?.toString().toLowerCase() ?? '';
        final narrator = hadith['english']?['narrator']?.toString().toLowerCase() ?? '';
        if (englishText.contains(queryLower) || narrator.contains(queryLower)) {
          matches = true;
        }
      }
      
      if (matches) {
        results.add({
          ...Map<String, dynamic>.from(hadith),
          'bookId': bookId,
          'bookName': majorBooks[bookId]?.arabicName ?? bookId,
        });
      }
    }
    
    return results;
  }

  /// Search across all books
  static Future<List<Map<String, dynamic>>> searchAllBooks(
    String query, {
    bool searchArabic = true,
    bool searchEnglish = true,
    int limit = 100,
  }) async {
    if (query.isEmpty) return [];
    
    final results = <Map<String, dynamic>>[];
    
    for (final bookId in majorBooks.keys) {
      if (results.length >= limit) break;
      
      final remaining = limit - results.length;
      final bookResults = await searchInBook(
        bookId,
        query,
        searchArabic: searchArabic,
        searchEnglish: searchEnglish,
        limit: remaining,
      );
      
      results.addAll(bookResults);
    }
    
    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAVORITES & BOOKMARKS (HIVE CACHE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Add hadith to favorites
  static Future<void> addToFavorites(String bookId, int hadithId) async {
    final favorites = await getFavorites();
    final key = '$bookId:$hadithId';
    if (!favorites.contains(key)) {
      favorites.add(key);
      await _cacheBox?.put('favorites', favorites);
    }
  }

  /// Remove hadith from favorites
  static Future<void> removeFromFavorites(String bookId, int hadithId) async {
    final favorites = await getFavorites();
    favorites.remove('$bookId:$hadithId');
    await _cacheBox?.put('favorites', favorites);
  }

  /// Check if hadith is favorited
  static Future<bool> isFavorite(String bookId, int hadithId) async {
    final favorites = await getFavorites();
    return favorites.contains('$bookId:$hadithId');
  }

  /// Get all favorites
  static Future<List<String>> getFavorites() async {
    final stored = _cacheBox?.get('favorites');
    if (stored is List) {
      return stored.cast<String>();
    }
    return [];
  }

  /// Get favorite hadiths with full data
  static Future<List<Map<String, dynamic>>> getFavoriteHadiths() async {
    final favorites = await getFavorites();
    final results = <Map<String, dynamic>>[];
    
    for (final key in favorites) {
      final parts = key.split(':');
      if (parts.length == 2) {
        final hadith = await getHadith(parts[0], int.tryParse(parts[1]) ?? 0);
        if (hadith != null) {
          results.add({
            ...hadith,
            'bookId': parts[0],
            'bookName': majorBooks[parts[0]]?.arabicName ?? parts[0],
          });
        }
      }
    }
    
    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get random hadith
  static Future<Map<String, dynamic>?> getRandomHadith({String? bookId}) async {
    final targetBook = bookId ?? 'bukhari';
    final book = await getBook(targetBook);
    final hadiths = book['hadiths'] as List?;
    if (hadiths == null || hadiths.isEmpty) return null;
    
    final index = DateTime.now().millisecondsSinceEpoch % hadiths.length;
    return {
      ...Map<String, dynamic>.from(hadiths[index]),
      'bookId': targetBook,
      'bookName': majorBooks[targetBook]?.arabicName ?? targetBook,
    };
  }

  /// Get daily hadith (same for entire day)
  static Future<Map<String, dynamic>?> getDailyHadith() async {
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    
    // Rotate through Bukhari
    final book = await getBook('bukhari');
    final hadiths = book['hadiths'] as List?;
    if (hadiths == null || hadiths.isEmpty) return null;
    
    final index = dayOfYear % hadiths.length;
    return {
      ...Map<String, dynamic>.from(hadiths[index]),
      'bookId': 'bukhari',
      'bookName': 'صحيح البخاري',
    };
  }

  /// Clear cache
  static Future<void> clearCache() async {
    await _cacheBox?.clear();
    _booksInMemory = null;
  }

  /// Check if hadith data is loaded
  static bool get isLoaded => _booksInMemory != null && _booksInMemory!.isNotEmpty;

  /// Get total hadith count across all books
  static int get totalHadithCount {
    return majorBooks.values.fold(0, (sum, book) => sum + book.hadithCount);
  }
}

/// Hadith book info
class HadithBookInfo {
  final String id;
  final String arabicName;
  final String englishName;
  final String author;
  final int hadithCount;

  const HadithBookInfo({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.author,
    required this.hadithCount,
  });
}

/// Hadith data exception
class HadithDataException implements Exception {
  final String message;
  HadithDataException(this.message);

  @override
  String toString() => 'HadithDataException: $message';
}
