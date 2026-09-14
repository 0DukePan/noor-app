import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/utils/arabic_text.dart';
import 'package:noor_app/features/quran/data/datasources/local_quran_data_source.dart';

/// LocalQuranDataSourceImpl (previously 9% incidental): real bundled assets
/// through IsolateParser (verified isolate-safe under flutter_test).
/// Plain tests; static caches persist per file, which the cache test uses.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dataSource = LocalQuranDataSourceImpl();

  test('getAllSurahs returns all 114 with Fatiha first', () async {
    final surahs = await dataSource.getAllSurahs();
    expect(surahs, hasLength(114));
    expect(surahs.first.number, 1);
    // normalizeArabic maps ة→ه, so match the normalized spelling.
    expect(normalizeArabic(surahs.first.nameArabic), contains('الفاتحه'));
    expect(surahs.first.versesCount, 7);
  });

  test('getSurahWithVerses loads Fatiha fully and caches it', () async {
    final first = await dataSource.getSurahWithVerses(1);
    expect(first.number, 1);
    expect(first.verses, hasLength(7));
    expect(first.verses.first.textUthmani, isNotEmpty);
    final second = await dataSource.getSurahWithVerses(1);
    expect(identical(second, first), isTrue);
  });

  test('getVersesByPage returns page 1, empty for unknown pages', () async {
    final page = await dataSource.getVersesByPage(1);
    expect(page, isNotEmpty);
    expect(page.every((v) => v.page == 1), isTrue);
    expect(page.every((v) => v.textUthmani.isNotEmpty), isTrue);
    expect(await dataSource.getVersesByPage(99999), isEmpty);
  });

  test('getPageForAyah maps verse 1:1 to page 1, null when unknown', () async {
    expect(await dataSource.getPageForAyah(1, 1), 1);
    expect(await dataSource.getPageForAyah(999, 999), isNull);
  });

  test('searchQuran is diacritic-insensitive, empty query is empty', () async {
    final hits = await dataSource.searchQuran('الرحمن');
    expect(hits, isNotEmpty);
    expect(await dataSource.searchQuran('   '), isEmpty);
  });

  test('tafsir/cause stubs stay null; cache is a safe no-op', () async {
    expect(await dataSource.getTafsir(1, 1), isNull);
    expect(await dataSource.getRevelationCause(1, 1), isNull);
    await dataSource.cacheQuranData([]);
  });
}
