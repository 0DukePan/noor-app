import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:noor_app/core/models/adhkar_models.dart';
import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/core/widgets/main_shell.dart';
import 'package:noor_app/features/home/presentation/pages/home_page.dart';
import 'package:noor_app/features/home/presentation/providers/home_provider.dart';
import 'package:noor_app/features/prayer/presentation/pages/prayer_page.dart';
import 'package:noor_app/features/prayer/presentation/providers/prayer_providers.dart';
import 'package:noor_app/features/tools/presentation/pages/tasbih_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Accessibility regression tests for the primary flows (Phase 9 seed).
///
/// These run Flutter's own accessibility guidelines over real page trees:
///   - androidTapTargetGuideline: every tappable node is at least 48x48 dp
///   - iOSTapTargetGuideline: every tappable node is at least 44x44 dp
///   - labeledTapTargetGuideline: every tappable node announces a label
///
/// The label requirement is what the Semantics work in this batch exists for:
/// before it, the app had zero Semantics widgets, so icon-only controls were
/// announced as unlabelled buttons. Any regression here fails CI.
///
/// Deliberately NOT used: textContrastGuideline. Widget tests render text with
/// the placeholder Ahem font, whose glyph boxes make contrast measurement
/// meaningless, so it would gate on a rendering artifact rather than on the
/// real theme. Contrast is verified through the theme matrix tests and the
/// manual device pass in docs/qa-checklist.md instead.
///
/// See docs/accessibility.md for what is covered and what is still manual.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  /// Requires an active `tester.ensureSemantics()` handle: the guidelines only
  /// inspect a live semantics tree, and so do the bySemanticsLabel finders.
  Future<void> expectA11yGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  }

  group('navigation shell', () {
    testWidgets('five nav destinations, all sized and labelled',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) => MainShell(child: child),
            routes: [
              for (final path in const [
                '/',
                '/quran',
                '/hadith',
                '/adhkar',
                '/tools',
              ])
                GoRoute(
                  path: path,
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('content')),
                  ),
                ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      final handle = tester.ensureSemantics();
      await expectA11yGuidelines(tester);

      // The selected tab reports its state, not just its name.
      expect(
        tester.getSemantics(find.bySemanticsLabel('الرئيسية')),
        isSemantics(isSelected: true, hasTapAction: true),
      );
      handle.dispose();

      await tester.pumpWidget(const SizedBox());
    }, timeout: const Timeout(Duration(seconds: 60)),);
  });

  group('tasbih page', () {
    Future<void> pumpTasbih(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TasbihPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('counter, presets and reset are all labelled and tappable',
        (tester) async {
      await pumpTasbih(tester);
      final handle = tester.ensureSemantics();
      await expectA11yGuidelines(tester);

      // The counter announces the count and is activatable by a screen reader.
      expect(
        tester.getSemantics(find.bySemanticsLabel('العدد: 0')),
        isSemantics(hasTapAction: true),
      );

      // Presets announce label + selected state.
      expect(
        tester.getSemantics(find.bySemanticsLabel('٣٣')),
        isSemantics(isSelected: true, hasTapAction: true),
      );
      handle.dispose();

      await tester.pumpWidget(const SizedBox());
    }, timeout: const Timeout(Duration(seconds: 60)),);

    testWidgets('the announced count follows the counter', (tester) async {
      await pumpTasbih(tester);

      final handle = tester.ensureSemantics();
      final counterTap = find.ancestor(
        of: find.byType(ScaleTransition),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(counterTap);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.bySemanticsLabel('العدد: 1'), findsOneWidget);
      handle.dispose();

      await tester.pumpWidget(const SizedBox());
    }, timeout: const Timeout(Duration(seconds: 60)),);
  });

  group('prayer page', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('noor_a11y_prayer');
      Hive.init(tempDir.path);
      await Hive.openBox<Map<dynamic, dynamic>>('settings');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          (call) async {
            if (call.method == 'checkPermission') return 0;
            if (call.method == 'requestPermission') return 0;
            if (call.method == 'isLocationServiceEnabled') return false;
            return null;
          },
        )
        ..setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geocoding'),
          (call) async => <dynamic>[],
        );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          null,
        )
        ..setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geocoding'),
          null,
        );
      await Hive.close();
      await Hive.deleteFromDisk();
      try {
        await tempDir.delete(recursive: true);
      } on Exception catch (_) {}
    });

    testWidgets('populated timeline meets the guidelines', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prayerDataProvider.overrideWith(
              (ref) async => PrayerPageData(
                prayerTimes: PrayerTimeEngine.calculate(
                  latitude: 21.4225,
                  longitude: 39.8262,
                  date: now,
                  method: CalculationMethod.ummAlQura,
                  utcOffset: now.timeZoneOffset.inMinutes / 60,
                ),
                cityName: 'مكة المكرمة',
                countryName: 'السعودية',
              ),
            ),
            prayerTimeTickProvider
                .overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PrayerPage(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final handle = tester.ensureSemantics();
      await expectA11yGuidelines(tester);

      // The AppBar's icon-only actions announce what they open. Material
      // exposes an IconButton's tooltip as the node's tooltip, not its label,
      // which is what find.byTooltip (and TalkBack) read.
      expect(find.byTooltip('الإعدادات'), findsOneWidget);
      expect(find.byTooltip('قضاء الصلوات'), findsOneWidget);
      handle.dispose();

      // The guideline capture mounts lazily-built rows, which schedule
      // flutter_animate's 0ms timers — flush them before unmounting.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(const SizedBox());
    }, timeout: const Timeout(Duration(seconds: 60)),);
  });

  group('home page', () {
    testWidgets('dashboard meets the guidelines', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
                adhkarStats: DailyAdhkarStats(
                  date: DateTime(2026, 3, 15),
                  morningCompleted: true,
                ),
              ),
            ),
            smartGreetingProvider.overrideWithValue('طاب يومك'),
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
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomePage(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final handle = tester.ensureSemantics();
      await expectA11yGuidelines(tester);
      handle.dispose();

      // flutter_animate schedules 0ms timers when the lazily-built cards mount;
      // flush them before unmounting (same treatment as home_page_test.dart).
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
    }, timeout: const Timeout(Duration(seconds: 60)),);
  });
}
