import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/data/data_sources/hadith_database.dart';
import 'core/router/app_router.dart';
import 'core/services/hadith_user_data_service.dart';
import 'core/services/narrator_database_service.dart';
import 'core/services/services.dart';
import 'core/theme/design_system.dart';
import 'core/theme/noor_theme.dart';
import 'core/utils/error_reporting.dart';
import 'core/widgets/noor_error_widget.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HijriCalendar.setLocal('ar');

  // Fonts are bundled (Cairo/Amiri) — never fetch them at runtime. This keeps
  // the app fully offline and deterministic.
  GoogleFonts.config.allowRuntimeFetching = false;

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  // Without a crash reporter, install the console handlers now so even a
  // failing service init is visible and still gets the branded error screen.
  // With a DSN this must wait until after SentryFlutter.init — Sentry replaces
  // FlutterError.onError during init, so a handler installed earlier is
  // silently dropped (see installGlobalErrorHandlers).
  if (sentryDsn.isEmpty) {
    installGlobalErrorHandlers(capture: (error, stackTrace) {});
    installErrorWidgetBuilder();
  }

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
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = sentryDsn
          ..tracesSampleRate = 0.0 // No performance tracking
          ..attachScreenshot = false // Privacy: no screenshots
          ..sendDefaultPii = false; // Privacy: no personal data
      },
      appRunner: () {
        // Sentry owns the error handlers from here on; add only the fallback UI.
        installErrorWidgetBuilder();
        runApp(
          const ProviderScope(
            child: NoorApp(),
          ),
        );
      },
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

/// Initialize all app services.
///
/// Hive storage is initialized first (everything else reads it); the
/// remaining services are independent of each other, so they are initialized
/// in parallel — the one-time first-launch import and the other warm-ups no
/// longer run as 30+ sequential awaits blocking the first frame.
Future<void> _initializeServices() async {
  // 1. Local storage first (hard dependency for everything below).
  await Hive.initFlutter();
  await HiveService.initialize();
  await HadithUserDataService.init();

  // 1b-6. Independent services, parallelized; each failure is logged and
  // non-fatal so startup always proceeds.
  await Future.wait([
    _safeInit('AnalyticsService', AnalyticsService.init),
    _safeInit('StatisticsService', StatisticsService.init),
    _safeInit('DayStateMachine', DayStateMachine.init),
    _safeInit('QuranDataSource', QuranDataSource.init),
    _safeInit('HadithDataSource', HadithDataSource.init),
    _safeInit('NarratorDatabaseService', NarratorDatabaseService.init),
    _safeInit('TafsirDataSource', () async {
      await TafsirDataSource.init();
      await TafsirDataSource.initPhase6();
    }),
    _safeInit('AdhkarDataSource', AdhkarDataSource.init),
    _safeInit('LocationTrustEngine', LocationTrustEngine.init),
    _safeInit('MosqueModeService', MosqueModeService.init),
    _safeInit('SeasonalOffsetsEngine', SeasonalOffsetsEngine.init),
    _safeInit('AdhkarTimerService', AdhkarTimerService.init),
    _safeInit('OfflineDataService', OfflineDataService.init),
    _safeInit('QuranAudioService', QuranAudioService.init),
    if (!kIsWeb) ...[
      _safeInit('AdhanSchedulerService', AdhanSchedulerService.init),
      _safeInit('PrayerHealthCheck', PrayerHealthCheck.init),
      _safeInit('QuranAudioEngine', QuranAudioEngine.init),
      _safeInit('SmartNotificationEngine', SmartNotificationEngine.init),
      _safeInit('WidgetService', WidgetService.init),
    ],
  ]);

  // No-op unless the user opted into anonymous usage statistics.
  AnalyticsService.record('app_open');

  // Background work: fire-and-forget, errors handled inside.
  unawaited(HadithDatabase.warmUp());
  unawaited(_initSearchEngine());
  if (!kIsWeb) {
    await runGuarded(
      'WidgetService updateAllWidgets',
      WidgetService.updateAllWidgets,
    );
  }
  unawaited(OfflineDataService.syncIfNeeded());
}

