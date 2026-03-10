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

  /// Get verses by Juz
  Future<Either<Failure, List<Verse>>> getVersesByJuz(int juzNumber);

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

/// مستودع الختمة - Khatmah Repository Interface
abstract class KhatmahRepository {
  /// Create new Khatmah plan
  Future<Either<Failure, Khatmah>> createKhatmah({
    required String name,
    DateTime? targetEndDate,
  });

  /// Get active Khatmah
  Future<Either<Failure, Khatmah?>> getActiveKhatmah();

  /// Update Khatmah progress
  Future<Either<Failure, void>> updateKhatmahProgress({
    required String khatmahId,
    required int currentSurah,
    required int currentVerse,
    required int currentPage,
  });

  /// Get all Khatmahs
  Future<Either<Failure, List<Khatmah>>> getAllKhatmahs();

  /// Delete Khatmah
  Future<Either<Failure, void>> deleteKhatmah(String id);
}

/// Failure class for error handling
abstract class Failure {
  final String message;
  const Failure(this.message);
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
