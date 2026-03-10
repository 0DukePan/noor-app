import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import '../../features/prayer/domain/entities/prayer_entities.dart';

/// خدمة البوصلة والقبلة - Compass & Qibla Service
class CompassService {
  // Kaaba coordinates
  static const double _kaabaLatitude = 21.4225;
  static const double _kaabaLongitude = 39.8262;

  StreamSubscription<CompassEvent>? _compassSubscription;
  double _calibrationOffset = 0;

  /// Check if compass is available
  Future<bool> isCompassAvailable() async {
    final events = await FlutterCompass.events?.first;
    return events != null;
  }

  /// Get compass heading stream
  Stream<double> getHeadingStream() {
    return FlutterCompass.events?.map((event) {
          final heading = event.heading ?? 0;
          return (heading + _calibrationOffset) % 360;
        }) ??
        const Stream.empty();
  }

  /// Calculate Qibla direction from a location
  double calculateQiblaDirection(Location location) {
    final lat1 = _toRadians(location.latitude);
    final lon1 = _toRadians(location.longitude);
    final lat2 = _toRadians(_kaabaLatitude);
    final lon2 = _toRadians(_kaabaLongitude);

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var bearing = math.atan2(y, x);
    bearing = _toDegrees(bearing);
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  /// Calculate distance to Kaaba in km
  double calculateDistanceToKaaba(Location location) {
    const earthRadius = 6371.0; // km

    final lat1 = _toRadians(location.latitude);
    final lon1 = _toRadians(location.longitude);
    final lat2 = _toRadians(_kaabaLatitude);
    final lon2 = _toRadians(_kaabaLongitude);

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calibrate compass with offset
  void calibrate(double offset) {
    _calibrationOffset = offset;
  }

  /// Reset calibration
  void resetCalibration() {
    _calibrationOffset = 0;
  }

  /// Get Qibla data with current heading
  Stream<QiblaData> getQiblaDataStream(Location location) {
    final qiblaDirection = calculateQiblaDirection(location);
    final distance = calculateDistanceToKaaba(location);

    return getHeadingStream().map((heading) => QiblaData(
          qiblaDirection: qiblaDirection,
          currentHeading: heading,
          distanceToKaaba: distance,
        ));
  }

  /// Stop compass updates
  void stopCompass() {
    _compassSubscription?.cancel();
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);
  double _toDegrees(double radians) => radians * (180 / math.pi);
}
