import 'prayer_time_models.dart';

/// Prayer country presets - prayer_country_presets.dart
/// Extracted from prayer_time_engine.dart (Phase 1 god-file split).

/// إعداد الدولة
class CountryPreset {

  const CountryPreset({
    required this.countryCode,
    required this.arabicName,
    required this.englishName,
    required this.method,
    this.madhab = Madhab.shafi,
    this.highLatitudeRule = HighLatitudeRule.middleOfNight,
    this.adjustments = const PrayerAdjustments(),
  });
  final String countryCode;
  final String arabicName;
  final String englishName;
  final CalculationMethod method;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;
  final PrayerAdjustments adjustments;
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
    ),
    'NO': CountryPreset(
      countryCode: 'NO',
      arabicName: 'النرويج',
      englishName: 'Norway',
      method: CalculationMethod.europeanCouncil,
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
      p.countryCode.toLowerCase().contains(q),
    ).toList();
  }

  /// هل الدولة مدعومة؟
  static bool isSupported(String countryCode) {
    return _presets.containsKey(countryCode.toUpperCase());
  }

  /// عدد الدول المدعومة
  static int get count => _presets.length;
}
