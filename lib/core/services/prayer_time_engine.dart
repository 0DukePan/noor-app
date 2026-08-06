import 'dart:math';

/// 🕌 محرك حساب مواقيت الصلاة - Prayer Time Engine
/// حساب فلكي دقيق مع تصحيح الارتفاع والمناطق الباردة
class PrayerTimeEngine {
  // ═══════════════════════════════════════════════════════════════════════════
  // CALCULATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<CalculationMethod, CalculationParams> methods = {
    CalculationMethod.muslimWorldLeague: CalculationParams(
      name: 'رابطة العالم الإسلامي',
      fajrAngle: 18.0,
      ishaAngle: 17.0,
    ),
    CalculationMethod.egyptian: CalculationParams(
      name: 'الهيئة المصرية',
      fajrAngle: 19.5,
      ishaAngle: 17.5,
    ),
    CalculationMethod.karachi: CalculationParams(
      name: 'جامعة كراتشي',
      fajrAngle: 18.0,
      ishaAngle: 18.0,
    ),
    CalculationMethod.ummAlQura: CalculationParams(
      name: 'أم القرى',
      fajrAngle: 18.5,
      ishaAngle: 0.0,
      ishaInterval: 90,
    ),
    CalculationMethod.dubai: CalculationParams(
      name: 'دبي',
      fajrAngle: 18.2,
      ishaAngle: 18.2,
    ),
    CalculationMethod.qatar: CalculationParams(
      name: 'قطر',
      fajrAngle: 18.0,
      ishaAngle: 0.0,
      ishaInterval: 90,
    ),
    CalculationMethod.kuwait: CalculationParams(
      name: 'الكويت',
      fajrAngle: 18.0,
      ishaAngle: 17.5,
    ),
    CalculationMethod.singapore: CalculationParams(
      name: 'سنغافورة',
      fajrAngle: 20.0,
      ishaAngle: 18.0,
    ),
    CalculationMethod.turkey: CalculationParams(
      name: 'تركيا',
      fajrAngle: 18.0,
      ishaAngle: 17.0,
    ),
    CalculationMethod.tehran: CalculationParams(
      name: 'طهران',
      fajrAngle: 17.7,
      ishaAngle: 14.0,
      maghribAngle: 4.5,
    ),
    CalculationMethod.northAmerica: CalculationParams(
      name: 'ISNA أمريكا الشمالية',
      fajrAngle: 15.0,
      ishaAngle: 15.0,
    ),
    
    // 🇪🇺 أوروبا - الطرق الرسمية
    CalculationMethod.europeanCouncil: CalculationParams(
      name: 'المجلس الأوروبي للإفتاء',
      fajrAngle: 18.0,
      ishaAngle: 18.0,
    ),
    CalculationMethod.moonsightingCommittee: CalculationParams(
      name: 'Moonsighting Committee',
      fajrAngle: 18.0,
      ishaAngle: 18.0,
    ),
    CalculationMethod.france: CalculationParams(
      name: 'فرنسا (UOIF)',
      fajrAngle: 12.0,
      ishaAngle: 12.0,
    ),
    CalculationMethod.germany: CalculationParams(
      name: 'ألمانيا (IGMG)',
      fajrAngle: 18.0,
      ishaAngle: 17.0,
    ),
    CalculationMethod.uk: CalculationParams(
      name: 'بريطانيا (London Fatwa Council)',
      fajrAngle: 18.0,
      ishaAngle: 18.0,
    ),
    
