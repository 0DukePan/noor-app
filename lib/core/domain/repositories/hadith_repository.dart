import '../entities/hadith.dart';

abstract class HadithRepository {
  /// Gets all available Hadith collections (books metadata).
  Future<List<HadithCollection>> getCollections();

  /// Gets a specific book details including chapters.
  Future<HadithBook> getBook(String bookId);

  /// Gets a paginated list of hadiths from a specific book.
  Future<List<Hadith>> getHadiths(
    String bookId, {
    required int page,
    required int limit,
  });

  /// Searches for hadiths within a specific book.
  Future<List<Hadith>> searchHadiths(String query, String bookId);

  /// Gets chapters for a specific book.
  Future<List<HadithChapter>> getChapters(String bookId);
}
