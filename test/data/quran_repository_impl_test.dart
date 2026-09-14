import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/domain/policies/offline_policy.dart';
import 'package:noor_app/features/quran/data/datasources/quran_datasources.dart';
import 'package:noor_app/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:noor_app/features/quran/domain/repositories/quran_repository.dart';

class FakeLocal implements QuranLocalDataSource {
  FakeLocal({this.surahs = const [], this.tafsir});
  final List<SurahModel> surahs;
  final TafsirModel? tafsir;
  int cacheCalls = 0;

  @override
  Future<List<SurahModel>> getAllSurahs() async => surahs;
  @override
  Future<SurahModel> getSurahWithVerses(int n) async => surahs.first;
  @override
  Future<List<VerseModel>> getVersesByPage(int p) async => [];
  @override
  Future<TafsirModel?> getTafsir(int s, int v) async => tafsir;
  @override
  Future<RevelationCauseModel?> getRevelationCause(int s, int v) async => null;
  @override
  Future<List<VerseModel>> searchQuran(String q) async => [];
  @override
  Future<void> cacheQuranData(List<SurahModel> s) async {
    cacheCalls++;
  }
}

class FakeRemote implements QuranRemoteDataSource {
  int fetchCalls = 0;

  @override
  Future<List<SurahModel>> fetchAllSurahs() async {
    fetchCalls++;
    return [];
  }

  @override
  Future<TafsirModel> fetchTafsir(int s, int v, String source) async =>
      throw UnimplementedError();
  @override
  Future<RevelationCauseModel?> fetchRevelationCause(int s, int v) async =>
      null;
  @override
  Future<void> syncQuranData() async {}
}

class FakePolicy implements OfflinePolicy {
  FakePolicy({required this.networkNeeded});
  final bool networkNeeded;

  @override
  bool requiresNetwork(FeatureType feature) => networkNeeded;

  @override
  Future<T?> getCachedData<T>(String key) async => null;

  @override
  Future<void> cacheData<T>(String key, T data) async {}

  @override
  bool isCacheStale(String key, Duration maxAge) => true;

  @override
  bool get isOfflineFirst => true;
}

SurahModel surah() => SurahModel.fromJson(const {
      'number': 1,
      'name': 'الفاتحة',
      'englishName': 'Al-Fatiha',
      'numberOfAyahs': 7,
      'revelationType': 'makki',
    });

/// QuranRepositoryImpl (previously 13%): offline-first branching with fake
/// data sources + a temp Hive box for reading progress. Plain tests.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_quran_repo_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('non-empty local wins without touching remote', () async {
    final local = FakeLocal(surahs: [surah()]);
    final remote = FakeRemote();
    final repo = QuranRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      offlinePolicy: FakePolicy(networkNeeded: false),
    );
    final result = await repo.getAllSurahs();
    expect(result.isRight(), isTrue);
    expect(remote.fetchCalls, 0);
    expect(local.cacheCalls, 0);
  });

  test('empty local + network required returns CacheFailure', () async {
    final repo = QuranRepositoryImpl(
      localDataSource: FakeLocal(),
      remoteDataSource: FakeRemote(),
      offlinePolicy: FakePolicy(networkNeeded: true),
    );
    final result = await repo.getAllSurahs();
    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<CacheFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('empty local + network allowed fetches remote and caches', () async {
    final local = FakeLocal();
    final remote = FakeRemote();
    final repo = QuranRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      offlinePolicy: FakePolicy(networkNeeded: false),
    );
    final result = await repo.getAllSurahs();
    expect(result.isRight(), isTrue);
    expect(remote.fetchCalls, 1);
    expect(local.cacheCalls, 1);
  });

  test('tafsir prefers local, denies offline miss in Arabic', () async {
    final tafsir = TafsirModel.fromJson(const {
      'surah_number': 1,
      'verse_number': 1,
      'brief_text': 'موجز',
      'source': 'muyassar',
      'author': 'م',
    });
    final hitRepo = QuranRepositoryImpl(
      localDataSource: FakeLocal(tafsir: tafsir),
      remoteDataSource: FakeRemote(),
      offlinePolicy: FakePolicy(networkNeeded: true),
    );
    final hit = await hitRepo.getTafsir(surahNumber: 1, verseNumber: 1);
    expect(hit.isRight(), isTrue);

    final missRepo = QuranRepositoryImpl(
      localDataSource: FakeLocal(),
      remoteDataSource: FakeRemote(),
      offlinePolicy: FakePolicy(networkNeeded: false),
    );
    final miss = await missRepo.getTafsir(surahNumber: 1, verseNumber: 1);
    expect(miss.isLeft(), isTrue);
    miss.fold(
      (failure) => expect(
        (failure as CacheFailure).message,
        'التفسير غير متوفر محلياً',
      ),
      (_) => fail('expected Left'),
    );
  });

  test('reading progress defaults to 1:1:1 then round-trips', () async {
    final repo = QuranRepositoryImpl(
      localDataSource: FakeLocal(),
      remoteDataSource: FakeRemote(),
      offlinePolicy: FakePolicy(networkNeeded: false),
    );
    final fresh = await repo.getLastReadingPosition();
    fresh.fold(
      (_) => fail('expected Right'),
      (pos) => expect(
        (pos.surahNumber, pos.verseNumber, pos.page),
        (1, 1, 1),
      ),
    );
    final saved = await repo.saveReadingProgress(
      surahNumber: 2,
      verseNumber: 255,
      page: 42,
    );
    expect(saved.isRight(), isTrue);
    final back = await repo.getLastReadingPosition();
    back.fold(
      (_) => fail('expected Right'),
      (pos) => expect(
        (pos.surahNumber, pos.verseNumber, pos.page),
        (2, 255, 42),
      ),
    );
  });
}
