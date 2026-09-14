import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/prayer_calculation_service.dart';
import 'package:noor_app/features/prayer/domain/entities/prayer_entities.dart';

/// Direct tests for PrayerCalculationService (previously zero-covered) — the
/// adhan-package-backed facade. The safety-critical contract: every enum
/// method maps to parameters, the six times are correct and ordered, and the
/// "next prayer" logic is deterministic for future/past dates.
void main() {
  final service = PrayerCalculationService();
  const mecca = Location(latitude: 21.4225, longitude: 39.8262);

  test('calculates six ordered prayer times for Umm al-Qura', () {
    final times = service.calculatePrayerTimes(
      date: DateTime(2026, 3, 15),
      location: mecca,
    );

    expect(
      times.fajr.nameArabic,
      isNotEmpty,
    );
    expect(times.isha.nameArabic, isNotEmpty);
    expect(times.date, DateTime(2026, 3, 15));

    final ordered = [
      times.fajr.time,
      times.sunrise.time,
      times.dhuhr.time,
      times.asr.time,
      times.maghrib.time,
      times.isha.time,
    ];
    for (var i = 0; i < ordered.length - 1; i++) {
      expect(
        ordered[i].isBefore(ordered[i + 1]),
        isTrue,
        reason: 'times must be chronological at index $i',
      );
    }
    // Times fall on the requested date (or just after midnight, never far).
    for (final t in ordered) {
      expect(t.difference(times.date).inHours.abs(), lessThan(24));
    }
  });

  test('every calculation method maps to adhan parameters without throwing',
      () {
    for (final method in CalculationMethod.values) {
      final times = service.calculatePrayerTimes(
        date: DateTime(2026, 3, 15),
        location: mecca,
        method: method,
      );
      expect(times.method, method);
      expect(times.fajr.time.isAfter(DateTime(2026, 3, 15)), isTrue);
    }
  });

  test('a future date has fajr as the next prayer', () {
    final future = DateTime.now().add(const Duration(days: 1));
    final times = service.calculatePrayerTimes(date: future, location: mecca);

    expect(times.nextPrayer, isNotNull);
    expect(
      times.nextPrayer!.name,
      'Fajr',
    );
    expect(times.fajr.isNext, isTrue);
  });

  test('a past date has no next prayer', () {
    final past = DateTime.now().subtract(const Duration(days: 1));
    final times = service.calculatePrayerTimes(date: past, location: mecca);

    expect(times.nextPrayer, isNull);
  });

  test('getTimeUntilNextPrayer returns the remaining duration', () {
    final future = DateTime.now().add(const Duration(days: 1));
    final times = service.calculatePrayerTimes(date: future, location: mecca);

    final remaining = service.getTimeUntilNextPrayer(times);
    expect(remaining, isNotNull);
    expect(remaining!.inSeconds, greaterThan(0));
  });

  test('formatTimeRemaining renders Arabic hours/minutes', () {
    expect(
      service.formatTimeRemaining(const Duration(hours: 2, minutes: 5)),
      contains('2'),
    );
    expect(
      service.formatTimeRemaining(const Duration(minutes: 45)),
      contains('45'),
    );
    // Negative durations (a passed prayer) render empty.
    expect(service.formatTimeRemaining(const Duration(minutes: -5)), isEmpty);
  });

  test('methods disagree on times (karachi vs umm-al-qura isha gap)', () {
    const date = mecca;
    final karachi = service.calculatePrayerTimes(
      date: DateTime(2026, 3, 15),
      location: date,
      method: CalculationMethod.karachi,
    );
    final ummAlQura = service.calculatePrayerTimes(
      date: DateTime(2026, 3, 15),
      location: date,
    );
    expect(
      karachi.isha.time,
      isNot(equals(ummAlQura.isha.time)),
    );
  });

  test('format edges: zero minutes and exact hours', () {
    expect(service.formatTimeRemaining(Duration.zero), isNotNull);
    final oneHour = service.formatTimeRemaining(const Duration(hours: 1));
    expect(oneHour, contains('1'));
    final oneMinute = service.formatTimeRemaining(const Duration(minutes: 1));
    expect(oneMinute, contains('1'));
  });

  test('exactly one future prayer is flagged next, none for the past', () {
    final future = DateTime.now().add(const Duration(days: 1));
    final times = service.calculatePrayerTimes(date: future, location: mecca);
    final flagged = [
      times.fajr,
      times.sunrise,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ].where((p) => p.isNext);
    expect(flagged, hasLength(1));
    expect(flagged.single.name, times.nextPrayer!.name);
  });
}
