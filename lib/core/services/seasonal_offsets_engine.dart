import 'package:hive_flutter/hive_flutter.dart';

/// ⏱️ نظام الإزاحات الموسمية - Seasonal Offsets System
/// 
/// Features:
/// - Per-prayer offsets
/// - Summer/Winter adjustments
/// - Mosque-specific offsets
/// - Automatic seasonal detection
class SeasonalOffsetsEngine {
  static Box? _offsetsBox;
  
  // Default offsets (minutes)
  static final Map<String, PrayerOffsets> _defaultOffsets = {
    'fajr': const PrayerOffsets(summer: 0, winter: 2),
    'sunrise': const PrayerOffsets(summer: 0, winter: 0),
    'dhuhr': const PrayerOffsets(summer: 5, winter: 5),
    'asr': const PrayerOffsets(summer: 0, winter: 0),
    'maghrib': const PrayerOffsets(summer: 3, winter: 3),
    'isha': const PrayerOffsets(summer: 0, winter: 5),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> init() async {
    _offsetsBox = await Hive.openBox('prayer_offsets');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEASONAL DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديد الفصل الحالي
  static Season getCurrentSeason({double? latitude}) {
    final now = DateTime.now();
    final month = now.month;
    
    // Northern hemisphere
    if (latitude == null || latitude >= 0) {
      if (month >= 6 && month <= 8) return Season.summer;
      if (month >= 12 || month <= 2) return Season.winter;
      if (month >= 3 && month <= 5) return Season.spring;
      return Season.autumn;
    }
    
    // Southern hemisphere (inverted)
    if (month >= 6 && month <= 8) return Season.winter;
    if (month >= 12 || month <= 2) return Season.summer;
    if (month >= 3 && month <= 5) return Season.autumn;
    return Season.spring;
  }

  /// هل نحن في فصل الشتاء؟
  static bool isWinterSeason({double? latitude}) {
    final season = getCurrentSeason(latitude: latitude);
    return season == Season.winter || season == Season.autumn;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OFFSET MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// الحصول على إزاحة صلاة معينة
  static Duration getOffset(String prayer, {double? latitude}) {
    // Check custom offsets first
    final customKey = 'custom_$prayer';
    final customData = _offsetsBox?.get(customKey);
    
    PrayerOffsets offsets;
    if (customData != null) {
      offsets = PrayerOffsets.fromMap(Map<String, dynamic>.from(customData));
    } else {
      offsets = _defaultOffsets[prayer.toLowerCase()] ?? const PrayerOffsets();
    }
    
    // Apply seasonal offset
    final minutes = isWinterSeason(latitude: latitude) 
        ? offsets.winter 
        : offsets.summer;
    
    return Duration(minutes: minutes);
  }

  /// تعيين إزاحة مخصصة
  static Future<void> setCustomOffset({
    required String prayer,
    required int summerMinutes,
    required int winterMinutes,
  }) async {
    final offsets = PrayerOffsets(
      summer: summerMinutes,
      winter: winterMinutes,
    );
    
    await _offsetsBox?.put('custom_$prayer', offsets.toMap());
  }

  /// إعادة تعيين الإزاحات
  static Future<void> resetOffsets([String? prayer]) async {
    if (prayer != null) {
      await _offsetsBox?.delete('custom_$prayer');
    } else {
      for (final key in _defaultOffsets.keys) {
        await _offsetsBox?.delete('custom_$key');
      }
    }
  }

  /// جميع الإزاحات الحالية
  static Map<String, Duration> getAllCurrentOffsets({double? latitude}) {
    final prayers = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    return {
      for (final prayer in prayers) 
        prayer: getOffset(prayer, latitude: latitude)
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOSQUE OFFSETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// حفظ إزاحات مسجد
  static Future<void> saveMosqueOffsets({
    required String mosqueId,
    required String mosqueName,
    required Map<String, int> offsets,
  }) async {
    await _offsetsBox?.put('mosque_$mosqueId', {
      'name': mosqueName,
      'offsets': offsets,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// استرجاع إزاحات مسجد
  static MosqueOffsets? getMosqueOffsets(String mosqueId) {
    final data = _offsetsBox?.get('mosque_$mosqueId');
    if (data == null) return null;
    
    return MosqueOffsets(
      id: mosqueId,
      name: data['name'] ?? '',
      offsets: Map<String, int>.from(data['offsets'] ?? {}),
    );
  }

  /// تطبيق إزاحات مسجد
  static Future<void> applyMosqueOffsets(String mosqueId) async {
    final mosque = getMosqueOffsets(mosqueId);
    if (mosque == null) return;
    
    for (final entry in mosque.offsets.entries) {
      await setCustomOffset(
        prayer: entry.key,
        summerMinutes: entry.value,
        winterMinutes: entry.value,
      );
    }
    
    await _offsetsBox?.put('active_mosque', mosqueId);
  }

  /// المسجد النشط
  static String? get activeMosqueId => _offsetsBox?.get('active_mosque');

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME ADJUSTMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// تطبيق الإزاحة على وقت الصلاة
  static DateTime applyOffset(DateTime prayerTime, String prayer, {double? latitude}) {
    final offset = getOffset(prayer, latitude: latitude);
    return prayerTime.add(offset);
  }

  /// تطبيق جميع الإزاحات على المواقيت
  static Map<String, DateTime> applyAllOffsets(
    Map<String, DateTime> times, 
    {double? latitude}
  ) {
    return times.map((prayer, time) {
      return MapEntry(prayer, applyOffset(time, prayer, latitude: latitude));
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// الفصول
enum Season {
  spring,  // الربيع
  summer,  // الصيف
  autumn,  // الخريف
  winter,  // الشتاء
}

extension SeasonInfo on Season {
  String get arabicName {
    switch (this) {
      case Season.spring: return 'الربيع';
      case Season.summer: return 'الصيف';
      case Season.autumn: return 'الخريف';
      case Season.winter: return 'الشتاء';
    }
  }

  String get icon {
    switch (this) {
      case Season.spring: return '🌸';
      case Season.summer: return '☀️';
      case Season.autumn: return '🍂';
      case Season.winter: return '❄️';
    }
  }
}

/// إزاحات الصلاة
class PrayerOffsets {
  final int summer;
  final int winter;

  const PrayerOffsets({
    this.summer = 0,
    this.winter = 0,
  });

  Map<String, dynamic> toMap() => {
    'summer': summer,
    'winter': winter,
  };

  factory PrayerOffsets.fromMap(Map<String, dynamic> map) {
    return PrayerOffsets(
      summer: map['summer'] ?? 0,
      winter: map['winter'] ?? 0,
    );
  }
}

/// إزاحات المسجد
class MosqueOffsets {
  final String id;
  final String name;
  final Map<String, int> offsets;

  const MosqueOffsets({
    required this.id,
    required this.name,
    required this.offsets,
  });
}
