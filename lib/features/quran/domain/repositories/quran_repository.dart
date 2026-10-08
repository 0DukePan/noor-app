import 'package:dartz/dartz.dart';
import '../entities/quran_entities.dart';

/// مستودع القرآن - Quran Repository Interface
abstract class QuranRepository {
  /// Get all Surahs metadata
  Future<Either<Failure, List<Surah>>> getAllSurahs();

  /// Get a specific Surah with all verses
  Future<Either<Failure, Surah>> getSurahWithVerses(int surahNumber);

  /// Get verses by page number
  Future<Either<Failure, List<Verse>>> getVersesByPage(int pageNumber);

  /// Get Tafsir for a verse
  Future<Either<Failure, Tafsir>> getTafsir({
    required int surahNumber,
    required int verseNumber,
    String? tafsirSource,
  });

  /// Get revelation cause for a verse
  Future<Either<Failure, RevelationCause?>> getRevelationCause({
    required int surahNumber,
    required int verseNumber,
  });

  /// Save reading progress
  Future<Either<Failure, void>> saveReadingProgress({
    required int surahNumber,
    required int verseNumber,
    required int page,
  });

  /// Get last reading position
  Future<Either<Failure, ({int surahNumber, int verseNumber, int page})>>
  getLastReadingPosition();

  /// Idempotent Qur'an bookmark (QUR-12): adding the same ayah twice stores
  /// exactly one row and never touches last-reading progress.
  Future<Either<Failure, void>> addBookmark({
    required int surahNumber,
    required int verseNumber,
  });

  /// Remove a Qur'an bookmark; missing rows are a no-op success.
  Future<Either<Failure, void>> removeBookmark({
    required int surahNumber,
    required int verseNumber,
  });

  /// True when the ayah is bookmarked.
  Future<Either<Failure, bool>> isBookmarked({
    required int surahNumber,
    required int verseNumber,
  });

  /// All Qur'an bookmarks, newest last.
  Future<Either<Failure, List<({int surahNumber, int verseNumber})>>>
  getBookmarks();

  /// Search in Quran
  Future<Either<Failure, List<Verse>>> searchQuran(String query);
}

/// مستودع التدبر - Tadabbur Repository Interface
abstract class TadabburRepository {
  /// Save personal reflection (encrypted)
  Future<Either<Failure, void>> saveTadabbur(Tadabbur tadabbur);

  /// Get reflections for a verse
  Future<Either<Failure, List<Tadabbur>>> getTadabburForVerse({
    required int surahNumber,
    required int verseNumber,
  });

  /// Get all reflections
  Future<Either<Failure, List<Tadabbur>>> getAllTadabbur();

  /// Delete reflection
  Future<Either<Failure, void>> deleteTadabbur(String id);

  /// Export reflections (optional)
  Future<Either<Failure, String>> exportTadabbur();
}

/// Failure class for error handling
abstract class Failure {
  const Failure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
