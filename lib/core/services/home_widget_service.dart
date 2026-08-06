import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'prayer_time_engine.dart';

/// 📱 خدمة Widget الشاشة الرئيسية
/// 
/// Features:
/// - Next prayer widget
/// - Prayer times list widget
/// - Auto-update
/// - Supports Android & iOS
class HomeWidgetService {
  static const String _appGroupId = 'group.com.noor.widget';
  static const String _androidWidgetName = 'PrayerTimesWidget';
  static const String _iosWidgetName = 'PrayerTimesWidget';

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> init() async {
    // Register callback for widget taps
    HomeWidget.setAppGroupId(_appGroupId);
    HomeWidget.registerInteractivityCallback(widgetCallback);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE WIDGET
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديث widget مع المواقيت الحالية
  static Future<void> updateWidget({
    required PrayerTimes prayerTimes,
    required String locationName,
  }) async {
    // Get next prayer
    final now = DateTime.now();
    String nextPrayer = '';
    String nextTime = '';
    String remaining = '';

    final prayers = {
      'الفجر': prayerTimes.fajr,
      'الشروق': prayerTimes.sunrise,
      'الظهر': prayerTimes.dhuhr,
      'العصر': prayerTimes.asr,
      'المغرب': prayerTimes.maghrib,
      'العشاء': prayerTimes.isha,
    };

    for (final entry in prayers.entries) {
      if (entry.value.isAfter(now)) {
        nextPrayer = entry.key;
        nextTime = _formatTime(entry.value);
        remaining = _formatRemaining(entry.value.difference(now));
        break;
      }
    }

    // If all prayers passed, show tomorrow's Fajr
    if (nextPrayer.isEmpty) {
      nextPrayer = 'الفجر';
      nextTime = _formatTime(prayerTimes.fajr.add(const Duration(days: 1)));
      remaining = 'غدًا';
    }

    // Save data for widget
    await HomeWidget.saveWidgetData('next_prayer', nextPrayer);
    await HomeWidget.saveWidgetData('next_time', nextTime);
    await HomeWidget.saveWidgetData('remaining', remaining);
    await HomeWidget.saveWidgetData('location', locationName);
    
    // All times
    await HomeWidget.saveWidgetData('fajr', _formatTime(prayerTimes.fajr));
    await HomeWidget.saveWidgetData('sunrise', _formatTime(prayerTimes.sunrise));
    await HomeWidget.saveWidgetData('dhuhr', _formatTime(prayerTimes.dhuhr));
    await HomeWidget.saveWidgetData('asr', _formatTime(prayerTimes.asr));
    await HomeWidget.saveWidgetData('maghrib', _formatTime(prayerTimes.maghrib));
    await HomeWidget.saveWidgetData('isha', _formatTime(prayerTimes.isha));
    
    // Last update
    await HomeWidget.saveWidgetData('last_update', DateTime.now().toIso8601String());

    // Update widget
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iosWidgetName,
    );
  }

  /// تحديث تلقائي كل دقيقة
  static Future<void> scheduleUpdates() async {
    // Use WorkManager for background updates
    // This is handled by the native code
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'ص' : 'م';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  static String _formatRemaining(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} س ${duration.inMinutes % 60} د';
    }
    return '${duration.inMinutes} دقيقة';
  }
}

/// Callback عند الضغط على widget
@pragma('vm:entry-point')
Future<void> widgetCallback(Uri? uri) async {
  if (uri?.host == 'open_app') {
    // Open app - handled by native
  } else if (uri?.host == 'refresh') {
    // Refresh data
    // Will need to recalculate prayer times
  }
}
