/// Normalize Arabic text for search and matching.
///
/// Strips diacritics (tashkeel), normalizes hamza variants of alef
/// (أ/إ/آ → ا), ta marbuta (ة → ه), alef maksura (ى → ي), and collapses
/// whitespace.
String normalizeArabic(String text) {
  return text
      .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ٱ', 'ا') // alef-wasla (common in Quranic text)
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
