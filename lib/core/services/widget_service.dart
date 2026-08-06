import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/services/prayer_calculation_service.dart';
import '../../core/services/offline_data_service.dart';
import '../../features/prayer/domain/entities/prayer_entities.dart';

/// خدمة الويدجت - Widget Service for iOS & Android Home Screen
class WidgetService {
  static const _appGroupId = 'group.com.noor.app';
  static const _iOSWidgetName = 'NoorWidget';
  static const _androidWidgetName = 'NoorWidgetProvider';

  /// Initialize widget service
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
    
    // Register background callback
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  /// Background callback for widget updates
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri == null) return;

    switch (uri.host) {
      case 'update_prayer':
        await updatePrayerWidget();
        break;
      case 'update_verse':
        await updateVerseWidget();
        break;
      case 'update_adhkar':
        await updateAdhkarWidget();
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRAYER TIMES WIDGET
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update prayer times widget
  static Future<void> updatePrayerWidget() async {
    try {
      final service = PrayerCalculationService();
      // Default to Makkah location
      const defaultLocation = Location(
        latitude: 21.4225,
        longitude: 39.8262,
        cityName: 'مكة المكرمة',
        countryName: 'السعودية',
      );
      final times = service.calculatePrayerTimes(
        date: DateTime.now(),
        location: defaultLocation,
      );

      // Find next prayer
      final nextPrayer = [
        times.fajr,
        times.dhuhr,
        times.asr,
        times.maghrib,
        times.isha,
      ].firstWhere((p) => p.isNext, orElse: () => times.fajr);

      // Format time
      final timeStr = '${nextPrayer.time.hour}:${nextPrayer.time.minute.toString().padLeft(2, '0')}';

      // Update widget data
      await HomeWidget.saveWidgetData<String>('prayer_name', nextPrayer.nameArabic);
      await HomeWidget.saveWidgetData<String>('prayer_time', timeStr);
      await HomeWidget.saveWidgetData<String>('prayer_icon', _getPrayerIcon(nextPrayer.name));

      // Update the widget
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
        qualifiedAndroidName: 'com.noor.app.$_androidWidgetName',
      );
    } catch (e) {
      // Widget update failed
    }
  }

  static String _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return '🌅';
      case 'dhuhr':
        return '☀️';
      case 'asr':
        return '🌤️';
      case 'maghrib':
        return '🌅';
      case 'isha':
        return '🌙';
      default:
        return '🕌';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VERSE OF THE DAY WIDGET
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update verse of the day widget
  static Future<void> updateVerseWidget() async {
    try {
      await OfflineDataService.init();

      // Get a verse based on day of year
      final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      final surahNumber = (dayOfYear % 114) + 1;
      final verseNumber = (dayOfYear % 7) + 1;

      final surah = await OfflineDataService.getSurah(surahNumber);
      if (surah != null) {
        final verses = surah['ayahs'] as List?;
        if (verses != null && verses.length >= verseNumber) {
          final verse = verses[verseNumber - 1];
          final verseText = verse['text'] as String? ?? '';

          // Truncate for widget
          final shortText = verseText.length > 100
              ? '${verseText.substring(0, 100)}...'
              : verseText;

          await HomeWidget.saveWidgetData<String>('verse_text', shortText);
          await HomeWidget.saveWidgetData<String>(
            'verse_reference',
            '${surah['name']} - آية $verseNumber',
          );

          await HomeWidget.updateWidget(
            iOSName: _iOSWidgetName,
            androidName: _androidWidgetName,
          );
        }
      }
    } catch (e) {
      // Widget update failed
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADHKAR COUNTER WIDGET
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update adhkar counter widget
  static Future<void> updateAdhkarWidget() async {
    try {
      // Get today's adhkar count from storage
      final todayCount = await _getTodayAdhkarCount();
      final targetCount = 100; // Daily target

      await HomeWidget.saveWidgetData<int>('adhkar_count', todayCount);
      await HomeWidget.saveWidgetData<int>('adhkar_target', targetCount);
      await HomeWidget.saveWidgetData<double>('adhkar_progress', todayCount / targetCount);

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      // Widget update failed
    }
  }

  /// Increment adhkar count
  static Future<void> incrementAdhkar() async {
    try {
      final currentCount = await _getTodayAdhkarCount();
      await HomeWidget.saveWidgetData<int>('adhkar_count', currentCount + 1);

      await updateAdhkarWidget();
    } catch (e) {
      // Increment failed
    }
  }

  static Future<int> _getTodayAdhkarCount() async {
    final count = await HomeWidget.getWidgetData<int>('adhkar_count');
    return count ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QIBLA COMPASS WIDGET
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update Qibla direction widget (static, updates less frequently)
  static Future<void> updateQiblaWidget(double direction) async {
    try {
      await HomeWidget.saveWidgetData<double>('qibla_direction', direction);

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      // Widget update failed
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHEDULE UPDATES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule periodic widget updates
  static Future<void> scheduleUpdates() async {
    // Update prayer widget every hour
    // (In production, this would use WorkManager or similar)
    await updatePrayerWidget();
    await updateVerseWidget();
    await updateAdhkarWidget();
  }

  /// Force update all widgets
  static Future<void> updateAllWidgets() async {
    await updatePrayerWidget();
    await updateVerseWidget();
    await updateAdhkarWidget();
  }
}
