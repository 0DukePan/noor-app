import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/services/adhan_scheduler_service.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/services/location_trust_engine.dart';
import '../../../../core/services/mosque_mode_service.dart';
import '../../../../core/services/prayer_health_check.dart';
import '../../../../core/services/prayer_time_engine.dart';
import '../../domain/entities/prayer_entities.dart' hide CalculationMethod;

// ═══════════════════════════════════════════════════════════════════════════
// PRAYER DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

class PrayerPageData {

  const PrayerPageData({
    required this.prayerTimes,
    required this.cityName,
    required this.countryName,
  });
  final PrayerTimes prayerTimes;
  final String cityName;
  final String countryName;
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Reactive stream that ticks every minute for countdown updates
final prayerTimeTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now())
      .asBroadcastStream();
});

/// Main data provider for the prayer page - fetches real prayer times
final prayerDataProvider = FutureProvider<PrayerPageData>((ref) async {
  final locationResult = await LocationTrustEngine.getTrustedLocation(
    timeout: const Duration(seconds: 5),
  );

  final lat = locationResult.location?.latitude ?? 21.4225;
  final lng = locationResult.location?.longitude ?? 39.8262;

  var city = 'موقعك الحالي';
  var country = '';
  try {
    // Try geocoding
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final mark = placemarks.first;
      city = mark.locality ?? mark.subAdministrativeArea ?? city;
      country = mark.country ?? '';
    }
  } on Exception catch (e) {
    // Offline is expected — the label falls back to "your current location" —
    // but a silent failure here also hides a broken geocoding plugin.
    debugPrint('Prayer page: reverse geocoding failed: $e');
  }

  final prayerTimes = PrayerTimeEngine.calculate(
    latitude: lat,
    longitude: lng,
    date: DateTime.now(),
    method: HiveService.getCalculationMethod() ?? CalculationMethod.ummAlQura,
    utcOffset: DateTime.now().timeZoneOffset.inMinutes / 60,
  );

  return PrayerPageData(
    prayerTimes: prayerTimes,
    cityName: city,
    countryName: country,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// QADA STATE MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════

class QadaState {

  const QadaState({
    this.prayerRecords = const [],
    this.fastingRecords = const [],
  });
  final List<QadaRecord> prayerRecords;
  final List<QadaRecord> fastingRecords;

  QadaState copyWith({
    List<QadaRecord>? prayerRecords,
    List<QadaRecord>? fastingRecords,
  }) {
    return QadaState(
      prayerRecords: prayerRecords ?? this.prayerRecords,
      fastingRecords: fastingRecords ?? this.fastingRecords,
    );
  }
}

class QadaNotifier extends StateNotifier<QadaState> {
  QadaNotifier() : super(const QadaState()) {
    ready = _loadFromHive();
  }

  /// Completes when the initial Hive load has finished. Callers (and tests)
  /// can await this instead of racing the unawaited constructor load.
  late final Future<void> ready;

  static const _boxName = 'qada_records';

  Future<void> _loadFromHive() async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      final prayerList = (box.get('prayer_records', defaultValue: <dynamic>[]) as List)
          .cast<Map<dynamic, dynamic>>()
          .map((m) => _mapToRecord(m, QadaType.prayer))
          .toList();
      final fastingList = (box.get('fasting_records', defaultValue: <dynamic>[]) as List)
          .cast<Map<dynamic, dynamic>>()
          .map((m) => _mapToRecord(m, QadaType.fasting))
          .toList();

      state = QadaState(
        prayerRecords: prayerList,
        fastingRecords: fastingList,
      );
    } on Object catch (e) {
      // Narrow by effect: only Hive lifecycle errors (HiveError, an Error
      // subclass) and corrupt-data cast errors are absorbed — anything else
      // rethrows.
      if (e is HiveError || e is TypeError) {
        state = const QadaState();
      } else {
        rethrow;
      }
    }
  }

  Future<void> _saveToHive() async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      await box.put('prayer_records', state.prayerRecords.map(_recordToMap).toList());
      await box.put('fasting_records', state.fastingRecords.map(_recordToMap).toList());
    } on Object catch (e) {
      // Persistence failure (closed/unavailable box, HiveError) must never
      // surface an unhandled async error; in-memory state stays authoritative.
      // Anything else rethrows.
      if (e is! HiveError) rethrow;
    }
  }

  void addRecord(QadaType type, String name, int totalCount, String? notes) {
    final record = QadaRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      totalCount: totalCount,
      completedCount: 0,
      startDate: DateTime.now(),
      notes: notes,
    );

    if (type == QadaType.prayer) {
      state = state.copyWith(prayerRecords: [...state.prayerRecords, record]);
    } else {
      state = state.copyWith(fastingRecords: [...state.fastingRecords, record]);
    }
    _saveToHive();
  }

  /// Returns true if the record is now complete
  bool incrementRecord(String id) {
    var isComplete = false;
    
    state = state.copyWith(
      prayerRecords: state.prayerRecords.map((r) {
        if (r.id == id) {
          final newCompleted = r.completedCount + 1;
          isComplete = newCompleted >= r.totalCount;
          return QadaRecord(
            id: r.id, type: r.type, totalCount: r.totalCount,
            completedCount: newCompleted, startDate: r.startDate, notes: r.notes,
          );
        }
        return r;
      }).toList(),
      fastingRecords: state.fastingRecords.map((r) {
        if (r.id == id) {
          final newCompleted = r.completedCount + 1;
          isComplete = newCompleted >= r.totalCount;
          return QadaRecord(
            id: r.id, type: r.type, totalCount: r.totalCount,
            completedCount: newCompleted, startDate: r.startDate, notes: r.notes,
          );
        }
        return r;
      }).toList(),
    );
    _saveToHive();
    return isComplete;
  }

  void deleteRecord(String id) {
    state = state.copyWith(
      prayerRecords: state.prayerRecords.where((r) => r.id != id).toList(),
      fastingRecords: state.fastingRecords.where((r) => r.id != id).toList(),
    );
    _saveToHive();
  }

  QadaRecord _mapToRecord(Map<dynamic, dynamic> m, QadaType type) {
    return QadaRecord(
      id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      totalCount: (m['totalCount'] as num?)?.toInt() ?? 0,
      completedCount: (m['completedCount'] as num?)?.toInt() ?? 0,
      startDate: m['startDate'] != null ? DateTime.tryParse(m['startDate'].toString()) : null,
      notes: m['notes']?.toString(),
    );
  }

  Map<String, dynamic> _recordToMap(QadaRecord r) {
    return {
      'id': r.id,
      'totalCount': r.totalCount,
      'completedCount': r.completedCount,
      'startDate': r.startDate?.toIso8601String(),
      'notes': r.notes,
    };
  }
}

