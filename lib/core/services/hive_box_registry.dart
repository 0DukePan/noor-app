import 'package:hive_flutter/hive_flutter.dart';

/// 📦 مركز تسجيل صناديق Hive - Hive Box Name Registry
///
/// Single source of truth for every Hive box name used in the app. All
/// services SHOULD reference these constants instead of hardcoding box name
/// strings. This prevents silent naming collisions and makes it easy to
/// discover which boxes exist and audit their lifecycle.
///
/// Usage:
/// ```dart
/// final box = await Hive.openBox<dynamic>(HiveBoxes.appStatistics);
/// ```
abstract final class HiveBoxes {
  // ═══════════════════════════════════════════════════════════════════════════
  // CORE — HiveService (opened at startup)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cached surah metadata (HiveService)
  static const String surahs = 'surahs';

  /// Cached verse data (HiveService)
  static const String verses = 'verses';

  /// Tafsir cache (HiveService)
  static const String tafsir = 'tafsir';

  /// Hadith key-value cache (HiveService)
  static const String hadiths = 'hadiths';

  /// Adhkar key-value cache (HiveService)
  static const String adhkar = 'adhkar';

  /// Quran reading progress (HiveService + QuranRepositoryImpl)
  static const String readingProgress = 'reading_progress';

  /// Quran bookmarks (HiveService)
  static const String bookmarks = 'bookmarks';

  /// Encrypted personal reflections (HiveService)
  static const String tadabbur = 'tadabbur';

  /// App settings (HiveService)
  static const String settings = 'settings';

  /// Qada (missed prayer/fasting) tracker (HiveService)
  static const String qada = 'qada';

  // ═══════════════════════════════════════════════════════════════════════════
  // STATISTICS & TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Aggregate usage counters: verses read, reading time, etc. (StatisticsService)
  static const String appStatistics = 'app_statistics';

  /// Historical activity log (StatisticsService)
  static const String activityHistory = 'activity_history';

  /// Islamic day state: current state, prayer completion, streaks (DayStateMachine)
  static const String dayState = 'day_state';

  /// Anonymous, opt-in usage counters (AnalyticsService)
  static const String analytics = 'analytics';

  /// Adhan scheduler preferences (AdhanSchedulerService)
  static const String adhanSettings = 'adhan_settings';

  /// Adhkar completion state, statistics, and preferences (AdhkarDataSource)
  static const String adhkarProgress = 'adhkar_progress';
  static const String adhkarStats = 'adhkar_stats';
  static const String adhkarSettings = 'adhkar_settings';

  /// Persisted application theme selection (ThemeService)
  static const String themeSettings = 'theme_settings';

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCATION & PRAYER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Trusted GPS location cache (LocationTrustEngine)
  static const String locationTrust = 'location_trust';

  /// Prayer-time health check history (PrayerHealthCheck)
  static const String healthCheck = 'health_check';

  /// Per-prayer user offsets for seasonal correction (SeasonalOffsetsEngine)
  static const String prayerOffsets = 'prayer_offsets';

  /// Prayer calculation settings: method, adjustments (PrayerProviders)
  static const String prayerSettings = 'prayer_settings';

  /// Notification scheduling settings (SmartNotificationEngine)
  static const String notificationSettings = 'notification_settings';

  /// Mosque mode preferences (MosqueModeService)
  static const String mosqueMode = 'mosque_mode';

  // ═══════════════════════════════════════════════════════════════════════════
  // QURAN & AUDIO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Quran asset cache metadata (QuranDataSource)
  static const String quranCache = 'quran_cache';

  /// Offline-sync Quran data (OfflineDataService)
  static const String offlineQuran = 'quran_offline';

  /// Audio file cache metadata (QuranAudioEngine)
  static const String audioCache = 'audio_cache';

  /// Audio playback progress (QuranAudioEngine)
  static const String audioProgress = 'audio_progress';

  /// Khatmah (reading plan) progress (KhatmahProviders)
  static const String khatmah = 'khatmah_plans';

