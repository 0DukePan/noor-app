import 'dart:math' as math;

/// 🧭 محرك القبلة الاحترافي - Professional Qibla Engine
/// 
/// Features:
/// - Astronomical Qibla calculation
/// - Magnetic declination correction
/// - Great Circle formula
/// - Offline-first (no API needed for calculation)
class QiblaEngine {
  // 🕋 إحداثيات الكعبة المشرفة (ثابتة)
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  // ═══════════════════════════════════════════════════════════════════════════
  // QIBLA CALCULATION (Great Circle Formula)
  // ═══════════════════════════════════════════════════════════════════════════

  /// حساب اتجاه القبلة الفلكي
  /// 
  /// Uses the Great Circle formula (spherical trigonometry)
  /// Returns bearing in degrees from True North (0-360)
  static double calculateQiblaDirection({
    required double latitude,
    required double longitude,
  }) {
    // Convert to radians
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final dLon = _toRadians(kaabaLongitude - longitude);

    // Great Circle formula
    // Qibla = atan2(sin(dLon), cos(lat1)*tan(lat2) - sin(lat1)*cos(dLon))
    final x = math.sin(dLon);
    final y = math.cos(lat1) * math.tan(lat2) - math.sin(lat1) * math.cos(dLon);
    
    var qibla = math.atan2(x, y);
    
    // Convert to degrees
    qibla = _toDegrees(qibla);
    
    // Normalize to 0-360
    return (qibla + 360) % 360;
  }

