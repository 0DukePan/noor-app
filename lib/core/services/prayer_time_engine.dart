import 'dart:math';

import 'prayer_country_presets.dart';
import 'prayer_region_presets.dart';
import 'prayer_solar_calculator.dart';
import 'prayer_time_models.dart';

export 'prayer_country_presets.dart';
export 'prayer_region_presets.dart';
export 'prayer_solar_calculator.dart';
export 'prayer_time_models.dart';

/// 🕌 محرك حساب مواقيت الصلاة - Prayer Time Engine
/// حساب فلكي دقيق مع تصحيح الارتفاع والمناطق الباردة
///
/// The solar math lives in [SolarCalculator] and the method/region/country
/// data in prayer_time_models.dart / prayer_region_presets.dart /
/// prayer_country_presets.dart (all re-exported from here so existing
/// importers keep working).
class PrayerTimeEngine {
  // ═══════════════════════════════════════════════════════════════════════════
  // CALCULATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<CalculationMethod, CalculationParams> methods = {
    CalculationMethod.muslimWorldLeague: CalculationParams(
      name: 'رابطة العالم الإسلامي',
      fajrAngle: 18,
      ishaAngle: 17,
    ),
    CalculationMethod.egyptian: CalculationParams(
      name: 'الهيئة المصرية',
      fajrAngle: 19.5,
      ishaAngle: 17.5,
    ),
    CalculationMethod.karachi: CalculationParams(
      name: 'جامعة كراتشي',
      fajrAngle: 18,
      ishaAngle: 18,
    ),
    CalculationMethod.ummAlQura: CalculationParams(
      name: 'أم القرى',
      fajrAngle: 18.5,
      ishaAngle: 0,
      ishaInterval: 90,
    ),
    CalculationMethod.dubai: CalculationParams(
      name: 'دبي',
      fajrAngle: 18.2,
      ishaAngle: 18.2,
    ),
    CalculationMethod.qatar: CalculationParams(
      name: 'قطر',
      fajrAngle: 18,
      ishaAngle: 0,
      ishaInterval: 90,
    ),
    CalculationMethod.kuwait: CalculationParams(
      name: 'الكويت',
      fajrAngle: 18,
      ishaAngle: 17.5,
    ),
    CalculationMethod.singapore: CalculationParams(
      name: 'سنغافورة',
      fajrAngle: 20,
      ishaAngle: 18,
    ),
    CalculationMethod.turkey: CalculationParams(
      name: 'تركيا',
      fajrAngle: 18,
      ishaAngle: 17,
    ),
    CalculationMethod.tehran: CalculationParams(
      name: 'طهران',
      fajrAngle: 17.7,
      ishaAngle: 14,
      maghribAngle: 4.5,
    ),
    CalculationMethod.northAmerica: CalculationParams(
      name: 'ISNA أمريكا الشمالية',
      fajrAngle: 15,
      ishaAngle: 15,
    ),

    // 🇪🇺 أوروبا - الطرق الرسمية
    CalculationMethod.europeanCouncil: CalculationParams(
      name: 'المجلس الأوروبي للإفتاء',
      fajrAngle: 18,
      ishaAngle: 18,
    ),
    CalculationMethod.moonsightingCommittee: CalculationParams(
      name: 'Moonsighting Committee',
      fajrAngle: 18,
      ishaAngle: 18,
    ),
    CalculationMethod.france: CalculationParams(
      name: 'فرنسا (UOIF)',
      fajrAngle: 12,
      ishaAngle: 12,
    ),
    CalculationMethod.germany: CalculationParams(
      name: 'ألمانيا (IGMG)',
      fajrAngle: 18,
      ishaAngle: 17,
    ),
    CalculationMethod.uk: CalculationParams(
      name: 'بريطانيا (London Fatwa Council)',
      fajrAngle: 18,
      ishaAngle: 18,
    ),

