import 'package:dartz/dartz.dart';
import '../entities/hadith_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

/// مستودع الحديث - Hadith Repository Interface
abstract class HadithRepository {
  /// Get all hadith categories
  Future<Either<Failure, List<HadithCategory>>> getCategories();

  /// Get hadiths by category
  Future<Either<Failure, List<Hadith>>> getHadithsByCategory(String categoryId);

  /// Get hadith by ID
  Future<Either<Failure, Hadith>> getHadithById(String id);

  /// Get hadith explanation
  Future<Either<Failure, HadithExplanation?>> getHadithExplanation(String hadithId);

  /// Search hadiths
  Future<Either<Failure, List<Hadith>>> searchHadiths(String query);

  /// Get hadiths by grade
  Future<Either<Failure, List<Hadith>>> getHadithsByGrade(HadithGrade grade);

  /// Get featured hadiths (for home screen)
  Future<Either<Failure, List<Hadith>>> getFeaturedHadiths({int limit = 5});

  /// Bookmark hadith
  Future<Either<Failure, void>> bookmarkHadith(String hadithId);

  /// Get bookmarked hadiths
  Future<Either<Failure, List<Hadith>>> getBookmarkedHadiths();

  /// Remove bookmark
  Future<Either<Failure, void>> removeBookmark(String hadithId);
}
