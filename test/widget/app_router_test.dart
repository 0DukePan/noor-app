import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/models/adhkar_models.dart';
import 'package:noor_app/core/router/app_router.dart';
import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/hive_service.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/features/home/presentation/pages/home_page.dart';
import 'package:noor_app/features/home/presentation/providers/home_provider.dart';
import 'package:noor_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Tests for the app router: the first-run onboarding gate (the redirect
/// logic) and the full route table. HomePage's periodic stream providers are
/// overridden with one-shot values so navigation tests don't leave pending
/// timers.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_router_test');
    Hive.init(tempDir.path);
    // Same generic type HiveService uses, or Hive throws on box() reuse.
    await Hive.openBox<Map<dynamic, dynamic>>('settings');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  List<Override> oneShotOverrides() => [
        homeDataProvider.overrideWith(
          (ref) async => HomeData(
            prayerTimes: PrayerTimeEngine.calculate(
              latitude: 21.4225,
              longitude: 39.8262,
              date: DateTime(2026, 3, 15),
              method: CalculationMethod.ummAlQura,
              utcOffset: 3,
            ),
            cityName: 'مكة المكرمة',
            adhkarStats: DailyAdhkarStats(date: DateTime(2026, 3, 15)),
          ),
        ),
        dayStateProvider.overrideWith(
          (ref) => Stream.value(
            const StateInfo(
              state: DayState.dhuhr,
              nextState: DayState.asr,
              timeToNextState: Duration(hours: 3),
              suggestedAdhkar: 'استغفر الله',
              suggestedAction: 'صلاة الظهر',
            ),
          ),
        ),
        currentTimeProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 3, 15)),
        ),
      ];

  Future<ProviderContainer> pumpRouter(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(appRouterProvider),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    return container;
  }

  testWidgets('redirects to onboarding when it has not been seen',
      (tester) async {
    final container = ProviderContainer(overrides: oneShotOverrides());
    await pumpRouter(tester, container);

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('stays on home once onboarding is seen', (tester) async {
    // Hive's disk-write future never completes inside fake-async, so the
    // persisted write runs in the real event loop.
    await tester.runAsync(HiveService.setOnboardingSeen);
    final container = ProviderContainer(overrides: oneShotOverrides());
    await pumpRouter(tester, container);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);

    // Content-branch animations are finite; settle flushes animate timers.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  test('route table exposes every expected route', () {
    final container = ProviderContainer(overrides: oneShotOverrides());
    final router = container.read(appRouterProvider);

    final paths = <String>[];
    void walk(List<RouteBase> routes) {
      for (final route in routes) {
        if (route is GoRoute) {
          paths.add(route.path);
        }
        // ShellRoute also nests routes under its own `routes` list.
        if (route.routes.isNotEmpty) {
          walk(route.routes);
        }
      }
    }

    walk(router.configuration.routes);
    container.dispose();

    for (final expected in [
      '/onboarding',
      '/',
      '/quran',
      'surah/:surahNumber',
      'tadabbur/:verseNumber',
      'khatmah',
      'mushaf',
      'hifz',
      '/hadith',
      'memorization',
      'quiz',
      'advanced',
      'topics',
      'search',
      'stats',
      'tags',
      '/adhkar',
      '/tafsir',
      '/audio-player',
      '/tools',
      'prayer',
      'qada',
      'settings',
      'qibla',
      'tasbih',
      'search',
      'profile',
      'notifications',
      'storage',
    ]) {
      expect(paths, contains(expected), reason: 'missing route: $expected');
    }
  });
}
