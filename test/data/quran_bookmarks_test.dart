import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/domain/policies/offline_policy.dart';
import 'package:noor_app/core/services/hive_box_registry.dart';
import 'package:noor_app/features/quran/data/datasources/local_quran_data_source.dart';
import 'package:noor_app/features/quran/data/datasources/remote_quran_data_source.dart';
import 'package:noor_app/features/quran/data/repositories/quran_repository_impl.dart';

/// QUR-12 contract: bookmarks and reading progress are separate typed
/// records. Adding the same ayah twice stores one bookmark and never touches
/// last-reading progress; removing then relaunching is stable.
void main() {
  late Directory tempDir;

  QuranRepositoryImpl makeRepo() => QuranRepositoryImpl(
    localDataSource: LocalQuranDataSourceImpl(),
    remoteDataSource: RemoteQuranDataSourceImpl(),
    offlinePolicy: DefaultOfflinePolicy(),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_quran_bm_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('duplicate add stores one bookmark; progress untouched', () async {
    final repo = makeRepo();

    await repo.saveReadingProgress(surahNumber: 2, verseNumber: 255, page: 42);

    final first = await repo.addBookmark(surahNumber: 36, verseNumber: 58);
    expect(first.isRight(), isTrue);
    final second = await repo.addBookmark(surahNumber: 36, verseNumber: 58);
    expect(second.isRight(), isTrue);

    final bookmarks = await repo.getBookmarks();
    final list = (bookmarks as Right).value as List;
    expect(list, hasLength(1));

    final marked = await repo.isBookmarked(surahNumber: 36, verseNumber: 58);
    expect((marked as Right).value, isTrue);
    final unmarked = await repo.isBookmarked(surahNumber: 36, verseNumber: 59);
    expect((unmarked as Right).value, isFalse);

    // Last-reading position is unchanged throughout bookmark churn.
    final pos = await repo.getLastReadingPosition();
    final record =
        (pos as Right).value as ({int page, int surahNumber, int verseNumber});
    expect(record.surahNumber, 2);
    expect(record.verseNumber, 255);
    expect(record.page, 42);
  });

  test(
    'remove deletes the bookmark and is a stable no-op when missing',
    () async {
      final repo = makeRepo();
      await repo.addBookmark(surahNumber: 1, verseNumber: 1);
      await repo.removeBookmark(surahNumber: 1, verseNumber: 1);
      final marked = await repo.isBookmarked(surahNumber: 1, verseNumber: 1);
      expect((marked as Right).value, isFalse);

      final again = await repo.removeBookmark(surahNumber: 1, verseNumber: 1);
      expect(again.isRight(), isTrue);

      final bookmarks = await repo.getBookmarks();
      expect(((bookmarks as Right).value) as List, isEmpty);
    },
  );

  test('progress and bookmarks use separate registry boxes', () async {
    final repo = makeRepo();
    await repo.saveReadingProgress(
      surahNumber: 18,
      verseNumber: 110,
      page: 304,
    );
    await repo.addBookmark(surahNumber: 18, verseNumber: 110);

    expect(Hive.isBoxOpen(HiveBoxes.readingProgress), isTrue);
    expect(Hive.isBoxOpen(HiveBoxes.bookmarks), isTrue);

    final progressBox = Hive.box<dynamic>(HiveBoxes.readingProgress);
    final bookmarkBox = Hive.box<dynamic>(HiveBoxes.bookmarks);
    expect(progressBox.get('last_position'), isNotNull);
    expect(bookmarkBox.containsKey('quran:18:110'), isTrue);
  });
}
