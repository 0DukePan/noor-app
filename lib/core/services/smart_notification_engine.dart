import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'prayer_time_engine.dart';

/// 🔔 خدمة الإشعارات الاحترافية - Professional Notification Service
/// 
/// Features:
/// - Smart Adhkar reminders (morning/evening based on actual prayer times)
/// - Prayer notifications
/// - Custom scheduling
/// - Quiet hours
/// - Sound customization
class SmartNotificationEngine {
  static final FlutterLocalNotificationsPlugin _plugin = 
      FlutterLocalNotificationsPlugin();
  static Box? _settingsBox;
  
  // Notification channels
  static const String _adhkarChannelId = 'adhkar_notifications';
  static const String _prayerChannelId = 'prayer_notifications';
  static const String _reminderChannelId = 'reminder_notifications';

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// تهيئة النظام
  static Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Initialize Hive
    _settingsBox = await Hive.openBox('notification_settings');
    
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Create notification channels
    await _createNotificationChannels();
  }

  /// إنشاء قنوات الإشعارات
  static Future<void> _createNotificationChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Adhkar channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _adhkarChannelId,
          'أذكار الصباح والمساء',
          description: 'تذكيرات الأذكار اليومية',
          importance: Importance.high,
          playSound: true,
        ),
      );
      
      // Prayer channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _prayerChannelId,
          'مواعيد الصلاة',
          description: 'تنبيهات مواعيد الصلاة',
          importance: Importance.max,
          playSound: true,
        ),
      );
      
      // Reminder channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _reminderChannelId,
          'تذكيرات عامة',
          description: 'تذكيرات متنوعة',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );
    }
  }

  /// طلب صلاحيات الإشعارات
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADHKAR NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// جدولة إشعارات الأذكار الذكية
  /// 
  /// - أذكار الصباح: بعد صلاة الفجر بـ 30 دقيقة
  /// - أذكار المساء: قبل صلاة المغرب بـ 30 دقيقة
  static Future<void> scheduleAdhkarNotifications({
    required double latitude,
    required double longitude,
    bool morningEnabled = true,
    bool eveningEnabled = true,
  }) async {
    // Cancel existing
    await cancelAdhkarNotifications();
    
    // Calculate prayer times
    final prayerTimes = PrayerTimeEngine.calculate(
      latitude: latitude,
      longitude: longitude,
      date: DateTime.now(),
      method: CalculationMethod.ummAlQura,
    );
    
    // Schedule morning adhkar (30 min after Fajr)
    if (morningEnabled) {
      final morningTime = prayerTimes.fajr.add(const Duration(minutes: 30));
      await _scheduleDaily(
        id: 100,
        title: '☀️ أذكار الصباح',
        body: 'حان وقت أذكار الصباح - ابدأ يومك بذكر الله',
        scheduledTime: morningTime,
        channelId: _adhkarChannelId,
        payload: 'adhkar_morning',
      );
    }
    
    // Schedule evening adhkar (30 min before Maghrib)
    if (eveningEnabled) {
      final eveningTime = prayerTimes.maghrib.subtract(const Duration(minutes: 30));
      await _scheduleDaily(
        id: 101,
        title: '🌙 أذكار المساء',
        body: 'حان وقت أذكار المساء - اختم يومك بذكر الله',
        scheduledTime: eveningTime,
        channelId: _adhkarChannelId,
        payload: 'adhkar_evening',
      );
    }
    
    // Save settings
    await _settingsBox?.put('adhkar_morning_enabled', morningEnabled);
    await _settingsBox?.put('adhkar_evening_enabled', eveningEnabled);
    
    debugPrint('Adhkar notifications scheduled');
  }

  /// إلغاء إشعارات الأذكار
  static Future<void> cancelAdhkarNotifications() async {
    await _plugin.cancel(100); // Morning
    await _plugin.cancel(101); // Evening
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRAYER NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// جدولة إشعارات الصلاة
  static Future<void> schedulePrayerNotifications({
    required double latitude,
    required double longitude,
    List<PrayerType> enabledPrayers = const [
      PrayerType.fajr,
      PrayerType.dhuhr,
      PrayerType.asr,
      PrayerType.maghrib,
      PrayerType.isha,
    ],
    int minutesBefore = 10,
  }) async {
    // Cancel existing
    await cancelPrayerNotifications();
    
    // Calculate prayer times
    final prayerTimes = PrayerTimeEngine.calculate(
      latitude: latitude,
      longitude: longitude,
      date: DateTime.now(),
      method: CalculationMethod.ummAlQura,
    );
    
    // Schedule each prayer
    for (final prayer in enabledPrayers) {
      final prayerTime = _getPrayerTime(prayerTimes, prayer);
      final notifyTime = prayerTime.subtract(Duration(minutes: minutesBefore));
      
      await _scheduleDaily(
        id: 200 + prayer.index,
        title: '🕌 ${prayer.arabicName}',
        body: minutesBefore > 0 
            ? 'تبقى $minutesBefore دقيقة على صلاة ${prayer.arabicName}'
            : 'حان وقت صلاة ${prayer.arabicName}',
        scheduledTime: notifyTime,
        channelId: _prayerChannelId,
        payload: 'prayer_${prayer.name}',
      );
    }
    
    debugPrint('Prayer notifications scheduled for ${enabledPrayers.length} prayers');
  }

  /// إلغاء إشعارات الصلاة
  static Future<void> cancelPrayerNotifications() async {
    for (int i = 0; i < 6; i++) {
      await _plugin.cancel(200 + i);
    }
  }

  static DateTime _getPrayerTime(PrayerTimes times, PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr: return times.fajr;
      case PrayerType.sunrise: return times.sunrise;
      case PrayerType.dhuhr: return times.dhuhr;
      case PrayerType.asr: return times.asr;
      case PrayerType.maghrib: return times.maghrib;
      case PrayerType.isha: return times.isha;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOM REMINDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// تذكير مخصص
  static Future<void> scheduleCustomReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _scheduleOnce(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      channelId: _reminderChannelId,
      payload: payload,
    );
  }

  /// تذكير الختمة اليومي
  static Future<void> scheduleKhatmahReminder({
    required int hour,
    required int minute,
    required String message,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If time passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    await _scheduleDaily(
      id: 300,
      title: '📖 تذكير القراءة اليومية',
      body: message,
      scheduledTime: scheduledTime,
      channelId: _reminderChannelId,
      payload: 'khatmah_reminder',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSTANT NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// إشعار فوري
  static Future<void> showInstant({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      'تذكيرات',
      channelDescription: 'إشعارات فورية',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// إشعار اكتمال الأذكار
  static Future<void> showAdhkarComplete(String type) async {
    await showInstant(
      title: '✅ أحسنت!',
      body: 'أتممت أذكار $type - بارك الله فيك',
      payload: 'adhkar_complete',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHEDULING HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// جدولة إشعار يومي متكرر
  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _adhkarChannelId ? 'أذكار' : 
        channelId == _prayerChannelId ? 'الصلاة' : 'تذكيرات',
      channelDescription: 'إشعار يومي',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: const BigTextStyleInformation(''),
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Convert to TZ
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
      payload: payload,
    );
  }

  /// جدولة إشعار مرة واحدة
  static Future<void> _scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'تذكيرات',
      channelDescription: 'إشعار لمرة واحدة',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// حفظ الإعدادات
  static Future<void> saveSettings(NotificationSettings settings) async {
    await _settingsBox?.put('settings', settings.toMap());
  }

  /// استرجاع الإعدادات
  static NotificationSettings getSettings() {
    final data = _settingsBox?.get('settings');
    if (data == null) return const NotificationSettings();
    return NotificationSettings.fromMap(Map<String, dynamic>.from(data));
  }

  /// إلغاء جميع الإشعارات
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// الإشعارات المعلقة
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notification tapped: $payload');
    
    // Handle navigation based on payload
    // This would typically use a navigation service or callback
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// إعدادات الإشعارات
class NotificationSettings {
  final bool adhkarMorningEnabled;
  final bool adhkarEveningEnabled;
  final bool prayerNotificationsEnabled;
  final int prayerNotificationMinutesBefore;
  final bool khatmahReminderEnabled;
  final int khatmahReminderHour;
  final int khatmahReminderMinute;
  final bool quietHoursEnabled;
  final int quietHoursStart;
  final int quietHoursEnd;

  const NotificationSettings({
    this.adhkarMorningEnabled = true,
    this.adhkarEveningEnabled = true,
    this.prayerNotificationsEnabled = true,
    this.prayerNotificationMinutesBefore = 10,
    this.khatmahReminderEnabled = false,
    this.khatmahReminderHour = 20,
    this.khatmahReminderMinute = 0,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 23,
    this.quietHoursEnd = 6,
  });

  Map<String, dynamic> toMap() => {
    'adhkarMorningEnabled': adhkarMorningEnabled,
    'adhkarEveningEnabled': adhkarEveningEnabled,
    'prayerNotificationsEnabled': prayerNotificationsEnabled,
    'prayerNotificationMinutesBefore': prayerNotificationMinutesBefore,
    'khatmahReminderEnabled': khatmahReminderEnabled,
    'khatmahReminderHour': khatmahReminderHour,
    'khatmahReminderMinute': khatmahReminderMinute,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
  };

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      adhkarMorningEnabled: map['adhkarMorningEnabled'] ?? true,
      adhkarEveningEnabled: map['adhkarEveningEnabled'] ?? true,
      prayerNotificationsEnabled: map['prayerNotificationsEnabled'] ?? true,
      prayerNotificationMinutesBefore: map['prayerNotificationMinutesBefore'] ?? 10,
      khatmahReminderEnabled: map['khatmahReminderEnabled'] ?? false,
      khatmahReminderHour: map['khatmahReminderHour'] ?? 20,
      khatmahReminderMinute: map['khatmahReminderMinute'] ?? 0,
      quietHoursEnabled: map['quietHoursEnabled'] ?? false,
      quietHoursStart: map['quietHoursStart'] ?? 23,
      quietHoursEnd: map['quietHoursEnd'] ?? 6,
    );
  }

  NotificationSettings copyWith({
    bool? adhkarMorningEnabled,
    bool? adhkarEveningEnabled,
    bool? prayerNotificationsEnabled,
    int? prayerNotificationMinutesBefore,
    bool? khatmahReminderEnabled,
    int? khatmahReminderHour,
    int? khatmahReminderMinute,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
  }) {
    return NotificationSettings(
      adhkarMorningEnabled: adhkarMorningEnabled ?? this.adhkarMorningEnabled,
      adhkarEveningEnabled: adhkarEveningEnabled ?? this.adhkarEveningEnabled,
      prayerNotificationsEnabled: prayerNotificationsEnabled ?? this.prayerNotificationsEnabled,
      prayerNotificationMinutesBefore: prayerNotificationMinutesBefore ?? this.prayerNotificationMinutesBefore,
      khatmahReminderEnabled: khatmahReminderEnabled ?? this.khatmahReminderEnabled,
      khatmahReminderHour: khatmahReminderHour ?? this.khatmahReminderHour,
      khatmahReminderMinute: khatmahReminderMinute ?? this.khatmahReminderMinute,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}
