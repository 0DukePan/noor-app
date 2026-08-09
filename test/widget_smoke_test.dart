import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/hive_service.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/features/home/presentation/widgets/day_state_card.dart';
import 'package:noor_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:noor_app/features/settings/presentation/pages/settings_page.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_widget_test');
    Hive.init(tempDir.path);
  });

  // NOTE: no Hive.deleteFromDisk here — real file I/O hangs inside
  // testWidgets' fake-async zone; the system temp dir is cleaned by the OS.

  testWidgets('onboarding: skip completes the flow and marks it seen',
      (tester) async {
    await tester.runAsync(() async {
      Hive.init(tempDir.path);
      await Hive.openBox<Map>('settings');
    });

    var completed = false;
    await tester.pumpWidget(MaterialApp(
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
      await Hive.openBox<Map>('settings');
    });

    await tester.pumpWidget(MaterialApp(
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
      home: Scaffold(body: DayStateCard()),
    ),);

    expect(find.textContaining('2/5'), findsOneWidget);

    DayStateMachine.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('settings: privacy sheet opens with the honest statement',
      (tester) async {
    await tester.runAsync(() async {
      Hive.init(tempDir.path);
      await Hive.openBox<Map>('settings');
      await Hive.openBox<Map>('theme_settings');
    });

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: SettingsPage()),
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
    expect(find.textContaining('لا نستخدم أدوات تتبع'), findsOneWidget);
    expect(find.textContaining('Sentry'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);
}
