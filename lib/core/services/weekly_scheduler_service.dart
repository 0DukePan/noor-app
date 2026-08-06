import 'dart:async';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'prayer_time_engine.dart';

/// 📅 جدولة أسبوعية للأذان - Weekly Adhan Scheduler
/// - جدولة 7 أيام مقدمًا
/// - فحص منتصف الليل (Self-Validation)
/// - إعادة الجدولة التلقائية
class WeeklySchedulerService {
  static const _cacheBoxName = 'weekly_scheduler';
  static const _channelName = 'com.noor.app/adhan';
  
  static Box? _cacheBox;
  static final _channel = const MethodChannel(_channelName);
  
  // Current settings
  static double _latitude = 0;
  static double _longitude = 0;
  static double _elevation = 0;
  static CalculationMethod _method = CalculationMethod.muslimWorldLeague;
  static Madhab _madhab = Madhab.shafi;
  static HighLatitudeRule _highLatitudeRule = HighLatitudeRule.middleOfNight;
  static PrayerAdjustments? _adjustments;
  
  // Notification settings per prayer
  static final Map<PrayerType, PrayerNotificationSettings> _notificationSettings = {
    PrayerType.fajr: const PrayerNotificationSettings(
      enableAdhan: true,
      adhanSoundId: 'fajr_special',
      enablePreReminder: true,
      preReminderMinutes: 15,
      enableMosqueMode: true,
      mosqueModeMinutes: 30,
    ),
    PrayerType.dhuhr: const PrayerNotificationSettings(),
    PrayerType.asr: const PrayerNotificationSettings(),
    PrayerType.maghrib: const PrayerNotificationSettings(),
    PrayerType.isha: const PrayerNotificationSettings(),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialize the weekly scheduler
  static Future<void> init() async {
    _cacheBox = await Hive.openBox(_cacheBoxName);
    await _loadSettings();
    
    // Start midnight validation
    _startMidnightValidation();
  }

  /// Load saved settings
  static Future<void> _loadSettings() async {
    _latitude = _cacheBox?.get('latitude', defaultValue: 0.0) ?? 0.0;
    _longitude = _cacheBox?.get('longitude', defaultValue: 0.0) ?? 0.0;
    _elevation = _cacheBox?.get('elevation', defaultValue: 0.0) ?? 0.0;
    _method = CalculationMethod.values[
      _cacheBox?.get('method', defaultValue: 0) ?? 0
    ];
    _madhab = Madhab.values[
      _cacheBox?.get('madhab', defaultValue: 0) ?? 0
    ];
  }

  /// Save settings
  static Future<void> saveSettings({
    required double latitude,
    required double longitude,
    double elevation = 0,
    required CalculationMethod method,
    Madhab madhab = Madhab.shafi,
    HighLatitudeRule highLatitudeRule = HighLatitudeRule.middleOfNight,
    PrayerAdjustments? adjustments,
  }) async {
    _latitude = latitude;
    _longitude = longitude;
    _elevation = elevation;
    _method = method;
    _madhab = madhab;
    _highLatitudeRule = highLatitudeRule;
    _adjustments = adjustments;
    
    await _cacheBox?.put('latitude', latitude);
    await _cacheBox?.put('longitude', longitude);
    await _cacheBox?.put('elevation', elevation);
    await _cacheBox?.put('method', method.index);
    await _cacheBox?.put('madhab', madhab.index);
    await _cacheBox?.put('highLatitudeRule', highLatitudeRule.index);
    
    // Reschedule with new settings
    await scheduleWeek();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEEKLY SCHEDULING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule all prayers for the next 7 days
  static Future<void> scheduleWeek() async {
    if (_latitude == 0 && _longitude == 0) {
      throw SchedulerException('الموقع غير محدد');
    }
    
    final today = DateTime.now();
    final weekPrayerTimes = PrayerTimeEngine.calculateWeek(
      latitude: _latitude,
      longitude: _longitude,
      startDate: today,
      method: _method,
      madhab: _madhab,
      highLatitudeRule: _highLatitudeRule,
      elevation: _elevation,
      adjustments: _adjustments,
    );
    
    // Cancel all existing alarms
    await _cancelAllAlarms();
    
    // Schedule each day
    for (int dayIndex = 0; dayIndex < weekPrayerTimes.length; dayIndex++) {
      final dayTimes = weekPrayerTimes[dayIndex];
      await _scheduleDay(dayTimes, dayIndex);
    }
    
    // Save scheduled times for validation
    await _saveScheduledTimes(weekPrayerTimes);
    
    // Log
    await _log('Scheduled ${weekPrayerTimes.length} days of prayers');
  }

  /// Schedule a single day's prayers
  static Future<void> _scheduleDay(PrayerTimes times, int dayIndex) async {
    final prayers = [
      PrayerType.fajr,
      PrayerType.dhuhr,
      PrayerType.asr,
      PrayerType.maghrib,
      PrayerType.isha,
    ];
    
    for (final prayer in prayers) {
      final time = times.getTime(prayer);
      final settings = _notificationSettings[prayer] ?? const PrayerNotificationSettings();
      
      // Skip if time has passed
      if (time.isBefore(DateTime.now())) continue;
      
      // Schedule pre-reminder
      if (settings.enablePreReminder && settings.preReminderMinutes > 0) {
        final reminderTime = time.subtract(Duration(minutes: settings.preReminderMinutes));
        if (reminderTime.isAfter(DateTime.now())) {
          await _schedulePreReminder(
            prayerId: 'pre_${prayer.name}_day$dayIndex',
            prayerName: prayer.name,
            prayerNameArabic: _getArabicName(prayer),
            scheduledTime: reminderTime,
            minutesBefore: settings.preReminderMinutes,
          );
        }
      }
      
      // Schedule adhan
      if (settings.enableAdhan) {
        await _scheduleAdhan(
          prayerId: '${prayer.name}_day$dayIndex',
          prayerName: prayer.name,
          prayerNameArabic: _getArabicName(prayer),
          scheduledTime: time,
          adhanSoundId: settings.adhanSoundId,
          vibrate: settings.vibrate,
          overrideDnd: settings.overrideDnd,
        );
      }
      
      // Schedule mosque mode
      if (settings.enableMosqueMode) {
        await _scheduleMosqueMode(
          prayerId: 'mosque_${prayer.name}_day$dayIndex',
          scheduledTime: time,
          durationMinutes: settings.mosqueModeMinutes,
        );
      }
      
      // Schedule post-reminder
      if (settings.enablePostReminder && settings.postReminderMinutes > 0) {
        final postTime = time.add(Duration(minutes: settings.postReminderMinutes));
        await _schedulePostReminder(
          prayerId: 'post_${prayer.name}_day$dayIndex',
          prayerName: prayer.name,
          prayerNameArabic: _getArabicName(prayer),
          scheduledTime: postTime,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIDNIGHT VALIDATION (Self-Validation)
  // ═══════════════════════════════════════════════════════════════════════════

  static Timer? _midnightTimer;

  /// Start midnight validation check
  static void _startMidnightValidation() {
    _midnightTimer?.cancel();
    
    // Calculate next midnight
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 1);
    final duration = nextMidnight.difference(now);
    
    _midnightTimer = Timer(duration, () async {
      await _validateAndReschedule();
      _startMidnightValidation(); // Schedule next check
    });
  }

  /// Validate prayer times and reschedule if needed
  static Future<void> _validateAndReschedule() async {
    try {
      // Calculate today's prayer times
      final todayTimes = PrayerTimeEngine.calculate(
        latitude: _latitude,
        longitude: _longitude,
        date: DateTime.now(),
        method: _method,
        madhab: _madhab,
        highLatitudeRule: _highLatitudeRule,
        elevation: _elevation,
        adjustments: _adjustments,
      );
      
      // Get cached times
      final cachedTimes = await _getCachedTodayTimes();
      
      if (cachedTimes == null) {
        // No cache, schedule fresh
        await scheduleWeek();
        return;
      }
      
      // Compare times
      bool needsReschedule = false;
      
      for (final prayer in PrayerType.values) {
        if (prayer == PrayerType.sunrise) continue; // Skip sunrise
        
        final newTime = todayTimes.getTime(prayer);
        final cachedTime = cachedTimes.getTime(prayer);
        
        final diff = newTime.difference(cachedTime).abs();
        
        if (diff > const Duration(minutes: 1)) {
          needsReschedule = true;
          await _log('Discrepancy detected: ${prayer.name} differs by ${diff.inMinutes} minutes');
          break;
        }
      }
      
      if (needsReschedule) {
        await _log('Rescheduling due to time discrepancy');
        await scheduleWeek();
      } else {
        await _log('Midnight validation: No discrepancy found');
      }
    } catch (e) {
      await _log('Midnight validation failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NATIVE CHANNEL CALLS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _scheduleAdhan({
    required String prayerId,
    required String prayerName,
    required String prayerNameArabic,
    required DateTime scheduledTime,
    required String adhanSoundId,
    bool vibrate = true,
    bool overrideDnd = true,
  }) async {
    try {
      await _channel.invokeMethod('scheduleExactAdhan', {
        'prayerId': prayerId,
        'prayerName': prayerName,
        'prayerNameArabic': prayerNameArabic,
        'scheduledTimeMillis': scheduledTime.millisecondsSinceEpoch,
        'adhanSoundId': adhanSoundId,
        'vibrate': vibrate,
        'overrideDnd': overrideDnd,
      });
    } catch (e) {
      await _log('Failed to schedule adhan: $e');
    }
  }

  static Future<void> _schedulePreReminder({
    required String prayerId,
    required String prayerName,
    required String prayerNameArabic,
    required DateTime scheduledTime,
    required int minutesBefore,
  }) async {
    try {
      await _channel.invokeMethod('schedulePreReminder', {
        'reminderId': prayerId,
        'prayerName': prayerName,
        'prayerNameArabic': prayerNameArabic,
        'scheduledTimeMillis': scheduledTime.millisecondsSinceEpoch,
        'minutesBefore': minutesBefore,
      });
    } catch (e) {
      await _log('Failed to schedule pre-reminder: $e');
    }
  }

  static Future<void> _schedulePostReminder({
    required String prayerId,
    required String prayerName,
    required String prayerNameArabic,
    required DateTime scheduledTime,
  }) async {
    try {
      await _channel.invokeMethod('schedulePostReminder', {
        'reminderId': prayerId,
        'prayerName': prayerName,
        'prayerNameArabic': prayerNameArabic,
        'scheduledTimeMillis': scheduledTime.millisecondsSinceEpoch,
      });
    } catch (e) {
      await _log('Failed to schedule post-reminder: $e');
    }
  }

  static Future<void> _scheduleMosqueMode({
    required String prayerId,
    required DateTime scheduledTime,
    required int durationMinutes,
  }) async {
    try {
      await _channel.invokeMethod('scheduleMosqueMode', {
        'prayerId': prayerId,
        'scheduledTimeMillis': scheduledTime.millisecondsSinceEpoch,
        'durationMinutes': durationMinutes,
      });
    } catch (e) {
      await _log('Failed to schedule mosque mode: $e');
    }
  }

  static Future<void> _cancelAllAlarms() async {
    try {
      await _channel.invokeMethod('cancelAllAdhans');
    } catch (e) {
      await _log('Failed to cancel alarms: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHING
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _saveScheduledTimes(List<PrayerTimes> weekTimes) async {
    for (int i = 0; i < weekTimes.length; i++) {
      final times = weekTimes[i];
      await _cacheBox?.put('day_$i', {
        'date': times.date.toIso8601String(),
        'fajr': times.fajr.toIso8601String(),
        'sunrise': times.sunrise.toIso8601String(),
        'dhuhr': times.dhuhr.toIso8601String(),
        'asr': times.asr.toIso8601String(),
        'maghrib': times.maghrib.toIso8601String(),
        'isha': times.isha.toIso8601String(),
      });
    }
  }

  static Future<PrayerTimes?> _getCachedTodayTimes() async {
    final data = _cacheBox?.get('day_0');
    if (data == null) return null;
    
    try {
      return PrayerTimes(
        date: DateTime.parse(data['date']),
        fajr: DateTime.parse(data['fajr']),
        sunrise: DateTime.parse(data['sunrise']),
        dhuhr: DateTime.parse(data['dhuhr']),
        asr: DateTime.parse(data['asr']),
        maghrib: DateTime.parse(data['maghrib']),
        isha: DateTime.parse(data['isha']),
      );
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS PER PRAYER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update notification settings for a specific prayer
  static Future<void> updatePrayerSettings(
    PrayerType prayer,
    PrayerNotificationSettings settings,
  ) async {
    _notificationSettings[prayer] = settings;
    await _cacheBox?.put('prayer_settings_${prayer.name}', settings.toMap());
    await scheduleWeek(); // Reschedule with new settings
  }

  /// Get notification settings for a prayer
  static PrayerNotificationSettings getPrayerSettings(PrayerType prayer) {
    return _notificationSettings[prayer] ?? const PrayerNotificationSettings();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _getArabicName(PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr: return 'الفجر';
      case PrayerType.sunrise: return 'الشروق';
      case PrayerType.dhuhr: return 'الظهر';
      case PrayerType.asr: return 'العصر';
      case PrayerType.maghrib: return 'المغرب';
      case PrayerType.isha: return 'العشاء';
    }
  }

  static Future<void> _log(String message) async {
    final logs = _cacheBox?.get('logs', defaultValue: <String>[]) ?? <String>[];
    logs.add('${DateTime.now().toIso8601String()}: $message');
    
    // Keep only last 100 logs
    if (logs.length > 100) {
      logs.removeRange(0, logs.length - 100);
    }
    
    await _cacheBox?.put('logs', logs);
  }

  /// Get scheduler logs
  static List<String> getLogs() {
    return (_cacheBox?.get('logs', defaultValue: <String>[]) ?? <String>[])
        .cast<String>();
  }

  /// Get today's prayer times
  static Future<PrayerTimes> getTodayPrayerTimes() async {
    return PrayerTimeEngine.calculate(
      latitude: _latitude,
      longitude: _longitude,
      date: DateTime.now(),
      method: _method,
      madhab: _madhab,
      highLatitudeRule: _highLatitudeRule,
      elevation: _elevation,
      adjustments: _adjustments,
    );
  }

  /// Dispose resources
  static void dispose() {
    _midnightTimer?.cancel();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION SETTINGS
// ═══════════════════════════════════════════════════════════════════════════

/// Settings for each prayer notification
class PrayerNotificationSettings {
  final bool enableAdhan;
  final String adhanSoundId;
  final bool vibrate;
  final bool overrideDnd;
  
  final bool enablePreReminder;
  final int preReminderMinutes;
  
  final bool enablePostReminder;
  final int postReminderMinutes;
  
  final bool enableMosqueMode;
  final int mosqueModeMinutes;
  
  final bool vibrateOnly;

  const PrayerNotificationSettings({
    this.enableAdhan = true,
    this.adhanSoundId = 'al_qatami',
    this.vibrate = true,
    this.overrideDnd = true,
    this.enablePreReminder = false,
    this.preReminderMinutes = 15,
    this.enablePostReminder = false,
    this.postReminderMinutes = 10,
    this.enableMosqueMode = false,
    this.mosqueModeMinutes = 20,
    this.vibrateOnly = false,
  });

  Map<String, dynamic> toMap() => {
    'enableAdhan': enableAdhan,
    'adhanSoundId': adhanSoundId,
    'vibrate': vibrate,
    'overrideDnd': overrideDnd,
    'enablePreReminder': enablePreReminder,
    'preReminderMinutes': preReminderMinutes,
    'enablePostReminder': enablePostReminder,
    'postReminderMinutes': postReminderMinutes,
    'enableMosqueMode': enableMosqueMode,
    'mosqueModeMinutes': mosqueModeMinutes,
    'vibrateOnly': vibrateOnly,
  };

  factory PrayerNotificationSettings.fromMap(Map<String, dynamic> map) {
    return PrayerNotificationSettings(
      enableAdhan: map['enableAdhan'] ?? true,
      adhanSoundId: map['adhanSoundId'] ?? 'al_qatami',
      vibrate: map['vibrate'] ?? true,
      overrideDnd: map['overrideDnd'] ?? true,
      enablePreReminder: map['enablePreReminder'] ?? false,
      preReminderMinutes: map['preReminderMinutes'] ?? 15,
      enablePostReminder: map['enablePostReminder'] ?? false,
      postReminderMinutes: map['postReminderMinutes'] ?? 10,
      enableMosqueMode: map['enableMosqueMode'] ?? false,
      mosqueModeMinutes: map['mosqueModeMinutes'] ?? 20,
      vibrateOnly: map['vibrateOnly'] ?? false,
    );
  }
}

/// Scheduler exception
class SchedulerException implements Exception {
  final String message;
  SchedulerException(this.message);
  
  @override
  String toString() => 'SchedulerException: $message';
}
