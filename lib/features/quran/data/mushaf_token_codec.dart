/// Deterministic Mushaf token builder (Phase 1 data rule).
///
/// Pure, dependency-free: builds the approved page-layout/token asset from
/// the reviewed canonical asset (`quran_uthmani.json`) and the approved
/// display convention (`quran_pages.json`). No I/O, no timestamps, no
/// randomness — the same inputs always produce the same tokens.
///
/// Rules:
/// - A token never holds manually retyped Qur'an text. `quranText` tokens
///   carry display strings from the page map; `basmala` tokens carry the
///   exact approved prefix observed in the page map (one single string across
///   all surah starts — the build fails loudly when the convention drifts).
/// - Concatenating content-bearing tokens reconstructs the approved display
///   text for the page.
/// - Basmala appears exactly once where approved (surah start, ayah 1,
///   surah not 1 or 9); never at At-Tawbah; Al-Fatihah keeps its ayah-1 text
///   untouched.
/// - BOM/non-content policy: only U+FEFF is stripped, in the generator, and
///   the strip is reported. All other characters are preserved byte-exact.
library;

/// U+FEFF stripped by the generator (documented non-content character).
const String kMushafStrippedBom = '\uFEFF';

String stripBom(String input) => input.replaceAll(kMushafStrippedBom, '');

/// Report produced alongside the tokens.
class MushafTokenReport {
  const MushafTokenReport({
    required this.pageCount,
    required this.entryCount,
    required this.uniqueIdentities,
    required this.exactMatches,
    required this.differences,
    required this.basmalaPages,
    required this.basmalaText,
    required this.anomalies,
  });

  final int pageCount;
  final int entryCount;
  final int uniqueIdentities;
  final int exactMatches;
  final int differences;

  /// Pages where a basmala token was split off (surah starts).
  final List<int> basmalaPages;

  /// The single observed basmala display string, or null when none found.
  final String? basmalaText;

  /// Human-readable anomaly rows needing scholarly review.
  final List<String> anomalies;

  Map<String, Object?> toJson() => {
    'pages': pageCount,
    'entries': entryCount,
    'uniqueIdentities': uniqueIdentities,
    'exactMatches': exactMatches,
    'differences': differences,
    'basmalaPages': basmalaPages,
    'basmalaPresent': basmalaText != null,
    'anomalies': anomalies,
  };
}

/// One built page: header metadata plus display tokens.
class BuiltMushafPage {
  const BuiltMushafPage({required this.header, required this.tokens});
  final Map<String, Object?> header;
  final List<Map<String, Object?>> tokens;

  Map<String, Object?> toJson() => {'header': header, 'tokens': tokens};
}

class MushafTokenBuild {
  const MushafTokenBuild({required this.pages, required this.report});

  /// pageKey ("1".."604") -> page.
  final Map<String, BuiltMushafPage> pages;
  final MushafTokenReport report;
}

