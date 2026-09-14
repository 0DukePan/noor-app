import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/models/adhkar_models.dart';
import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/hive_service.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/features/home/presentation/pages/home_page.dart';
import 'package:noor_app/features/home/presentation/providers/home_provider.dart';
import 'package:noor_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:noor_app/main.dart';

/// Tests for the app root (lib/main.dart): the hadith-DB readiness gate, the
/// one-time import screen, and the router-backed app shell. main()'s bootstrap
/// itself (service init, error handlers, Sentry wiring) is covered by the
/// emulator integration test, which is the right tool for it.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_main_app_test');
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

  Future<void> pumpApp(
    WidgetTester tester,
    List<Override> overrides,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const NoorApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('shows the import screen while the hadith DB is pending',
      (tester) async {
    // Pin the DB-gate provider to loading: the one-time first-launch import
    // screen must render without a real database.
    final gate = Completer<bool>();
    await pumpApp(tester, [
      hadithDbReadyProvider.overrideWith((ref) => gate.future),
    ]);

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('%'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('builds the app shell and routes to onboarding on first run',
      (tester) async {
    await pumpApp(tester, [
      hadithDbReadyProvider.overrideWith((ref) async => true),
      ...oneShotOverrides(),
    ]);

    // Gate resolved -> MaterialApp.router -> onboarding redirect (not seen).
    expect(find.byType(OnboardingPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('builds the app shell and lands on home after onboarding',
      (tester) async {
    // Hive's disk-write future never completes inside fake-async, so the
    // persisted write runs in the real event loop.
    await tester.runAsync(HiveService.setOnboardingSeen);

    await pumpApp(tester, [
      hadithDbReadyProvider.overrideWith((ref) async => true),
      ...oneShotOverrides(),
    ]);

    expect(find.byType(HomePage), findsOneWidget);

    // Content-branch animations are finite; settle flushes animate timers.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('Arabic device locale resolves to Arabic (RTL) chrome',
      (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('ar');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());

    await tester.runAsync(HiveService.setOnboardingSeen);
    await pumpApp(tester, [
      hadithDbReadyProvider.overrideWith((ref) async => true),
      ...oneShotOverrides(),
    ]);

    // The Arabic locale surfaces Arabic chrome (nav bar) and RTL direction.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    final context = tester.element(find.byType(HomePage));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.text('الرئيسية'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('non-Arabic device locale resolves to English (LTR) chrome',
      (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());

    await tester.runAsync(HiveService.setOnboardingSeen);
    await pumpApp(tester, [
      hadithDbReadyProvider.overrideWith((ref) async => true),
      ...oneShotOverrides(),
    ]);

    // The English locale surfaces English chrome and LTR direction.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    final context = tester.element(find.byType(HomePage));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(find.text('Home'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);
}
