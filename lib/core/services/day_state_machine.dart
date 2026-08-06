import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'prayer_time_engine.dart';

/// 🕐 آلة حالات اليوم - Day State Machine
/// 
/// تقنية أنظمة الطيران لإدارة حالات اليوم الإسلامي
/// 
/// الحالات:
/// - قبل الفجر (الثلث الأخير)
/// - وقت الفجر
/// - الشروق
/// - الضحى
/// - الظهر
/// - العصر
/// - المغرب
/// - العشاء
/// - النوم
class DayStateMachine {
  static Box? _stateBox;
  static Timer? _stateTimer;
  static PrayerTimes? _todayTimes;
  
  // State stream
  static final _stateController = StreamController<DayState>.broadcast();
  static Stream<DayState> get stateStream => _stateController.stream;
  
  static DayState _currentState = DayState.unknown;
  static DayState get currentState => _currentState;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRAYER COMPLETION TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bumped whenever a prayer is marked/unmarked, so widgets can rebuild.
  static final ValueNotifier<int> completionVersion = ValueNotifier(0);

  static const _completedKeyPrefix = 'completed_';
  static const _streakKey = 'streak';
  static const _lastCompleteKey = 'last_complete_date';

  static Set<PrayerType>? _todayCompleted;
  static String _lastDate = '';

  static String _todayKey() => _dateKey(DateTime.now());

