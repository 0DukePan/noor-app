import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:noor_app/core/services/location_service.dart';
import 'package:noor_app/features/prayer/domain/entities/prayer_entities.dart';

/// Tests for LocationService (previously zero-covered): the geolocator
/// channel is mocked so the permission/denied/error branches are exercised
/// deterministically (unmocked plugin channels hang in tests, they never
/// throw).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  late List<MethodCall> calls;

  void mockGeolocator(
    Future<Object?> Function(MethodCall call) handler,
  ) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  setUp(() {
    calls = [];
  });

  test('granted permission returns the location', () async {
    mockGeolocator((call) async {
      calls.add(call);
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
            'altitude': 600.0,
            'heading': 0.0,
            'speed': 0.0,
            'timestamp': DateTime(2026).millisecondsSinceEpoch,
          };
      }
      return null;
    });

    final location = await LocationService().getCurrentLocation();
    expect(location, isNotNull);
    expect(location!.latitude, closeTo(21.4225, 1e-6));
    expect(location.longitude, closeTo(39.8262, 1e-6));
    expect(location.altitude, 600.0);
    expect(calls.map((c) => c.method), contains('getCurrentPosition'));
  });

  test('denied permission returns null without calling the position API',
      () async {
    mockGeolocator((call) async {
      calls.add(call);
      if (call.method == 'checkPermission') return 0; // denied
      if (call.method == 'requestPermission') return 0; // still denied
      return null;
    });

    final location = await LocationService().getCurrentLocation();
    expect(location, isNull);
    expect(calls.map((c) => c.method), isNot(contains('getCurrentPosition')));
  });

  test('a channel error degrades to null', () async {
    mockGeolocator((call) async {
      throw PlatformException(code: 'LOCATION_UNAVAILABLE');
    });

    expect(await LocationService().getCurrentLocation(), isNull);
  });

  test('isLocationEnabled and requestPermission delegate to the channel',
      () async {
    mockGeolocator((call) async {
      calls.add(call);
      if (call.method == 'isLocationServiceEnabled') return false;
      if (call.method == 'checkPermission') return 2; // whileInUse
      return null;
    });

    final service = LocationService();
    expect(await service.isLocationEnabled(), isFalse);
    expect(await service.requestPermission(), LocationPermission.whileInUse);
  });

  test('calculateDistance computes the real haversine distance in km',
      () async {
    // Geolocator.distanceBetween is pure Dart (no channel), so this is a real
    // geodesic check: Mecca -> Riyadh is ~791 km by the haversine formula.
    final km = LocationService().calculateDistance(
      const Location(latitude: 21.4225, longitude: 39.8262),
      const Location(latitude: 24.7136, longitude: 46.6753),
    );
    expect(km, closeTo(791.19, 0.01));
  });
}
