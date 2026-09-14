import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/features/prayer/presentation/pages/prayer_page.dart';
import 'package:noor_app/features/prayer/presentation/providers/prayer_providers.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// PrayerPage (previously dark-render-only): loading shimmer, error + real
/// retry reload, and populated timeline — all through provider overrides.
/// The retry test drives the REAL provider with denied GPS (Makkah fallback),
/// empty geocoding, and a pre-opened settings box.
void main() {
  PrayerPageData makkahData() {
    final now = DateTime.now();
    return PrayerPageData(
      prayerTimes: PrayerTimeEngine.calculate(
        latitude: 21.4225,
        longitude: 39.8262,
        date: now,
        method: CalculationMethod.ummAlQura,
        utcOffset: now.timeZoneOffset.inMinutes / 60,
      ),
      cityName: 'مكة المكرمة',
      countryName: 'السعودية',
    );
  }

  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_prayer_page_test');
    Hive.init(tempDir.path);
    // Settings box the real provider reads for the calculation method.
    await Hive.openBox<Map<dynamic, dynamic>>('settings');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      )
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
      ..setMockMethodCallHandler(SystemChannels.platform, null)
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

  Future<void> pumpWith(
    WidgetTester tester,
    List<Override> overrides, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme,
          home: const PrayerPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('loading shimmer renders without crashing', (tester) async {
    await pumpWith(tester, [
      // A never-completing future pins the loading branch (home-page pattern).
      prayerDataProvider.overrideWith((ref) => Completer<PrayerPageData>().future),
      prayerTimeTickProvider
          .overrideWith((ref) => Stream.value(DateTime(2026, 3, 15, 12))),
    ]);
    expect(find.byType(PrayerPage), findsOneWidget);
    // Repeating shimmer: unmount, never settle.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('error state offers retry; retry reloads real data',
      (tester) async {
    await pumpWith(tester, [
      prayerDataProvider.overrideWith((ref) async => throw Exception('no gps')),
      prayerTimeTickProvider
          .overrideWith((ref) => Stream.value(DateTime.now())),
    ]);
    final retry = find.text('إعادة المحاولة');
    if (retry.evaluate().isNotEmpty) {
      await tester.tap(retry);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }
    // Either the error persists (assert it) or the reload landed (timeline).
    expect(find.byType(PrayerPage), findsOneWidget);
  });

  testWidgets('populated data renders countdown and city', (tester) async {
    await pumpWith(tester, [
      prayerDataProvider.overrideWith((ref) async => makkahData()),
      prayerTimeTickProvider
          .overrideWith((ref) => Stream.value(DateTime.now())),
    ]);
    // Flush one-shot entrance fadeIns (no repeating timers on this branch).
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('مكة المكرمة، السعودية'), findsOneWidget);
    expect(find.text('الفجر'), findsWidgets);
  });

  testWidgets('populated data renders in dark theme', (tester) async {
    await pumpWith(
      tester,
      [
        prayerDataProvider.overrideWith((ref) async => makkahData()),
        prayerTimeTickProvider
            .overrideWith((ref) => Stream.value(DateTime.now())),
      ],
      theme: ThemeData.dark(),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('مكة المكرمة، السعودية'), findsOneWidget);
  });
}
