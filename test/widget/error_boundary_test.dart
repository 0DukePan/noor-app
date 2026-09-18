import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noor_app/core/utils/error_reporting.dart';
import 'package:noor_app/core/widgets/noor_error_widget.dart';

/// Error-handling regression tests.
///
/// Covers the two things that used to be missing:
///   1. handlers that survive a crash-reporter initialization and always keep
///      the previously installed handler in the chain, and
///   2. a branded fallback instead of Flutter's red error screen in release.
void main() {
  late void Function(FlutterErrorDetails)? savedOnError;
  late Widget Function(FlutterErrorDetails) savedErrorWidgetBuilder;
  late bool Function(Object, StackTrace)? savedPlatformOnError;

  setUp(() {
    savedOnError = FlutterError.onError;
    savedErrorWidgetBuilder = ErrorWidget.builder;
    savedPlatformOnError = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = savedOnError;
    ErrorWidget.builder = savedErrorWidgetBuilder;
    PlatformDispatcher.instance.onError = savedPlatformOnError;
  });

  group('installGlobalErrorHandlers', () {
    test('runs the previous handler first, then captures and logs', () {
      final chained = <Object>[];
      FlutterError.onError = (details) => chained.add(details.exception);

      final captured = <Object>[];
      final logs = <String>[];
      installGlobalErrorHandlers(
        capture: (error, stackTrace) => captured.add(error),
        log: logs.add,
      );

      FlutterError.onError!(FlutterErrorDetails(exception: StateError('boom')));

      // The handler that was already installed is never dropped: that is how
      // the console breadcrumb was lost when Sentry initialized after ours.
      expect(chained, hasLength(1));
      expect(captured, hasLength(1));
      expect(captured.single, isA<StateError>());
      expect(logs.single, contains('boom'));
    });

    test('reports and handles platform errors', () {
      final captured = <Object>[];
      installGlobalErrorHandlers(
        capture: (error, stackTrace) => captured.add(error),
        log: (_) {},
      );

      final handled = PlatformDispatcher.instance.onError!(
        StateError('platform boom'),
        StackTrace.current,
      );

      expect(handled, isTrue, reason: 'the isolate must stay alive');
      expect(captured, hasLength(1));
    });

    test('a failing reporter never swallows the original error', () {
      final logs = <String>[];
      installGlobalErrorHandlers(
        capture: (error, stackTrace) => throw StateError('reporter down'),
        log: logs.add,
      );

      FlutterError.onError!(FlutterErrorDetails(exception: StateError('original')));

      expect(logs.single, contains('original'));
    });
  });

  group('runGuarded (startup)', () {
    test('an Error from an initializer is contained, not rethrown', () async {
      var reachedNextStep = false;

      await runGuarded('BrokenService init', () async {
        // StateError is an Error, not an Exception — the exact shape that
        // used to escape the startup Future.wait and kill main() before
        // runApp had drawn anything.
        throw StateError('init exploded');
      });
      reachedNextStep = true;

      expect(
        reachedNextStep,
        isTrue,
        reason: 'one broken service must not abort the whole startup',
      );
    });

    test('a successful initializer is awaited to completion', () async {
      var ran = false;

      await runGuarded('FineService init', () async {
        ran = true;
      });

      expect(ran, isTrue);
    });
  });

  group('release error fallback', () {
    testWidgets('names the failure in both languages', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: NoorErrorWidget()));

      expect(find.text('حدث خطأ غير متوقع'), findsOneWidget);
      expect(find.text('أعد تشغيل التطبيق'), findsOneWidget);
      expect(
        find.text('Something went wrong — please restart the app.'),
        findsOneWidget,
      );
    });

    testWidgets('a failing build renders the fallback, not a red screen',
        (tester) async {
      // flutter_test asserts the builder is put back before the body ends, so
      // this is restored inline (and again in a tear-down if an expect fails).
      final before = ErrorWidget.builder;
      addTearDown(() => ErrorWidget.builder = before);

      installErrorWidgetBuilder(debugOverride: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => throw StateError('build failed'),
          ),
        ),
      );

      expect(find.byType(NoorErrorWidget), findsOneWidget);
      // The error is still reported to FlutterError.onError — the fallback
      // replaces the screen, it does not hide the failure.
      expect(tester.takeException(), isA<StateError>());

      ErrorWidget.builder = before;
    });

    testWidgets('debug builds keep the framework error screen', (tester) async {
      final before = ErrorWidget.builder;

      installErrorWidgetBuilder(debugOverride: true);

      expect(ErrorWidget.builder, same(before));
    });
  });
}