/// Runs a service initializer, logging failures without crashing startup.
///
/// Delegates to [runGuarded], which catches [Object] rather than [Exception]
/// for the reason documented there.
Future<void> _safeInit(String name, Future<void> Function() init) =>
    runGuarded('$name init', init);

/// Build the hadith search index in the background (errors are non-fatal).
Future<void> _initSearchEngine() =>
    runGuarded('HadithSearchEngine init', HadithSearchEngine.init);

/// نور - التطبيق الإسلامي الشامل
/// A comprehensive Islamic app serving as a digital worship environment
///
/// UI language follows the device: Arabic (RTL) for Arabic/RTL locales,
/// English (LTR) otherwise. The en/ar string pairs live in lib/l10n
/// (supportedLocales is generated from the ARB files; parity is CI-gated).
///
/// Arabic devices get Arabic (RTL); every other device falls back to
/// English (LTR) rather than forcing Arabic UI on non-Arabic users.
Locale _resolveAppLocale(Locale? deviceLocale) {
  final language = deviceLocale?.languageCode.toLowerCase();
  if (language == 'ar' || language == 'fa' || language == 'ur') {
    return const Locale('ar');
  }
  return const Locale('en');
}

class NoorApp extends ConsumerStatefulWidget {
  const NoorApp({super.key});

  @override
  ConsumerState<NoorApp> createState() => _NoorAppState();
}

/// Resolves once the hadith SQLite database is ready. On first launch this
/// drives the import-progress screen; on later launches the database opens in
/// milliseconds so the gate is skipped via [HadithDatabase.isDbCached].
final hadithDbReadyProvider = FutureProvider<bool>((ref) async {
  await HadithDatabase.database;
  return true;
});

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
    } on Object catch (e, stackTrace) {
      debugPrint('DayState refresh failed: $e\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve UI language from the device; Arabic-first for Arabic/RTL
    // locales, English otherwise. MaterialApp applies the matching text
    // direction automatically (RTL for ar, LTR for en).
    final deviceLocale = View.of(context).platformDispatcher.locale;
    final appLocale = _resolveAppLocale(deviceLocale);

    // On later launches the database opens in milliseconds; go straight to
    // the app. Only the one-time first-launch import shows the progress UI.
    if (HadithDatabase.isDbCached) {
      return _buildApp(context, appLocale);
    }

    final dbReady = ref.watch(hadithDbReadyProvider);
    return dbReady.when(
      data: (_) => _buildApp(context, appLocale),
      loading: () {
        // The import screen is a standalone full-screen UI rendered BEFORE
        // the router app exists — it needs its own MaterialApp (Directionality
        // + theme), otherwise a fresh-install launch crashes with "No
        // Directionality widget found".
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: NoorTheme.light,
          darkTheme: NoorTheme.dark,
          // The import screen predates the router app, so it carries its own
          // localization delegates.
          locale: appLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const _DatabaseImportScreen(),
        );
      },
      error: (e, _) {
        debugPrint('Hadith database gate failed: $e');
        return _buildApp(context, appLocale);
      },
    );
  }

  Widget _buildApp(BuildContext context, Locale appLocale) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'نور',
      debugShowCheckedModeBanner: false,

      // Khushu Theme - Calm, spiritual design
      theme: NoorTheme.light,
      darkTheme: NoorTheme.dark,

      // Localization — device-driven: Arabic (RTL) for Arabic/RTL locales,
      // English (LTR) for everything else. String pairs live in lib/l10n.
      locale: appLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Navigation
      routerConfig: router,
    );
  }
}

/// Full-screen progress shown only during the one-time first-launch import of
/// the 17 hadith books into SQLite.
class _DatabaseImportScreen extends StatelessWidget {
  const _DatabaseImportScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_stories_rounded,
                size: 72,
                color: NoorDesignSystem.primaryGreen,
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).dbImportTitle,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NoorDesignSystem.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).dbImportSubtitle,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: NoorDesignSystem.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              ValueListenableBuilder<double>(
                valueListenable: HadithDatabase.importProgress,
                builder: (context, value, _) => Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: NoorDesignSystem.primaryGreen
                            .withValues(alpha: 0.1),
                        color: NoorDesignSystem.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: NoorDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
