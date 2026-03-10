import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/theme/noor_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
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
}

/// Initialize all app services in correct order
Future<void> _initializeServices() async {
  // 1. Local storage first
  await Hive.initFlutter();
  await HiveService.initialize();

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

  // 4. Smart notifications (Skip on web if not supported or causing issues)
  if (!kIsWeb) {
    try {
      await SmartNotificationService.initialize();
    } catch (e) {
      debugPrint('SmartNotificationService init failed: $e');
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

