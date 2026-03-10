class SearchResult {
  final String text; // Matching text snippet
  final String source; // 'quran' or 'hadith'
  final Map<String, dynamic> metadata; // {surah: 1, verse: 1} etc

  const SearchResult({
    required this.text,
    required this.source,
    required this.metadata,
  });
}
