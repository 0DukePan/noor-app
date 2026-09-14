import 'prayer_time_models.dart';

/// Prayer region presets - prayer_region_presets.dart
/// Extracted from prayer_time_engine.dart (Phase 1 god-file split).

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

  const RegionPreset({
    required this.arabicName,
    required this.englishName,
    required this.method,
    this.highLatitudeRule = HighLatitudeRule.middleOfNight,
    this.adjustments = const PrayerAdjustments(),
    this.defaultMadhab = Madhab.shafi,
  });
  final String arabicName;
  final String englishName;
  final CalculationMethod method;
  final HighLatitudeRule highLatitudeRule;
  final PrayerAdjustments adjustments;
  final Madhab defaultMadhab;
}

/// إعدادات المناطق الجاهزة
class RegionPresets {
  static const Map<PrayerRegion, RegionPreset> presets = {
    // 🇸🇦 الخليج العربي
    PrayerRegion.gulf: RegionPreset(
      arabicName: 'الخليج العربي',
      englishName: 'Gulf Region',
      method: CalculationMethod.ummAlQura,
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
