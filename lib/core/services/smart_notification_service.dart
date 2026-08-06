import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../services/prayer_calculation_service.dart';
import '../services/location_service.dart';
import '../../features/prayer/domain/entities/prayer_entities.dart';

/// خدمة الإشعارات الذكية - Smart Notifications Service
/// Contextual reminders + Auto-DND during prayer
class SmartNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static Timer? _prayerCheckTimer;
  static bool _isDndActive = false;
  static DateTime? _dndUntil;
  
  static final PrayerCalculationService _prayerService = PrayerCalculationService();
  static final LocationService _locationService = LocationService();

  // Notification Channel IDs
  static const String _prayerChannelId = 'prayer_notifications';
  static const String _adhkarChannelId = 'adhkar_notifications';
  static const String _quranChannelId = 'quran_notifications';

  /// Initialize notification service
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels
    await _createNotificationChannels();

    // Start prayer time monitoring
    _startPrayerTimeMonitoring();
  }

  static Future<void> _createNotificationChannels() async {
    const prayerChannel = AndroidNotificationChannel(
      _prayerChannelId,
      'تذكير الصلاة',
      description: 'إشعارات مواقيت الصلاة',
      importance: Importance.high,
      playSound: true,
    );

    const adhkarChannel = AndroidNotificationChannel(
      _adhkarChannelId,
      'تذكير الأذكار',
      description: 'أذكار الصباح والمساء',
      importance: Importance.defaultImportance,
    );

    const quranChannel = AndroidNotificationChannel(
      _quranChannelId,
      'تذكير القرآن',
      description: 'تذكير بورد القرآن اليومي',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(prayerChannel);
    await androidPlugin?.createNotificationChannel(adhkarChannel);
    await androidPlugin?.createNotificationChannel(quranChannel);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRAYER TIME NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static void _startPrayerTimeMonitoring() {
    // Check every minute
    _prayerCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkPrayerTime();
    });
  }

  static Future<void> _checkPrayerTime() async {
    final location = await _locationService.getCurrentLocation();
    if (location == null) return;

    final times = _prayerService.calculatePrayerTimes(
      date: DateTime.now(),
      location: location,
    );

    final now = DateTime.now();

    // Check each prayer time
    final prayerTimes = [
      times.fajr,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];

    for (final prayer in prayerTimes) {
      final diff = prayer.time.difference(now);

      // 15 minutes before prayer - pre-notification
      if (diff.inMinutes == 15 && diff.inMinutes > 0) {
        await _showPrePrayerNotification(prayer);
      }

      // At prayer time - main notification + auto-DND
      if (diff.inMinutes == 0 || (diff.inMinutes <= 1 && diff.inMinutes >= -1)) {
        await _showPrayerNotification(prayer);
        await _enableAutoDnd(prayer);
      }
    }

    // Check if DND should be disabled
    if (_isDndActive && _dndUntil != null && now.isAfter(_dndUntil!)) {
      await _disableAutoDnd();
    }
  }

  static Future<void> _showPrePrayerNotification(PrayerTime prayer) async {
    await _notifications.show(
      prayer.name.hashCode + 100,
      'يقترب وقت ${prayer.nameArabic}',
      'استعد للصلاة بعد 15 دقيقة',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          'تذكير الصلاة',
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF1B5E20),
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> _showPrayerNotification(PrayerTime prayer) async {
    await HapticFeedback.heavyImpact();
    
    await _notifications.show(
      prayer.name.hashCode,
      'حان وقت صلاة ${prayer.nameArabic}',
      'حيّ على الصلاة، حيّ على الفلاح',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          'تذكير الصلاة',
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF1B5E20),
          importance: Importance.high,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          actions: [
            const AndroidNotificationAction(
              'silent_mode',
              'تفعيل الصامت',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTO-DND (DO NOT DISTURB)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _enableAutoDnd(PrayerTime prayer) async {
    _isDndActive = true;
    // DND for ~30 minutes (typical prayer duration)
    _dndUntil = DateTime.now().add(const Duration(minutes: 30));

    // On Android, we can request DND permission and enable it
    // This requires special permission on Android
    if (Platform.isAndroid) {
      // Note: Requires android.permission.ACCESS_NOTIFICATION_POLICY
      // and android.permission.MODIFY_AUDIO_SETTINGS
      try {
        // Enable silent mode via MethodChannel
        const platform = MethodChannel('com.noor.app/audio');
        await platform.invokeMethod('setRingerMode', {'mode': 0}); // 0 = silent
      } catch (e) {
        // Fallback: just track internally
      }
    }

    // Show notification that DND is active
    await _notifications.show(
      999,
      'وضع الصمت مفعّل 🤫',
      'سيتم إيقافه تلقائياً بعد 30 دقيقة',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          'تذكير الصلاة',
          icon: '@mipmap/ic_launcher',
          ongoing: true,
          autoCancel: false,
          category: AndroidNotificationCategory.service,
        ),
      ),
    );
  }

  static Future<void> _disableAutoDnd() async {
    _isDndActive = false;
    _dndUntil = null;

    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.noor.app/audio');
        await platform.invokeMethod('setRingerMode', {'mode': 2}); // 2 = normal
      } catch (e) {
        // Fallback
      }
    }

    // Cancel DND notification
    await _notifications.cancel(999);
  }

  /// Manually enable silent mode for prayer
  static Future<void> enableSilentMode({int durationMinutes = 30}) async {
    final fakePrayer = PrayerTime(
      name: 'manual',
      nameArabic: 'يدوي',
      time: DateTime.now(),
      isPassed: false,
      isNext: false,
    );
    await _enableAutoDnd(fakePrayer);
    _dndUntil = DateTime.now().add(Duration(minutes: durationMinutes));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADHKAR NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule morning adhkar notification
  static Future<void> scheduleMorningAdhkar() async {
    // Cancel existing
    await _notifications.cancel(1001);

    await _notifications.zonedSchedule(
      1001,
      'أذكار الصباح ☀️',
      'حافظ على أذكار الصباح لتبدأ يومك ببركة',
      _nextInstanceOfTime(6, 0), // 6:00 AM
      NotificationDetails(
        android: AndroidNotificationDetails(
          _adhkarChannelId,
          'تذكير الأذكار',
          icon: '@mipmap/ic_launcher',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedule evening adhkar notification
  static Future<void> scheduleEveningAdhkar() async {
    await _notifications.cancel(1002);

    await _notifications.zonedSchedule(
      1002,
      'أذكار المساء 🌙',
      'لا تنسَ أذكار المساء لختام يومك',
      _nextInstanceOfTime(17, 0), // 5:00 PM
      NotificationDetails(
        android: AndroidNotificationDetails(
          _adhkarChannelId,
          'تذكير الأذكار',
          icon: '@mipmap/ic_launcher',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QURAN NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule daily Quran reminder
  static Future<void> scheduleDailyQuranReminder({
    int hour = 10,
    int minute = 0,
  }) async {
    await _notifications.cancel(1003);

    await _notifications.zonedSchedule(
      1003,
      'وردك اليومي من القرآن 📖',
      'اجعل القرآن رفيقك اليوم',
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _quranChannelId,
          'تذكير القرآن',
          icon: '@mipmap/ic_launcher',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Show verse of the day notification
  static Future<void> showVerseOfTheDay({
    required String verseText,
    required String reference,
  }) async {
    await _notifications.show(
      2001,
      'آية اليوم',
      verseText.length > 100 ? '${verseText.substring(0, 100)}...' : verseText,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _quranChannelId,
          'تذكير القرآن',
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            verseText,
            summaryText: reference,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEEKLY SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Show weekly spiritual summary
  static Future<void> showWeeklySummary({
    required int prayersCompleted,
    required int adhkarCompleted,
    required int pagesRead,
  }) async {
    await _notifications.show(
      3001,
      'ملخص الأسبوع الروحي 🌟',
      '🕌 $prayersCompleted صلاة | 📿 $adhkarCompleted ذكر | 📖 $pagesRead صفحة',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _quranChannelId,
          'تذكير القرآن',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          styleInformation: BigTextStyleInformation(
            'أحسنت! هذا الأسبوع:\n'
            '• صليت $prayersCompleted صلاة\n'
            '• ذكرت الله $adhkarCompleted مرة\n'
            '• قرأت $pagesRead صفحة من القرآن\n\n'
            'استمر في طريقك إلى الله 💚',
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    tz_data.initializeTimeZones();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduled, tz.local);
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - navigate to appropriate screen
    final payload = response.payload;
    // Use go_router to navigate based on payload
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    _prayerCheckTimer?.cancel();
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Request notification permission
  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    return false;
  }

  /// Get DND status
  static bool get isDndActive => _isDndActive;

  /// Get DND end time
  static DateTime? get dndEndTime => _dndUntil;
}

