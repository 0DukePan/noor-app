import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_day_state_test');
    Hive.init(tempDir.path);
    await DayStateMachine.init();
  });

  tearDown(() async {
    await DayStateMachine.dispose();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('starts empty', () {
    expect(DayStateMachine.todayPrayersCompleted, 0);
    expect(DayStateMachine.isDayComplete, isFalse);
    expect(DayStateMachine.streak, 0);
  });

  test('marking all five prayers completes the day and starts a streak', () async {
    await DayStateMachine.markPrayerCompleted(PrayerType.fajr);
    await DayStateMachine.markPrayerCompleted(PrayerType.dhuhr);
    await DayStateMachine.markPrayerCompleted(PrayerType.asr);
    await DayStateMachine.markPrayerCompleted(PrayerType.maghrib);
    await DayStateMachine.markPrayerCompleted(PrayerType.isha);

    expect(DayStateMachine.todayPrayersCompleted, 5);
    expect(DayStateMachine.isDayComplete, isTrue);
    expect(DayStateMachine.streak, 1);

    // Re-marking must not double-count the streak.
    await DayStateMachine.markPrayerCompleted(PrayerType.isha);
    expect(DayStateMachine.streak, 1);
  });

  test('unmarking drops below complete; sunrise is never counted', () async {
    await DayStateMachine.markPrayerCompleted(PrayerType.fajr);
    await DayStateMachine.markPrayerCompleted(PrayerType.dhuhr);
    await DayStateMachine.markPrayerCompleted(PrayerType.asr);
    await DayStateMachine.markPrayerCompleted(PrayerType.maghrib);
    await DayStateMachine.markPrayerCompleted(PrayerType.isha);

    await DayStateMachine.unmarkPrayerCompleted(PrayerType.isha);
    expect(DayStateMachine.isDayComplete, isFalse);
    expect(DayStateMachine.todayPrayersCompleted, 4);

    await DayStateMachine.markPrayerCompleted(PrayerType.sunrise);
    expect(DayStateMachine.todayPrayersCompleted, 4);
  });
}
