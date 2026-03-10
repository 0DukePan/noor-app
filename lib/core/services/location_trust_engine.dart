import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 🌍 محرك ثقة الموقع - Location Trust Engine
/// 
/// Features:
/// - GPS accuracy evaluation
/// - Trusted location caching
/// - Prevents recalculation on low accuracy
/// - Indoor/Outdoor detection
/// - Fallback to last known good location
class LocationTrustEngine {
  static Box? _locationBox;
  
  // Thresholds
  static const double _highAccuracyThreshold = 20.0;   // meters
  static const double _mediumAccuracyThreshold = 100.0;
  static const double _lowAccuracyThreshold = 500.0;
  
  // Cached location
  static TrustedLocation? _cachedLocation;
  static TrustedLocation? get cachedLocation => _cachedLocation;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> init() async {
    _locationBox = await Hive.openBox('location_trust');
    _loadCachedLocation();
  }

  static void _loadCachedLocation() {
    final data = _locationBox?.get('trusted_location');
    if (data != null) {
      _cachedLocation = TrustedLocation.fromMap(Map<String, dynamic>.from(data));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCATION ACQUISITION
  // ═══════════════════════════════════════════════════════════════════════════

  /// الحصول على موقع موثوق
  /// 
  /// Returns cached location if:
  /// - Current GPS accuracy is too low
  /// - Permission denied
  /// - Timeout
  static Future<LocationResult> getTrustedLocation({
    Duration timeout = const Duration(seconds: 15),
    bool forceRefresh = false,
  }) async {
    // Check permission first
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      return _fallbackToCached('صلاحية الموقع مرفوضة');
    }

    // Check if GPS is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _fallbackToCached('خدمة الموقع غير مفعلة');
    }

    // Don't refresh if we have a recent trusted location
    if (!forceRefresh && _cachedLocation != null) {
      final age = DateTime.now().difference(_cachedLocation!.timestamp);
      if (age.inMinutes < 30 && _cachedLocation!.trustLevel.isUsable) {
        debugPrint('Using cached location (age: ${age.inMinutes} min)');
        return LocationResult.success(_cachedLocation!);
      }
    }

    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );

      // Evaluate accuracy
      final trustLevel = _evaluateAccuracy(position.accuracy);
      