final qadaProvider = StateNotifierProvider<QadaNotifier, QadaState>((ref) {
  return QadaNotifier();
});

/// Bumped whenever a per-prayer adhan notification is toggled so the prayer
/// page rebuilds its bell icons.
final prayerAdhanToggleProvider = StateProvider<int>((ref) => 0);

// ═══════════════════════════════════════════════════════════════════════════
// PRAYER SETTINGS STATE
// ═══════════════════════════════════════════════════════════════════════════

class PrayerSettingsState {

  const PrayerSettingsState({
    this.adhanEnabled = const {},
    this.mosqueModeGlobal = false,
    this.mosqueDuration = 30,
    this.healthReport,
    this.healthLoading = false,
  });
  final Map<String, bool> adhanEnabled;
  final bool mosqueModeGlobal;
  final int mosqueDuration;
  final HealthReport? healthReport;
  final bool healthLoading;

  PrayerSettingsState copyWith({
    Map<String, bool>? adhanEnabled,
    bool? mosqueModeGlobal,
    int? mosqueDuration,
    HealthReport? healthReport,
    bool? healthLoading,
  }) {
    return PrayerSettingsState(
      adhanEnabled: adhanEnabled ?? this.adhanEnabled,
      mosqueModeGlobal: mosqueModeGlobal ?? this.mosqueModeGlobal,
      mosqueDuration: mosqueDuration ?? this.mosqueDuration,
      healthReport: healthReport ?? this.healthReport,
      healthLoading: healthLoading ?? this.healthLoading,
    );
  }
}

class PrayerSettingsNotifier extends StateNotifier<PrayerSettingsState> {
  PrayerSettingsNotifier() : super(const PrayerSettingsState()) {
    _loadSettings();
  }

  static const _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  void _loadSettings() {
    final adhan = <String, bool>{};
    for (final p in _prayers) {
      adhan[p] = AdhanSchedulerService.isAdhanEnabled(p);
    }

    state = state.copyWith(
      adhanEnabled: adhan,
      mosqueModeGlobal: MosqueModeService.isEnabled,
      mosqueDuration: MosqueModeService.durationMinutes,
    );
  }

  Future<void> toggleAdhan(String prayer, {required bool enabled}) async {
    await AdhanSchedulerService.setAdhanEnabled(prayer, enabled: enabled);
    state = state.copyWith(
      adhanEnabled: {...state.adhanEnabled, prayer: enabled},
    );
  }

  Future<void> setMosqueMode({required bool enabled}) async {
    if (enabled) {
      await MosqueModeService.enable();
    } else {
      await MosqueModeService.disable();
    }
    state = state.copyWith(mosqueModeGlobal: enabled);
  }

  Future<void> setMosqueDuration(int minutes) async {
    await MosqueModeService.setDuration(minutes);
    state = state.copyWith(mosqueDuration: minutes);
  }

  Future<void> runHealthCheck() async {
    state = state.copyWith(healthLoading: true);
    try {
      final report = await PrayerHealthCheck.runHealthCheck();
      state = state.copyWith(healthReport: report, healthLoading: false);
    } on Exception {
      state = state.copyWith(healthLoading: false);
    }
  }
}

final prayerSettingsProvider =
    StateNotifierProvider<PrayerSettingsNotifier, PrayerSettingsState>((ref) {
  return PrayerSettingsNotifier();
});
