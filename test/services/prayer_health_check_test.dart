import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/prayer_health_check.dart';

/// PrayerHealthCheck (previously 0.8%): permission + geolocator channels are
/// mocked, Hive runs in a temp dir. Plain zone-safe tests — `init()` is
/// called once in setUpAll (its daily Timer is a real-zone timer and the
/// broadcast controller must stay open for the whole file).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  // permission.value → PermissionStatus index (denied 0, granted 1).
  var permStatus = <int, int>{};
  var locationServiceOn = true;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_health_test');
    Hive.init(tempDir.path);
    permStatus = {3: 1, 16: 1, 17: 1, 34: 1};

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async {
          if (call.method == 'checkPermissionStatus') {
            return permStatus[call.arguments as int] ?? 0;
          }
          if (call.method == 'requestPermissions') {
            final args = call.arguments as List<dynamic>;
            return {
              for (final key in args) (key as int): permStatus[key] ?? 0,
            };
          }
          return null;
        },
      )
      ..setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (call) async {
          if (call.method == 'isLocationServiceEnabled') {
            return locationServiceOn;
          }
          return null;
        },
      );

    await PrayerHealthCheck.init();
  });

  setUp(() {
    // Healthy baseline; individual tests degrade from here.
    permStatus = {3: 1, 16: 1, 17: 1, 34: 1};
    locationServiceOn = true;
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
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

  Future<void> seedScheduleAndLocation() async {
    await PrayerHealthCheck.recordSuccessfulSchedule();
    await PrayerHealthCheck.recordLocationUpdate();
  }

  test('healthy when everything is granted, scheduled and fresh', () async {
    await seedScheduleAndLocation();
    final report = await PrayerHealthCheck.runHealthCheck();
    expect(report.totalChecks, 7);
    expect(report.issues, isEmpty);
    expect(report.overallStatus, HealthStatus.healthy);
    expect(report.isHealthy, isTrue);
    expect(report.passedChecks, 7);
    expect(PrayerHealthCheck.lastReport, isNotNull);
  });

  test('denied notification permission is critical', () async {
    await seedScheduleAndLocation();
    permStatus[17] = 0;
    final report = await PrayerHealthCheck.runHealthCheck();
    expect(report.overallStatus, HealthStatus.critical);
    expect(
      report.issues.map((i) => i.code),
      contains('NOTIF_PERM'),
    );
    expect(report.passedChecks, lessThan(report.totalChecks));
  });

  test('disabled location service alone is a warning', () async {
    await seedScheduleAndLocation();
    locationServiceOn = false;
    final report = await PrayerHealthCheck.runHealthCheck();
    expect(report.overallStatus, HealthStatus.warning);
    expect(
      report.issues.map((i) => i.code),
      contains('LOC_SERVICE'),
    );
  });

  test('missing schedule + stale location surface, then records clear them',
      () async {
    final box = Hive.box<dynamic>('health_check');
    final today = DateTime.now();
    await box.delete('scheduled_prayers_${today.day}');
    await box.put(
      'last_location_update',
      today.subtract(const Duration(days: 2)).toIso8601String(),
    );

    var report = await PrayerHealthCheck.runHealthCheck();
    expect(
      report.issues.map((i) => i.code),
      containsAll(['SCHEDULE', 'OLD_LOC']),
    );

    await PrayerHealthCheck.recordSuccessfulSchedule();
    await PrayerHealthCheck.recordLocationUpdate();
    report = await PrayerHealthCheck.runHealthCheck();
    expect(
      report.issues.map((i) => i.code),
      isNot(contains('SCHEDULE')),
    );
    expect(report.issues.map((i) => i.code), isNot(contains('OLD_LOC')));
  });

  test('attemptFix maps codes to permission requests', () async {
    const unknown = HealthIssue(
      code: 'NOPE',
      title: 't',
      description: 'd',
      severity: IssueSeverity.info,
      action: 'a',
      canAutoFix: false,
    );
    expect(await PrayerHealthCheck.attemptFix(unknown), isFalse);

    const notif = HealthIssue(
      code: 'NOTIF_PERM',
      title: 't',
      description: 'd',
      severity: IssueSeverity.critical,
      action: 'a',
      canAutoFix: true,
    );
    permStatus[17] = 1;
    expect(await PrayerHealthCheck.attemptFix(notif), isTrue);
    permStatus[17] = 0;
    expect(await PrayerHealthCheck.attemptFix(notif), isFalse);
  });

  test('status display info and report serialization', () {
    expect(HealthStatus.healthy.arabicName, 'سليم');
    expect(HealthStatus.warning.arabicName, 'تحذيرات');
    expect(HealthStatus.critical.arabicName, 'مشاكل حرجة');
    expect(HealthStatus.healthy.icon, '✅');
    expect(HealthStatus.warning.icon, '⚠️');
    expect(HealthStatus.critical.icon, '🔴');

    final report = HealthReport(
      timestamp: DateTime.utc(2026),
      checks: const [
        CheckResult(name: 'a', passed: true),
        CheckResult(
          name: 'b',
          passed: false,
          issue: HealthIssue(
            code: 'X',
            title: 't',
            description: 'd',
            severity: IssueSeverity.warning,
            action: 'a',
            canAutoFix: false,
          ),
        ),
      ],
      issues: const [
        HealthIssue(
          code: 'X',
          title: 't',
          description: 'd',
          severity: IssueSeverity.warning,
          action: 'a',
          canAutoFix: false,
        ),
      ],
      overallStatus: HealthStatus.warning,
    );
    expect(report.passedChecks, 1);
    expect(report.totalChecks, 2);
    expect(report.isHealthy, isFalse);
    final map = report.toMap();
    expect(map['overallStatus'], HealthStatus.warning.index);
    expect(map['passedChecks'], 1);
    expect(map['totalChecks'], 2);
    expect(map['issueCount'], 1);
    expect(map['timestamp'], '2026-01-01T00:00:00.000Z');
  });
}