    // 🇲🇦 شمال إفريقيا - الطرق الرسمية
    CalculationMethod.morocco: CalculationParams(
      name: 'وزارة الأوقاف المغربية',
      fajrAngle: 19.0,
      ishaAngle: 17.0,
    ),
    CalculationMethod.algeriaTunisia: CalculationParams(
      name: 'الجزائر / تونس',
      fajrAngle: 18.0,
      ishaAngle: 18.0,
    ),
    CalculationMethod.libya: CalculationParams(
      name: 'ليبيا',
      fajrAngle: 18.5,
      ishaAngle: 18.0,
    ),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate prayer times for a specific date and location
  static PrayerTimes calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod method,
    Madhab madhab = Madhab.shafi,
    HighLatitudeRule highLatitudeRule = HighLatitudeRule.middleOfNight,
    double elevation = 0,
    PrayerAdjustments? adjustments,
  }) {
    final params = methods[method]!;
    final jd = _julianDay(date);
    
    // Solar calculations
    final sunDeclination = _sunDeclination(jd);
    final equationOfTime = _equationOfTime(jd);
    
    // Elevation adjustment
    final elevationAngle = elevation > 0 ? 0.0347 * sqrt(elevation) : 0;
    
    // Calculate each prayer time
    final dhuhr = _calculateDhuhr(longitude, equationOfTime, date);
    final sunrise = _calculateSunAngle(
      latitude, sunDeclination, -0.833 - elevationAngle, dhuhr, false,
    );
    final fajr = _calculateSunAngle(
      latitude, sunDeclination, -params.fajrAngle, dhuhr, false,
    );
    final maghrib = _calculateSunAngle(
      latitude, sunDeclination, 
      params.maghribAngle != null ? -params.maghribAngle! : -0.833 - elevationAngle, 
      dhuhr, true,
    );
    final asr = _calculateAsr(
      latitude, sunDeclination, dhuhr, madhab,
    );
    
    // Isha calculation
    DateTime isha;
    if (params.ishaInterval != null) {
      isha = maghrib.add(Duration(minutes: params.ishaInterval!));
    } else {
      isha = _calculateSunAngle(
        latitude, sunDeclination, -params.ishaAngle, dhuhr, true,
      );
    }
    
    // High latitude adjustments
    final times = _applyHighLatitudeRule(
      highLatitudeRule,
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
    );
    
    // Apply manual adjustments
    final adjusted = _applyAdjustments(times, adjustments);
    
    return adjusted;
  }

  /// Calculate prayer times for a week
  static List<PrayerTimes> calculateWeek({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required CalculationMethod method,
    Madhab madhab = Madhab.shafi,
    HighLatitudeRule highLatitudeRule = HighLatitudeRule.middleOfNight,
    double elevation = 0,
    PrayerAdjustments? adjustments,
  }) {
    return List.generate(7, (i) {
      return calculate(
        latitude: latitude,
        longitude: longitude,
        date: startDate.add(Duration(days: i)),
        method: method,
        madhab: madhab,
        highLatitudeRule: highLatitudeRule,
        elevation: elevation,
        adjustments: adjustments,
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOLAR CALCULATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static double _julianDay(DateTime date) {
    int year = date.year;
    int month = date.month;
    final d = date.day;
    
    // تصحيح الشهر (بدون recursion)
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    
    return (365.25 * (year + 4716)).floor() +
           (30.6001 * (month + 1)).floor() +
           d + b - 1524.5;
  }

  static double _sunDeclination(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final l0 = 280.46646 + t * (36000.76983 + 0.0003032 * t);
    final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    
    final c = (1.914602 - t * (0.004817 + 0.000014 * t)) * _sin(m) +
              (0.019993 - 0.000101 * t) * _sin(2 * m) +
              0.000289 * _sin(3 * m);
    
    final sunLong = l0 + c;
    final omega = 125.04 - 1934.136 * t;
    final lambda = sunLong - 0.00569 - 0.00478 * _sin(omega);
    
    final eps0 = 23.439291 - t * (0.013004167 + t * (0.00000016389 - t * 0.0000005036));
    final eps = eps0 + 0.00256 * _cos(omega);
    
    return _arcsin(_sin(eps) * _sin(lambda));
  }

  static double _equationOfTime(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final l0 = 280.46646 + t * (36000.76983 + 0.0003032 * t);
    final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    
    var y = _tan(23.439291 / 2);
    y *= y;
    
    final eqTime = y * _sin(2 * l0) -
                   2 * e * _sin(m) +
                   4 * e * y * _sin(m) * _cos(2 * l0) -
                   0.5 * y * y * _sin(4 * l0) -
                   1.25 * e * e * _sin(2 * m);
    
    return eqTime * 4; // Convert to minutes
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRAYER TIME CALCULATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static DateTime _calculateDhuhr(double longitude, double eqTime, DateTime date) {
    final noon = 12 - longitude / 15 - eqTime / 60;
    return _toDateTime(date, noon);
  }

  static DateTime _calculateSunAngle(
    double latitude,
    double declination,
    double angle,
    DateTime dhuhr,
    bool isAfternoon,
  ) {
    final hourAngle = _arccos(
      (_sin(angle) - _sin(latitude) * _sin(declination)) /
      (_cos(latitude) * _cos(declination))
    ) / 15;
    
    if (isAfternoon) {
      return dhuhr.add(Duration(minutes: (hourAngle * 60).round()));
    } else {
      return dhuhr.subtract(Duration(minutes: (hourAngle * 60).round()));
    }
  }

  static DateTime _calculateAsr(
    double latitude,
    double declination,
    DateTime dhuhr,
    Madhab madhab,
  ) {
    final shadowLength = madhab == Madhab.hanafi ? 2 : 1;
    final angle = -_arccot(shadowLength + _tan((latitude - declination).abs()));
    
    return _calculateSunAngle(latitude, declination, angle, dhuhr, true);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HIGH LATITUDE ADJUSTMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  static PrayerTimes _applyHighLatitudeRule(
    HighLatitudeRule rule, {
    required DateTime fajr,
    required DateTime sunrise,
    required DateTime dhuhr,
    required DateTime asr,
    required DateTime maghrib,
    required DateTime isha,
  }) {
    // If times are valid, no adjustment needed
    if (fajr.isBefore(sunrise) && isha.isAfter(maghrib)) {
      return PrayerTimes(
        fajr: fajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        date: fajr,
      );
    }
    
    final nightDuration = sunrise.difference(maghrib.subtract(const Duration(days: 1)));
    
    switch (rule) {
      case HighLatitudeRule.middleOfNight:
        final halfNight = nightDuration.inMinutes ~/ 2;
        return PrayerTimes(
          fajr: sunrise.subtract(Duration(minutes: halfNight)),
          sunrise: sunrise,
          dhuhr: dhuhr,
          asr: asr,
          maghrib: maghrib,
          isha: maghrib.add(Duration(minutes: halfNight)),
          date: fajr,
        );
        
      case HighLatitudeRule.seventhOfNight:
        final seventh = nightDuration.inMinutes ~/ 7;
        return PrayerTimes(
          fajr: sunrise.subtract(Duration(minutes: seventh)),
          sunrise: sunrise,
          dhuhr: dhuhr,
          asr: asr,
          maghrib: maghrib,
          isha: maghrib.add(Duration(minutes: seventh)),
          date: fajr,
        );
        
      case HighLatitudeRule.twilightAngle:
        // Use twilight angle method
        return PrayerTimes(
          fajr: fajr,
          sunrise: sunrise,
          dhuhr: dhuhr,
          asr: asr,
          maghrib: maghrib,
          isha: isha,
          date: fajr,
        );
    }
  }

  static PrayerTimes _applyAdjustments(PrayerTimes times, PrayerAdjustments? adj) {
    if (adj == null) return times;
    
    return PrayerTimes(
      fajr: times.fajr.add(Duration(minutes: adj.fajr)),
      sunrise: times.sunrise.add(Duration(minutes: adj.sunrise)),
      dhuhr: times.dhuhr.add(Duration(minutes: adj.dhuhr)),
      asr: times.asr.add(Duration(minutes: adj.asr)),
      maghrib: times.maghrib.add(Duration(minutes: adj.maghrib)),
      isha: times.isha.add(Duration(minutes: adj.isha)),
      date: times.date,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATH HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static double _sin(double deg) => sin(deg * pi / 180);
  static double _cos(double deg) => cos(deg * pi / 180);
  static double _tan(double deg) => tan(deg * pi / 180);
  static double _arcsin(double x) => asin(x) * 180 / pi;
  static double _arccos(double x) => acos(x) * 180 / pi;
  static double _arccot(double x) => atan(1 / x) * 180 / pi;

  static DateTime _toDateTime(DateTime date, double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return DateTime(date.year, date.month, date.day, h, m);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Prayer times for a day
class PrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime date;

  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
  });

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
  final String name;
  final double fajrAngle;
  final double ishaAngle;
  final int? ishaInterval; // Minutes after Maghrib
  final double? maghribAngle;

  const CalculationParams({
    required this.name,
    required this.fajrAngle,
    required this.ishaAngle,
    this.ishaInterval,
    this.maghribAngle,
  });
}

/// Manual time adjustments
class PrayerAdjustments {
  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  const PrayerAdjustments({
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });
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

// ═══════════════════════════════════════════════════════════════════════════
// REGION PRESETS (الطريقة الاحترافية)
// ═══════════════════════════════════════════════════════════════════════════

/// المناطق الجغرافية
enum PrayerRegion {
  gulf,         // الخليج العربي
  egypt,        // مصر
  northAfrica,  // شمال إفريقيا (المغرب، الجزائر، تونس)
  europe,       // أوروبا
  turkey,       // تركيا
  southAsia,    // جنوب آسيا (باكستان، الهند)
  southeastAsia,// جنوب شرق آسيا (ماليزيا، إندونيسيا)
  northAmerica, // أمريكا الشمالية
  iran,         // إيران
}

/// إعداد المنطقة الجغرافية
class RegionPreset {
  final String arabicName;
  final String englishName;
  final CalculationMethod method;
  final HighLatitudeRule highLatitudeRule;
  final PrayerAdjustments adjustments;
  final Madhab defaultMadhab;

  const RegionPreset({
    required this.arabicName,
    required this.englishName,
    required this.method,
    this.highLatitudeRule = HighLatitudeRule.middleOfNight,
    this.adjustments = const PrayerAdjustments(),
    this.defaultMadhab = Madhab.shafi,
  });
}

/// إعدادات المناطق الجاهزة
class RegionPresets {
  static const Map<PrayerRegion, RegionPreset> presets = {
    // 🇸🇦 الخليج العربي
    PrayerRegion.gulf: RegionPreset(
      arabicName: 'الخليج العربي',
      englishName: 'Gulf Region',
      method: CalculationMethod.ummAlQura,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
    ),
    
    // 🇪🇬 مصر
    PrayerRegion.egypt: RegionPreset(
      arabicName: 'مصر',
      englishName: 'Egypt',
      method: CalculationMethod.egyptian,
    ),
    
    // 🇲🇦 شمال إفريقيا (المغرب، الجزائر، تونس)
    PrayerRegion.northAfrica: RegionPreset(
      arabicName: 'شمال إفريقيا',
      englishName: 'North Africa',
      method: CalculationMethod.egyptian,
      adjustments: PrayerAdjustments(
        fajr: 2,
        maghrib: 1,
      ),
    ),
    
    // 🇪🇺 أوروبا
    PrayerRegion.europe: RegionPreset(
      arabicName: 'أوروبا',
      englishName: 'Europe',
      method: CalculationMethod.muslimWorldLeague,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
      adjustments: PrayerAdjustments(
        fajr: 1,
        isha: 1,
      ),
    ),
    
    // 🇹🇷 تركيا
    PrayerRegion.turkey: RegionPreset(
      arabicName: 'تركيا',
      englishName: 'Turkey',
      method: CalculationMethod.turkey,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
    ),
    
    // 🇵🇰 جنوب آسيا
    PrayerRegion.southAsia: RegionPreset(
      arabicName: 'جنوب آسيا',
      englishName: 'South Asia',
      method: CalculationMethod.karachi,
      defaultMadhab: Madhab.hanafi,
    ),
    
    // 🇲🇾 جنوب شرق آسيا
    PrayerRegion.southeastAsia: RegionPreset(
      arabicName: 'جنوب شرق آسيا',
      englishName: 'Southeast Asia',
      method: CalculationMethod.singapore,
    ),
    
    // 🇺🇸 أمريكا الشمالية
    PrayerRegion.northAmerica: RegionPreset(
      arabicName: 'أمريكا الشمالية',
      englishName: 'North America',
      method: CalculationMethod.northAmerica,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
    ),
    
    // 🇮🇷 إيران
    PrayerRegion.iran: RegionPreset(
      arabicName: 'إيران',
      englishName: 'Iran',
      method: CalculationMethod.tehran,
    ),
  };
  
  /// الحصول على preset للمنطقة
  static RegionPreset getPreset(PrayerRegion region) {
    return presets[region]!;
  }
  
  /// الحصول على كل المناطق
  static List<MapEntry<PrayerRegion, RegionPreset>> get all {
    return presets.entries.toList();
  }
  
  /// تخمين المنطقة من الإحداثيات
  static PrayerRegion guessRegion(double latitude, double longitude) {
    // الخليج
    if (latitude >= 12 && latitude <= 32 && longitude >= 34 && longitude <= 60) {
      return PrayerRegion.gulf;
    }
    // مصر
    if (latitude >= 22 && latitude <= 32 && longitude >= 25 && longitude <= 36) {
      return PrayerRegion.egypt;
    }
    // شمال إفريقيا
    if (latitude >= 20 && latitude <= 38 && longitude >= -17 && longitude <= 25) {
      return PrayerRegion.northAfrica;
    }
    // تركيا
    if (latitude >= 36 && latitude <= 42 && longitude >= 26 && longitude <= 45) {
      return PrayerRegion.turkey;
    }
    // إيران
    if (latitude >= 25 && latitude <= 40 && longitude >= 44 && longitude <= 63) {
      return PrayerRegion.iran;
    }
    // جنوب آسيا
    if (latitude >= 5 && latitude <= 38 && longitude >= 60 && longitude <= 98) {
      return PrayerRegion.southAsia;
    }
    // جنوب شرق آسيا
    if (latitude >= -11 && latitude <= 21 && longitude >= 95 && longitude <= 141) {
      return PrayerRegion.southeastAsia;
    }
    // أمريكا الشمالية
    if (latitude >= 14 && latitude <= 84 && longitude >= -170 && longitude <= -50) {
      return PrayerRegion.northAmerica;
    }
    // أوروبا (الافتراضي لخطوط العرض العالية)
    return PrayerRegion.europe;
  }
}

/// Extension لسهولة الاستخدام
extension PrayerTimeEngineRegion on PrayerTimeEngine {
  /// حساب المواقيت باستخدام المنطقة
  static PrayerTimes calculateWithRegion({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerRegion region,
    Madhab? madhab,
    double elevation = 0,
    PrayerAdjustments? additionalAdjustments,
  }) {
    final preset = RegionPresets.getPreset(region);
    
    // 🔄 Auto-switch للمناطق الباردة
    HighLatitudeRule effectiveRule = preset.highLatitudeRule;
    if (latitude.abs() > 48) {
      effectiveRule = HighLatitudeRule.seventhOfNight;
    }
    if (latitude.abs() > 60) {
      effectiveRule = HighLatitudeRule.middleOfNight;
    }
    
    // دمج التعديلات
    final adjustments = additionalAdjustments != null
        ? PrayerAdjustments(
            fajr: preset.adjustments.fajr + additionalAdjustments.fajr,
            sunrise: preset.adjustments.sunrise + additionalAdjustments.sunrise,
            dhuhr: preset.adjustments.dhuhr + additionalAdjustments.dhuhr,
            asr: preset.adjustments.asr + additionalAdjustments.asr,
            maghrib: preset.adjustments.maghrib + additionalAdjustments.maghrib,
            isha: preset.adjustments.isha + additionalAdjustments.isha,
          )
        : preset.adjustments;
    
    return PrayerTimeEngine.calculate(
      latitude: latitude,
      longitude: longitude,
      date: date,
      method: preset.method,
      madhab: madhab ?? preset.defaultMadhab,
      highLatitudeRule: effectiveRule,
      elevation: elevation,
      adjustments: adjustments,
    );
  }
  
  /// حساب المواقيت مع اكتشاف تلقائي للمنطقة
  static PrayerTimes calculateAuto({
    required double latitude,
    required double longitude,
    required DateTime date,
    double elevation = 0,
  }) {
    final region = RegionPresets.guessRegion(latitude, longitude);
    return calculateWithRegion(
      latitude: latitude,
      longitude: longitude,
      date: date,
      region: region,
      elevation: elevation,
    );
  }
  
  /// حساب المواقيت باستخدام الدولة
  static PrayerTimes calculateByCountry({
    required double latitude,
    required double longitude,
    required DateTime date,
    required String countryCode,
    double elevation = 0,
    PrayerAdjustments? additionalAdjustments,
  }) {
    final preset = CountryPresets.getPreset(countryCode);
    
    // 🔄 Auto-switch للمناطق الباردة
    HighLatitudeRule effectiveRule = preset.highLatitudeRule;
    if (latitude.abs() > 48) {
      effectiveRule = HighLatitudeRule.seventhOfNight;
    }
    if (latitude.abs() > 60) {
      effectiveRule = HighLatitudeRule.middleOfNight;
    }
    
    // دمج التعديلات
    final adjustments = additionalAdjustments != null
        ? PrayerAdjustments(
            fajr: preset.adjustments.fajr + additionalAdjustments.fajr,
            sunrise: preset.adjustments.sunrise + additionalAdjustments.sunrise,
            dhuhr: preset.adjustments.dhuhr + additionalAdjustments.dhuhr,
            asr: preset.adjustments.asr + additionalAdjustments.asr,
            maghrib: preset.adjustments.maghrib + additionalAdjustments.maghrib,
            isha: preset.adjustments.isha + additionalAdjustments.isha,
          )
        : preset.adjustments;
    
    return PrayerTimeEngine.calculate(
      latitude: latitude,
      longitude: longitude,
      date: date,
      method: preset.method,
      madhab: preset.madhab,
      highLatitudeRule: effectiveRule,
      elevation: elevation,
      adjustments: adjustments,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COUNTRY PRESETS (إعدادات الدول)
// ═══════════════════════════════════════════════════════════════════════════

/// إعداد الدولة
class CountryPreset {
  final String countryCode;
  final String arabicName;
  final String englishName;
  final CalculationMethod method;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;
  final PrayerAdjustments adjustments;

  const CountryPreset({
    required this.countryCode,
    required this.arabicName,
    required this.englishName,
    required this.method,
    this.madhab = Madhab.shafi,
    this.highLatitudeRule = HighLatitudeRule.middleOfNight,
    this.adjustments = const PrayerAdjustments(),
  });
}

/// قاعدة بيانات الدول
class CountryPresets {
  static const Map<String, CountryPreset> _presets = {
    // ═══════════════════════════════════════════════════════════════════════
    // 🇸🇦 الخليج العربي
    // ═══════════════════════════════════════════════════════════════════════
    'SA': CountryPreset(
      countryCode: 'SA',
      arabicName: 'السعودية',
      englishName: 'Saudi Arabia',
      method: CalculationMethod.ummAlQura,
    ),
    'AE': CountryPreset(
      countryCode: 'AE',
      arabicName: 'الإمارات',
      englishName: 'UAE',
      method: CalculationMethod.dubai,
    ),
    'KW': CountryPreset(
      countryCode: 'KW',
      arabicName: 'الكويت',
      englishName: 'Kuwait',
      method: CalculationMethod.kuwait,
    ),
    'QA': CountryPreset(
      countryCode: 'QA',
      arabicName: 'قطر',
      englishName: 'Qatar',
      method: CalculationMethod.qatar,
    ),
    'BH': CountryPreset(
      countryCode: 'BH',
      arabicName: 'البحرين',
      englishName: 'Bahrain',
      method: CalculationMethod.ummAlQura,
    ),
    'OM': CountryPreset(
      countryCode: 'OM',
      arabicName: 'عُمان',
      englishName: 'Oman',
      method: CalculationMethod.ummAlQura,
    ),
    'YE': CountryPreset(
      countryCode: 'YE',
      arabicName: 'اليمن',
      englishName: 'Yemen',
      method: CalculationMethod.ummAlQura,
    ),
    
    // ═══════════════════════════════════════════════════════════════════════
    // 🇪🇬 مصر والشام
    // ═══════════════════════════════════════════════════════════════════════
    'EG': CountryPreset(
      countryCode: 'EG',
      arabicName: 'مصر',
      englishName: 'Egypt',
      method: CalculationMethod.egyptian,
    ),
    'JO': CountryPreset(
      countryCode: 'JO',
      arabicName: 'الأردن',
      englishName: 'Jordan',
      method: CalculationMethod.ummAlQura,
    ),
    'PS': CountryPreset(
      countryCode: 'PS',
      arabicName: 'فلسطين',
      englishName: 'Palestine',
      method: CalculationMethod.ummAlQura,
    ),
    'LB': CountryPreset(
      countryCode: 'LB',
      arabicName: 'لبنان',
      englishName: 'Lebanon',
      method: CalculationMethod.ummAlQura,
    ),
    'SY': CountryPreset(
      countryCode: 'SY',
      arabicName: 'سوريا',
      englishName: 'Syria',
      method: CalculationMethod.ummAlQura,
    ),
    'IQ': CountryPreset(
      countryCode: 'IQ',
      arabicName: 'العراق',
      englishName: 'Iraq',
      method: CalculationMethod.ummAlQura,
    ),
    
    // ═══════════════════════════════════════════════════════════════════════
    // 🇲🇦 شمال إفريقيا
    // ═══════════════════════════════════════════════════════════════════════
    'MA': CountryPreset(
      countryCode: 'MA',
      arabicName: 'المغرب',
      englishName: 'Morocco',
      method: CalculationMethod.morocco,
    ),
    'DZ': CountryPreset(
      countryCode: 'DZ',
      arabicName: 'الجزائر',
      englishName: 'Algeria',
      method: CalculationMethod.algeriaTunisia,
    ),
    'TN': CountryPreset(
      countryCode: 'TN',
      arabicName: 'تونس',
      englishName: 'Tunisia',
      method: CalculationMethod.algeriaTunisia,
    ),
    'LY': CountryPreset(
      countryCode: 'LY',
      arabicName: 'ليبيا',
      englishName: 'Libya',
      method: CalculationMethod.libya,
    ),
    'SD': CountryPreset(
      countryCode: 'SD',
      arabicName: 'السودان',
      englishName: 'Sudan',
      method: CalculationMethod.egyptian,
    ),
    'MR': CountryPreset(
      countryCode: 'MR',
      arabicName: 'موريتانيا',
      englishName: 'Mauritania',
      method: CalculationMethod.muslimWorldLeague,
    ),
    
    // ═══════════════════════════════════════════════════════════════════════
    // 🇪🇺 أوروبا
    // ═══════════════════════════════════════════════════════════════════════
    'FR': CountryPreset(
      countryCode: 'FR',
      arabicName: 'فرنسا',
      englishName: 'France',
      method: CalculationMethod.france,
      highLatitudeRule: HighLatitudeRule.seventhOfNight,
    ),
    'DE': CountryPreset(
      countryCode: 'DE',
      arabicName: 'ألمانيا',
      englishName: 'Germany',
      method: CalculationMethod.germany,
      highLatitudeRule: HighLatitudeRule.seventhOfNight,
    ),
    'GB': CountryPreset(
      countryCode: 'GB',
      arabicName: 'بريطانيا',
      englishName: 'United Kingdom',
      method: CalculationMethod.uk,
      highLatitudeRule: HighLatitudeRule.seventhOfNight,
    ),
    'NL': CountryPreset(
      countryCode: 'NL',
      arabicName: 'هولندا',
      englishName: 'Netherlands',
      method: CalculationMethod.europeanCouncil,
      highLatitudeRule: HighLatitudeRule.seventhOfNight,
    ),
    'BE': CountryPreset(
      countryCode: 'BE',
      arabicName: 'بلجيكا',
      englishName: 'Belgium',
      method: CalculationMethod.europeanCouncil,
      highLatitudeRule: HighLatitudeRule.seventhOfNight,
    ),
    'ES': CountryPreset(
      countryCode: 'ES',
      arabicName: 'إسبانيا',
      englishName: 'Spain',
      method: CalculationMethod.europeanCouncil,
    ),
    'IT': CountryPreset(
      countryCode: 'IT',
      arabicName: 'إيطاليا',
      englishName: 'Italy',
      method: CalculationMethod.europeanCouncil,
    ),
    'AT': CountryPreset(
      countryCode: 'AT',
      arabicName: 'النمسا',
      englishName: 'Austria',
      method: CalculationMethod.europeanCouncil,
      highLatitudeRule: HighLatitudeRule.seventhOfNight,
    ),
    'SE': CountryPreset(
      countryCode: 'SE',
      arabicName: 'السويد',
      englishName: 'Sweden',
      method: CalculationMethod.europeanCouncil,
      highLatitudeRule: HighLatitudeRule.middleOfNight, // خط عرض عالي جداً
    ),
    'NO': CountryPreset(
      countryCode: 'NO',
      arabicName: 'النرويج',
      englishName: 'Norway',
      method: CalculationMethod.europeanCouncil,
      highLatitudeRule: HighLatitudeRule.middleOfNight,
    ),
    'DK': CountryPreset(
      countryCode: 'DK',
      arabicName: 'الدنمارك',
      englishName: 'Denmark',
      method: CalculationMethod.europeanCouncil,
      highLatitudeRule: HighLatitudeRule.seventhOfNight,
    ),
    'CH': CountryPreset(
      countryCode: 'CH',
      arabicName: 'سويسرا',
      englishName: 'Switzerland',
      method: CalculationMethod.europeanCouncil,
    ),
    
    // ═══════════════════════════════════════════════════════════════════════
    // 🇹🇷 تركيا وإيران
    // ═══════════════════════════════════════════════════════════════════════
    'TR': CountryPreset(
      countryCode: 'TR',
      arabicName: 'تركيا',
      englishName: 'Turkey',
      method: CalculationMethod.turkey,
      madhab: Madhab.hanafi,
    ),
    'IR': CountryPreset(
      countryCode: 'IR',
      arabicName: 'إيران',
      englishName: 'Iran',
      method: CalculationMethod.tehran,
    ),
    
    // ═══════════════════════════════════════════════════════════════════════
    // 🇵🇰 جنوب آسيا
    // ═══════════════════════════════════════════════════════════════════════
    'PK': CountryPreset(
      countryCode: 'PK',
      arabicName: 'باكستان',
      englishName: 'Pakistan',
      method: CalculationMethod.karachi,
      madhab: Madhab.hanafi,
    ),
    'IN': CountryPreset(
      countryCode: 'IN',
      arabicName: 'الهند',
      englishName: 'India',
      method: CalculationMethod.karachi,
      madhab: Madhab.hanafi,
    ),
    'BD': CountryPreset(
      countryCode: 'BD',
      arabicName: 'بنغلاديش',
      englishName: 'Bangladesh',
      method: CalculationMethod.karachi,
      madhab: Madhab.hanafi,
    ),
    'AF': CountryPreset(
      countryCode: 'AF',
      arabicName: 'أفغانستان',
      englishName: 'Afghanistan',
      method: CalculationMethod.karachi,
      madhab: Madhab.hanafi,
    ),
    
    // ═══════════════════════════════════════════════════════════════════════
    // 🇲🇾 جنوب شرق آسيا
    // ═══════════════════════════════════════════════════════════════════════
    'MY': CountryPreset(
      countryCode: 'MY',
      arabicName: 'ماليزيا',
      englishName: 'Malaysia',
      method: CalculationMethod.singapore,
    ),
    'ID': CountryPreset(
      countryCode: 'ID',
      arabicName: 'إندونيسيا',
      englishName: 'Indonesia',
      method: CalculationMethod.singapore,
    ),
    'SG': CountryPreset(
      countryCode: 'SG',
      arabicName: 'سنغافورة',
      englishName: 'Singapore',
      method: CalculationMethod.singapore,
    ),
    'BN': CountryPreset(
      countryCode: 'BN',
      arabicName: 'بروناي',
      englishName: 'Brunei',
      method: CalculationMethod.singapore,
    ),
    
    // ═══════════════════════════════════════════════════════════════════════
    // 🇺🇸 أمريكا الشمالية
    // ═══════════════════════════════════════════════════════════════════════
    'US': CountryPreset(
      countryCode: 'US',
      arabicName: 'أمريكا',
      englishName: 'United States',
      method: CalculationMethod.northAmerica,
    ),
    'CA': CountryPreset(
      countryCode: 'CA',
      arabicName: 'كندا',
      englishName: 'Canada',
      method: CalculationMethod.northAmerica,
      highLatitudeRule: HighLatitudeRule.seventhOfNight,
    ),
  };
  
  /// الحصول على preset للدولة
  static CountryPreset getPreset(String countryCode) {
    return _presets[countryCode.toUpperCase()] ?? _defaultPreset;
  }
  
  /// الافتراضي (رابطة العالم الإسلامي)
  static const CountryPreset _defaultPreset = CountryPreset(
    countryCode: 'XX',
    arabicName: 'افتراضي',
    englishName: 'Default',
    method: CalculationMethod.muslimWorldLeague,
  );
  
  /// الحصول على كل الدول
  static List<CountryPreset> get all => _presets.values.toList();
  
  /// البحث عن دولة
  static List<CountryPreset> search(String query) {
    final q = query.toLowerCase();
    return _presets.values.where((p) =>
      p.arabicName.contains(q) ||
      p.englishName.toLowerCase().contains(q) ||
      p.countryCode.toLowerCase().contains(q)
    ).toList();
  }
  
  /// هل الدولة مدعومة؟
  static bool isSupported(String countryCode) {
    return _presets.containsKey(countryCode.toUpperCase());
  }
  
  /// عدد الدول المدعومة
  static int get count => _presets.length;
}

