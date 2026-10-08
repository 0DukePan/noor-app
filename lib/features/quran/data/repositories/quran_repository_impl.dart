import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/domain/policies/offline_policy.dart';
import '../../../../core/services/hive_box_registry.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_datasources.dart';

/// تنفيذ مستودع القرآن - Quran Repository Implementation
class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.offlinePolicy,
  });
  final QuranLocalDataSource localDataSource;
  final QuranRemoteDataSource remoteDataSource;
  final OfflinePolicy offlinePolicy;

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
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Surah>> getSurahWithVerses(int surahNumber) async {
    try {
      final surah = await localDataSource.getSurahWithVerses(surahNumber);
      return Right(surah);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Verse>>> getVersesByPage(int pageNumber) async {
    try {
      final verses = await localDataSource.getVersesByPage(pageNumber);
      return Right(verses);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Tafsir>> getTafsir({
    required int surahNumber,
    required int verseNumber,
    String? tafsirSource,
  }) async {
    try {
      // Try local first
      final localTafsir = await localDataSource.getTafsir(
        surahNumber,
        verseNumber,
      );
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
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RevelationCause?>> getRevelationCause({
    required int surahNumber,
    required int verseNumber,
  }) async {
    try {
      final localCause = await localDataSource.getRevelationCause(
        surahNumber,
        verseNumber,
      );
      if (localCause != null) {
        return Right(localCause);
      }

      final remoteCause = await remoteDataSource.fetchRevelationCause(
        surahNumber,
        verseNumber,
      );
      return Right(remoteCause);
    } on Exception {
      return const Right(null); // Revelation cause is optional
    }
  }

  Future<Box<dynamic>> _progressBox() async {
    if (Hive.isBoxOpen(HiveBoxes.readingProgress)) {
      return Hive.box<dynamic>(HiveBoxes.readingProgress);
    }
    return Hive.openBox<dynamic>(HiveBoxes.readingProgress);
  }

  Future<Box<dynamic>> _bookmarkBox() async {
    if (Hive.isBoxOpen(HiveBoxes.bookmarks)) {
      return Hive.box<dynamic>(HiveBoxes.bookmarks);
    }
    return Hive.openBox<dynamic>(HiveBoxes.bookmarks);
  }

  static String _bookmarkKey(int surah, int ayah) => 'quran:$surah:$ayah';

  @override
  Future<Either<Failure, void>> saveReadingProgress({
    required int surahNumber,
    required int verseNumber,
    required int page,
  }) async {
    try {
      final box = await _progressBox();
      await box.put('last_position', {
        'surah_number': surahNumber,
        'verse_number': verseNumber,
        'page': page,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ({int surahNumber, int verseNumber, int page})>>
  getLastReadingPosition() async {
    try {
      final box = await _progressBox();
      final data = box.get('last_position') as Map<dynamic, dynamic>?;
      if (data == null) {
        return const Right((surahNumber: 1, verseNumber: 1, page: 1));
      }
      return Right((
        surahNumber: data['surah_number'] as int,
        verseNumber: data['verse_number'] as int,
        page: data['page'] as int,
      ));
    } on Exception {
      return const Right((surahNumber: 1, verseNumber: 1, page: 1));
    }
  }

  @override
  Future<Either<Failure, void>> addBookmark({
    required int surahNumber,
    required int verseNumber,
  }) async {
    try {
      final box = await _bookmarkBox();
      // Idempotent: the same key overwrites itself; no duplicate rows.
      await box.put(_bookmarkKey(surahNumber, verseNumber), {
        'type': 'quran',
        'surah': surahNumber,
        'ayah': verseNumber,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeBookmark({
    required int surahNumber,
    required int verseNumber,
  }) async {
    try {
      final box = await _bookmarkBox();
      await box.delete(_bookmarkKey(surahNumber, verseNumber));
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isBookmarked({
    required int surahNumber,
    required int verseNumber,
  }) async {
    try {
      final box = await _bookmarkBox();
      return Right(box.containsKey(_bookmarkKey(surahNumber, verseNumber)));
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<({int surahNumber, int verseNumber})>>>
  getBookmarks() async {
    try {
      final box = await _bookmarkBox();
      final out = <({int surahNumber, int verseNumber})>[];
      for (final value in box.values) {
        final map = value is Map
            ? Map<String, dynamic>.from(value)
            : <String, dynamic>{};
        if (map['type'] != 'quran') continue;
        final surah = map['surah'] as int?;
        final ayah = map['ayah'] as int?;
        if (surah == null || ayah == null) continue;
        out.add((surahNumber: surah, verseNumber: ayah));
      }
      return Right(out);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Verse>>> searchQuran(String query) async {
    try {
      final results = await localDataSource.searchQuran(query);
      return Right(results);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
