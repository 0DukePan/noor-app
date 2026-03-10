import 'dart:async';
import 'package:flutter/services.dart';
import 'package:adhan/adhan.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'location_service.dart';
import 'prayer_calculation_service.dart';

/// 🕌 خدمة جدولة الأذان الاحترافية - Professional Adhan Scheduler
/// 
/// Multi-layer architecture:
/// 1️⃣ Prayer Time Engine (Adhan library)
/// 2️⃣ Native Background Scheduler
/// 3️⃣ Exact Alarm (Android) / Critical Alert (iOS)
/// 4️⃣ Local Audio Service
/// 5️⃣ Fallback Notification
class AdhanSchedulerService {
  static const _methodChannel = MethodChannel('com.noor.app/adhan');
  static const _settingsBox = 'adhan_settings';
  static Box? _settings;

  // Available Adhan sounds
  static const List<AdhanSound> adhanSounds = [
    AdhanSound(id: 'al_qatami', nameArabic: 'ناصر القطامي', nameEnglish: 'Nasser Al-Qatami'),
    AdhanSound(id: 'makkah', nameArabic: 'أذان الحرم المكي', nameEnglish: 'Makkah'),
    AdhanSound(id: 'madinah', nameArabic: 'أذان المسجد النبوي', nameEnglish: 'Madinah'),
    AdhanSound(id: 'alaqsa', nameArabic: 'أذان المسجد الأقصى', nameEnglish: 'Al-Aqsa'),
    AdhanSound(id: 'mishary', nameArabic: 'مشاري العفاسي', nameEnglish: 'Mishary Alafasy'),
    AdhanSound(id: 'abdulbasit', nameArabic: 'عبد الباسط', nameEnglish: 'Abdul Basit'),
    AdhanSound(id: 'fajr_special', nameArabic: 'أذان الفجر الخاص', nameEnglish: 'Fajr Special'),
  ];

