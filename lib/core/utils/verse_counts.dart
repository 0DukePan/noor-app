/// Canonical Qur'an structural constants.
///
/// Single source of truth for verse counts, page bounds, and surah bounds.
/// All audio advance/seek, route validation, Khatmah math, and page mapping
/// must use this table — never a second hard-coded copy.
library;

/// Verses per surah, index 0 == Surah 1. Total must be 6236.
const List<int> kVerseCounts = [
  7,
  286,
  200,
  176,
  120,
  165,
  206,
  75,
  129,
  109,
  123,
  111,
  43,
  52,
  99,
  128,
  111,
  110,
  98,
  135,
  112,
  78,
  118,
  64,
  77,
  227,
  93,
  88,
  69,
  60,
  34,
  30,
  73,
  54,
  45,
  83,
  182,
  88,
  75,
  85,
  54,
  53,
  89,
  59,
  37,
  35,
  38,
  29,
  18,
  45,
  60,
  49,
  62,
  55,
  78,
  96,
  29,
  22,
  24,
  13,
  14,
  11,
  11,
  18,
  12,
  12,
  30,
  52,
  52,
  44,
  28,
  28,
  20,
  56,
  40,
  31,
  50,
  40,
  46,
  42,
  29,
  19,
  36,
  25,
  22,
  17,
  19,
  26,
  30,
  20,
  15,
  21,
  11,
  8,
  8,
  19,
  5,
  8,
  8,
  11,
  11,
  8,
  3,
  9,
  5,
  4,
  7,
  3,
  6,
  3,
  5,
  4,
  5,
  6,
];

/// Total ayahs in the canonical Madani mushaf count.
const int kTotalAyahs = 6236;

/// Total pages in the Madani mushaf page map.
const int kTotalPages = 604;

/// Total surahs.
const int kTotalSurahs = 114;

/// True when [surah] is 1..114.
bool isValidSurah(int surah) => surah >= 1 && surah <= kTotalSurahs;

/// Verse count for [surah], or 0 when out of range.
int verseCountForSurah(int surah) =>
    isValidSurah(surah) ? kVerseCounts[surah - 1] : 0;

/// True when ([surah],[ayah]) names a real ayah.
bool isValidAyah(int surah, int ayah) =>
    isValidSurah(surah) && ayah >= 1 && ayah <= kVerseCounts[surah - 1];

/// True when [page] is 1..604.
bool isValidPage(int page) => page >= 1 && page <= kTotalPages;

/// Clamp [page] into 1..604.
int clampPage(int page) => page.clamp(1, kTotalPages);

/// 1-based absolute verse number (1..6236), or -1 when invalid.
int absoluteVerseNumber(int surah, int ayah) {
  if (!isValidAyah(surah, ayah)) return -1;
  var n = 0;
  for (var i = 0; i < surah - 1; i++) {
    n += kVerseCounts[i];
  }
  return n + ayah;
}
