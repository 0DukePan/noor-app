import 'package:equatable/equatable.dart';

/// وقت صلاة - Prayer Time Entity
class PrayerTime extends Equatable {
  final String name;
  final String nameArabic;
  final DateTime time;
  final bool isPassed;
  final bool isNext;

  const PrayerTime({
    required this.name,
    required this.nameArabic,
    required this.time,
    this.isPassed = false,
    this.isNext = false,
  });

  @override
  List<Object?> get props => [name, time];
}

/// مواقيت اليوم - Daily Prayer Times
class DailyPrayerTimes extends Equatable {
  final DateTime date;
  final PrayerTime fajr;
  final PrayerTime sunrise;
  final PrayerTime dhuhr;
  final PrayerTime asr;
  final PrayerTime maghrib;
  final PrayerTime isha;
  final Location location;
  final CalculationMethod method;

  const DailyPrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.location,
    required this.method,
  });

  List<PrayerTime> get allPrayers => [fajr, sunrise, dhuhr, asr, maghrib, isha];

  PrayerTime? get nextPrayer {
    final now = DateTime.now();
    for (final prayer in allPrayers) {
      if (prayer.time.isAfter(now)) return prayer;
    }
    return null;
  }

  @override
  List<Object?> get props => [date, location, method];
}

/// الموقع - Location
class Location extends Equatable {
  final double latitude;
  final double longitude;
  final double? altitude;
  final String? cityName;
  final String? countryName;
  final String? timezone;

  const Location({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.cityName,
    this.countryName,
    this.timezone,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// طريقة الحساب - Calculation Method
enum CalculationMethod {
  /// رابطة العالم الإسلامي
  muslimWorldLeague,

  /// أم القرى (مكة)
  ummAlQura,

  /// الهيئة المصرية
  egyptian,

  /// أمريكا الشمالية (ISNA)
  isna,

  /// كراتشي
  karachi,

  /// طهران
  tehran,

  /// الخليج
  gulf,

  /// الكويت
  kuwait,

  /// قطر
  qatar,

  /// سنغافورة
  singapore,
}

/// بيانات القبلة - Qibla Data
class QiblaData extends Equatable {
  final double qiblaDirection;
  final double currentHeading;
  final double distanceToKaaba;
  final bool isLocked;
  final bool isCalibrated;

  const QiblaData({
    required this.qiblaDirection,
    required this.currentHeading,
    required this.distanceToKaaba,
    this.isLocked = false,
    this.isCalibrated = true,
  });

  double get offset => qiblaDirection - currentHeading;

  bool get isAligned => offset.abs() < 5 || (360 - offset.abs()) < 5;

  @override
  List<Object?> get props => [qiblaDirection, currentHeading, isLocked];
}

/// سجل القضاء - Qada Record
class QadaRecord extends Equatable {
  final String id;
  final QadaType type;
  final int totalCount;
  final int completedCount;
  final DateTime? startDate;
  final String? notes;

  const QadaRecord({
    required this.id,
    required this.type,
    required this.totalCount,
    required this.completedCount,
    this.startDate,
    this.notes,
  });

  int get remainingCount => totalCount - completedCount;
  double get progressPercentage => totalCount > 0 ? completedCount / totalCount : 0;

  @override
  List<Object?> get props => [id, type, totalCount, completedCount];
}

/// نوع القضاء - Qada Type
enum QadaType {
  /// صلاة - Prayer
  prayer,

  /// صيام - Fasting
  fasting,
}
