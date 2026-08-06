import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/services/location_trust_engine.dart';
import '../../../../core/services/prayer_time_engine.dart';
import '../../../../core/services/adhan_scheduler_service.dart';
import '../../../../core/services/mosque_mode_service.dart';
import '../../../../core/services/prayer_health_check.dart';
import '../../domain/entities/prayer_entities.dart' hide CalculationMethod;

// ═══════════════════════════════════════════════════════════════════════════
// PRAYER DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

class PrayerPageData {
  final PrayerTimes prayerTimes;
  final String cityName;
  final String countryName;

  const PrayerPageData({
    required this.prayerTimes,
    required this.cityName,
    required this.countryName,
  });
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

  String city = "موقعك الحالي";
  String country = "";
  try {
    // Try geocoding
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final mark = placemarks.first;
      city = mark.locality ?? mark.subAdministrativeArea ?? city;
      country = mark.country ?? '';
    }
  } catch (_) {}

  final prayerTimes = PrayerTimeEngine.calculate(
    latitude: lat,
    longitude: lng,
    date: DateTime.now(),
    method: CalculationMethod.ummAlQura,
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
  final List<QadaRecord> prayerRecords;
  final List<QadaRecord> fastingRecords;

  const QadaState({
    this.prayerRecords = const [],
    this.fastingRecords = const [],
  });

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
    _loadFromHive();
  }

  static const _boxName = 'qada_records';

  Future<void> _loadFromHive() async {
    try {
      final box = await Hive.openBox(_boxName);
      final prayerList = (box.get('prayer_records', defaultValue: []) as List)
          .cast<Map>()
          .map((m) => _mapToRecord(m, QadaType.prayer))
          .toList();
      final fastingList = (box.get('fasting_records', defaultValue: []) as List)
          .cast<Map>()
          .map((m) => _mapToRecord(m, QadaType.fasting))
          .toList();

      state = QadaState(
        prayerRecords: prayerList,
        fastingRecords: fastingList,
      );
    } catch (e) {
      // Start fresh if Hive fails
      state = const QadaState();
    }
  }

  Future<void> _saveToHive() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put('prayer_records', state.prayerRecords.map(_recordToMap).toList());
      await box.put('fasting_records', state.fastingRecords.map(_recordToMap).toList());
    } catch (_) {}
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
    bool isComplete = false;
    
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

  QadaRecord _mapToRecord(Map m, QadaType type) {
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

// ═══════════════════════════════════════════════════════════════════════════
// PRAYER SETTINGS STATE
// ═══════════════════════════════════════════════════════════════════════════

class PrayerSettingsState {
  final Map<String, bool> adhanEnabled;
  final bool mosqueModeGlobal;
  final int mosqueDuration;
  final HealthReport? healthReport;
  final bool healthLoading;

  const PrayerSettingsState({
    this.adhanEnabled = const {},
    this.mosqueModeGlobal = false,
    this.mosqueDuration = 30,
    this.healthReport,
    this.healthLoading = false,
  });

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

  Future<void> toggleAdhan(String prayer, bool enabled) async {
    await AdhanSchedulerService.setAdhanEnabled(prayer, enabled);
    state = state.copyWith(
      adhanEnabled: {...state.adhanEnabled, prayer: enabled},
    );
  }

  Future<void> setMosqueMode(bool enabled) async {
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
    } catch (e) {
      state = state.copyWith(healthLoading: false);
    }
  }
}

final prayerSettingsProvider =
    StateNotifierProvider<PrayerSettingsNotifier, PrayerSettingsState>((ref) {
  return PrayerSettingsNotifier();
});
