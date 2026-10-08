/// Validated intent to show one Qur'an position.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/utils/verse_counts.dart';

///
/// Every Qur'an entry point (home continue, library continue, Khatmah resume,
/// search result, bookmark, audio action, study deep link) builds one of
/// these and resolves it through [QuranLocationResolver]. Screens never
/// hand-build partial `/quran/surah/X` URLs.
class QuranLocation extends Equatable {
  const QuranLocation({required this.surah, required this.ayah, this.page});

  /// Lenient factory: clamps surah 1..114, ayah to its surah range,
  /// page 1..604 (or null when absent/invalid). Never throws.
  factory QuranLocation.validated({
    required int surah,
    required int ayah,
    int? page,
  }) {
    final s = surah.clamp(1, kTotalSurahs);
    final maxAyah = verseCountForSurah(s);
    final a = ayah.clamp(1, maxAyah == 0 ? 1 : maxAyah);
    final p = page == null ? null : clampPage(page);
    return QuranLocation(surah: s, ayah: a, page: p);
  }

  final int surah;
  final int ayah;

  /// Mushaf page when known; null means "derive from ayah-to-page index".
  final int? page;

  bool get isValid => isValidAyah(surah, ayah);

  /// Study route for the exact ayah context.
  String get studyRoute => '/quran/surah/$surah?ayah=$ayah';

  /// Mushaf route when a page is known.
  String mushafRoute(int fallbackPage) =>
      '/quran/mushaf?page=${page ?? fallbackPage}';

  @override
  List<Object?> get props => [surah, ayah, page];
}

/// Validated intent to show one Tafsir position.
///
/// Carries the Qur'an location plus the requested source/mode and the
/// return context so Back restores the calling screen.
class TafsirLocation extends Equatable {
  const TafsirLocation({
    required this.surah,
    required this.ayah,
    required this.source,
    this.returnRoute,
  });

  factory TafsirLocation.validated({
    required int surah,
    required int ayah,
    required String source,
    String? returnRoute,
  }) {
    final q = QuranLocation.validated(surah: surah, ayah: ayah);
    return TafsirLocation(
      surah: q.surah,
      ayah: q.ayah,
      source: source,
      returnRoute: returnRoute,
    );
  }

  final int surah;
  final int ayah;
  final String source;
  final String? returnRoute;

  String get route => '/tafsir?surah=$surah&ayah=$ayah&source=$source';

  @override
  List<Object?> get props => [surah, ayah, source, returnRoute];
}
