import 'package:flutter/foundation.dart';

/// Receives every uncaught error the app can still observe.
typedef ErrorCapture = void Function(Object error, StackTrace? stackTrace);

/// Installs the app's global error handlers.
///
/// **Call this after any crash-reporter initialization.** `sentry_flutter`
/// replaces `FlutterError.onError` while initializing, so handlers installed
/// before it are silently dropped — which is exactly how the console
/// breadcrumb used to disappear once a DSN was configured.
///
/// The previously installed handler is always preserved and runs first
/// (Sentry's integration, or the framework default that prints the error), so
/// installing this never hides an error from an existing reporter.
///
/// [capture] is the reporting sink (Sentry when a DSN is configured, otherwise
/// a no-op). [log] writes the human-readable breadcrumb; it defaults to
/// [debugPrint].
void installGlobalErrorHandlers({
  required ErrorCapture capture,
  void Function(String message)? log,
}) {
  final write = log ?? debugPrint;
  final previousOnError = FlutterError.onError;

  FlutterError.onError = (FlutterErrorDetails details) {
    (previousOnError ?? FlutterError.presentError)(details);
    _guard(() => capture(details.exception, details.stack));
    write('Uncaught Flutter error: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _guard(() => capture(error, stack));
    write('Uncaught platform error: $error');
    // Returning true marks the error as handled so the isolate stays alive.
    return true;
  };
}

/// A reporting sink must never throw: an exception raised while reporting
/// would replace the original error with a reporting error.
void _guard(void Function() action) {
  try {
    action();
  } on Object catch (reportingError) {
    debugPrint('Error reporting failed: $reportingError');
  }
}

/// Runs [action], logging any failure without rethrowing it.
///
/// Startup work uses this so one broken service degrades the app instead of
/// preventing the first frame. It catches [Object], not [Exception], on
/// purpose: an [Error] (TypeError, StateError, RangeError) is exactly what a
/// buggy initializer throws, and catching only [Exception] would let it escape
/// the startup `Future.wait` and kill `main()` before `runApp` has drawn
/// anything — too early for the branded error widget to help.
Future<void> runGuarded(String label, Future<void> Function() action) async {
  try {
    await action();
  } on Object catch (e, stackTrace) {
    debugPrint('$label failed: $e\n$stackTrace');
  }
}