    // 🇲🇦 شمال إفريقيا - الطرق الرسمية
    CalculationMethod.morocco: CalculationParams(
      name: 'وزارة الأوقاف المغربية',
      fajrAngle: 19,
      ishaAngle: 17,
    ),
    CalculationMethod.algeriaTunisia: CalculationParams(
      name: 'الجزائر / تونس',
      fajrAngle: 18,
      ishaAngle: 18,
    ),
    CalculationMethod.libya: CalculationParams(
      name: 'ليبيا',
      fajrAngle: 18.5,
      ishaAngle: 18,
    ),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate prayer times for a specific date and location
  ///
  /// [utcOffset] is the UTC offset in hours (east positive) for the location's
  /// civil time. The solar calculations produce UTC instants; this offset
  /// converts them to the local wall-clock time shown to the user.
  static PrayerTimes calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod method,
    Madhab madhab = Madhab.shafi,
    HighLatitudeRule highLatitudeRule = HighLatitudeRule.middleOfNight,
    double elevation = 0,
    PrayerAdjustments? adjustments,
    double utcOffset = 0,
  }) {
    final params = methods[method]!;
    final jd = SolarCalculator.julianDay(date);

    // Solar calculations
    final sunDeclination = SolarCalculator.sunDeclination(jd);
    final equationOfTime = SolarCalculator.equationOfTime(jd);

    // Elevation adjustment
    final elevationAngle = elevation > 0 ? 0.0347 * sqrt(elevation) : 0;

    // Calculate each prayer time
    final dhuhr = SolarCalculator.dhuhrTime(longitude, equationOfTime, date, utcOffset);
    final sunrise = SolarCalculator.sunAngleTime(
      latitude, sunDeclination, -0.833 - elevationAngle, dhuhr, isAfternoon: false,
    );
    final fajr = SolarCalculator.sunAngleTime(
      latitude, sunDeclination, -params.fajrAngle, dhuhr, isAfternoon: false,
    );
    final maghrib = SolarCalculator.sunAngleTime(
      latitude, sunDeclination,
      params.maghribAngle != null ? -params.maghribAngle! : -0.833 - elevationAngle,
      dhuhr, isAfternoon: true,
    );
    final asr = SolarCalculator.asrTime(
      latitude, sunDeclination, dhuhr, madhab,
    );

    // Isha calculation
    DateTime isha;
    if (params.ishaInterval != null) {
      isha = maghrib.add(Duration(minutes: params.ishaInterval!));
    } else {
      isha = SolarCalculator.sunAngleTime(
        latitude, sunDeclination, -params.ishaAngle, dhuhr, isAfternoon: true,
      );
    }

    // High latitude adjustments
    final times = SolarCalculator.applyHighLatitudeRule(
      highLatitudeRule,
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
    );

    // Apply manual adjustments
    final adjusted = SolarCalculator.applyAdjustments(times, adjustments);

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
    double utcOffset = 0,
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
        utcOffset: utcOffset,
      );
    });
  }

  static PrayerTimes calculateWithRegion({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerRegion region,
    Madhab? madhab,
    double elevation = 0,
    PrayerAdjustments? additionalAdjustments,
    double utcOffset = 0,
  }) {
    final preset = RegionPresets.getPreset(region);

    // 🔄 Auto-switch للمناطق الباردة
    var effectiveRule = preset.highLatitudeRule;
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
      utcOffset: utcOffset,
    );
  }

  /// حساب المواقيت مع اكتشاف تلقائي للمنطقة
  static PrayerTimes calculateAuto({
    required double latitude,
    required double longitude,
    required DateTime date,
    double elevation = 0,
    double utcOffset = 0,
  }) {
    final region = RegionPresets.guessRegion(latitude, longitude);
    return calculateWithRegion(
      latitude: latitude,
      longitude: longitude,
      date: date,
      region: region,
      elevation: elevation,
      utcOffset: utcOffset,
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
    double utcOffset = 0,
  }) {
    final preset = CountryPresets.getPreset(countryCode);

    // 🔄 Auto-switch للمناطق الباردة
    var effectiveRule = preset.highLatitudeRule;
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
      utcOffset: utcOffset,
    );
  }
}