/// Builds tokens from decoded JSON maps.
///
/// [pagesMap] is `quran_pages.json` (`page -> [{surah, ayah, text, juz,
/// hizb, surah_name}]`); [canonicalMap] is `quran_uthmani.json`
/// (`surah -> [{verse, text}]`). Throws [StateError] on structural problems
/// (missing pages, duplicate identities, unknown identities, empty text,
/// drifting basmala convention).
MushafTokenBuild buildMushafTokens({
  required Map<String, dynamic> pagesMap,
  required Map<String, dynamic> canonicalMap,
}) {
  // Canonical lookup: "surah:ayah" -> stripped text.
  final canonical = <String, String>{};
  for (final surahKey in canonicalMap.keys) {
    final surah = int.tryParse(surahKey);
    if (surah == null) {
      throw StateError('canonical: non-numeric surah key "$surahKey"');
    }
    final verses = canonicalMap[surahKey] as List?;
    if (verses == null) throw StateError('canonical: surah $surah has no list');
    for (final v in verses) {
      final map = v as Map;
      final ayah = (map['verse'] ?? map['ayah']) as int?;
      final text = (map['text'] ?? map['text_uthmani']) as String?;
      if (ayah == null || text == null || stripBom(text).isEmpty) {
        throw StateError('canonical: invalid/empty entry at $surah:$ayah');
      }
      canonical['$surah:$ayah'] = stripBom(text);
    }
  }
  if (canonicalMap.keys.length != 114) {
    throw StateError(
      'canonical: expected 114 surahs, found ${canonicalMap.keys.length}',
    );
  }
  if (canonical.length != 6236) {
    throw StateError(
      'canonical: expected 6236 ayahs, found ${canonical.length}',
    );
  }

  // Page keys must be exactly 1..604.
  final pageNumbers = <int>[];
  for (final key in pagesMap.keys) {
    final n = int.tryParse(key);
    if (n == null) throw StateError('pages: non-numeric page key "$key"');
    pageNumbers.add(n);
  }
  pageNumbers.sort();
  if (pageNumbers.length != 604 ||
      pageNumbers.first != 1 ||
      pageNumbers.last != 604) {
    throw StateError(
      'pages: expected keys 1..604, found ${pageNumbers.length} keys',
    );
  }

  final seen = <String>{};
  final pages = <String, BuiltMushafPage>{};
  final basmalaObserved = <String>{};
  final basmalaPages = <int>[];
  final anomalies = <String>[];
  var exactMatches = 0;
  var differences = 0;

  for (final page in pageNumbers) {
    final rawEntries = pagesMap[page.toString()] as List?;
    if (rawEntries == null || rawEntries.isEmpty) {
      throw StateError('pages: page $page has no entries');
    }
    final tokens = <Map<String, Object?>>[];
    var firstSurah = 0;
    var firstSurahName = '';
    var juz = 0;
    var hizb = 0;
    var first = true;
    int? lastSurah;

    for (final raw in rawEntries) {
      final map = raw as Map;
      final surah = map['surah'] as int?;
      final ayah = map['ayah'] as int?;
      final displayRaw = map['text'] as String?;
      if (surah == null || ayah == null || displayRaw == null) {
        throw StateError('pages: malformed entry on page $page: $raw');
      }
      final display = stripBom(displayRaw);
      if (display.isEmpty) {
        throw StateError('pages: empty text at $surah:$ayah (page $page)');
      }
      final identity = '$surah:$ayah';
      if (!seen.add(identity)) {
        throw StateError('pages: duplicate ayah identity $identity');
      }
      final canon = canonical[identity];
      if (canon == null) {
        throw StateError(
          'pages: identity $identity absent from canonical source',
        );
      }

      if (first) {
        firstSurah = surah;
        firstSurahName = (map['surah_name'] as String?) ?? '';
        juz = (map['juz'] as int?) ?? 0;
        hizb = (map['hizb'] as int?) ?? 0;
        first = false;
      }

      // Surah boundary: metadata heading only — never Qur'an text.
      if (lastSurah == null || surah != lastSurah) {
        if (ayah == 1 || lastSurah != null) {
          tokens.add({
            'kind': 'surahHeading',
            'surah': surah,
            'name': (map['surah_name'] as String?) ?? '',
          });
        }
        lastSurah = surah;
      }

      // Basmala policy: ayah 1 of surahs other than 1 and 9, only when the
      // display text cleanly extends the canonical ayah text. The split-off
      // prefix is the observed convention — never a retyped string.
      var remainder = display;
      if (ayah == 1 && surah != 1 && surah != 9 && display != canon) {
        if (display.endsWith(canon)) {
          final prefix = display.substring(0, display.length - canon.length);
          if (prefix.trim().isNotEmpty) {
            basmalaObserved.add(prefix);
            tokens.add({'kind': 'basmala', 'text': prefix});
            if (!basmalaPages.contains(page)) basmalaPages.add(page);
            remainder = canon;
          }
        } else {
          anomalies.add(
            'basmala-unsplit $identity (page $page): display does not extend canonical text',
          );
        }
      }

      if (remainder == canon) {
        exactMatches++;
      } else {
        differences++;
      }
      tokens.add({'kind': 'quranText', 'text': remainder});
      tokens.add({
        'kind': 'ayahEnd',
        'surah': surah,
        'ayah': ayah,
        'juz': (map['juz'] as int?) ?? 0,
        'hizb': (map['hizb'] as int?) ?? 0,
        'surahName': (map['surah_name'] as String?) ?? '',
      });
    }

    pages[page.toString()] = BuiltMushafPage(
      header: {
        'firstSurah': firstSurah,
        'firstSurahName': firstSurahName,
        'juz': juz,
        'hizb': hizb,
      },
      tokens: tokens,
    );
  }

  if (seen.length != 6236) {
    throw StateError(
      'pages: expected 6236 unique identities, found ${seen.length}',
    );
  }
  if (basmalaObserved.length > 1) {
    throw StateError(
      'pages: basmala convention drifted — ${basmalaObserved.length} distinct prefixes observed',
    );
  }

  basmalaPages.sort();
  return MushafTokenBuild(
    pages: pages,
    report: MushafTokenReport(
      pageCount: 604,
      entryCount: seen.length,
      uniqueIdentities: seen.length,
      exactMatches: exactMatches,
      differences: differences,
      basmalaPages: basmalaPages,
      basmalaText: basmalaObserved.isEmpty ? null : basmalaObserved.single,
      anomalies: anomalies,
    ),
  );
}
