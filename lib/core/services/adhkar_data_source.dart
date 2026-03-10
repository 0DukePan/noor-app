import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/adhkar_models.dart';

/// 📿 AdhkarDataSource - مصدر بيانات الأذكار
class AdhkarDataSource {
  static const String _progressBoxName = 'adhkar_progress';
  static const String _statsBoxName = 'adhkar_stats';
  static const String _settingsBoxName = 'adhkar_settings';

  static Box? _progressBox;
  static Box? _statsBox;
  static Box? _settingsBox;

  // Cache للأذكار المحملة
  static final Map<AdhkarType, AdhkarCollection> _cache = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> init() async {
    _progressBox = await Hive.openBox(_progressBoxName);
    _statsBox = await Hive.openBox(_statsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
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
    } catch (e) {
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
      return AdhkarProgress.fromJson(Map<String, dynamic>.from(json));
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
      return DailyAdhkarStats.fromJson(Map<String, dynamic>.from(json));
    }
    
    return DailyAdhkarStats(date: DateTime.now());
  }

  /// تحديث الإحصائيات
  static Future<void> _updateDailyStats(AdhkarType type, {bool completed = false}) async {
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
    int streak = 0;
    var date = DateTime.now();
    
    while (true) {
      final key = _dateKey(date);
      final json = _statsBox?.get(key);
      
      if (json == null) break;
      
      final stats = DailyAdhkarStats.fromJson(Map<String, dynamic>.from(json));
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
      return AdhkarDisplaySettings.fromJson(Map<String, dynamic>.from(json));
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
