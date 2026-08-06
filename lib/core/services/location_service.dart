import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../features/prayer/domain/entities/prayer_entities.dart';

/// خدمة الموقع - Location Service
class LocationService {
  StreamSubscription<Position>? _positionSubscription;

  /// Check if location services are enabled
  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Get current location
  Future<Location?> getCurrentLocation() async {
    try {
      final permission = await requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return Location(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
      );
    } catch (e) {
      return null;
    }
  }

  /// Start listening to location updates
  Stream<Location> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    ).map((position) => Location(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
        ));
  }

  /// Calculate distance between two locations (in km)
  double calculateDistance(Location from, Location to) {
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000;
  }

  /// Stop location updates
  void stopLocationUpdates() {
    _positionSubscription?.cancel();
  }
}