  /// Initialize service
  static Future<void> init() async {
    _settings = await Hive.openBox(_settingsBox);
    
    // Request exact alarm permission (Android 12+)
    await _requestExactAlarmPermission();
    
    // Request battery optimization exemption
    await _requestBatteryOptimization();
    
    // Schedule all prayers for today and tomorrow
    await scheduleAllPrayers();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 1: PRAYER TIME CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate prayer times with high precision
  static Future<Map<String, DateTime>> calculatePrayerTimes({
    DateTime? date,
    double? latitude,
    double? longitude,
    double? elevation,
  }) async {
    date ??= DateTime.now();
    
    // Get location
    final locationService = LocationService();
    final location = await locationService.getCurrentLocation();
    latitude ??= location?.latitude ?? 21.4225;
    longitude ??= location?.longitude ?? 39.8262;
    elevation ??= 0;

    // Get calculation method from settings
    final methodName = _settings?.get('calculation_method', defaultValue: 'muslim_world_league');
    final madhab = _settings?.get('madhab', defaultValue: 'shafi');
    
    final calculationMethod = _getCalculationMethod(methodName);
    final params = calculationMethod.getParameters();
    params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    
    // High latitude adjustment
    final highLatRule = _settings?.get('high_latitude_rule', defaultValue: 'middle_of_night');
    if (latitude.abs() > 48) {
      params.highLatitudeRule = _getHighLatitudeRule(highLatRule);
    }

    final coordinates = Coordinates(latitude, longitude);
    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(date),
      params,
    );

    // Apply manual adjustments
    final adjustments = _getManualAdjustments();

    return {
      'fajr': prayerTimes.fajr.add(Duration(minutes: adjustments['fajr'] ?? 0)),
      'sunrise': prayerTimes.sunrise.add(Duration(minutes: adjustments['sunrise'] ?? 0)),
      'dhuhr': prayerTimes.dhuhr.add(Duration(minutes: adjustments['dhuhr'] ?? 0)),
      'asr': prayerTimes.asr.add(Duration(minutes: adjustments['asr'] ?? 0)),
      'maghrib': prayerTimes.maghrib.add(Duration(minutes: adjustments['maghrib'] ?? 0)),
      'isha': prayerTimes.isha.add(Duration(minutes: adjustments['isha'] ?? 0)),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 2: NATIVE BACKGROUND SCHEDULER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule all prayers for today and tomorrow
  static Future<void> scheduleAllPrayers() async {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    // Schedule today's remaining prayers
    await _scheduleDayPrayers(today);
    
    // Schedule tomorrow's prayers
    await _scheduleDayPrayers(tomorrow);
  }

  static Future<void> _scheduleDayPrayers(DateTime date) async {
    final prayerTimes = await calculatePrayerTimes(date: date);
    final now = DateTime.now();

    for (final entry in prayerTimes.entries) {
      final prayerName = entry.key;
      final prayerTime = entry.value;

      // Skip sunrise (no adhan)
      if (prayerName == 'sunrise') continue;

      // Skip if already passed
      if (prayerTime.isBefore(now)) continue;

      // Schedule the adhan
      await _scheduleExactAdhan(
        prayerId: '${prayerName}_${date.year}${date.month}${date.day}',
        prayerName: prayerName,
        scheduledTime: prayerTime,
      );

      // Schedule pre-adhan reminder if enabled
      final preReminderMinutes = _settings?.get('pre_reminder_minutes', defaultValue: 0) ?? 0;
      if (preReminderMinutes > 0) {
        final reminderTime = prayerTime.subtract(Duration(minutes: preReminderMinutes));
        if (reminderTime.isAfter(now)) {
          await _schedulePreReminder(
            reminderId: 'pre_${prayerName}_${date.year}${date.month}${date.day}',
            prayerName: prayerName,
            reminderTime: reminderTime,
            minutesBefore: preReminderMinutes,
          );
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 3: EXACT ALARM / CRITICAL ALERT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule exact adhan using native code
  static Future<void> _scheduleExactAdhan({
    required String prayerId,
    required String prayerName,
    required DateTime scheduledTime,
  }) async {
    final adhanSoundId = _getAdhanSoundForPrayer(prayerName);
    final vibrate = _settings?.get('vibrate_on_adhan', defaultValue: true) ?? true;
    final overrideDnd = _settings?.get('override_dnd', defaultValue: true) ?? true;

    try {
      await _methodChannel.invokeMethod('scheduleExactAdhan', {
        'prayerId': prayerId,
        'prayerName': prayerName,
        'prayerNameArabic': _getPrayerNameArabic(prayerName),
        'scheduledTimeMillis': scheduledTime.millisecondsSinceEpoch,
        'adhanSoundId': adhanSoundId,
        'vibrate': vibrate,
        'overrideDnd': overrideDnd,
      });
    } catch (e) {
      // Fallback to Flutter notifications
      await _scheduleFallbackNotification(prayerId, prayerName, scheduledTime);
    }
  }

  /// Schedule pre-prayer reminder
  static Future<void> _schedulePreReminder({
    required String reminderId,
    required String prayerName,
    required DateTime reminderTime,
    required int minutesBefore,
  }) async {
    try {
      await _methodChannel.invokeMethod('schedulePreReminder', {
        'reminderId': reminderId,
        'prayerName': prayerName,
        'prayerNameArabic': _getPrayerNameArabic(prayerName),
        'scheduledTimeMillis': reminderTime.millisecondsSinceEpoch,
        'minutesBefore': minutesBefore,
      });
    } catch (e) {
      // Fallback handled separately
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 4: AUDIO SERVICE CONTROLS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stop currently playing adhan
  static Future<void> stopAdhan() async {
    try {
      await _methodChannel.invokeMethod('stopAdhan');
    } catch (e) {
      // Ignore
    }
  }

  /// Snooze adhan (postpone reminder)
  static Future<void> snoozeAdhan(String prayerName, int minutes) async {
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    await _schedulePreReminder(
      reminderId: 'snooze_$prayerName',
      prayerName: prayerName,
      reminderTime: snoozeTime,
      minutesBefore: 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 5: FALLBACK NOTIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _scheduleFallbackNotification(
    String prayerId,
    String prayerName,
    DateTime scheduledTime,
  ) async {
    // Use flutter_local_notifications as fallback
    // This is less reliable but better than nothing
    try {
      await _methodChannel.invokeMethod('scheduleFallbackNotification', {
        'prayerId': prayerId,
        'prayerName': prayerName,
        'prayerNameArabic': _getPrayerNameArabic(prayerName),
        'scheduledTimeMillis': scheduledTime.millisecondsSinceEpoch,
      });
    } catch (e) {
      // Log error
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISSIONS & BATTERY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Request exact alarm permission (Android 12+)
  static Future<bool> _requestExactAlarmPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('requestExactAlarmPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request battery optimization exemption
  static Future<bool> _requestBatteryOptimization() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('requestBatteryOptimization');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if exact alarm is allowed
  static Future<bool> isExactAlarmAllowed() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isExactAlarmAllowed');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if battery optimization is disabled
  static Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isBatteryOptimizationDisabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get adhan enabled for prayer
  static bool isAdhanEnabled(String prayerName) {
    return _settings?.get('adhan_${prayerName}_enabled', defaultValue: true) ?? true;
  }

  /// Set adhan enabled for prayer  
  static Future<void> setAdhanEnabled(String prayerName, bool enabled) async {
    await _settings?.put('adhan_${prayerName}_enabled', enabled);
    await scheduleAllPrayers(); // Re-schedule
  }

  /// Get adhan sound for prayer
  static String _getAdhanSoundForPrayer(String prayerName) {
    if (prayerName == 'fajr') {
      return _settings?.get('fajr_adhan_sound', defaultValue: 'fajr_special') ?? 'fajr_special';
    }
    return _settings?.get('regular_adhan_sound', defaultValue: 'makkah') ?? 'makkah';
  }

  /// Set adhan sound
  static Future<void> setAdhanSound(String soundId, {bool forFajr = false}) async {
    if (forFajr) {
      await _settings?.put('fajr_adhan_sound', soundId);
    } else {
      await _settings?.put('regular_adhan_sound', soundId);
    }
  }

  /// Get manual adjustments
  static Map<String, int> _getManualAdjustments() {
    return {
      'fajr': _settings?.get('adjust_fajr', defaultValue: 0) ?? 0,
      'sunrise': _settings?.get('adjust_sunrise', defaultValue: 0) ?? 0,
      'dhuhr': _settings?.get('adjust_dhuhr', defaultValue: 0) ?? 0,
      'asr': _settings?.get('adjust_asr', defaultValue: 0) ?? 0,
      'maghrib': _settings?.get('adjust_maghrib', defaultValue: 0) ?? 0,
      'isha': _settings?.get('adjust_isha', defaultValue: 0) ?? 0,
    };
  }

  /// Set manual adjustment
  static Future<void> setManualAdjustment(String prayerName, int minutes) async {
    await _settings?.put('adjust_$prayerName', minutes);
    await scheduleAllPrayers();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static CalculationMethod _getCalculationMethod(String? name) {
    switch (name) {
      case 'muslim_world_league':
        return CalculationMethod.muslim_world_league;
      case 'egyptian':
        return CalculationMethod.egyptian;
      case 'karachi':
        return CalculationMethod.karachi;
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura;
      case 'dubai':
        return CalculationMethod.dubai;
      case 'qatar':
        return CalculationMethod.qatar;
      case 'kuwait':
        return CalculationMethod.kuwait;
      case 'singapore':
        return CalculationMethod.singapore;
      case 'north_america':
        return CalculationMethod.north_america;
      default:
        return CalculationMethod.muslim_world_league;
    }
  }

  static HighLatitudeRule _getHighLatitudeRule(String? rule) {
    switch (rule) {
      case 'middle_of_night':
        return HighLatitudeRule.middle_of_the_night;
      case 'seventh_of_night':
        return HighLatitudeRule.seventh_of_the_night;
      case 'twilight_angle':
        return HighLatitudeRule.twilight_angle;
      default:
        return HighLatitudeRule.middle_of_the_night;
    }
  }

  static String _getPrayerNameArabic(String prayerName) {
    switch (prayerName) {
      case 'fajr':
        return 'الفجر';
      case 'sunrise':
        return 'الشروق';
      case 'dhuhr':
        return 'الظهر';
      case 'asr':
        return 'العصر';
      case 'maghrib':
        return 'المغرب';
      case 'isha':
        return 'العشاء';
      default:
        return prayerName;
    }
  }

  /// Cancel all scheduled adhans
  static Future<void> cancelAllAdhans() async {
    try {
      await _methodChannel.invokeMethod('cancelAllAdhans');
    } catch (e) {
      // Ignore
    }
  }

  /// Get adhan log (for debugging)
  static Future<List<Map<String, dynamic>>> getAdhanLog() async {
    try {
      final result = await _methodChannel.invokeMethod<List>('getAdhanLog');
      return result?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
}

/// Adhan sound model
class AdhanSound {
  final String id;
  final String nameArabic;
  final String nameEnglish;

  const AdhanSound({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
  });
}
