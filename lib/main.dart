import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:hijri/hijri_calendar.dart';

import 'core/theme/noor_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/services.dart';
import 'core/services/hadith_user_data_service.dart';
import 'core/services/narrator_database_service.dart';
import 'core/data/data_sources/hadith_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HijriCalendar.setLocal('ar');

  // Set preferred orientations (Mobile only)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Initialize all services
  await _initializeServices();

  // Initialize Sentry for crash reporting (errors only, no user tracking)
  const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.0; // No performance tracking
        options.attachScreenshot = false; // Privacy: no screenshots
        options.sendDefaultPii = false; // Privacy: no personal data
      },
      appRunner: () => runApp(
        const ProviderScope(
          child: NoorApp(),
        ),
      ),
    );
  } else {
    // No Sentry DSN → run directly (avoids zone mismatch on web)
    runApp(
      const ProviderScope(
        child: NoorApp(),
      ),
    );
  }
}

/// Initialize all app services in correct order
Future<void> _initializeServices() async {
  // 1. Local storage first
  await Hive.initFlutter();
  await HiveService.initialize();
  await HadithUserDataService.init();

  // 1b. Statistics service (depends on Hive)
  try {
    await StatisticsService.init();
  } catch (e) {
    debugPrint('StatisticsService init failed: $e');
  }

  // 1c. Day state machine (depends on Hive)
  try {
    await DayStateMachine.init();
  } catch (e) {
    debugPrint('DayStateMachine init failed: $e');
  }

  // 1d. Content data sources (Quran, Hadith, Narrators, Tafsir, Adhkar)
  try {
    await QuranDataSource.init();
  } catch (e) {
    debugPrint('QuranDataSource init failed: $e');
  }
  try {
    await HadithDataSource.init();
  } catch (e) {
    debugPrint('HadithDataSource init failed: $e');
  }
  // Build the hadith SQLite database in the background so the first frame is
  // not blocked by the one-time 17-book import (cached on later launches).
  HadithDatabase.warmUp();
  // Build the scientific search index in the background too; it is cached in
  // Hive after the first build.
  _initSearchEngine();
  try {
    await NarratorDatabaseService.init();
  } catch (e) {
    debugPrint('NarratorDatabaseService init failed: $e');
  }
  try {
    await TafsirDataSource.init();
    await TafsirDataSource.initPhase6();
  } catch (e) {
    debugPrint('TafsirDataSource init failed: $e');
  }
  try {
    await AdhkarDataSource.init();
  } catch (e) {
    debugPrint('AdhkarDataSource init failed: $e');
  }

  // 1e. Prayer system (location trust, mosque mode, seasonal offsets,
  //     weekly scheduler, adhan scheduler, health checks)
  try {
    await LocationTrustEngine.init();
  } catch (e) {
    debugPrint('LocationTrustEngine init failed: $e');
  }
  try {
    await MosqueModeService.init();
  } catch (e) {
    debugPrint('MosqueModeService init failed: $e');
  }
  try {
    await SeasonalOffsetsEngine.init();
  } catch (e) {
    debugPrint('SeasonalOffsetsEngine init failed: $e');
  }
  if (!kIsWeb) {
    try {
      await AdhanSchedulerService.init();
    } catch (e) {
      debugPrint('AdhanSchedulerService init failed: $e');
    }
    try {
      await PrayerHealthCheck.init();
    } catch (e) {
      debugPrint('PrayerHealthCheck init failed: $e');
    }
  }
  try {
    await AdhkarTimerService.init();
  } catch (e) {
    debugPrint('AdhkarTimerService init failed: $e');
  }

  // 2. Offline data service (loads bundled assets)
  // On web, we might need to handle assets differently or they might be missing
  try {
    await OfflineDataService.init();
  } catch (e) {
    debugPrint('OfflineDataService init failed: $e');
  }

  // 3. Audio service
  try {
    await QuranAudioService.init();
  } catch (e) {
    debugPrint('QuranAudioService init failed: $e');
  }
  if (!kIsWeb) {
    try {
      await QuranAudioEngine.init();
    } catch (e) {
      debugPrint('QuranAudioEngine init failed: $e');
    }
  }

  // 4. Smart notifications (Skip on web if not supported or causing issues)
  if (!kIsWeb) {
    try {
      await SmartNotificationEngine.init();
    } catch (e) {
      debugPrint('SmartNotificationEngine init failed: $e');
    }
  }

  // 5. Widget service for home screen (Mobile only)
  if (!kIsWeb) {
    try {
      await WidgetService.init();
      await WidgetService.updateAllWidgets();
    } catch (e) {
      debugPrint('WidgetService init failed: $e');
    }
  }

  // 6. Sync data if connected (background)
  OfflineDataService.syncIfNeeded();
}

/// Build the hadith search index in the background (errors are non-fatal).
Future<void> _initSearchEngine() async {
  try {
    await HadithSearchEngine.init();
  } catch (e) {
    debugPrint('HadithSearchEngine init failed: $e');
  }
}

/// نور - التطبيق الإسلامي الشامل
/// A comprehensive Islamic app serving as a digital worship environment
class NoorApp extends ConsumerStatefulWidget {
  const NoorApp({super.key});

  @override
  ConsumerState<NoorApp> createState() => _NoorAppState();
}

class _NoorAppState extends ConsumerState<NoorApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh prayer times when app comes to foreground
      WidgetService.updatePrayerWidget();
      _refreshDayState();
    }
  }

  /// Recompute today's prayer times and feed them to the day state machine so
  /// the home dashboard reflects the real day period.
  Future<void> _refreshDayState() async {
    try {
      final locationResult = await LocationTrustEngine.getTrustedLocation(
        timeout: const Duration(seconds: 3),
      );
      final lat = locationResult.location?.latitude ?? 21.4225;
      final lng = locationResult.location?.longitude ?? 39.8262;
      final times = PrayerTimeEngine.calculate(
        latitude: lat,
        longitude: lng,
        date: DateTime.now(),
        method: CalculationMethod.ummAlQura,
        utcOffset: DateTime.now().timeZoneOffset.inMinutes / 60,
      );
      DayStateMachine.updateTodayTimes(times);
    } catch (e) {
      debugPrint('DayState refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'نور',
      debugShowCheckedModeBanner: false,
      
      // Khushu Theme - Calm, spiritual design
      theme: NoorTheme.light,
      darkTheme: NoorTheme.dark,
      themeMode: ThemeMode.system,
      
      // Localization
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Builder for RTL and text direction
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      
      // Navigation
      routerConfig: router,
    );
  }
}

