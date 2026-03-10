import 'dart:async';
import 'package:flutter/services.dart';
import 'prayer_time_engine.dart';
import 'weekly_scheduler_service.dart';

/// 📿 خدمة الأذكار المرتبطة بالوقت - Adhkar Timer Service
/// الأذكار تظهر في وقتها الحقيقي فقط
class AdhkarTimerService {
  static PrayerTimes? _todayPrayerTimes;
  static Timer? _refreshTimer;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialize service
  static Future<void> init() async {
    await _refreshPrayerTimes();
    _startDailyRefresh();
  }

  /// Refresh prayer times
  static Future<void> _refreshPrayerTimes() async {
    try {
      _todayPrayerTimes = await WeeklySchedulerService.getTodayPrayerTimes();
    } catch (e) {
      // Fallback to default times
    }
  }

  /// Start daily refresh at midnight
  static void _startDailyRefresh() {
    _refreshTimer?.cancel();
    
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 5);
    final duration = nextMidnight.difference(now);
    
    _refreshTimer = Timer(duration, () async {
      await _refreshPrayerTimes();
      _startDailyRefresh();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADHKAR AVAILABILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// أذكار الصباح متاحة من الفجر إلى الشروق
  static bool get isMorningAdhkarAvailable {
    if (_todayPrayerTimes == null) return false;
    final now = DateTime.now();
    return now.isAfter(_todayPrayerTimes!.fajr) && 
           now.isBefore(_todayPrayerTimes!.sunrise);
  }

  /// أذكار المساء متاحة من العصر إلى المغرب
  static bool get isEveningAdhkarAvailable {
    if (_todayPrayerTimes == null) return false;
    final now = DateTime.now();
    return now.isAfter(_todayPrayerTimes!.asr) && 
           now.isBefore(_todayPrayerTimes!.maghrib);
  }

  /// أذكار بعد الصلاة متاحة لـ 30 دقيقة بعد كل صلاة
  static bool get isPostPrayerAdhkarAvailable {
    if (_todayPrayerTimes == null) return false;
    final now = DateTime.now();
    const postPrayerDuration = Duration(minutes: 30);
    
    final prayers = [
      _todayPrayerTimes!.fajr,
      _todayPrayerTimes!.dhuhr,
      _todayPrayerTimes!.asr,
      _todayPrayerTimes!.maghrib,
      _todayPrayerTimes!.isha,
    ];
    
    for (final prayer in prayers) {
      if (now.isAfter(prayer) && now.isBefore(prayer.add(postPrayerDuration))) {
        return true;
      }
    }
    return false;
  }

  /// أذكار النوم متاحة بعد العشاء
  static bool get isSleepAdhkarAvailable {
    if (_todayPrayerTimes == null) return false;
    final now = DateTime.now();
    return now.isAfter(_todayPrayerTimes!.isha);
  }

  /// Check if specific adhkar type is available
  static bool isAdhkarAvailable(AdhkarType type) {
    switch (type) {
      case AdhkarType.morning:
        return isMorningAdhkarAvailable;
      case AdhkarType.evening:
        return isEveningAdhkarAvailable;
      case AdhkarType.afterPrayer:
        return isPostPrayerAdhkarAvailable;
      case AdhkarType.sleep:
        return isSleepAdhkarAvailable;
      case AdhkarType.wakeUp:
        return isMorningAdhkarAvailable; // Same as morning
      case AdhkarType.general:
        return true; // Always available
    }
  }

  /// Get current adhkar type that should be shown
  static AdhkarType? getCurrentAdhkarType() {
    if (isMorningAdhkarAvailable) return AdhkarType.morning;
    if (isEveningAdhkarAvailable) return AdhkarType.evening;
    if (isPostPrayerAdhkarAvailable) return AdhkarType.afterPrayer;
    if (isSleepAdhkarAvailable) return AdhkarType.sleep;
    return null;
  }

  /// Get remaining time for current adhkar
  static Duration? getRemainingTime(AdhkarType type) {
    if (_todayPrayerTimes == null) return null;
    final now = DateTime.now();
    
    switch (type) {
      case AdhkarType.morning:
        if (isMorningAdhkarAvailable) {
          return _todayPrayerTimes!.sunrise.difference(now);
        }
        break;
      case AdhkarType.evening:
        if (isEveningAdhkarAvailable) {
          return _todayPrayerTimes!.maghrib.difference(now);
        }
        break;
      case AdhkarType.afterPrayer:
        // Find active post-prayer window
        final prayers = [
          _todayPrayerTimes!.fajr,
          _todayPrayerTimes!.dhuhr,
          _todayPrayerTimes!.asr,
          _todayPrayerTimes!.maghrib,
          _todayPrayerTimes!.isha,
        ];
        for (final prayer in prayers) {
          final endTime = prayer.add(const Duration(minutes: 30));
          if (now.isAfter(prayer) && now.isBefore(endTime)) {
            return endTime.difference(now);
          }
        }
        break;
      default:
        break;
    }
    return null;
  }

  /// Get next start time for adhkar
  static DateTime? getNextStartTime(AdhkarType type) {
    if (_todayPrayerTimes == null) return null;
    final now = DateTime.now();
    
    switch (type) {
      case AdhkarType.morning:
        if (now.isBefore(_todayPrayerTimes!.fajr)) {
          return _todayPrayerTimes!.fajr;
        }
        // Tomorrow's fajr
        return _todayPrayerTimes!.fajr.add(const Duration(days: 1));
        
      case AdhkarType.evening:
        if (now.isBefore(_todayPrayerTimes!.asr)) {
          return _todayPrayerTimes!.asr;
        }
        // Tomorrow's asr
        return _todayPrayerTimes!.asr.add(const Duration(days: 1));
        
      default:
        return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CURRENT PRAYER STATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get current prayer (if any)
  static PrayerType? getCurrentPrayer() {
    if (_todayPrayerTimes == null) return null;
    final now = DateTime.now();
    
    // Check if we're in a prayer window (15 minutes after adhan)
    const prayerWindow = Duration(minutes: 15);
    
    if (now.isAfter(_todayPrayerTimes!.isha)) {
      return PrayerType.isha;
    }
    if (now.isAfter(_todayPrayerTimes!.maghrib) && 
        now.isBefore(_todayPrayerTimes!.maghrib.add(prayerWindow))) {
      return PrayerType.maghrib;
    }
    if (now.isAfter(_todayPrayerTimes!.asr) &&
        now.isBefore(_todayPrayerTimes!.maghrib)) {
      return PrayerType.asr;
    }
    if (now.isAfter(_todayPrayerTimes!.dhuhr) &&
        now.isBefore(_todayPrayerTimes!.asr)) {
      return PrayerType.dhuhr;
    }
    if (now.isAfter(_todayPrayerTimes!.sunrise) &&
        now.isBefore(_todayPrayerTimes!.dhuhr)) {
      return null; // Duha time
    }
    if (now.isAfter(_todayPrayerTimes!.fajr)) {
      return PrayerType.fajr;
    }
    
    return null;
  }

  /// Get next prayer
  static PrayerType? getNextPrayer() {
    return _todayPrayerTimes?.getNextPrayer();
  }

  /// Get time until next prayer
  static Duration? getTimeUntilNextPrayer() {
    final nextPrayer = getNextPrayer();
    if (nextPrayer == null || _todayPrayerTimes == null) return null;
    
    final prayerTime = _todayPrayerTimes!.getTime(nextPrayer);
    return prayerTime.difference(DateTime.now());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  static void dispose() {
    _refreshTimer?.cancel();
  }
}

/// Adhkar types
enum AdhkarType {
  morning,    // أذكار الصباح
  evening,    // أذكار المساء
  afterPrayer, // أذكار بعد الصلاة
  sleep,      // أذكار النوم
  wakeUp,     // أذكار الاستيقاظ
  general,    // أذكار عامة
}

/// Extension for adhkar type
extension AdhkarTypeExtension on AdhkarType {
  String get arabicName {
    switch (this) {
      case AdhkarType.morning: return 'أذكار الصباح';
      case AdhkarType.evening: return 'أذكار المساء';
      case AdhkarType.afterPrayer: return 'أذكار بعد الصلاة';
      case AdhkarType.sleep: return 'أذكار النوم';
      case AdhkarType.wakeUp: return 'أذكار الاستيقاظ';
      case AdhkarType.general: return 'أذكار متنوعة';
    }
  }
  
  String get timeDescription {
    switch (this) {
      case AdhkarType.morning: return 'من الفجر إلى الشروق';
      case AdhkarType.evening: return 'من العصر إلى المغرب';
      case AdhkarType.afterPrayer: return 'بعد كل صلاة';
      case AdhkarType.sleep: return 'قبل النوم';
      case AdhkarType.wakeUp: return 'عند الاستيقاظ';
      case AdhkarType.general: return 'في أي وقت';
    }
  }
}
