import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_datasources.dart';
import '../../../../core/domain/policies/offline_policy.dart';

/// تنفيذ مستودع القرآن - Quran Repository Implementation
class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalDataSource localDataSource;
  final QuranRemoteDataSource remoteDataSource;
  final OfflinePolicy offlinePolicy;

  QuranRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.offlinePolicy,
  });

  @override
  Future<Either<Failure, List<Surah>>> getAllSurahs() async {
    try {
      // Offline-first: Always try local first
      final localSurahs = await localDataSource.getAllSurahs();
      if (localSurahs.isNotEmpty) {
        return Right(localSurahs);
      }

      // If local is empty and we don't need network, return empty
      if (offlinePolicy.requiresNetwork(FeatureType.quranReading)) {
        return const Left(CacheFailure('لا توجد بيانات محلية'));
      }

      // Try remote
      final remoteSurahs = await remoteDataSource.fetchAllSurahs();
      await localDataSource.cacheQuranData(remoteSurahs);
      return Right(remoteSurahs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Surah>> getSurahWithVerses(int surahNumber) async {
    try {
      final surah = await localDataSource.getSurahWithVerses(surahNumber);
      return Right(surah);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Verse>>> getVersesByPage(int pageNumber) async {
    try {
      final verses = await localDataSource.getVersesByPage(pageNumber);
      return Right(verses);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Verse>>> getVersesByJuz(int juzNumber) async {
    // TODO: Implement
    return const Right([]);
  }

  @override
  Future<Either<Failure, Tafsir>> getTafsir({
    required int surahNumber,
    required int verseNumber,
    String? tafsirSource,
  }) async {
    try {
      // Try local first
      final localTafsir = await localDataSource.getTafsir(surahNumber, verseNumber);
      if (localTafsir != null) {
        return Right(localTafsir);
      }

      // Try remote if allowed
      if (!offlinePolicy.requiresNetwork(FeatureType.tafsir)) {
        return const Left(CacheFailure('التفسير غير متوفر محلياً'));
      }

      final remoteTafsir = await remoteDataSource.fetchTafsir(
        surahNumber,
        verseNumber,
        tafsirSource ?? 'ibn_kathir',
      );
      return Right(remoteTafsir);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RevelationCause?>> getRevelationCause({
    required int surahNumber,
    required int verseNumber,
  }) async {
    try {
      final localCause = await localDataSource.getRevelationCause(surahNumber, verseNumber);
      if (localCause != null) {
        return Right(localCause);
      }

      final remoteCause = await remoteDataSource.fetchRevelationCause(surahNumber, verseNumber);
      return Right(remoteCause);
    } catch (e) {
      return Right(null); // Revelation cause is optional
    }
  }

  @override
  Future<Either<Failure, void>> saveReadingProgress({
    required int surahNumber,
    required int verseNumber,
    required int page,
  }) async {
    try {
      final box = await Hive.openBox('reading_progress');
      await box.put('last_position', {
        'surah_number': surahNumber,
        'verse_number': verseNumber,
        'page': page,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ({int surahNumber, int verseNumber, int page})>>
      getLastReadingPosition() async {
    try {
      final box = await Hive.openBox('reading_progress');
      final data = box.get('last_position') as Map<dynamic, dynamic>?;
      if (data == null) {
        return const Right((surahNumber: 1, verseNumber: 1, page: 1));
      }
      return Right((
        surahNumber: data['surah_number'] as int,
        verseNumber: data['verse_number'] as int,
        page: data['page'] as int,
      ));
    } catch (e) {
      return const Right((surahNumber: 1, verseNumber: 1, page: 1));
    }
  }

  @override
  Future<Either<Failure, List<Verse>>> searchQuran(String query) async {
    try {
      final results = await localDataSource.searchQuran(query);
      return Right(results);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
