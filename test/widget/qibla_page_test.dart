import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/features/qibla/presentation/pages/qibla_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Widget tests for QiblaPage.
///
/// In widget tests the geolocator and flutter_compass plugins have no native
/// host: their method channels never complete (they would hang forever). So we
/// mock the channels explicitly to drive the page's three behaviours:
///   1. location failure  -> Riyadh fallback + warning banner,
///   2. location success  -> real Qibla result, no warning,
///   3. compass stream    -> heading updates / graceful error handling.
///
/// The page runs a repeating pulse animation and a 60s auto-timeout timer, so
/// tests use fixed pumps (never pumpAndSettle) and end by unmounting the widget
/// so dispose() cancels the timer.
void main() {
  const geoChannel = MethodChannel('flutter.baseflow.com/geolocator');
  const compassChannel = EventChannel('hemanthraj/flutter_compass');

  /// Location plugin fails (permission denied / service error) -> fallback path.
  void mockLocationFailure() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geoChannel, (call) async {
      throw PlatformException(code: 'PERMISSION_DENIED');
    });
  }

  /// Location plugin returns a real position (Riyadh) -> success path.
  void mockLocationSuccess() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geoChannel, (call) async {
      switch (call.method) {
        case 'checkPermission':
        case 'requestPermission':
          return 3; // LocationPermission.always
        case 'getCurrentPosition':
          return <String, dynamic>{
            'latitude': 24.7136,
            'longitude': 46.6753,
            'accuracy': 5.0,
            'altitude': 0.0,
            'heading': 0.0,
            'speed': 0.0,
            'timestamp': DateTime(2026).millisecondsSinceEpoch,
          };
      }
      return null;
    });
  }

  /// Compass stream that emits no events but consumes the listen/cancel
  /// messages, so no platform message is left pending.
  void mockCompassNoop() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      compassChannel,
      MockStreamHandler.inline(
        onListen: (args, events) {},
        onCancel: (args) {},
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    // Wide + tall surface so the info panel Row (3 items) and the compass
    // layout (status bar + 300px compass + panels + buttons) don't overflow.
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // HapticFeedback() would hang on an unmocked platform channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);

    await tester.pumpWidget(const MaterialApp(
      locale: Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: QiblaPage(),
    ),);
    // Let _getLocation() run its async path and rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Unmount so the 60s auto-timeout timer is cancelled by dispose().
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  group('QiblaPage', () {
    testWidgets('shows the loading view while locating, then degrades to the '
        'fallback with a warning when location fails', (tester) async {
      mockCompassNoop();
      final completer = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(geoChannel, (call) => completer.future);

      await tester.pumpWidget(const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: QiblaPage(),
      ),);
      expect(find.text('جارٍ تحديد موقعك...'), findsOneWidget);

      completer.completeError(PlatformException(code: 'PERMISSION_DENIED'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('تعذّر تحديد موقعك'), findsOneWidget);
      expect(find.text('🕋 الكعبة'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('location failure shows the Riyadh fallback qibla',
        (tester) async {
      mockLocationFailure();
      mockCompassNoop();
      await pumpPage(tester);

      expect(find.text('اتجاه القبلة'), findsWidgets);
      expect(find.textContaining('تعذّر تحديد موقعك'), findsOneWidget);
      expect(find.text('🕋 الكعبة'), findsOneWidget);
      // Riyadh → Kaaba bearing ≈ 244° (southwest) → 'جنوب غرب'.
      expect(find.text('جنوب غرب'), findsWidgets);

      // The compass is visual-only: its spoken label carries both angles, and
      // every tappable node on the page is at least 48 dp.
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(
          RegExp(r'اتجاه القبلة \d+ درجة، واتجاه الجهاز \d+ درجة'),
        ),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();

      await unmount(tester);
    });

    testWidgets('location success shows a real qibla result with no warning',
        (tester) async {
      mockLocationSuccess();
      mockCompassNoop();
      await pumpPage(tester);

      expect(find.textContaining('تعذّر تحديد موقعك'), findsNothing);
      expect(find.text('🕋 الكعبة'), findsOneWidget);
      expect(find.text('جنوب غرب'), findsWidgets);
      await unmount(tester);
    });

    testWidgets('retry button re-attempts location and still degrades safely',
        (tester) async {
      mockLocationFailure();
      mockCompassNoop();
      await pumpPage(tester);

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('تعذّر تحديد موقعك'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('debug toggle reveals the heading panel', (tester) async {
      mockLocationFailure();
      mockCompassNoop();
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pump();
      expect(find.textContaining('Heading:'), findsOneWidget);
      expect(find.textContaining('Deviation:'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bug_report));
      await tester.pump();
      expect(find.textContaining('Heading:'), findsNothing);
      await unmount(tester);
    });

    testWidgets('calibration help opens and closes a dialog', (tester) async {
      mockLocationFailure();
      mockCompassNoop();
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.help_outline).first);
      await tester.pump();
      expect(find.text('معايرة البوصلة'), findsOneWidget);

      await tester.tap(find.text('فهمت'));
      await tester.pump();
      expect(find.text('معايرة البوصلة'), findsNothing);
      await unmount(tester);
    });

    testWidgets('lock button toggles between تثبيت and إلغاء', (tester) async {
      mockLocationFailure();
      mockCompassNoop();
      await pumpPage(tester);

      expect(find.text('تثبيت'), findsOneWidget);
      await tester.tap(find.text('تثبيت'));
      await tester.pump();
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('🔒 تم التثبيت'), findsOneWidget);

      await tester.tap(find.text('إلغاء'));
      await tester.pump();
      expect(find.text('تثبيت'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('mosque mode locks direction and shows a snackbar',
        (tester) async {
      mockLocationFailure();
      mockCompassNoop();
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.mosque_rounded));
      await tester.pump();
      expect(find.text('🔒 تم تثبيت اتجاه القبلة'), findsOneWidget);
      expect(find.text('🔒 اتجاه مثبت'), findsOneWidget);

      // Toggling mosque mode off returns the lock button to its unlocked label.
      await tester.tap(find.byIcon(Icons.mosque_rounded));
      await tester.pump();
      expect(find.text('تثبيت'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('refresh location button re-runs the fallback safely',
        (tester) async {
      mockLocationFailure();
      mockCompassNoop();
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('تعذّر تحديد موقعك'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('compass stream delivers a heading that appears in the debug '
        'panel', (tester) async {
      mockLocationFailure();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        compassChannel,
        MockStreamHandler.inline(
          onListen: (args, events) {
            events.success(const [90.0, 90.0, 5.0]);
          },
          onCancel: (args) {},
        ),
      );

      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pump();
      expect(find.textContaining('90.0'), findsWidgets);
      await unmount(tester);
    });

    testWidgets('survives an erroring compass stream (no sensor)',
        (tester) async {
      mockLocationFailure();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        compassChannel,
        MockStreamHandler.inline(
          onListen: (args, events) {
            events.error(
              code: 'NO_SENSOR',
              message: 'no compass',
            );
          },
          onCancel: (args) {},
        ),
      );

      await pumpPage(tester);
      // No crash; page still renders the fallback qibla.
      expect(find.text('🕋 الكعبة'), findsOneWidget);
      await unmount(tester);
    });
  });
}