  static String _dateKey(DateTime time) {
    return '${time.year}-'
        '${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')}';
  }

  static Set<PrayerType> _loadCompleted() {
    final key = '$_completedKeyPrefix${_todayKey()}';
    final data = _stateBox?.get(key);
    if (data == null) return {};
    return (data as List).map((e) => PrayerType.values[e as int]).toSet();
  }

  /// Prayers already prayed today (Fajr, Dhuhr, Asr, Maghrib, Isha).
  static Set<PrayerType> get completedPrayers =>
      _todayCompleted ??= _loadCompleted();

  static bool isPrayerCompleted(PrayerType prayer) =>
      completedPrayers.contains(prayer);

  static int get todayPrayersCompleted => completedPrayers.length;

  /// True when all five daily prayers have been marked completed today.
  static bool get isDayComplete {
    const required = {
      PrayerType.fajr,
      PrayerType.dhuhr,
      PrayerType.asr,
      PrayerType.maghrib,
      PrayerType.isha,
    };
    return completedPrayers.containsAll(required);
  }

  /// Consecutive days on which all five prayers were completed.
  static int get streak => _stateBox?.get(_streakKey) ?? 0;

  static Future<void> markPrayerCompleted(PrayerType prayer) async {
    if (prayer == PrayerType.sunrise) return;
    final set = {...completedPrayers}..add(prayer);
    await _saveCompleted(set);
    _todayCompleted = set;
    completionVersion.value++;
  }

  static Future<void> unmarkPrayerCompleted(PrayerType prayer) async {
    final set = {...completedPrayers}..remove(prayer);
    await _saveCompleted(set);
    _todayCompleted = set;
    completionVersion.value++;
  }

  static Future<void> _saveCompleted(Set<PrayerType> set) async {
    final key = '$_completedKeyPrefix${_todayKey()}';
    await _stateBox?.put(key, set.map((p) => p.index).toList());

    if (set.length == 5) {
      final today = _todayKey();
      if (_stateBox?.get('_counted_$today') != true) {
        final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
        final lastComplete = _stateBox?.get(_lastCompleteKey) as String?;
        final newStreak = lastComplete == yesterday ? (streak + 1) : 1;
        await _stateBox?.put(_streakKey, newStreak);
        await _stateBox?.put(_lastCompleteKey, today);
        await _stateBox?.put('_counted_$today', true);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> init() async {
    _stateBox = await Hive.openBox('day_state');
    
    // Start state checking
    _startStateMonitoring();
  }

  /// تحديث مواقيت اليوم
  static void updateTodayTimes(PrayerTimes times) {
    _todayTimes = times;
    _checkAndUpdateState();
  }

  /// بدء مراقبة الحالة
  static void _startStateMonitoring() {
    // Check every minute
    _stateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndUpdateState();
    });
    
    // Initial check
    _checkAndUpdateState();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE DETERMINATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديد الحالة الحالية
  static void _checkAndUpdateState() {
    // Reset the day-scoped completion cache at midnight.
    final today = _todayKey();
    if (_lastDate != today) {
      _lastDate = today;
      _todayCompleted = null;
      completionVersion.value++;
    }

    if (_todayTimes == null) return;
    
    final now = DateTime.now();
    final newState = _determineState(now, _todayTimes!);
    
    if (newState != _currentState) {
      final oldState = _currentState;
      _currentState = newState;
      _stateController.add(newState);
      _onStateChange(oldState, newState);
    }
  }

  static DayState _determineState(DateTime now, PrayerTimes times) {
    // Calculate last third of night (for Tahajjud)
    final midnightToFajr = times.fajr.difference(
      DateTime(now.year, now.month, now.day, 0, 0),
    );
    final lastThird = times.fajr.subtract(midnightToFajr ~/ 3);
    
    // Determine state based on time
    if (now.isBefore(lastThird)) {
      return DayState.lateNight; // قبل الثلث الأخير
    }
    if (now.isBefore(times.fajr)) {
      return DayState.lastThird; // الثلث الأخير (وقت التهجد)
    }
    if (now.isBefore(times.sunrise)) {
      return DayState.fajr; // وقت الفجر
    }
    if (now.isBefore(times.sunrise.add(const Duration(minutes: 15)))) {
      return DayState.sunrise; // الشروق
    }
    if (now.isBefore(times.dhuhr.subtract(const Duration(minutes: 10)))) {
      return DayState.duha; // الضحى
    }
    if (now.isBefore(times.asr)) {
      return DayState.dhuhr; // الظهر
    }
    if (now.isBefore(times.maghrib)) {
      return DayState.asr; // العصر
    }
    if (now.isBefore(times.isha)) {
      return DayState.maghrib; // المغرب
    }
    if (now.hour < 23) {
      return DayState.isha; // العشاء
    }
    return DayState.sleep; // النوم
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE CHANGE HANDLING
  // ═══════════════════════════════════════════════════════════════════════════

  static void _onStateChange(DayState oldState, DayState newState) {
    debugPrint('Day state changed: ${oldState.name} → ${newState.name}');
    
    // Save state
    _stateBox?.put('current_state', newState.index);
    _stateBox?.put('last_update', DateTime.now().toIso8601String());
    
    // Trigger appropriate actions
    _triggerStateActions(newState);
  }

  static void _triggerStateActions(DayState state) {
    // Actions are handled by listeners
    // This could trigger:
    // - Notification changes
    // - UI theme changes
    // - Adhkar suggestions
    // - Volume adjustments
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE INFO
  // ═══════════════════════════════════════════════════════════════════════════

  /// معلومات الحالة الحالية
  static StateInfo getCurrentStateInfo() {
    return StateInfo(
      state: _currentState,
      nextState: _getNextState(),
      timeToNextState: _getTimeToNextState(),
      suggestedAdhkar: _currentState.suggestedAdhkar,
      suggestedAction: _currentState.suggestedAction,
    );
  }

  static DayState _getNextState() {
    final states = DayState.values;
    final currentIndex = states.indexOf(_currentState);
    if (currentIndex < states.length - 1) {
      return states[currentIndex + 1];
    }
    return DayState.lastThird; // Wrap to next day
  }

  static Duration _getTimeToNextState() {
    if (_todayTimes == null) return Duration.zero;
    
    final now = DateTime.now();
    final times = _todayTimes!;
    
    switch (_currentState) {
      case DayState.lastThird:
        return times.fajr.difference(now);
      case DayState.fajr:
        return times.sunrise.difference(now);
      case DayState.sunrise:
        return times.sunrise.add(const Duration(minutes: 15)).difference(now);
      case DayState.duha:
        return times.dhuhr.subtract(const Duration(minutes: 10)).difference(now);
      case DayState.dhuhr:
        return times.asr.difference(now);
      case DayState.asr:
        return times.maghrib.difference(now);
      case DayState.maghrib:
        return times.isha.difference(now);
      case DayState.isha:
        final sleep = DateTime(now.year, now.month, now.day, 23, 0);
        return sleep.difference(now);
      default:
        return Duration.zero;
    }
  }

  /// تنظيف
  static void dispose() {
    _stateTimer?.cancel();
    _stateController.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// حالات اليوم الإسلامي
enum DayState {
  unknown,     // غير معروف
  lateNight,   // الليل (قبل الثلث الأخير)
  lastThird,   // الثلث الأخير من الليل
  fajr,        // وقت الفجر
  sunrise,     // الشروق
  duha,        // الضحى
  dhuhr,       // الظهر
  asr,         // العصر
  maghrib,     // المغرب
  isha,        // العشاء
  sleep,       // وقت النوم
}

extension DayStateInfo on DayState {
  String get arabicName {
    switch (this) {
      case DayState.unknown: return 'غير معروف';
      case DayState.lateNight: return 'الليل';
      case DayState.lastThird: return 'الثلث الأخير';
      case DayState.fajr: return 'الفجر';
      case DayState.sunrise: return 'الشروق';
      case DayState.duha: return 'الضحى';
      case DayState.dhuhr: return 'الظهر';
      case DayState.asr: return 'العصر';
      case DayState.maghrib: return 'المغرب';
      case DayState.isha: return 'العشاء';
      case DayState.sleep: return 'النوم';
    }
  }

  String get icon {
    switch (this) {
      case DayState.unknown: return '❓';
      case DayState.lateNight: return '🌃';
      case DayState.lastThird: return '🌙';
      case DayState.fajr: return '🌅';
      case DayState.sunrise: return '☀️';
      case DayState.duha: return '🌤️';
      case DayState.dhuhr: return '☀️';
      case DayState.asr: return '🌇';
      case DayState.maghrib: return '🌆';
      case DayState.isha: return '🌙';
      case DayState.sleep: return '😴';
    }
  }

  String get suggestedAdhkar {
    switch (this) {
      case DayState.lastThird: return 'الاستغفار والدعاء';
      case DayState.fajr: return 'أذكار الصباح';
      case DayState.duha: return 'صلاة الضحى';
      case DayState.asr: return 'أذكار المساء';
      case DayState.maghrib: return 'أذكار المساء';
      case DayState.isha: return 'أذكار النوم';
      case DayState.sleep: return 'أذكار النوم';
      default: return '';
    }
  }

  String get suggestedAction {
    switch (this) {
      case DayState.lastThird: return 'قم للتهجد';
      case DayState.fajr: return 'صلِّ الفجر';
      case DayState.sunrise: return 'انتظر حتى ترتفع الشمس';
      case DayState.duha: return 'صلِّ الضحى';
      case DayState.dhuhr: return 'صلِّ الظهر';
      case DayState.asr: return 'صلِّ العصر';
      case DayState.maghrib: return 'صلِّ المغرب';
      case DayState.isha: return 'صلِّ العشاء';
      case DayState.sleep: return 'نم مبكرًا للفجر';
      default: return '';
    }
  }

  /// هل يسمح بالأذان في هذه الحالة؟
  bool get allowsAdhan {
    return this == DayState.fajr ||
           this == DayState.dhuhr ||
           this == DayState.asr ||
           this == DayState.maghrib ||
           this == DayState.isha;
  }

  /// هل هذا وقت هادئ؟
  bool get isQuietTime {
    return this == DayState.lateNight ||
           this == DayState.sleep;
  }
}

/// معلومات الحالة الكاملة
class StateInfo {
  final DayState state;
  final DayState nextState;
  final Duration timeToNextState;
  final String suggestedAdhkar;
  final String suggestedAction;

  const StateInfo({
    required this.state,
    required this.nextState,
    required this.timeToNextState,
    required this.suggestedAdhkar,
    required this.suggestedAction,
  });

  String get formattedTimeToNext {
    final hours = timeToNextState.inHours;
    final minutes = timeToNextState.inMinutes % 60;
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    }
    return '$minutes دقيقة';
  }
}
