import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

/// ✅ نظام الفحص الذاتي - Self Health Check System
/// 
/// What professional systems do:
/// - Daily automatic health check
/// - Verify all adhan are scheduled
/// - Check permissions
/// - Warn user about issues
class PrayerHealthCheck {
  static Box? _healthBox;
  static Timer? _dailyCheckTimer;
  
  // Health status stream
  static final _healthController = StreamController<HealthReport>.broadcast();
  static Stream<HealthReport> get healthStream => _healthController.stream;
  
  static HealthReport? _lastReport;
  static HealthReport? get lastReport => _lastReport;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> init() async {
    _healthBox = await Hive.openBox('health_check');
    
    // Schedule daily check at 3 AM
    _scheduleDailyCheck();
    
    // Check on init
    await runHealthCheck();
  }

  static void _scheduleDailyCheck() {
    final now = DateTime.now();
    var nextCheck = DateTime(now.year, now.month, now.day, 3, 0);
    if (nextCheck.isBefore(now)) {
      nextCheck = nextCheck.add(const Duration(days: 1));
    }
    
    final delay = nextCheck.difference(now);
    
    Timer(delay, () {
      runHealthCheck();
      // Schedule next daily check
      _dailyCheckTimer = Timer.periodic(const Duration(days: 1), (_) {
        runHealthCheck();
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH CHECK
  // ═══════════════════════════════════════════════════════════════════════════

  /// تشغيل فحص شامل
  static Future<HealthReport> runHealthCheck() async {
    debugPrint('Running health check...');
    
    final issues = <HealthIssue>[];
    final checks = <CheckResult>[];
    
    // 1. Check notification permission
    final notifCheck = await _checkNotificationPermission();
    checks.add(notifCheck);
    if (!notifCheck.passed) issues.add(notifCheck.issue!);
    
    // 2. Check location permission
    final locCheck = await _checkLocationPermission();
    checks.add(locCheck);
    if (!locCheck.passed) issues.add(locCheck.issue!);
    
    // 3. Check location service
    final locServiceCheck = await _checkLocationService();
    checks.add(locServiceCheck);
    if (!locServiceCheck.passed) issues.add(locServiceCheck.issue!);
    
    // 4. Check exact alarm permission (Android 12+)
    final alarmCheck = await _checkExactAlarmPermission();
    checks.add(alarmCheck);
    if (!alarmCheck.passed) issues.add(alarmCheck.issue!);
    
    // 5. Check battery optimization
    final batteryCheck = await _checkBatteryOptimization();
    checks.add(batteryCheck);
    if (!batteryCheck.passed) issues.add(batteryCheck.issue!);
    
    // 6. Check scheduled alarms
    final alarmsCheck = await _checkScheduledAlarms();
    checks.add(alarmsCheck);
    if (!alarmsCheck.passed) issues.add(alarmsCheck.issue!);
    
    // 7. Check last location update
    final lastLocCheck = _checkLastLocationUpdate();
    checks.add(lastLocCheck);
    if (!lastLocCheck.passed) issues.add(lastLocCheck.issue!);
    
    // Create report
    final report = HealthReport(
      timestamp: DateTime.now(),
      checks: checks,
      issues: issues,
      overallStatus: issues.isEmpty 
          ? HealthStatus.healthy 
          : issues.any((i) => i.severity == IssueSeverity.critical)
              ? HealthStatus.critical
              : HealthStatus.warning,
    );
    
    // Cache report
    _lastReport = report;
    await _healthBox?.put('last_report', report.toMap());
    
    // Broadcast
    _healthController.add(report);
    
    debugPrint('Health check complete: ${report.overallStatus.name}');
    
    return report;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INDIVIDUAL CHECKS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<CheckResult> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    
    return CheckResult(
      name: 'إذن الإشعارات',
      passed: status.isGranted,
      issue: status.isGranted ? null : HealthIssue(
        code: 'NOTIF_PERM',
        title: 'إذن الإشعارات مطلوب',
        description: 'لن يعمل الأذان بدون إذن الإشعارات',
        severity: IssueSeverity.critical,
        action: 'اذهب للإعدادات وفعّل الإشعارات',
        canAutoFix: true,
      ),
    );
  }

  static Future<CheckResult> _checkLocationPermission() async {
    final status = await Permission.location.status;
    
    return CheckResult(
      name: 'إذن الموقع',
      passed: status.isGranted,
      issue: status.isGranted ? null : HealthIssue(
        code: 'LOC_PERM',
        title: 'إذن الموقع مطلوب',
        description: 'لن تكون المواقيت دقيقة بدون إذن الموقع',
        severity: IssueSeverity.warning,
        action: 'اذهب للإعدادات وفعّل الموقع',
        canAutoFix: true,
      ),
    );
  }

  static Future<CheckResult> _checkLocationService() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    
    return CheckResult(
      name: 'خدمة الموقع',
      passed: enabled,
      issue: enabled ? null : HealthIssue(
        code: 'LOC_SERVICE',
        title: 'خدمة الموقع معطلة',
        description: 'فعّل GPS للحصول على مواقيت دقيقة',
        severity: IssueSeverity.warning,
        action: 'افتح إعدادات الموقع',
        canAutoFix: false,
      ),
    );
  }

  static Future<CheckResult> _checkExactAlarmPermission() async {
    // Android 12+ requires SCHEDULE_EXACT_ALARM
    final status = await Permission.scheduleExactAlarm.status;
    
    return CheckResult(
      name: 'إذن المنبه الدقيق',
      passed: status.isGranted || status.isLimited,
      issue: (status.isGranted || status.isLimited) ? null : HealthIssue(
        code: 'ALARM_PERM',
        title: 'إذن المنبه الدقيق مطلوب',
        description: 'لضمان دقة توقيت الأذان',
        severity: IssueSeverity.critical,
        action: 'اذهب للإعدادات وفعّل المنبهات',
        canAutoFix: true,
      ),
    );
  }

  static Future<CheckResult> _checkBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    
    return CheckResult(
      name: 'استثناء توفير البطارية',
      passed: status.isGranted,
      issue: status.isGranted ? null : HealthIssue(
        code: 'BATTERY_OPT',
        title: 'التطبيق قد يُوقف لتوفير البطارية',
        description: 'استثنِ التطبيق من تحسين البطارية لضمان الأذان في الوقت',
        severity: IssueSeverity.warning,
        action: 'اذهب للإعدادات واستثنِ التطبيق',
        canAutoFix: true,
      ),
    );
  }

  static Future<CheckResult> _checkScheduledAlarms() async {
    // Check if today's prayers are scheduled
    final today = DateTime.now();
    final scheduled = _healthBox?.get('scheduled_prayers_${today.day}');
    
    return CheckResult(
      name: 'جدولة الصلوات',
      passed: scheduled == true,
      issue: scheduled == true ? null : HealthIssue(
        code: 'SCHEDULE',
        title: 'صلوات اليوم غير مجدولة',
        description: 'افتح التطبيق لتحديث الجدولة',
        severity: IssueSeverity.critical,
        action: 'أعد فتح التطبيق',
        canAutoFix: false,
      ),
    );
  }

  static CheckResult _checkLastLocationUpdate() {
    final lastUpdate = _healthBox?.get('last_location_update');
    DateTime? lastUpdateTime;
    
    if (lastUpdate != null) {
      lastUpdateTime = DateTime.tryParse(lastUpdate);
    }
    
    final isRecent = lastUpdateTime != null && 
        DateTime.now().difference(lastUpdateTime).inHours < 24;
    
    return CheckResult(
      name: 'تحديث الموقع',
      passed: isRecent,
      issue: isRecent ? null : HealthIssue(
        code: 'OLD_LOC',
        title: 'الموقع قديم',
        description: 'لم يُحدَّث الموقع منذ أكثر من 24 ساعة',
        severity: IssueSeverity.info,
        action: 'أعد فتح التطبيق أو فعّل GPS',
        canAutoFix: false,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIX ISSUES
  // ═══════════════════════════════════════════════════════════════════════════

  /// محاولة إصلاح مشكلة
  static Future<bool> attemptFix(HealthIssue issue) async {
    switch (issue.code) {
      case 'NOTIF_PERM':
        final result = await Permission.notification.request();
        return result.isGranted;
        
      case 'LOC_PERM':
        final result = await Permission.location.request();
        return result.isGranted;
        
      case 'ALARM_PERM':
        final result = await Permission.scheduleExactAlarm.request();
        return result.isGranted;
        
      case 'BATTERY_OPT':
        final result = await Permission.ignoreBatteryOptimizations.request();
        return result.isGranted;
        
      default:
        return false;
    }
  }

  /// إصلاح جميع المشاكل القابلة للإصلاح
  static Future<int> attemptFixAll() async {
    if (_lastReport == null) return 0;
    
    int fixed = 0;
    for (final issue in _lastReport!.issues) {
      if (issue.canAutoFix) {
        final success = await attemptFix(issue);
        if (success) fixed++;
      }
    }
    
    // Refresh report
    await runHealthCheck();
    
    return fixed;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// تسجيل جدولة ناجحة
  static Future<void> recordSuccessfulSchedule() async {
    final today = DateTime.now();
    await _healthBox?.put('scheduled_prayers_${today.day}', true);
  }

  /// تسجيل تحديث الموقع
  static Future<void> recordLocationUpdate() async {
    await _healthBox?.put('last_location_update', DateTime.now().toIso8601String());
  }

  /// تنظيف
  static void dispose() {
    _dailyCheckTimer?.cancel();
    _healthController.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// حالة الصحة
enum HealthStatus {
  healthy,   // كل شيء سليم
  warning,   // بعض التحذيرات
  critical,  // مشاكل حرجة
}

extension HealthStatusInfo on HealthStatus {
  String get arabicName {
    switch (this) {
      case HealthStatus.healthy: return 'سليم';
      case HealthStatus.warning: return 'تحذيرات';
      case HealthStatus.critical: return 'مشاكل حرجة';
    }
  }

  String get icon {
    switch (this) {
      case HealthStatus.healthy: return '✅';
      case HealthStatus.warning: return '⚠️';
      case HealthStatus.critical: return '🔴';
    }
  }
}

/// خطورة المشكلة
enum IssueSeverity {
  info,      // معلومة
  warning,   // تحذير
  critical,  // حرج
}

/// نتيجة فحص
class CheckResult {
  final String name;
  final bool passed;
  final HealthIssue? issue;

  const CheckResult({
    required this.name,
    required this.passed,
    this.issue,
  });
}

/// مشكلة صحية
class HealthIssue {
  final String code;
  final String title;
  final String description;
  final IssueSeverity severity;
  final String action;
  final bool canAutoFix;

  const HealthIssue({
    required this.code,
    required this.title,
    required this.description,
    required this.severity,
    required this.action,
    required this.canAutoFix,
  });
}

/// تقرير الصحة
class HealthReport {
  final DateTime timestamp;
  final List<CheckResult> checks;
  final List<HealthIssue> issues;
  final HealthStatus overallStatus;

  const HealthReport({
    required this.timestamp,
    required this.checks,
    required this.issues,
    required this.overallStatus,
  });

  int get passedChecks => checks.where((c) => c.passed).length;
  int get totalChecks => checks.length;
  bool get isHealthy => overallStatus == HealthStatus.healthy;

  Map<String, dynamic> toMap() => {
    'timestamp': timestamp.toIso8601String(),
    'overallStatus': overallStatus.index,
    'passedChecks': passedChecks,
    'totalChecks': totalChecks,
    'issueCount': issues.length,
  };
}