  // ═══════════════════════════════════════════════════════════════════════════
  // HADITH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hadith reading progress & last-read position (HadithUserDataService)
  static const String hadithProgress = 'hadith_progress';

  /// Hadith bookmarks (HadithUserDataService)
  static const String hadithBookmarks = 'hadith_bookmarks';

  /// Hadith personal notes (ScholarModePage, HadithSharhSheet)
  static const String hadithNotes = 'hadith_notes';

  /// Hadith scholarly review marks (ScholarModePage)
  static const String hadithReview = 'hadith_review';

  /// Quiz result history (QuizNotifier)
  static const String quizHistory = 'quiz_history';

  /// FSRS spaced-repetition card state (MemorizationNotifier)
  static const String memorizationCards = 'memorization_cards';

  /// Custom hadith tag collections (TagsManagementPage)
  static const String hadithTags = 'hadith_tags';

  /// Offline-sync hadith data (OfflineDataService)
  static const String offlineHadith = 'hadith_offline';

  /// Inverted search index cache (HadithSearchEngine)
  static const String hadithSearchIndex = 'hadith_search_index';

  /// Search result cache (HadithSearchEngine)
  static const String hadithSearchCache = 'hadith_search_cache';

  // ═══════════════════════════════════════════════════════════════════════════
  // TAFSIR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tafsir content cache (TafsirDataSource)
  static const String tafsirCache = 'tafsir_cache';

  /// Tafsir reader settings: font size, source (TafsirDataSource)
  static const String tafsirSettings = 'tafsir_settings';

  /// Tafsir bookmarks (TafsirDataSource)
  static const String tafsirBookmarks = 'tafsir_bookmarks';

  /// Tafsir reading history (TafsirDataSource)
  static const String tafsirHistory = 'tafsir_history';

  /// Tafsir text highlights (TafsirDataSource Phase 6)
  static const String tafsirHighlights = 'tafsir_highlights';

  /// Tafsir annotations (TafsirDataSource Phase 6)
  static const String tafsirAnnotations = 'tafsir_annotations';

  // ═══════════════════════════════════════════════════════════════════════════
  // HIFZ & HOME
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hifz (memorization) tracking state (HifzProviders)
  static const String hifzData = 'hifz_data';

  /// Home page widget cache (HomeProvider)
  static const String homeCache = 'home_cache';

  // ═══════════════════════════════════════════════════════════════════════════
  // ALL BOX NAMES — for lifecycle management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Every box name in the app. Used by [closeAll] to ensure nothing leaks.
  static const List<String> allBoxNames = [
    // Core
    surahs, verses, tafsir, hadiths, adhkar,
    readingProgress, bookmarks, tadabbur, settings, qada,
    // Statistics
    appStatistics, activityHistory, dayState, analytics, themeSettings,
    adhkarProgress, adhkarStats, adhkarSettings,
    // Location & Prayer
    locationTrust, healthCheck, prayerOffsets, prayerSettings,
    notificationSettings, mosqueMode, adhanSettings,
    // Quran & Audio
    quranCache, offlineQuran, audioCache, audioProgress, khatmah,
    // Hadith
    hadithProgress, hadithBookmarks, hadithNotes, hadithReview,
    quizHistory, memorizationCards, hadithTags, offlineHadith,
    hadithSearchIndex, hadithSearchCache,
    // Tafsir
    tafsirCache, tafsirSettings, tafsirBookmarks,
    tafsirHistory, tafsirHighlights, tafsirAnnotations,
    // Hifz & Home
    hifzData, homeCache,
  ];

  /// Opens every registered box. This is intended for controlled lifecycle
  /// operations and tests; normal app startup opens boxes lazily by service.
  static Future<void> openAll() async {
    await Future.wait(allBoxNames.map(Hive.openBox<dynamic>));
  }

  /// Close every registered box. Call during app shutdown or before clearing
  /// data. Tolerates already-closed boxes (common in tests).
  static Future<void> closeAll() async {
    for (final name in allBoxNames) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box<dynamic>(name).close();
        }
      } on Object catch (_) {
        // Box may have been closed or never opened — both are fine.
      }
    }
  }
}
