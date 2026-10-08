/// One typed, range-aware route decoder (NAV-01).
///
/// Every numeric Qur'an route parameter flows through here. Valid input
/// yields a [QuranLocation] present before first paint; invalid input yields
/// a [RouteFailure] that the router renders as a localized recovery screen —
/// never an uncaught `int.parse` exception.
library;

import '../../features/quran/domain/entities/quran_location.dart';
import '../utils/verse_counts.dart';

/// Outcome of decoding one Qur'an route.
sealed class DecodedQuranRoute {
  const DecodedQuranRoute();
}

/// Valid location ready before first paint.
class DecodedQuranLocation extends DecodedQuranRoute {
  const DecodedQuranLocation(this.location);
  final QuranLocation location;
}

/// Invalid input that must reach the recovery screen.
class RouteFailure extends DecodedQuranRoute {
  const RouteFailure(this.reason, {this.rawValue});
  final String reason;
  final String? rawValue;
}

QuranLocation? _tryLocation(int? surah, int? ayah, int? page) {
  if (surah == null) return null;
  if (!isValidSurah(surah)) return null;
  final a = ayah ?? 1;
  if (!isValidAyah(surah, a)) return null;
  if (page != null && !isValidPage(page)) return null;
  return QuranLocation(surah: surah, ayah: a, page: page);
}

/// Decode `/quran/surah/:surahNumber` + optional `?ayah=`.
DecodedQuranRoute decodeSurahRoute({
  required String? surahRaw,
  required String? ayahRaw,
}) {
  final surah = int.tryParse((surahRaw ?? '').trim());
  if (surah == null)
    return RouteFailure('surah-not-numeric', rawValue: surahRaw);
  if (!isValidSurah(surah)) {
    return RouteFailure('surah-out-of-range', rawValue: surahRaw);
  }
  if (ayahRaw == null || ayahRaw.trim().isEmpty) {
    return DecodedQuranLocation(QuranLocation(surah: surah, ayah: 1));
  }
  final ayah = int.tryParse(ayahRaw.trim());
  if (ayah == null) return RouteFailure('ayah-not-numeric', rawValue: ayahRaw);
  if (!isValidAyah(surah, ayah)) {
    return RouteFailure('ayah-out-of-range', rawValue: ayahRaw);
  }
  return DecodedQuranLocation(QuranLocation(surah: surah, ayah: ayah));
}

/// Decode `/quran/mushaf?page=`. Lenient: clamps to 1..604 for the reader,
/// but reports whether the raw input was out of range so callers can show
/// the recovery hint when they choose strict handling.
({int page, bool wasClamped}) decodeMushafPage(String? pageRaw) {
  final parsed = int.tryParse((pageRaw ?? '').trim());
  if (parsed == null)
    return (page: 1, wasClamped: pageRaw != null && pageRaw.trim().isNotEmpty);
  if (!isValidPage(parsed)) return (page: clampPage(parsed), wasClamped: true);
  return (page: parsed, wasClamped: false);
}

/// Decode tafsir query `?surah=&ayah=&source=`.
DecodedQuranRoute decodeTafsirRoute({
  required String? surahRaw,
  required String? ayahRaw,
}) {
  if ((surahRaw == null || surahRaw.trim().isEmpty) &&
      (ayahRaw == null || ayahRaw.trim().isEmpty)) {
    return const RouteFailure('tafsir-missing-location');
  }
  return decodeSurahRoute(surahRaw: surahRaw, ayahRaw: ayahRaw);
}

/// Decode tadabbur path params.
DecodedQuranRoute decodeTadabburRoute({
  required String? surahRaw,
  required String? verseRaw,
}) {
  return decodeSurahRoute(surahRaw: surahRaw, ayahRaw: verseRaw);
}

/// Build a validated location or null when unknown (legacy-data fallback).
QuranLocation? validatedLocationOrNull({int? surah, int? ayah, int? page}) =>
    _tryLocation(surah, ayah, page);
