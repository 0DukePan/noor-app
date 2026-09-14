import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/adhan_scheduler_service.dart';

/// AdhanSchedulerService (previously 1.4%): the native adhan channel is
/// mocked (calls recorded), geolocator is denied (Makkah fallback), Hive in
/// a temp dir. Plain zone-safe tests; `init()` once in setUpAll.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final calls = <String, List<Map<dynamic, dynamic>>>{};

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_adhan_test');
    Hive.init(tempDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('com.noor.app/adhan'),
        (call) async {
          calls.putIfAbsent(call.method, () => []).add(
            (call.arguments as Map?)?.cast<dynamic, dynamic>() ??
                <dynamic, dynamic>{},
          );
          switch (call.method) {
            case 'isExactAlarmAllowed':
              return true;
            case 'isBatteryOptimizationDisabled':
              return false;
            case 'getAdhanLog':
              return [
                {'prayerId': 'fajr_202611', 'played': true},
              ];
            case 'requestExactAlarmPermission':
            case 'requestBatteryOptimization':
              return true;
          }
          return null;
        },
      )
      ..setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (call) async {
          if (call.method == 'checkPermission') return 0;
          if (call.method == 'requestPermission') return 0;
          if (call.method == 'isLocationServiceEnabled') return false;
          return null;
        },
      );

    await AdhanSchedulerService.init();
    calls.clear();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('com.noor.app/adhan'),
        null,
      )
      ..setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        null,
      );
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('prayer times are chronological for a fixed Makkah date', () async {
    final times = await AdhanSchedulerService.calculatePrayerTimes(
      date: DateTime(2026, 3, 15),
      latitude: 21.4225,
      longitude: 39.8262,
    );
    expect(
      times.keys,
      containsAll(['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']),
    );
    final ordered = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']
        .map((k) => times[k]!);
    expect(
      ordered.toList(),
      ordered.toList()..sort(),
    );
  });

  test('manual adjustment shifts only the targeted prayer', () async {
    final before = await AdhanSchedulerService.calculatePrayerTimes(
      date: DateTime(2026, 3, 15),
      latitude: 21.4225,
      longitude: 39.8262,
    );
    await AdhanSchedulerService.setManualAdjustment('fajr', 10);
    final after = await AdhanSchedulerService.calculatePrayerTimes(
      date: DateTime(2026, 3, 15),
      latitude: 21.4225,
      longitude: 39.8262,
    );
    expect(after['fajr']!.difference(before['fajr']!), const Duration(minutes: 10));
    expect(after['dhuhr'], before['dhuhr']);
    await AdhanSchedulerService.setManualAdjustment('fajr', 0);
  });

  test('scheduleAllPrayers skips sunrise/past and sends Arabic names',
      () async {
    await AdhanSchedulerService.scheduleAllPrayers();
    final scheduled = calls['scheduleExactAdhan'] ?? [];
    expect(scheduled, isNotEmpty);
    final names =
        scheduled.map((a) => a['prayerName'] as String).toList();
    expect(names, isNot(contains('sunrise')));
    final arabic =
        scheduled.map((a) => a['prayerNameArabic'] as String).toList();
    expect(
      arabic,
      everyElement(isNotEmpty),
    );
    expect(
      arabic,
      containsAll(['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']),
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final args in scheduled) {
      expect(args['scheduledTimeMillis'] as int, greaterThan(now - 60000));
      expect(args['prayerId'] as String, matches(RegExp(r'^[a-z]+_\d+$')));
      expect(args['adhanSoundId'], isNotNull);
    }
  });

  test('stop/cancel/snooze/log delegate to the native channel', () async {
    await AdhanSchedulerService.stopAdhan();
    await AdhanSchedulerService.cancelAllAdhans();
    await AdhanSchedulerService.snoozeAdhan('fajr', 10);
    expect(
      calls.keys,
      containsAll(['stopAdhan', 'cancelAllAdhans', 'schedulePreReminder']),
    );

    final log = await AdhanSchedulerService.getAdhanLog();
    expect(log, hasLength(1));
    expect(log.first['prayerId'], 'fajr_202611');

    expect(await AdhanSchedulerService.isExactAlarmAllowed(), isTrue);
    expect(
      await AdhanSchedulerService.isBatteryOptimizationDisabled(),
      isFalse,
    );
  });

  test('adhan sound catalog holds 7 unique sounds', () {
    const sounds = AdhanSchedulerService.adhanSounds;
    expect(sounds, hasLength(7));
    final ids = sounds.map((s) => s.id).toList();
    expect(ids.toSet(), hasLength(7));
    for (final sound in sounds) {
      expect(sound.nameArabic, isNotEmpty);
      expect(sound.nameEnglish, isNotEmpty);
    }
  });

  test('isAdhanEnabled defaults true and persists toggles', () async {
    expect(AdhanSchedulerService.isAdhanEnabled('fajr'), isTrue);
    await AdhanSchedulerService.setAdhanEnabled('fajr', enabled: false);
    expect(AdhanSchedulerService.isAdhanEnabled('fajr'), isFalse);
    await AdhanSchedulerService.setAdhanEnabled('fajr', enabled: true);
    expect(AdhanSchedulerService.isAdhanEnabled('fajr'), isTrue);
  });
}
