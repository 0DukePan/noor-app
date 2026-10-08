import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/features/quran/data/mushaf_token_codec.dart';
import 'package:noor_app/features/quran/domain/entities/mushaf.dart';

/// Content + generator contract (Phase 1 exit):
/// approved source has exactly 114 surahs / 6,236 ayahs; the token map has
/// pages 1..604 with every canonical identity exactly once; no invalid or
/// empty tokens; basmala appears exactly once where approved, never at
/// At-Tawbah; the generator is deterministic.
void main() {
  late Map<String, dynamic> pagesMap;
  late Map<String, dynamic> canonicalMap;

  setUpAll(() {
    pagesMap =
        jsonDecode(File('assets/quran/quran_pages.json').readAsStringSync())
            as Map<String, dynamic>;
    canonicalMap =
        jsonDecode(File('assets/quran/quran_uthmani.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  test('canonical source has 114 surahs and 6236 non-empty ayahs', () {
    expect(canonicalMap.keys, hasLength(114));
    var total = 0;
    for (final verses in canonicalMap.values) {
      for (final v in (verses as List)) {
        final text = ((v as Map)['text'] as String?) ?? '';
        expect(text.trim(), isNotEmpty);
        total++;
      }
    }
    expect(total, 6236);
  });

  test('token build covers 604 pages and every identity exactly once', () {
    final build = buildMushafTokens(
      pagesMap: pagesMap,
      canonicalMap: canonicalMap,
    );
    expect(build.report.pageCount, 604);
    expect(build.report.uniqueIdentities, 6236);
    expect(build.report.entryCount, 6236);
    expect(build.pages.keys, hasLength(604));

    for (var page = 1; page <= 604; page++) {
      expect(
        build.pages.containsKey(page.toString()),
        isTrue,
        reason: 'missing page $page',
      );
    }
  });

  test('tokens carry no invalid or empty Quran text', () {
    final build = buildMushafTokens(
      pagesMap: pagesMap,
      canonicalMap: canonicalMap,
    );
    const contentKinds = {'basmala', 'quranText'};
    for (final entry in build.pages.entries) {
      for (final rawToken in entry.value.tokens) {
        final token = rawToken;
        final kind = token['kind'] as String?;
        expect(kind, isNotNull, reason: 'page ${entry.key}');
        expect(
          const {
            'surahHeading',
            'basmala',
            'quranText',
            'ayahEnd',
            'sajdah',
            'metadata',
            'spacing',
          }.contains(kind),
          isTrue,
          reason: 'page ${entry.key} kind=$kind',
        );
        if (contentKinds.contains(kind)) {
          final text = token['text'] as String?;
          expect(text, isNotNull, reason: 'page ${entry.key}');
          expect(text!.trim(), isNotEmpty, reason: 'page ${entry.key}');
        }
      }
    }
  });

  test('basmala appears once per approved surah start, never at At-Tawbah', () {
    final build = buildMushafTokens(
      pagesMap: pagesMap,
      canonicalMap: canonicalMap,
    );
    var basmalaTokens = 0;
    var tawbahBasmala = 0;
    var fatihaBasmala = 0;
    for (final page in build.pages.values) {
      var pendingSurah = 0;
      for (final rawToken in page.tokens) {
        final token = rawToken;
        if (token['kind'] == 'surahHeading') {
          pendingSurah = (token['surah'] as int?) ?? 0;
        }
        if (token['kind'] == 'basmala') {
          basmalaTokens++;
          if (pendingSurah == 9) tawbahBasmala++;
          if (pendingSurah == 1) fatihaBasmala++;
        }
        if (token['kind'] == 'ayahEnd') pendingSurah = 0;
      }
    }
    // 24 clean splits + 88 embedded in full display text (anomalies) cover
    // all 112 approved surah starts exactly once; the widget adds none.
    expect(basmalaTokens, build.report.basmalaPages.length);
    expect(tawbahBasmala, 0);
    expect(fatihaBasmala, 0);
    expect(
      build.report.basmalaPages.length + build.report.anomalies.length,
      112,
    );
  });

  test('content tokens reconstruct the approved display text', () {
    final build = buildMushafTokens(
      pagesMap: pagesMap,
      canonicalMap: canonicalMap,
    );
    // Spot-check first, middle, and last pages.
    for (final pageKey in ['1', '2', '300', '604']) {
      final rawEntries = pagesMap[pageKey]! as List;
      final expected = rawEntries
          .map((e) => stripBom((e as Map)['text'] as String))
          .join();
      final tokens = build.pages[pageKey]!.tokens;
      final actual = tokens
          .where((t) => t['kind'] == 'quranText' || t['kind'] == 'basmala')
          .map((t) => t['text'] as String)
          .join();
      expect(actual, expected, reason: 'page $pageKey');
    }
  });

  test('generator output on disk matches a fresh deterministic build', () {
    final build = buildMushafTokens(
      pagesMap: pagesMap,
      canonicalMap: canonicalMap,
    );
    final onDisk =
        jsonDecode(File('assets/quran/mushaf_tokens.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(onDisk['schema'], 1);
    final pages = onDisk['pages'] as Map<String, dynamic>;
    expect(pages.keys, hasLength(604));
    // Report embedded in the artifact agrees with the fresh build.
    final report = onDisk['report'] as Map<String, dynamic>;
    expect(report['entries'], build.report.entryCount);
    expect(report['differences'], build.report.differences);
    expect(
      (onDisk['basmalaPages'] as List).length,
      build.report.basmalaPages.length,
    );
  });

  test('surah starts, transitions, and boundary pages are present', () {
    final build = buildMushafTokens(
      pagesMap: pagesMap,
      canonicalMap: canonicalMap,
    );
    // Page 1 opens Al-Fatihah; page 2 opens Al-Baqarah; page 604 closes
    // An-Nas (114:6).
    final page1Tokens = build.pages['1']!.tokens;
    expect(page1Tokens.first['kind'], 'surahHeading');
    expect(page1Tokens.first['surah'], 1);

    final page604Tokens = build.pages['604']!.tokens;
    final lastEnd = page604Tokens.lastWhere((t) => t['kind'] == 'ayahEnd');
    expect(lastEnd['surah'], 114);
    expect(lastEnd['ayah'], 6);
  });

  test('typed MushafPageModel resolves every page to verse rows', () {
    final tokensDoc =
        jsonDecode(File('assets/quran/mushaf_tokens.json').readAsStringSync())
            as Map<String, dynamic>;
    final pages = tokensDoc['pages'] as Map<String, dynamic>;
    var total = 0;
    final stopwatch = Stopwatch()..start();
    for (var page = 1; page <= 604; page++) {
      final model = MushafPageModel.fromJson(
        page.toString(),
        Map<String, dynamic>.from(pages[page.toString()] as Map),
      );
      expect(model.pageNumber, page);
      final rows = model.verses();
      expect(rows, isNotEmpty, reason: 'page $page');
      for (final row in rows) {
        expect(row.surah, inInclusiveRange(1, 114));
        expect(row.text.trim(), isNotEmpty);
      }
      total += rows.length;
    }
    stopwatch.stop();
    expect(total, 6236);
    // Full-corpus typed resolution stays comfortably interactive.
    expect(stopwatch.elapsedMilliseconds, lessThan(15000));
  });

  test('stored verse text carries no BOM or render-time joiners', () {
    // Copy/share output contract (Phase 1.6): U+FEFF is stripped by the
    // generator and U+2060 exists only inside renderer marker spans.
    final tokensDoc =
        jsonDecode(File('assets/quran/mushaf_tokens.json').readAsStringSync())
            as Map<String, dynamic>;
    final pages = tokensDoc['pages'] as Map<String, dynamic>;
    for (var page = 1; page <= 604; page++) {
      final model = MushafPageModel.fromJson(
        page.toString(),
        Map<String, dynamic>.from(pages[page.toString()] as Map),
      );
      for (final row in model.verses()) {
        expect(row.text.contains('\uFEFF'), isFalse, reason: 'page $page');
        expect(row.text.contains('\u2060'), isFalse, reason: 'page $page');
      }
    }
  });
}
