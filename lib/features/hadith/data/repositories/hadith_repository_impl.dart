import 'package:dartz/dartz.dart';

import '../../domain/entities/hadith_entities.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../datasources/hadith_datasources.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

/// تنفيذ مستودع الحديث - Hadith Repository Implementation
class HadithRepositoryImpl implements HadithRepository {
  final HadithLocalDataSource localDataSource;
  final HadithRemoteDataSource remoteDataSource;

  HadithRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<HadithCategory>>> getCategories() async {
    try {
      // Try local first
      final localCategories = await localDataSource.getCategories();
      if (localCategories.isNotEmpty) {
        return Right(localCategories);
      }

      // Fallback to remote
      final remoteCategories = await remoteDataSource.fetchCategories();
      return Right(remoteCategories);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Hadith>>> getHadithsByCategory(String categoryId) async {
    try {
      // Try local first
      final localHadiths = await localDataSource.getHadithsByCategory(categoryId);
      if (localHadiths.isNotEmpty) {
        return Right(localHadiths);
      }

      // Fallback to remote and cache
      final remoteHadiths = await remoteDataSource.fetchHadithsByCategory(categoryId);
      await localDataSource.cacheHadiths(categoryId, remoteHadiths);
      return Right(remoteHadiths);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Hadith>> getHadithById(String id) async {
    try {
      final hadith = await localDataSource.getHadithById(id);
      if (hadith != null) {
        return Right(hadith);
      }
      return const Left(CacheFailure('Hadith not found'));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HadithExplanation?>> getHadithExplanation(String hadithId) async {
    try {
      final explanation = await remoteDataSource.fetchHadithExplanation(hadithId);
      return Right(explanation);
    } catch (e) {
      return Right(null); // Explanation is optional
    }
  }

  @override
  Future<Either<Failure, List<Hadith>>> searchHadiths(String query) async {
    try {
      final results = await localDataSource.searchHadiths(query);
      return Right(results);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Hadith>>> getHadithsByGrade(HadithGrade grade) async {
    try {
      // This would normally filter from database
      return const Right([]);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Hadith>>> getFeaturedHadiths({int limit = 5}) async {
    try {
      // Return featured hadiths for home screen
      return const Right([]);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> bookmarkHadith(String hadithId) async {
    try {
      await localDataSource.toggleBookmark(hadithId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Hadith>>> getBookmarkedHadiths() async {
    try {
      final bookmarkedIds = await localDataSource.getBookmarkedHadithIds();
      final hadiths = <Hadith>[];
      for (final id in bookmarkedIds) {
        final hadith = await localDataSource.getHadithById(id);
        if (hadith != null) hadiths.add(hadith);
      }
      return Right(hadiths);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeBookmark(String hadithId) async {
    try {
      await localDataSource.toggleBookmark(hadithId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
