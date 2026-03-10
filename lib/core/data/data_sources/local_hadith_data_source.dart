import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/entities/hadith.dart';
import '../../utils/isolate_parser.dart';

class LocalHadithDataSource {
  // In-memory cache for the currently active book to avoid re-parsing on every interaction
  final Map<String, HadithBook> _bookCache = {};

  /// Loads a specific book by ID (e.g., 'bukhari', 'muslim')
  /// Uses [IsolateParser] to prevent UI jank.
  Future<HadithBook> loadBook(String bookId) async {
    // 1. Check cache
    if (_bookCache.containsKey(bookId)) {
      return _bookCache[bookId]!;
    }

    // 2. Parse in background
    // Determine path based on bookId
    String path;
    if (bookId.contains('nawawi') || bookId.contains('qudsi') || bookId.contains('shah')) {
      path = 'assets/hadith/by_book/forties/$bookId.json';
    } else {
      path = 'assets/hadith/by_book/the_9_books/$bookId.json';
    }

    try {
      final book = await IsolateParser.parseInBackground(
        assetPath: path,
        parser: (jsonString) => _parseHadithBook(jsonString, bookId),
      );

      // 3. Update cache
      // Strategy: Clear other books to keep memory usage low (active book only)
      _bookCache.clear(); 
      _bookCache[bookId] = book;

      return book;
    } catch (e) {
      debugPrint('Error loading hadith book $bookId: $e');
      // Fallback or rethrow? Rethrow to handle in Repository.
      throw Exception('Failed to load book: $bookId');
    }
  }

  /// Helper to get paginated hadiths from the *already loaded* book.
  /// Should be called after [loadBook].
  List<Hadith> getHadithsPage({
    required String bookId,
    required int page,
    required int limit,
  }) {
    final book = _bookCache[bookId];
    if (book == null) {
      throw Exception('Book $bookId not loaded in cache. Call loadBook first.');
    }

    final start = (page - 1) * limit; // 1-based page
    if (start >= book.hadiths.length) return [];

    final end = start + limit;
    final actualEnd = end > book.hadiths.length ? book.hadiths.length : end;

    return book.hadiths.sublist(start, actualEnd);
  }

  /// Searches the *currently loaded* book.
  /// Since we only cache one book, this is fast enough in-memory.
  List<Hadith> searchInBook(String bookId, String query) {
     final book = _bookCache[bookId];
    if (book == null) return [];

    final q = query.toLowerCase();
    return book.hadiths.where((h) {
      return h.arabic.contains(query) || 
             h.englishText.toLowerCase().contains(q);
    }).toList();
  }

  // --- Parser Logic (Run in Isolate) ---

  static HadithBook _parseHadithBook(String jsonString, String bookId) {
    final Map<String, dynamic> json = jsonDecode(jsonString);

    // Map Metadata
    final metaJson = json['metadata'] as Map<String, dynamic>;
    final arabicMeta = metaJson['arabic'] as Map<String, dynamic>;
    // English meta might differ, but we focus on Arabic title usually
    
    final metadata = BookMetadata(
      title: arabicMeta['title'] ?? 'Unknown Book',
      author: arabicMeta['author'] ?? '',
      introduction: arabicMeta['introduction'] ?? '',
    );

    // Map Chapters
    final chaptersList = (json['chapters'] as List).cast<Map<String, dynamic>>();
    final chapters = chaptersList.map((c) => HadithChapter(
      id: c['id'] is int ? c['id'] : int.tryParse(c['id'].toString()) ?? 0,
      bookId: c['bookId'].toString(),
      topicArabic: c['arabic'] ?? '',
      topicEnglish: c['english'] ?? '',
    )).toList();

    // Map Hadiths
    final hadithsList = (json['hadiths'] as List).cast<Map<String, dynamic>>();
    final hadiths = hadithsList.map((h) {
      final textEng = (h['english'] as Map<String, dynamic>)['text'] ?? '';
      final narratorEng = (h['english'] as Map<String, dynamic>)['narrator'] ?? '';

      return Hadith(
        id: h['id'] ?? 0,
        idInBook: h['idInBook'] ?? 0,
        arabic: h['arabic'] ?? '',
        englishText: textEng,
        narratorEnglish: narratorEng,
        chapterId: h['chapterId'] ?? 0,
        bookId: h['bookId'],
      );
    }).toList();

    return HadithBook(
      id: bookId,
      metadata: metadata,
      chapters: chapters,
      hadiths: hadiths,
    );
  }
}
