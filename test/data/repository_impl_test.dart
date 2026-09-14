import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/data/data_sources/local_tafsir_data_source.dart';
import 'package:noor_app/core/data/repositories/tafsir_repository_impl.dart';
import 'package:noor_app/core/domain/entities/tafsir.dart';
import 'package:noor_app/features/search/data/data_sources/search_local_data_source.dart';
import 'package:noor_app/features/search/data/repositories/search_repository_impl.dart';
import 'package:sqflite/sqflite.dart';

/// Tests for the thin repository implementations using fake data sources.
void main() {
  group('SearchRepositoryImpl', () {
    test('maps indexed rows to SearchResult (original text + metadata)',
        () async {
      final rows = [
        {
          'text': 'normalized',
          'source': 'quran',
          'reference':
              jsonEncode({'surah': 1, 'verse': 1, 'original': 'النص الأصلي'}),
        },
        {
          'text': 'بدون أصل',
          'source': 'hadith',
          'reference': jsonEncode({'book': 'bukhari', 'id': 42}),
        },
      ];
      final repo = SearchRepositoryImpl(_FakeSearchDataSource(rows));

      final results = await repo.search('query');
      expect(results.length, 2);

      // Uses the diacritized original text from the reference when present.
      expect(results[0].text, 'النص الأصلي');
      expect(results[0].source, 'quran');
      expect(results[0].metadata['surah'], 1);
      expect(results[0].metadata['verse'], 1);

      // Falls back to the row text when the reference has no 'original'.
      expect(results[1].text, 'بدون أصل');
      expect(results[1].source, 'hadith');
      expect(results[1].metadata['book'], 'bukhari');
    });

    test('initializeIndex delegates to the data source', () async {
      final ds = _FakeSearchDataSource([]);
      await SearchRepositoryImpl(ds).initializeIndex();
      expect(ds.ensureIndexedCalled, isTrue);
    });
  });

  group('TafsirRepositoryImpl', () {
    test('getTafsir delegates with the mapped book id', () async {
      final fake = _FakeTafsirDataSource();
      final repo = TafsirRepositoryImpl(fake);

      final t = await repo.getTafsir(2, 255, source: 'saadi');
      expect(fake.lastBookId, 'saadi');
      expect(t, isNotNull);
      expect(t!.surahId, 2);
      expect(t.verseId, 255);
      expect(t.source, 'saadi');
    });

    test('getAvailableSources returns the four bundled book ids', () async {
      final repo = TafsirRepositoryImpl(_FakeTafsirDataSource());
      expect(
        await repo.getAvailableSources(),
        ['muyassar', 'ibn_kathir', 'saadi', 'tabari'],
      );
    });
  });
}

class _FakeSearchDataSource extends SearchLocalDataSource {
  _FakeSearchDataSource(this.rows);
  final List<Map<String, dynamic>> rows;
  bool ensureIndexedCalled = false;

  @override
  Future<void> ensureIndexed(
    List<String> quranPaths,
    List<String> hadithPaths, {
    Database? hadithDb,
  }) async {
    ensureIndexedCalled = true;
  }

  @override
  Future<List<Map<String, dynamic>>> search(String query) async => rows;
}

class _FakeTafsirDataSource extends LocalTafsirDataSource {
  String? lastBookId;

  @override
  Future<TafsirVerse?> getTafsir({
    required int surahId,
    required int verseId,
    String bookId = 'muyassar',
  }) async {
    lastBookId = bookId;
    return TafsirVerse(
      surahId: surahId,
      verseId: verseId,
      text: 'نص',
      source: bookId,
    );
  }
}