  /// حساب المسافة إلى الكعبة (Haversine Formula)
  static double calculateDistanceToKaaba({
    required double latitude,
    required double longitude,
  }) {
    const earthRadius = 6371.0; // km
    
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final dLat = _toRadians(kaabaLatitude - latitude);
    final dLon = _toRadians(kaabaLongitude - longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAGNETIC DECLINATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// الحصول على الانحراف المغناطيسي التقريبي
  /// 
  /// Note: For production, use NOAA's World Magnetic Model API
  /// This is a simplified approximation based on region
  static double getMagneticDeclination({
    required double latitude,
    required double longitude,
  }) {
    // Simplified regional approximations (2024 values)
    // For production: use https://www.ngdc.noaa.gov/geomag/calculators/magcalc.shtml
    
    // Middle East region (Saudi Arabia, UAE, etc.)
    if (latitude >= 15 && latitude <= 35 && longitude >= 30 && longitude <= 60) {
      return 2.5; // ~2.5° East
    }
    
    // North Africa (Egypt, Libya, etc.)
    if (latitude >= 20 && latitude <= 35 && longitude >= -10 && longitude <= 35) {
      return 1.5; // ~1.5° East
    }
    
    // Europe
    if (latitude >= 35 && latitude <= 70 && longitude >= -10 && longitude <= 40) {
      return 0.0; // Varies significantly, ~0° average
    }
    
    // South Asia (India, Pakistan, etc.)
    if (latitude >= 5 && latitude <= 40 && longitude >= 60 && longitude <= 100) {
      return -1.0; // ~1° West
    }
    
    // Southeast Asia
    if (latitude >= -10 && latitude <= 25 && longitude >= 95 && longitude <= 145) {
      return 0.5;
    }
    
    // North America (East)
    if (latitude >= 25 && latitude <= 50 && longitude >= -90 && longitude <= -60) {
      return -14.0; // ~14° West
    }
    
    // North America (West)
    if (latitude >= 25 && latitude <= 50 && longitude >= -130 && longitude <= -100) {
      return 12.0; // ~12° East
    }
    
    // Default: assume minimal declination
    return 0.0;
  }

  /// تصحيح البوصلة بالانحراف المغناطيسي
  static double correctForDeclination({
    required double magneticHeading,
    required double declination,
  }) {
    // True North = Magnetic North + Declination
    return (magneticHeading + declination + 360) % 360;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPASS ACCURACY
  // ═══════════════════════════════════════════════════════════════════════════

  /// تقييم دقة البوصلة
  static CompassAccuracy evaluateAccuracy(double accuracy) {
    if (accuracy < 0) return CompassAccuracy.unknown;
    if (accuracy <= 5) return CompassAccuracy.high;
    if (accuracy <= 15) return CompassAccuracy.medium;
    if (accuracy <= 30) return CompassAccuracy.low;
    return CompassAccuracy.unreliable;
  }

  /// هل تحتاج البوصلة لمعايرة؟
  static bool needsCalibration(double accuracy) {
    return accuracy > 15;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QIBLA ALIGNMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// حساب زاوية الانحراف عن القبلة
  static double getDeviationFromQibla({
    required double currentHeading,
    required double qiblaDirection,
  }) {
    var deviation = qiblaDirection - currentHeading;
    
    // Normalize to -180 to +180
    if (deviation > 180) deviation -= 360;
    if (deviation < -180) deviation += 360;
    
    return deviation;
  }

  /// هل الجهاز يواجه القبلة؟
  static QiblaAlignment getAlignment({
    required double currentHeading,
    required double qiblaDirection,
    double tolerance = 5.0,
  }) {
    final deviation = getDeviationFromQibla(
      currentHeading: currentHeading,
      qiblaDirection: qiblaDirection,
    ).abs();

    if (deviation <= tolerance) return QiblaAlignment.aligned;
    if (deviation <= 15) return QiblaAlignment.close;
    if (deviation <= 45) return QiblaAlignment.moderate;
    return QiblaAlignment.far;
  }

  /// اتجاه الدوران المطلوب
  static String getRotationDirection({
    required double currentHeading,
    required double qiblaDirection,
  }) {
    final deviation = getDeviationFromQibla(
      currentHeading: currentHeading,
      qiblaDirection: qiblaDirection,
    );

    if (deviation.abs() < 5) return 'مُوجَّه';
    if (deviation > 0) return 'أدر لليمين';
    return 'أدر لليسار';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  static double _toRadians(double degrees) => degrees * math.pi / 180;
  static double _toDegrees(double radians) => radians * 180 / math.pi;

  /// تنسيق الاتجاه كنص
  static String formatDirection(double degrees) {
    final normalized = degrees % 360;
    
    if (normalized < 22.5 || normalized >= 337.5) return 'شمال';
    if (normalized < 67.5) return 'شمال شرق';
    if (normalized < 112.5) return 'شرق';
    if (normalized < 157.5) return 'جنوب شرق';
    if (normalized < 202.5) return 'جنوب';
    if (normalized < 247.5) return 'جنوب غرب';
    if (normalized < 292.5) return 'غرب';
    return 'شمال غرب';
  }

  /// تنسيق المسافة
  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} م';
    if (km < 100) return '${km.toStringAsFixed(1)} كم';
    return '${km.round()} كم';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// دقة البوصلة
enum CompassAccuracy {
  high,       // < 5°
  medium,     // 5-15°
  low,        // 15-30°
  unreliable, // > 30°
  unknown,
}

extension CompassAccuracyInfo on CompassAccuracy {
  String get arabicName {
    switch (this) {
      case CompassAccuracy.high: return 'عالية';
      case CompassAccuracy.medium: return 'متوسطة';
      case CompassAccuracy.low: return 'منخفضة';
      case CompassAccuracy.unreliable: return 'غير موثوقة';
      case CompassAccuracy.unknown: return 'غير معروفة';
    }
  }

  String get icon {
    switch (this) {
      case CompassAccuracy.high: return '🟢';
      case CompassAccuracy.medium: return '🟡';
      case CompassAccuracy.low: return '🟠';
      case CompassAccuracy.unreliable: return '🔴';
      case CompassAccuracy.unknown: return '⚪';
    }
  }

  bool get needsCalibration => 
      this == CompassAccuracy.low || this == CompassAccuracy.unreliable;
}

/// حالة التوجه نحو القبلة
enum QiblaAlignment {
  aligned,   // < 5° - مُوجَّه
  close,     // 5-15° - قريب
  moderate,  // 15-45° - متوسط
  far,       // > 45° - بعيد
}

extension QiblaAlignmentInfo on QiblaAlignment {
  String get message {
    switch (this) {
      case QiblaAlignment.aligned: return '✓ أنت تواجه القبلة';
      case QiblaAlignment.close: return 'قريب جدًا، عدّل قليلًا';
      case QiblaAlignment.moderate: return 'أدر الجهاز نحو القبلة';
      case QiblaAlignment.far: return 'اتجه نحو السهم';
    }
  }

  bool get isAligned => this == QiblaAlignment.aligned;
}

/// نتيجة حساب القبلة الكاملة
class QiblaResult {
  final double trueQiblaDirection;    // من الشمال الحقيقي
  final double magneticQiblaDirection; // من الشمال المغناطيسي
  final double declination;
  final double distanceToKaaba;
  final String directionText;

  const QiblaResult({
    required this.trueQiblaDirection,
    required this.magneticQiblaDirection,
    required this.declination,
    required this.distanceToKaaba,
    required this.directionText,
  });

  factory QiblaResult.calculate({
    required double latitude,
    required double longitude,
  }) {
    final trueQibla = QiblaEngine.calculateQiblaDirection(
      latitude: latitude,
      longitude: longitude,
    );
    
    final declination = QiblaEngine.getMagneticDeclination(
      latitude: latitude,
      longitude: longitude,
    );
    
    final magneticQibla = (trueQibla - declination + 360) % 360;
    
    final distance = QiblaEngine.calculateDistanceToKaaba(
      latitude: latitude,
      longitude: longitude,
    );

    return QiblaResult(
      trueQiblaDirection: trueQibla,
      magneticQiblaDirection: magneticQibla,
      declination: declination,
      distanceToKaaba: distance,
      directionText: QiblaEngine.formatDirection(trueQibla),
    );
  }
}

/// إعدادات وضع المسجد
class MosqueMode {
  final bool enabled;
  final bool permanentLock;
  final bool ignoreVibrations;
  final bool noAutoTimeout;
  final double lockedDirection;

  const MosqueMode({
    this.enabled = false,
    this.permanentLock = true,
    this.ignoreVibrations = true,
    this.noAutoTimeout = true,
    this.lockedDirection = 0,
  });

  MosqueMode copyWith({
    bool? enabled,
    bool? permanentLock,
    bool? ignoreVibrations,
    bool? noAutoTimeout,
    double? lockedDirection,
  }) {
    return MosqueMode(
      enabled: enabled ?? this.enabled,
      permanentLock: permanentLock ?? this.permanentLock,
      ignoreVibrations: ignoreVibrations ?? this.ignoreVibrations,
      noAutoTimeout: noAutoTimeout ?? this.noAutoTimeout,
      lockedDirection: lockedDirection ?? this.lockedDirection,
    );
  }
}
