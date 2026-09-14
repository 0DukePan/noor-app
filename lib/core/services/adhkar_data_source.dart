import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/adhkar_models.dart';
import 'hive_box_registry.dart';

/// 📿 AdhkarDataSource - مصدر بيانات الأذكار
class AdhkarDataSource {
  static const String _progressBoxName = HiveBoxes.adhkarProgress;
  static const String _statsBoxName = HiveBoxes.adhkarStats;
  static const String _settingsBoxName = HiveBoxes.adhkarSettings;

  static Box<dynamic>? _progressBox;
  static Box<dynamic>? _statsBox;
  static Box<dynamic>? _settingsBox;

  // Cache للأذكار المحملة
  static final Map<AdhkarType, AdhkarCollection> _cache = {};

  static AdhkarLibrary? _libraryCache;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIBRARY (مكتبة الأذكار الموسعة)
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحميل مكتبة الأذكار الموسعة (١٠٠+ ذكر بمصادرها).
  static Future<AdhkarLibrary?> getLibrary() async {
    if (_libraryCache != null) return _libraryCache;
    try {
      final jsonString =
          await rootBundle.loadString('assets/adhkar/library.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return _libraryCache = AdhkarLibrary.fromJson(json);
    } on Exception {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> init() async {
    _progressBox = await Hive.openBox<dynamic>(_progressBoxName);
    _statsBox = await Hive.openBox<dynamic>(_statsBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD ADHKAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحميل مجموعة أذكار
  static Future<AdhkarCollection?> getCollection(AdhkarType type) async {
    // من الكاش
    if (_cache.containsKey(type)) {
      return _cache[type];
    }

    try {
      final jsonString = await rootBundle.loadString(type.assetPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final collection = AdhkarCollection.fromJson(json, type);
      _cache[type] = collection;
      return collection;
    } on Exception {
      return null;
    }
  }

  /// الحصول على ذكر معين
  static Future<Zekr?> getZekr(AdhkarType type, int index) async {
    final collection = await getCollection(type);
    if (collection == null || index >= collection.count) return null;
    return collection.adhkar[index];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROGRESS TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// الحصول على التقدم الحالي
  static AdhkarProgress getProgress(AdhkarType type) {
    final today = _todayKey();
    final key = '${type.name}:$today';
    final json = _progressBox?.get(key);

    if (json != null) {
      return AdhkarProgress.fromJson(Map<String, dynamic>.from(json as Map));
    }

    return AdhkarProgress(type: type);
  }

  /// حفظ التقدم
  static Future<void> saveProgress(AdhkarProgress progress) async {
    final today = _todayKey();
    final key = '${progress.type.name}:$today';
    await _progressBox?.put(key, progress.toJson());
  }

  /// زيادة العداد
  static Future<AdhkarProgress> incrementCount(AdhkarType type) async {
    final progress = getProgress(type).increment();
    await saveProgress(progress);
    return progress;
  }

  /// الانتقال للذكر التالي
  static Future<AdhkarProgress> nextZekr(AdhkarType type) async {
    final progress = getProgress(type).nextZekr();
    await saveProgress(progress);
    return progress;
  }

  /// إتمام الأذكار
  static Future<void> completeAdhkar(AdhkarType type) async {
    final progress = getProgress(type).complete();
    await saveProgress(progress);
    await _updateDailyStats(type, completed: true);
  }

  /// إعادة تعيين التقدم
  static Future<void> resetProgress(AdhkarType type) async {
    final progress = AdhkarProgress(type: type);
    await saveProgress(progress);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAILY STATS
  // ═══════════════════════════════════════════════════════════════════════════

  /// إحصائيات اليوم
  static DailyAdhkarStats getTodayStats() {
    final today = _todayKey();
    final json = _statsBox?.get(today);

    if (json != null) {
      return DailyAdhkarStats.fromJson(Map<String, dynamic>.from(json as Map));
    }

    return DailyAdhkarStats(date: DateTime.now());
  }

  /// تحديث الإحصائيات
  static Future<void> _updateDailyStats(AdhkarType type,
      {bool completed = false,}) async {
    final today = _todayKey();
    var stats = getTodayStats();

    if (type == AdhkarType.morning && completed) {
      stats = DailyAdhkarStats(
        date: stats.date,
        morningCompleted: true,
        eveningCompleted: stats.eveningCompleted,
        afterPrayerCount: stats.afterPrayerCount,
        totalAdhkarCount: stats.totalAdhkarCount + 1,
      );
    } else if (type == AdhkarType.evening && completed) {
      stats = DailyAdhkarStats(
        date: stats.date,
        morningCompleted: stats.morningCompleted,
        eveningCompleted: true,
        afterPrayerCount: stats.afterPrayerCount,
        totalAdhkarCount: stats.totalAdhkarCount + 1,
      );
    } else if (type == AdhkarType.afterPrayer) {
      stats = DailyAdhkarStats(
        date: stats.date,
        morningCompleted: stats.morningCompleted,
        eveningCompleted: stats.eveningCompleted,
        afterPrayerCount: stats.afterPrayerCount + 1,
        totalAdhkarCount: stats.totalAdhkarCount + 1,
      );
    }

    await _statsBox?.put(today, stats.toJson());
  }

  /// سلسلة الأيام المتتالية
  static int getStreak() {
    var streak = 0;
    var date = DateTime.now();

    while (true) {
      final key = _dateKey(date);
      final json = _statsBox?.get(key);

      if (json == null) break;

      final stats =
          DailyAdhkarStats.fromJson(Map<String, dynamic>.from(json as Map));
      if (!stats.isComplete) break;

      streak++;
      date = date.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  static AdhkarDisplaySettings getSettings() {
    final json = _settingsBox?.get('display');
    if (json != null) {
      return AdhkarDisplaySettings.fromJson(
          Map<String, dynamic>.from(json as Map),);
    }
    return const AdhkarDisplaySettings();
  }

  static Future<void> saveSettings(AdhkarDisplaySettings settings) async {
    await _settingsBox?.put('display', settings.toJson());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  static String _todayKey() => _dateKey(DateTime.now());

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// الأنواع المتاحة
  static List<AdhkarType> get availableTypes => [
        AdhkarType.morning,
        AdhkarType.evening,
        AdhkarType.afterPrayer,
      ];
}
