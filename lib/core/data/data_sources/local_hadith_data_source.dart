import 'package:flutter/foundation.dart';

import '../../domain/entities/hadith.dart';
import 'hadith_database.dart';

/// SQLite-backed Hadith Data Source
/// Replaces the old JSON-in-memory approach with instant SQLite queries.
class LocalHadithDataSource {
  /// Initialize the database (call on app startup)
  Future<void> init() async {
    await HadithDatabase.database; // Triggers creation if needed
  }

  /// Get all collections from the database
  Future<List<HadithCollection>> getCollections() async {
    final rows = await HadithDatabase.getCollections();
    return rows.map((r) => HadithCollection(
      id: r['id'] as String,
      titleArabic: r['title_arabic'] as String,
      titleEnglish: r['title_english'] as String? ?? '',
      hadithsCount: r['hadith_count'] as int? ?? 0,
      author: r['author_arabic'] as String? ?? '',
    )).toList();
  }

  /// Load a "book" - now just fetches metadata + chapters + first batch
  Future<HadithBook> loadBook(String bookId) async {
    final chapters = await getChapters(bookId);
    final collectionsRows = await HadithDatabase.getCollections();
    final collRow = collectionsRows.firstWhere(
      (r) => r['id'] == bookId,
      orElse: () => {'title_arabic': bookId, 'author_arabic': '', 'introduction': ''},
    );

    // Get ALL hadiths for this book (for compatibility with existing reader)
    final hadithRows = await HadithDatabase.getHadiths(
      collectionId: bookId,
      limit: 100000, // Effectively "all"
    );

    final hadiths = hadithRows.map((h) => Hadith(
      id: h['id'] as int,
      idInBook: h['id_in_book'] as int? ?? h['id'] as int,
      arabic: h['arabic'] as String,
      englishText: h['english_text'] as String? ?? '',
      narratorEnglish: h['english_narrator'] as String? ?? '',
      chapterId: h['chapter_id'] as int? ?? 0,
      bookId: null,
      collectionId: bookId,
    )).toList();

    return HadithBook(
      id: bookId,
      metadata: BookMetadata(
        title: collRow['title_arabic'] as String? ?? bookId,
        author: collRow['author_arabic'] as String? ?? '',
        introduction: collRow['introduction'] as String? ?? '',
      ),
      chapters: chapters,
      hadiths: hadiths,
    );
  }

  /// Get chapters for a collection
  Future<List<HadithChapter>> getChapters(String bookId) async {
    final rows = await HadithDatabase.getChapters(bookId);
    return rows.map((c) => HadithChapter(
      id: c['id'] as int,
      bookId: bookId,
      topicArabic: c['title_arabic'] as String,
      topicEnglish: c['title_english'] as String? ?? '',
    )).toList();
  }

  /// Paginated hadiths from SQLite
  Future<List<Hadith>> getHadithsPage({
    required String bookId,
    required int page,
    required int limit,
    int? chapterId,
  }) async {
    final offset = (page - 1) * limit;
    final rows = await HadithDatabase.getHadiths(
      collectionId: bookId,
      chapterId: chapterId,
      limit: limit,
      offset: offset,
    );
    return rows.map((h) => Hadith(
      id: h['id'] as int,
      idInBook: h['id_in_book'] as int? ?? h['id'] as int,
      arabic: h['arabic'] as String,
      englishText: h['english_text'] as String? ?? '',
      narratorEnglish: h['english_narrator'] as String? ?? '',
      chapterId: h['chapter_id'] as int? ?? 0,
      bookId: null,
      collectionId: bookId,
    )).toList();
  }

  /// Search within a book or across all books
  Future<List<Hadith>> searchHadiths(String query, {String? bookId}) async {
    final rows = await HadithDatabase.search(query, collectionId: bookId);
    return rows.map((h) => Hadith(
      id: h['id'] as int,
      idInBook: h['id_in_book'] as int? ?? h['id'] as int,
      arabic: h['arabic'] as String,
      englishText: h['english_text'] as String? ?? '',
      narratorEnglish: h['english_narrator'] as String? ?? '',
      chapterId: h['chapter_id'] as int? ?? 0,
      bookId: null,
      collectionId: h['collection_id'] as String? ?? bookId,
    )).toList();
  }

  /// Search by narrator
  Future<List<Hadith>> searchByNarrator(String narrator) async {
    final rows = await HadithDatabase.searchByNarrator(narrator);
    return rows.map((h) => Hadith(
      id: h['id'] as int,
      idInBook: h['id_in_book'] as int? ?? h['id'] as int,
      arabic: h['arabic'] as String,
      englishText: h['english_text'] as String? ?? '',
      narratorEnglish: h['english_narrator'] as String? ?? '',
      chapterId: h['chapter_id'] as int? ?? 0,
      bookId: null,
      collectionId: h['collection_id'] as String?,
    )).toList();
  }

  /// Get a random hadith (Hadith of the Day)
  Future<Hadith?> getRandomHadith() async {
    final row = await HadithDatabase.getRandomHadith();
    if (row == null) return null;
    return Hadith(
      id: row['id'] as int,
      idInBook: row['id_in_book'] as int? ?? row['id'] as int,
      arabic: row['arabic'] as String,
      englishText: row['english_text'] as String? ?? '',
      narratorEnglish: row['english_narrator'] as String? ?? '',
      chapterId: row['chapter_id'] as int? ?? 0,
      bookId: null,
      collectionId: row['collection_id'] as String?,
    );
  }

  /// Get chapter hadith counts
  Future<Map<int, int>> getChapterHadithCounts(String bookId) async {
    return HadithDatabase.getChapterHadithCounts(bookId);
  }
}
