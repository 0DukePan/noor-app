import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/utils/verse_counts.dart';

/// Single canonical table (QUR-08/AUD-02): every boundary computation in the
/// app must agree with this table. Total must be 6,236 across 114 surahs.
void main() {
  test('table holds 114 surahs totalling 6236 ayahs', () {
    expect(kVerseCounts, hasLength(kTotalSurahs));
    expect(kVerseCounts.reduce((a, b) => a + b), kTotalAyahs);
    expect(kTotalAyahs, 6236);
    expect(kTotalPages, 604);
  });

  test('boundary surahs have known counts', () {
    expect(verseCountForSurah(1), 7);
    expect(verseCountForSurah(2), 286);
    expect(verseCountForSurah(9), 129);
    expect(verseCountForSurah(114), 6);
    expect(verseCountForSurah(0), 0);
    expect(verseCountForSurah(115), 0);
  });

  test('validity predicates agree with the table', () {
    expect(isValidSurah(1), isTrue);
    expect(isValidSurah(114), isTrue);
    expect(isValidSurah(0), isFalse);
    expect(isValidSurah(115), isFalse);

    expect(isValidAyah(1, 7), isTrue);
    expect(isValidAyah(1, 8), isFalse);
    expect(isValidAyah(114, 6), isTrue);
    expect(isValidAyah(114, 7), isFalse);
    expect(isValidAyah(0, 1), isFalse);

    expect(isValidPage(1), isTrue);
    expect(isValidPage(604), isTrue);
    expect(isValidPage(0), isFalse);
    expect(isValidPage(605), isFalse);
  });

  test('absolute numbering spans 1..6236 monotonically', () {
    expect(absoluteVerseNumber(1, 1), 1);
    expect(absoluteVerseNumber(114, 6), 6236);
    expect(absoluteVerseNumber(0, 1), -1);
    expect(absoluteVerseNumber(1, 8), -1);

    var previous = 0;
    for (var surah = 1; surah <= 114; surah++) {
      final start = absoluteVerseNumber(surah, 1);
      expect(start, greaterThan(previous));
      previous = start;
      expect(
        absoluteVerseNumber(surah, verseCountForSurah(surah)),
        start + verseCountForSurah(surah) - 1,
      );
    }
  });

  test('clampPage keeps paging inside 1..604', () {
    expect(clampPage(0), 1);
    expect(clampPage(-40), 1);
    expect(clampPage(605), 604);
    expect(clampPage(300), 300);
  });
}
