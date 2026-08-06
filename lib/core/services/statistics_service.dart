import 'package:hive_flutter/hive_flutter.dart';

/// 📊 خدمة الإحصائيات الاحترافية - Professional Statistics Service
/// 
/// Features:
/// - Reading progress tracking
/// - Adhkar completion history
/// - Streaks (daily consistency)
/// - Time-based analytics
class StatisticsService {
  static Box? _statsBox;
  static Box? _historyBox;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> init() async {
    _statsBox = await Hive.openBox('app_statistics');
    _historyBox = await Hive.openBox('activity_history');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QURAN READING STATS
  // ═══════════════════════════════════════════════════════════════════════════

  /// تسجيل قراءة آية
  static Future<void> recordVerseRead(int surah, int ayah) async {
    final today = _getTodayKey();
    
    // Update today's count
    final todayVerses = _statsBox?.get('verses_$today', defaultValue: 0) ?? 0;
    await _statsBox?.put('verses_$today', todayVerses + 1);
    
    // Update total count
    final totalVerses = _statsBox?.get('total_verses', defaultValue: 0) ?? 0;
    await _statsBox?.put('total_verses', totalVerses + 1);
    
    // Save last read position
    await _statsBox?.put('last_read', {
      'surah': surah,
      'ayah': ayah,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// تسجيل وقت قراءة
  static Future<void> recordReadingTime(Duration duration) async {
    final today = _getTodayKey();
    
    // Update today's reading time
    final todaySeconds = _statsBox?.get('reading_time_$today', defaultValue: 0) ?? 0;
    await _statsBox?.put('reading_time_$today', todaySeconds + duration.inSeconds);
    
    // Update total reading time
    final totalSeconds = _statsBox?.get('total_reading_time', defaultValue: 0) ?? 0;
    await _statsBox?.put('total_reading_time', totalSeconds + duration.inSeconds);
  }

  /// آخر موضع قراءة
  static Map<String, dynamic>? getLastReadPosition() {
    final data = _statsBox?.get('last_read');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// إحصائيات القراءة اليوم
  static ReadingStats getTodayReadingStats() {
    final today = _getTodayKey();
    return ReadingStats(
      versesRead: _statsBox?.get('verses_$today', defaultValue: 0) ?? 0,
      readingTimeSeconds: _statsBox?.get('reading_time_$today', defaultValue: 0) ?? 0,
    );
  }

  /// إحصائيات القراءة الكلية
  static ReadingStats getTotalReadingStats() {
    return ReadingStats(
      versesRead: _statsBox?.get('total_verses', defaultValue: 0) ?? 0,
      readingTimeSeconds: _statsBox?.get('total_reading_time', defaultValue: 0) ?? 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADHKAR STATS
  // ═══════════════════════════════════════════════════════════════════════════

  /// تسجيل إكمال الأذكار
  static Future<void> recordAdhkarComplete(String type) async {
    final today = _getTodayKey();
    final key = 'adhkar_${type}_$today';
    
    await _statsBox?.put(key, true);
    
    // Update total
    final totalKey = 'total_adhkar_$type';
    final total = _statsBox?.get(totalKey, defaultValue: 0) ?? 0;
    await _statsBox?.put(totalKey, total + 1);
    
    // Update streak
    await _updateAdhkarStreak(type);
  }

  /// حالة الأذكار اليوم
  static AdhkarDayStatus getTodayAdhkarStatus() {
    final today = _getTodayKey();
    return AdhkarDayStatus(
      morningComplete: _statsBox?.get('adhkar_morning_$today', defaultValue: false) ?? false,
      eveningComplete: _statsBox?.get('adhkar_evening_$today', defaultValue: false) ?? false,
      afterPrayerCount: _statsBox?.get('adhkar_after_prayer_$today', defaultValue: 0) ?? 0,
    );
  }

  /// سلسلة الأذكار
  static int getAdhkarStreak() {
    return _statsBox?.get('adhkar_streak', defaultValue: 0) ?? 0;
  }

  static Future<void> _updateAdhkarStreak(String type) async {
    final today = _getTodayKey();
    final yesterday = _getDateKey(DateTime.now().subtract(const Duration(days: 1)));
    
    // Check if both morning and evening are complete today
    final morningComplete = _statsBox?.get('adhkar_morning_$today', defaultValue: false) ?? false;
    final eveningComplete = _statsBox?.get('adhkar_evening_$today', defaultValue: false) ?? false;
    
    if (morningComplete && eveningComplete) {
      // Check yesterday
      final yesterdayMorning = _statsBox?.get('adhkar_morning_$yesterday', defaultValue: false) ?? false;
      final yesterdayEvening = _statsBox?.get('adhkar_evening_$yesterday', defaultValue: false) ?? false;
      
      if (yesterdayMorning && yesterdayEvening) {
        // Continue streak
        final streak = _statsBox?.get('adhkar_streak', defaultValue: 0) ?? 0;
        await _statsBox?.put('adhkar_streak', streak + 1);
      } else {
        // Reset streak
        await _statsBox?.put('adhkar_streak', 1);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTENING STATS
  // ═══════════════════════════════════════════════════════════════════════════

  /// تسجيل استماع
  static Future<void> recordListening({
    required int surah,
    required int ayah,
    required Duration duration,
    required String reciter,
  }) async {
    final today = _getTodayKey();
    
    // Update listening time
    final todaySeconds = _statsBox?.get('listening_time_$today', defaultValue: 0) ?? 0;
    await _statsBox?.put('listening_time_$today', todaySeconds + duration.inSeconds);
    
    // Update total
    final totalSeconds = _statsBox?.get('total_listening_time', defaultValue: 0) ?? 0;
    await _statsBox?.put('total_listening_time', totalSeconds + duration.inSeconds);
    
    // Update verses listened
    final todayVerses = _statsBox?.get('verses_listened_$today', defaultValue: 0) ?? 0;
    await _statsBox?.put('verses_listened_$today', todayVerses + 1);
  }

  /// إحصائيات الاستماع
  static ListeningStats getListeningStats() {
    final today = _getTodayKey();
    return ListeningStats(
      todayTimeSeconds: _statsBox?.get('listening_time_$today', defaultValue: 0) ?? 0,
      totalTimeSeconds: _statsBox?.get('total_listening_time', defaultValue: 0) ?? 0,
      todayVerses: _statsBox?.get('verses_listened_$today', defaultValue: 0) ?? 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KHATMAH (COMPLETION) TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديث تقدم الختمة
  static Future<void> updateKhatmahProgress({
    required int surah,
    required int ayah,
  }) async {
    await _statsBox?.put('khatmah_progress', {
      'surah': surah,
      'ayah': ayah,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Calculate percentage
    final percentage = _calculateKhatmahPercentage(surah, ayah);
    await _statsBox?.put('khatmah_percentage', percentage);
  }

  /// تقدم الختمة
  static KhatmahProgress getKhatmahProgress() {
    final data = _statsBox?.get('khatmah_progress');
    if (data == null) {
      return const KhatmahProgress(surah: 1, ayah: 1, percentage: 0);
    }
    
    return KhatmahProgress(
      surah: data['surah'] ?? 1,
      ayah: data['ayah'] ?? 1,
      percentage: _statsBox?.get('khatmah_percentage', defaultValue: 0.0) ?? 0.0,
    );
  }

  /// بدء ختمة جديدة
  static Future<void> startNewKhatmah() async {
    final completedCount = _statsBox?.get('completed_khatmah_count', defaultValue: 0) ?? 0;
    await _statsBox?.put('completed_khatmah_count', completedCount + 1);
    
    await _statsBox?.put('khatmah_progress', {
      'surah': 1,
      'ayah': 1,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _statsBox?.put('khatmah_percentage', 0.0);
  }

  /// عدد الختمات المكتملة
  static int getCompletedKhatmahCount() {
    return _statsBox?.get('completed_khatmah_count', defaultValue: 0) ?? 0;
  }

  static double _calculateKhatmahPercentage(int surah, int ayah) {
    // Total verses in Quran: 6236
    const verseCounts = [
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
      111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30,
      73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29,
      18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18,
      12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
      29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19,
      5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
    ];
    
    int completedVerses = 0;
    for (int i = 0; i < surah - 1; i++) {
      completedVerses += verseCounts[i];
    }
    completedVerses += ayah;
    
    return (completedVerses / 6236) * 100;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEEKLY SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════

  /// ملخص الأسبوع
  static WeeklySummary getWeeklySummary() {
    final now = DateTime.now();
    int totalVerses = 0;
    int totalReadingSeconds = 0;
    int totalListeningSeconds = 0;
    int adhkarDays = 0;
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _getDateKey(date);
      
      totalVerses += (_statsBox?.get('verses_$key', defaultValue: 0) ?? 0) as int;
      totalReadingSeconds += (_statsBox?.get('reading_time_$key', defaultValue: 0) ?? 0) as int;
      totalListeningSeconds += (_statsBox?.get('listening_time_$key', defaultValue: 0) ?? 0) as int;
      
      final morning = _statsBox?.get('adhkar_morning_$key', defaultValue: false) ?? false;
      final evening = _statsBox?.get('adhkar_evening_$key', defaultValue: false) ?? false;
      if (morning && evening) adhkarDays++;
    }
    
    return WeeklySummary(
      versesRead: totalVerses,
      readingTimeSeconds: totalReadingSeconds,
      listeningTimeSeconds: totalListeningSeconds,
      completeAdhkarDays: adhkarDays,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _getTodayKey() => _getDateKey(DateTime.now());
  
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// مسح جميع الإحصائيات
  static Future<void> clearAll() async {
    await _statsBox?.clear();
    await _historyBox?.clear();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class ReadingStats {
  final int versesRead;
  final int readingTimeSeconds;

  const ReadingStats({
    required this.versesRead,
    required this.readingTimeSeconds,
  });

  Duration get readingTime => Duration(seconds: readingTimeSeconds);
  
  String get formattedTime {
    if (readingTimeSeconds < 60) return '$readingTimeSeconds ثانية';
    if (readingTimeSeconds < 3600) return '${readingTimeSeconds ~/ 60} دقيقة';
    final hours = readingTimeSeconds ~/ 3600;
    final minutes = (readingTimeSeconds % 3600) ~/ 60;
    return '$hours ساعة و $minutes دقيقة';
  }
}

class ListeningStats {
  final int todayTimeSeconds;
  final int totalTimeSeconds;
  final int todayVerses;

  const ListeningStats({
    required this.todayTimeSeconds,
    required this.totalTimeSeconds,
    required this.todayVerses,
  });

  Duration get todayTime => Duration(seconds: todayTimeSeconds);
  Duration get totalTime => Duration(seconds: totalTimeSeconds);
}

class AdhkarDayStatus {
  final bool morningComplete;
  final bool eveningComplete;
  final int afterPrayerCount;

  const AdhkarDayStatus({
    required this.morningComplete,
    required this.eveningComplete,
    required this.afterPrayerCount,
  });

  bool get isComplete => morningComplete && eveningComplete;
}

class KhatmahProgress {
  final int surah;
  final int ayah;
  final double percentage;

  const KhatmahProgress({
    required this.surah,
    required this.ayah,
    required this.percentage,
  });

  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';
}

class WeeklySummary {
  final int versesRead;
  final int readingTimeSeconds;
  final int listeningTimeSeconds;
  final int completeAdhkarDays;

  const WeeklySummary({
    required this.versesRead,
    required this.readingTimeSeconds,
    required this.listeningTimeSeconds,
    required this.completeAdhkarDays,
  });

  Duration get readingTime => Duration(seconds: readingTimeSeconds);
  Duration get listeningTime => Duration(seconds: listeningTimeSeconds);
}