      // Create trusted location
      final trusted = TrustedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        trustLevel: trustLevel,
        timestamp: DateTime.now(),
        source: LocationSource.gps,
      );

      // Only cache if accuracy is usable
      if (trustLevel.isUsable) {
        await _cacheLocation(trusted);
      } else if (_cachedLocation != null && _cachedLocation!.trustLevel.isUsable) {
        // Keep using cached if current is not usable
        debugPrint('Current accuracy too low (${position.accuracy}m), using cached');
        return LocationResult.success(
          _cachedLocation!,
          warning: 'دقة GPS منخفضة، استخدام آخر موقع موثوق',
        );
      }

      return LocationResult.success(trusted);
    } on TimeoutException {
      return _fallbackToCached('انتهت مهلة تحديد الموقع');
    } catch (e) {
      return _fallbackToCached('خطأ في تحديد الموقع: $e');
    }
  }

  static LocationResult _fallbackToCached(String reason) {
    if (_cachedLocation != null) {
      debugPrint('$reason - using cached location');
      return LocationResult.success(
        _cachedLocation!,
        warning: '$reason - تم استخدام آخر موقع معروف',
      );
    }
    
    // Ultimate fallback: Makkah coordinates
    debugPrint('$reason - no cached location, using Makkah');
    return LocationResult.success(
      TrustedLocation(
        latitude: 21.4225,
        longitude: 39.8262,
        altitude: 277,
        accuracy: 1000,
        trustLevel: LocationTrustLevel.fallback,
        timestamp: DateTime.now(),
        source: LocationSource.fallback,
      ),
      warning: '$reason - تم استخدام موقع مكة المكرمة كافتراضي',
    );
  }

  static Future<void> _cacheLocation(TrustedLocation location) async {
    _cachedLocation = location;
    await _locationBox?.put('trusted_location', location.toMap());
    debugPrint('Cached location: ${location.latitude}, ${location.longitude} (${location.trustLevel.name})');
  }

  static LocationTrustLevel _evaluateAccuracy(double accuracy) {
    if (accuracy <= _highAccuracyThreshold) {
      return LocationTrustLevel.high;
    }
    if (accuracy <= _mediumAccuracyThreshold) {
      return LocationTrustLevel.medium;
    }
    if (accuracy <= _lowAccuracyThreshold) {
      return LocationTrustLevel.low;
    }
    return LocationTrustLevel.veryLow;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCATION MONITORING
  // ═══════════════════════════════════════════════════════════════════════════

  /// مراقبة الموقع في الخلفية
  static Stream<TrustedLocation> monitorLocation({
    Duration interval = const Duration(minutes: 5),
  }) async* {
    while (true) {
      await Future.delayed(interval);
      final result = await getTrustedLocation();
      if (result.isSuccess) {
        yield result.location!;
      }
    }
  }

  /// كشف الحركة الكبيرة
  static bool hasSignificantMovement(TrustedLocation newLocation, {
    double thresholdKm = 1.0,
  }) {
    if (_cachedLocation == null) return true;
    
    final distance = Geolocator.distanceBetween(
      _cachedLocation!.latitude,
      _cachedLocation!.longitude,
      newLocation.latitude,
      newLocation.longitude,
    );
    
    return distance > (thresholdKm * 1000);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INDOOR/OUTDOOR DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// كشف البيئة (داخلي/خارجي)
  static EnvironmentType detectEnvironment() {
    if (_cachedLocation == null) return EnvironmentType.unknown;
    
    // Based on accuracy
    if (_cachedLocation!.accuracy < 10) {
      return EnvironmentType.outdoor;
    }
    if (_cachedLocation!.accuracy > 50) {
      return EnvironmentType.indoor;
    }
    return EnvironmentType.unknown;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// مسح الكاش
  static Future<void> clearCache() async {
    _cachedLocation = null;
    await _locationBox?.delete('trusted_location');
  }

  /// معلومات آخر موقع
  static String getLastLocationInfo() {
    if (_cachedLocation == null) return 'لا يوجد موقع محفوظ';
    
    final age = DateTime.now().difference(_cachedLocation!.timestamp);
    String ageStr;
    if (age.inMinutes < 60) {
      ageStr = '${age.inMinutes} دقيقة';
    } else if (age.inHours < 24) {
      ageStr = '${age.inHours} ساعة';
    } else {
      ageStr = '${age.inDays} يوم';
    }
    
    return 'دقة: ${_cachedLocation!.accuracy.toStringAsFixed(0)}م | منذ: $ageStr';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// مستوى ثقة الموقع
enum LocationTrustLevel {
  high,     // < 20m - ممتاز
  medium,   // 20-100m - جيد
  low,      // 100-500m - مقبول
  veryLow,  // > 500m - ضعيف
  fallback, // موقع افتراضي
}

extension LocationTrustLevelInfo on LocationTrustLevel {
  String get arabicName {
    switch (this) {
      case LocationTrustLevel.high: return 'ممتاز';
      case LocationTrustLevel.medium: return 'جيد';
      case LocationTrustLevel.low: return 'مقبول';
      case LocationTrustLevel.veryLow: return 'ضعيف';
      case LocationTrustLevel.fallback: return 'افتراضي';
    }
  }

  String get icon {
    switch (this) {
      case LocationTrustLevel.high: return '🟢';
      case LocationTrustLevel.medium: return '🟡';
      case LocationTrustLevel.low: return '🟠';
      case LocationTrustLevel.veryLow: return '🔴';
      case LocationTrustLevel.fallback: return '⚪';
    }
  }

  bool get isUsable => this != LocationTrustLevel.veryLow;
  bool get isReliable => this == LocationTrustLevel.high || this == LocationTrustLevel.medium;
}

/// مصدر الموقع
enum LocationSource {
  gps,
  cached,
  network,
  fallback,
}

/// نوع البيئة
enum EnvironmentType {
  indoor,
  outdoor,
  unknown,
}

/// موقع موثوق
class TrustedLocation {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final LocationTrustLevel trustLevel;
  final DateTime timestamp;
  final LocationSource source;

  const TrustedLocation({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.trustLevel,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'accuracy': accuracy,
    'trustLevel': trustLevel.index,
    'timestamp': timestamp.toIso8601String(),
    'source': source.index,
  };

  factory TrustedLocation.fromMap(Map<String, dynamic> map) {
    return TrustedLocation(
      latitude: map['latitude'] ?? 0,
      longitude: map['longitude'] ?? 0,
      altitude: map['altitude'] ?? 0,
      accuracy: map['accuracy'] ?? 1000,
      trustLevel: LocationTrustLevel.values[map['trustLevel'] ?? 4],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      source: LocationSource.values[map['source'] ?? 3],
    );
  }
}

/// نتيجة الموقع
class LocationResult {
  final bool isSuccess;
  final TrustedLocation? location;
  final String? error;
  final String? warning;

  const LocationResult._({
    required this.isSuccess,
    this.location,
    this.error,
    this.warning,
  });

  factory LocationResult.success(TrustedLocation location, {String? warning}) {
    return LocationResult._(
      isSuccess: true,
      location: location,
      warning: warning,
    );
  }

  factory LocationResult.failure(String error) {
    return LocationResult._(
      isSuccess: false,
      error: error,
    );
  }
}
