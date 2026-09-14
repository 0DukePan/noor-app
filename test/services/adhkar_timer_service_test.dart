import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/adhkar_timer_service.dart';
import 'package:noor_app/core/services/prayer_time_models.dart';

/// Tests for AdhkarTimerService (previously zero-covered). init() refreshes
/// prayer times through LocationTrustEngine, so the geolocator and geocoding
/// channels are mocked (they hang, not throw, when unmocked); the time-window
/// getters are then exercised for valid outputs and the enum extensions are
/// covered directly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (call) async {
          switch (call.method) {
            case 'isLocationServiceEnabled':
              return true;
            case 'checkPermission':
              return 3; // always
            case 'getCurrentPosition':
              return <String, dynamic>{
                'latitude': 21.4225,
                'longitude': 39.8262,
                'accuracy': 5.0,
                'altitude': 0.0,
                'heading': 0.0,
                'speed': 0.0,
                'timestamp': DateTime(2026).millisecondsSinceEpoch,
              };
          }
          return null;
        },
      )
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/geocoding'),
        (call) async => <dynamic>[],
      );
  });

  test('init completes and the availability getters return valid values',
      () async {
    await AdhkarTimerService.init();

    expect(AdhkarTimerService.isMorningAdhkarAvailable, isA<bool>());
    expect(AdhkarTimerService.isEveningAdhkarAvailable, isA<bool>());
    expect(AdhkarTimerService.isPostPrayerAdhkarAvailable, isA<bool>());
  });

  test('next prayer and current prayer are computed from the loaded times',
      () async {
    await AdhkarTimerService.init();

    final next = AdhkarTimerService.getNextPrayer();
    expect(next, isA<PrayerType>());

    // getCurrentPrayer() must return without throwing (the exact value
    // depends on the wall-clock time, which the test cannot control).
    AdhkarTimerService.getCurrentPrayer();

    final untilNext = AdhkarTimerService.getTimeUntilNextPrayer();
    expect(untilNext == null || untilNext.inSeconds >= 0, isTrue);
  });

  test('getNextStartTime for morning adhkar is always in the future', () async {
    await AdhkarTimerService.init();

    final nextStart = AdhkarTimerService.getNextStartTime(AdhkarType.morning);
    expect(nextStart, isNotNull);
    expect(nextStart!.isAfter(DateTime.now()), isTrue);
  });

  test('getCurrentAdhkarType returns a valid type or null', () async {
    await AdhkarTimerService.init();

    final type = AdhkarTimerService.getCurrentAdhkarType();
    if (type != null) {
      expect(AdhkarType.values, contains(type));
    }
  });

  test('AdhkarType extension provides Arabic names and time descriptions', () {
    for (final type in AdhkarType.values) {
      expect(type.arabicName, isNotEmpty);
      expect(type.timeDescription, isNotEmpty);
    }
  });
}
