/// Centralized route constants — prevents hardcoded string coupling
/// Usage: context.push(AppRoutes.surah(1))
class AppRoutes {
  AppRoutes._();

  // ── Quran ──
  static const quranIndex = '/quran';
  static String surah(int number) => '/quran/surah/$number';
  static const mushaf = '/quran/mushaf';

  // ── Hadith ──
  static const hadithIndex = '/hadith';
  static String hadithReader(String collectionId) => '/hadith/reader/$collectionId';

  // ── Tools ──
  static const tools = '/tools';
  static const profile = '/tools/profile';
  static const settings = '/settings';

  // ── Prayer ──
  static const prayer = '/prayer';
  static const qibla = '/qibla';
  static const adhkar = '/adhkar';
}
