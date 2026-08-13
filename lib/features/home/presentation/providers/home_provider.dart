import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/models/adhkar_models.dart';
import '../../../../core/services/adhkar_data_source.dart';
import '../../../../core/services/day_state_machine.dart';
import '../../../../core/services/hadith_data_source.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/services/location_trust_engine.dart';
import '../../../../core/services/prayer_time_engine.dart';
import '../../../../core/services/quran_data_source.dart';
import '../../../../core/services/statistics_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HOME DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

class HomeData {

  HomeData({
    required this.prayerTimes,
    required this.cityName,
    required this.adhkarStats, this.hadithOfDay,
    this.lastRead,
  });
  final PrayerTimes prayerTimes;
  final String cityName;
  final Map<String, dynamic>? hadithOfDay;
  final DailyAdhkarStats adhkarStats;
  final LastReadData? lastRead;
}

class LastReadData {

  LastReadData({
    required this.surah,
    required this.ayah,
    required this.surahName,
  });
  final int surah;
  final int ayah;
  final String surahName;
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider to fetch all essential data for the Home screen
final homeDataProvider = FutureProvider<HomeData>((ref) async {
  ref.keepAlive();
  // 1. Geography & Prayer Times
  final locationResult = await LocationTrustEngine.getTrustedLocation(
    timeout: const Duration(seconds: 5),
  );
  
  final lat = locationResult.location?.latitude ?? 21.4225;
  final lng = locationResult.location?.longitude ?? 39.8262;
  
  var city = 'موقعك الحالي';
  try {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final mark = placemarks.first;
      city = mark.locality ?? mark.subAdministrativeArea ?? mark.administrativeArea ?? city;
    }
  } on Exception {
    // Fallback if geocoding fails
  }

  final times = PrayerTimeEngine.calculate(
    latitude: lat,
    longitude: lng,
    date: DateTime.now(),
    method: HiveService.getCalculationMethod() ?? CalculationMethod.ummAlQura,
    utcOffset: DateTime.now().timeZoneOffset.inMinutes / 60,
  );

  // 2. Hadith of the Day (Cached daily)
  final hadith = await _getDailyHadith();

  // 3. Adhkar Stats
  final adhkarStats = AdhkarDataSource.getTodayStats();

  // 4. Continue Reading
  LastReadData? lastRead;
  final lastMap = StatisticsService.getLastReadPosition();
  if (lastMap != null && lastMap['surah'] != null) {
    final sId = lastMap['surah'] as int;
    final aId = (lastMap['ayah'] ?? 1) as int;
    try {
      final surahData = await QuranDataSource.getSurah(sId);
      final sName = (surahData['name'] ?? 'سورة $sId') as String;
      lastRead = LastReadData(surah: sId, ayah: aId, surahName: sName);
    } on Exception catch (_) {
      lastRead = LastReadData(surah: sId, ayah: aId, surahName: 'سورة $sId');
    }
  }

  return HomeData(
    prayerTimes: times,
    cityName: city,
    hadithOfDay: hadith,
    adhkarStats: adhkarStats,
    lastRead: lastRead,
  );
});

/// Stream for current time (updates every 30 seconds)
final currentTimeProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 30),
    (_) => DateTime.now(),
  );
});

/// Stream for DayStateInfo (updates every minute)
final dayStateProvider = StreamProvider<StateInfo>((ref) {
  return Stream.periodic(const Duration(minutes: 1), (_) {
    return DayStateMachine.getCurrentStateInfo();
  });
});

/// Smart greeting based on prayer times
final smartGreetingProvider = Provider<String>((ref) {
  final stateAsync = ref.watch(dayStateProvider);
  
  return stateAsync.maybeWhen(
    data: (info) {
      switch (info.state) {
        case DayState.fajr:
          return 'صلاة الفجر خير من النوم 🌙';
        case DayState.sunrise:
        case DayState.duha:
          return 'صباح الجد والتوكل ☀️';
        case DayState.dhuhr:
          return 'وقت الطمأنينة 🌤️';
        case DayState.asr:
          return 'لا تنس أذكار المساء 🌇';
        case DayState.maghrib:
          return 'مساء السكينة 🌆';
        case DayState.isha:
          return 'طاب مساؤك ✨';
        case DayState.lateNight:
        case DayState.lastThird:
        case DayState.sleep:
          return 'قيام الليل 🌙';
        case DayState.unknown:
          return 'طاب يومك ☀️';
      }
    },
    orElse: () {
       final hour = DateTime.now().hour;
       if (hour < 5) return 'قيام الليل 🌙';
       if (hour < 12) return 'صباح الخير ☀️';
       if (hour < 17) return 'طاب يومك 🌤️';
       return 'مساء النور 🌆';
    },
  );
});

/// Smart suggestion based on Day State
final smartSuggestionProvider = Provider<String>((ref) {
  final stateAsync = ref.watch(dayStateProvider);
  return stateAsync.maybeWhen(
    data: (info) => info.state.suggestedAdhkar,
    orElse: () => 'استغفر الله',
  );
});

Future<Map<String, dynamic>?> _getDailyHadith() async {
  try {
    final box = await Hive.openBox<dynamic>('home_cache');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cachedStr = box.get('daily_hadith_str');
    final cachedDate = box.get('daily_hadith_date');
    
    if (cachedStr != null && cachedDate == today) {
       return Map<String, dynamic>.from(jsonDecode(cachedStr as String) as Map);
    }
    
    // Fetch new
    final newHadith = await HadithDataSource.getRandomHadith();
    if (newHadith != null) {
      await box.put('daily_hadith_str', jsonEncode(newHadith));
      await box.put('daily_hadith_date', today);
    }
    return newHadith;
  } on Exception {
    return HadithDataSource.getRandomHadith();
  }
}
