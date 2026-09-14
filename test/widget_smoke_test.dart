import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:noor_app/core/services/analytics_service.dart';
import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/hive_service.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/features/home/presentation/widgets/day_state_card.dart';
import 'package:noor_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:noor_app/features/settings/presentation/pages/settings_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // Fonts are bundled — never hit the network in tests.
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_widget_test');
    Hive.init(tempDir.path);
  });

  // NOTE: no Hive.deleteFromDisk here — real file I/O hangs inside
  // testWidgets' fake-async zone; the system temp dir is cleaned by the OS.

  testWidgets('onboarding: skip completes the flow and marks it seen',
      (tester) async {
    await tester.runAsync(() async {
      Hive.init(tempDir.path);
      await Hive.openBox<Map<dynamic, dynamic>>('settings');
    });

    var completed = false;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OnboardingPage(onComplete: () => completed = true),
    ),);

    expect(find.text('أهلاً بك في نور'), findsOneWidget);

    await tester.tap(find.text('تخطي'));
    // Give the real event loop time to complete Hive's async disk write.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(completed, isTrue);
    expect(HiveService.isOnboardingSeen, isTrue);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('onboarding: last step shows the start button', (tester) async {
    await tester.runAsync(() async {
      Hive.init(tempDir.path);
      await Hive.openBox<Map<dynamic, dynamic>>('settings');
    });

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OnboardingPage(onComplete: () {}),
    ),);

    expect(find.text('التالي'), findsOneWidget);
    // Advance through all 5 steps.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('التالي'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(find.text('ابدأ الآن'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('day state card shows prayer completion progress',
      (tester) async {
    await tester.runAsync(() async {
      Hive.init(tempDir.path);
      await DayStateMachine.init();
      await DayStateMachine.markPrayerCompleted(PrayerType.fajr);
      await DayStateMachine.markPrayerCompleted(PrayerType.dhuhr);
    });

    await tester.pumpWidget(const MaterialApp(
      locale: Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: DayStateCard()),
    ),);

    expect(find.textContaining('2/5'), findsOneWidget);

    DayStateMachine.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('settings: privacy sheet opens with the honest statement',
      (tester) async {
    await tester.runAsync(() async {
      Hive.init(tempDir.path);
      await Hive.openBox<Map<dynamic, dynamic>>('settings');
      await Hive.openBox<Map<dynamic, dynamic>>('theme_settings');
    });

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(),
      ),
    ),);

    // The privacy tile sits below the fold of the lazy ListView.
    await tester.scrollUntilVisible(
      find.text('الخصوصية والبيانات'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('الخصوصية والبيانات'), findsOneWidget);

    await tester.ensureVisible(find.text('الخصوصية والبيانات'));
    await tester.pump();
    await tester.tap(find.text('الخصوصية والبيانات'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.textContaining('لا أدوات تتبع'), findsOneWidget);
    expect(
      find.textContaining('إحصائيات الاستخدام المجهولة: مغلقة افتراضياً'),
      findsOneWidget,
    );
    expect(find.textContaining('Sentry'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('settings: analytics toggle opts in, persists, and reverts',
      (tester) async {
    await tester.runAsync(() async {
      Hive.init(tempDir.path);
      await Hive.openBox<Map<dynamic, dynamic>>('settings');
      await Hive.openBox<Map<dynamic, dynamic>>('theme_settings');
      await AnalyticsService.init();
      await AnalyticsService.setOptedIn(value: false);
    });

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(),
      ),
    ),);

    // The analytics tile lives in the general section, below the fold.
    final tile = find.ancestor(
      of: find.text('إحصائيات الاستخدام'),
      matching: find.byType(ListTile),
    );
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(tile);
    await tester.pump();
    expect(find.textContaining('مغلقة افتراضياً'), findsWidgets);
    expect(AnalyticsService.optedIn, isFalse);

    // Flip the analytics toggle on (never the haptics switch above it): the
    // flag flips and the subtitle updates.
    final analyticsSwitch = find.descendant(
      of: tile,
      matching: find.byType(Switch),
    );
    await tester.tap(analyticsSwitch);
    await tester.pump();
    expect(AnalyticsService.optedIn, isTrue);
    expect(find.textContaining('مفعلة'), findsOneWidget);

    // A fresh init (app restart) restores the persisted choice.
    await tester.runAsync(AnalyticsService.init);
    expect(AnalyticsService.optedIn, isTrue);

    // Toggle off restores the default.
    await tester.tap(analyticsSwitch);
    await tester.pump();
    expect(AnalyticsService.optedIn, isFalse);
    await tester.runAsync(AnalyticsService.init);
    expect(AnalyticsService.optedIn, isFalse);
  }, timeout: const Timeout(Duration(seconds: 30)),);
}
