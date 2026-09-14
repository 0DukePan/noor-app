// Prayer time data classes - prayer_time_models.dart
// Extracted from prayer_time_engine.dart (Phase 1 god-file split).

/// Prayer times for a day
class PrayerTimes {

  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
  });
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime date;

  /// Get next prayer
  PrayerType? getNextPrayer() {
    final now = DateTime.now();
    if (now.isBefore(fajr)) return PrayerType.fajr;
    if (now.isBefore(sunrise)) return PrayerType.sunrise;
    if (now.isBefore(dhuhr)) return PrayerType.dhuhr;
    if (now.isBefore(asr)) return PrayerType.asr;
    if (now.isBefore(maghrib)) return PrayerType.maghrib;
    if (now.isBefore(isha)) return PrayerType.isha;
    return null;
  }

  /// Get time for prayer type
  DateTime getTime(PrayerType type) {
    switch (type) {
      case PrayerType.fajr: return fajr;
      case PrayerType.sunrise: return sunrise;
      case PrayerType.dhuhr: return dhuhr;
      case PrayerType.asr: return asr;
      case PrayerType.maghrib: return maghrib;
      case PrayerType.isha: return isha;
    }
  }

  /// Get all prayer times as list
  List<MapEntry<PrayerType, DateTime>> get all => [
    MapEntry(PrayerType.fajr, fajr),
    MapEntry(PrayerType.sunrise, sunrise),
    MapEntry(PrayerType.dhuhr, dhuhr),
    MapEntry(PrayerType.asr, asr),
    MapEntry(PrayerType.maghrib, maghrib),
    MapEntry(PrayerType.isha, isha),
  ];
}

/// Calculation method parameters
class CalculationParams {

  const CalculationParams({
    required this.name,
    required this.fajrAngle,
    required this.ishaAngle,
    this.ishaInterval,
    this.maghribAngle,
  });
  final String name;
  final double fajrAngle;
  final double ishaAngle;
  final int? ishaInterval; // Minutes after Maghrib
  final double? maghribAngle;
}

/// Manual time adjustments
class PrayerAdjustments {

  const PrayerAdjustments({
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });
  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;
}

/// Prayer types
enum PrayerType { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerTypeExtension on PrayerType {
  String get arabicName {
    switch (this) {
      case PrayerType.fajr: return 'الفجر';
      case PrayerType.sunrise: return 'الشروق';
      case PrayerType.dhuhr: return 'الظهر';
      case PrayerType.asr: return 'العصر';
      case PrayerType.maghrib: return 'المغرب';
      case PrayerType.isha: return 'العشاء';
    }
  }
}

/// Calculation methods
enum CalculationMethod {
  // الطرق الأساسية
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  qatar,
  kuwait,
  singapore,
  turkey,
  tehran,
  northAmerica,

  // 🇪🇺 أوروبا - الطرق الرسمية
  europeanCouncil,      // المجلس الأوروبي للإفتاء
  moonsightingCommittee,// Moonsighting Committee Worldwide
  france,               // فرنسا UOIF
  germany,              // ألمانيا IGMG
  uk,                   // بريطانيا

  // 🇲🇦 شمال إفريقيا - الطرق الرسمية
  morocco,              // وزارة الأوقاف المغربية
  algeriaTunisia,       // الجزائر / تونس
  libya,                // ليبيا
}

/// Madhab for Asr calculation
enum Madhab { shafi, hanafi }

/// High latitude rule
enum HighLatitudeRule { middleOfNight, seventhOfNight, twilightAngle }
