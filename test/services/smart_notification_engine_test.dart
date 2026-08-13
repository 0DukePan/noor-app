import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/smart_notification_engine.dart';

/// Tests the notification settings persistence and defaults. The plugin
/// initialization is unavailable in unit tests, so init() is expected to
/// throw AFTER the Hive boxes are opened.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_notif_test');
    Hive.init(tempDir.path);
    try {
      await SmartNotificationEngine.init();
    } on Object {
      // Plugin init requires platform channels — boxes are open already.
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('defaults are sensible and safe', () {
    final settings = SmartNotificationEngine.getSettings();
    expect(settings.adhkarMorningEnabled, isTrue);
    expect(settings.adhkarEveningEnabled, isTrue);
    expect(settings.prayerNotificationsEnabled, isTrue);
    expect(settings.prayerNotificationMinutesBefore, 10);
    expect(settings.khatmahReminderEnabled, isFalse);
    expect(settings.quietHoursEnabled, isFalse);
  });

  test('settings round-trip through Hive', () async {
    const custom = NotificationSettings(
      adhkarMorningEnabled: false,
      prayerNotificationsEnabled: false,
      prayerNotificationMinutesBefore: 20,
      khatmahReminderEnabled: true,
      khatmahReminderHour: 21,
      khatmahReminderMinute: 30,
      quietHoursEnabled: true,
      quietHoursStart: 22,
      quietHoursEnd: 5,
    );
    await SmartNotificationEngine.saveSettings(custom);

    final loaded = SmartNotificationEngine.getSettings();
    expect(loaded.adhkarMorningEnabled, isFalse);
    expect(loaded.adhkarEveningEnabled, isTrue);
    expect(loaded.prayerNotificationsEnabled, isFalse);
    expect(loaded.prayerNotificationMinutesBefore, 20);
    expect(loaded.khatmahReminderEnabled, isTrue);
    expect(loaded.khatmahReminderHour, 21);
    expect(loaded.khatmahReminderMinute, 30);
    expect(loaded.quietHoursEnabled, isTrue);
    expect(loaded.quietHoursStart, 22);
    expect(loaded.quietHoursEnd, 5);
  });

  test('quiet hours are preserved across save/load', () async {
    await SmartNotificationEngine.saveSettings(
      const NotificationSettings(
        quietHoursEnabled: true,
        quietHoursEnd: 4,
      ),
    );
    final loaded = SmartNotificationEngine.getSettings();
    expect(loaded.quietHoursEnabled, isTrue);
    expect(loaded.quietHoursStart, 23);
    expect(loaded.quietHoursEnd, 4);
  });
}
