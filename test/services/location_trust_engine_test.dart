import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/location_trust_engine.dart';

/// Tests LocationTrustEngine's cached-location loading and the
/// TrustedLocation mapping.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_location_test');
    Hive.init(tempDir.path);
    await LocationTrustEngine.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('no cached location initially', () {
    expect(LocationTrustEngine.cachedLocation, isNull);
  });

  test('a stored location is loaded and mapped on init', () async {
    final box = await Hive.openBox<dynamic>('location_trust');
    await box.put('trusted_location', {
      'latitude': 21.4225,
      'longitude': 39.8262,
      'altitude': 298.0,
      'accuracy': 25.0,
      'trustLevel': 4,
      'timestamp': '2026-08-01T12:00:00.000',
      'source': 2,
    });

    // Reload the engine so it reads the seeded box.
    await LocationTrustEngine.init();
    final cached = LocationTrustEngine.cachedLocation;
    expect(cached, isNotNull);
    expect(cached!.latitude, 21.4225);
    expect(cached.longitude, 39.8262);
    expect(cached.altitude, 298.0);
    expect(cached.accuracy, 25.0);
  });

  test('getLastLocationInfo describes a cached location', () async {
    final box = await Hive.openBox<dynamic>('location_trust');
    await box.put('trusted_location', {
      'latitude': 21.4225,
      'longitude': 39.8262,
      'altitude': 0.0,
      'accuracy': 30.0,
      'trustLevel': 3,
      'timestamp': DateTime.now().toIso8601String(),
      'source': 0,
    });
    await LocationTrustEngine.init();
    final info = LocationTrustEngine.getLastLocationInfo();
    expect(info, isNotEmpty);
  });
}
