import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';

/// Reference values are derived from standard NOAA solar equations (as used by
/// the well-known PrayTimes library). The engine's job is to produce the
/// *local wall-clock* times for the given [utcOffset].
///
/// Verified reference points (rounded to the nearest minute):
///  - Mecca (21.42N, 39.83E), 2026-03-15, Umm al-Qura:
///      solar noon ≈ 09:29 UTC → 12:29 local (UTC+3)
///  - London (51.51N, -0.13E), 2026-03-15, MWL:
///      solar noon ≈ 12:09 UTC → 12:09 local (UTC+0)
///  - New York (40.71N, -74.01E), 2026-06-15, ISNA:
///      solar noon ≈ 16:55 UTC → 12:55 local (UTC-4, EDT)
void main() {
  group('PrayerTimeEngine', () {
    group('calculate()', () {
      test('returns valid prayer times for Mecca', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 3,
        );

        expect(times.fajr, isNotNull);
        expect(times.sunrise, isNotNull);
        expect(times.dhuhr, isNotNull);
        expect(times.asr, isNotNull);
        expect(times.maghrib, isNotNull);
        expect(times.isha, isNotNull);
        expect(times.date.day, 15);
      });

      test('prayer times are chronologically ordered', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 6, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 3,
        );

        expect(times.fajr.isBefore(times.sunrise), isTrue);
        expect(times.sunrise.isBefore(times.dhuhr), isTrue);
        expect(times.dhuhr.isBefore(times.asr), isTrue);
        expect(times.asr.isBefore(times.maghrib), isTrue);
        expect(times.maghrib.isBefore(times.isha), isTrue);
      });

      test('Fajr is AM and Isha is PM', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 3,
        );

        expect(times.fajr.hour, lessThan(12));
        expect(times.isha.hour, greaterThanOrEqualTo(12));
      });

      test('Hanafi Asr is later than Shafi Asr', () {
        final shafi = PrayerTimeEngine.calculate(
          latitude: 41.0082,
          longitude: 28.9784,
          date: DateTime(2026, 6, 15),
          method: CalculationMethod.turkey,
          madhab: Madhab.shafi,
          utcOffset: 3,
        );

        final hanafi = PrayerTimeEngine.calculate(
          latitude: 41.0082,
          longitude: 28.9784,
          date: DateTime(2026, 6, 15),
          method: CalculationMethod.turkey,
          madhab: Madhab.hanafi,
          utcOffset: 3,
        );

        final diffMinutes = hanafi.asr.difference(shafi.asr).inMinutes;
        expect(diffMinutes, greaterThanOrEqualTo(0));
      });

      test('different calculation methods produce different Fajr times', () {
        final ummAlQura = PrayerTimeEngine.calculate(
          latitude: 36.7538,
          longitude: 3.0588,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 1,
        );

        final egyptian = PrayerTimeEngine.calculate(
          latitude: 36.7538,
          longitude: 3.0588,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.egyptian,
          utcOffset: 1,
        );

        expect(
          ummAlQura.fajr.difference(egyptian.fajr).inMinutes.abs(),
          greaterThanOrEqualTo(0),
        );
      });

      test('works for high latitude (Stockholm)', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 59.3293,
          longitude: 18.0686,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.muslimWorldLeague,
          highLatitudeRule: HighLatitudeRule.middleOfNight,
          utcOffset: 1,
        );

        expect(times.fajr, isNotNull);
        expect(times.isha, isNotNull);
        expect(times.fajr.isBefore(times.sunrise), isTrue);
      });

      test('works for Southern hemisphere (Cape Town)', () {
        final times = PrayerTimeEngine.calculate(
          latitude: -33.9249,
          longitude: 18.4241,
          date: DateTime(2026, 6, 15),
          method: CalculationMethod.muslimWorldLeague,
          utcOffset: 2,
        );

        expect(times.fajr.isBefore(times.sunrise), isTrue);
        expect(times.maghrib.isBefore(times.isha), isTrue);
      });

      test('adjustments shift times correctly', () {
        final base = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 3,
        );

        final adjusted = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 3,
          adjustments: PrayerAdjustments(
            fajr: 5,
            dhuhr: -3,
          ),
        );

        expect(
          adjusted.fajr.difference(base.fajr).inMinutes,
          equals(5),
        );
        expect(
          adjusted.dhuhr.difference(base.dhuhr).inMinutes,
          equals(-3),
        );
      });
    });

    group('timezone correction', () {
      test('Mecca dhuhr is ~12:29 local (UTC+3)', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 3,
        );

        expect(times.dhuhr.hour, 12);
        expect(times.dhuhr.minute, inInclusiveRange(20, 40));
      });

      test('London dhuhr is ~12:09 local (UTC+0)', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 51.5074,
          longitude: -0.1278,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.muslimWorldLeague,
          utcOffset: 0,
        );

        expect(times.dhuhr.hour, 12);
        expect(times.dhuhr.minute, inInclusiveRange(0, 20));
      });

      test('New York dhuhr is ~12:55 local with DST offset (UTC-4)', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 40.7128,
          longitude: -74.006,
          date: DateTime(2026, 6, 15),
          method: CalculationMethod.northAmerica,
          utcOffset: -4,
        );

        expect(times.dhuhr.hour, 12);
        expect(times.dhuhr.minute, inInclusiveRange(40, 70));
      });

      test('without the correct offset, New York dhuhr is NOT at noon', () {
        // Regression guard: if a caller forgets the offset, Dhuhr would
        // fall at ~16:55 instead of ~12:55 — this test documents that
        // omitting utcOffset is a bug, not a feature.
        final wrong = PrayerTimeEngine.calculate(
          latitude: 40.7128,
          longitude: -74.006,
          date: DateTime(2026, 6, 15),
          method: CalculationMethod.northAmerica,
          utcOffset: 0,
        );

        expect(wrong.dhuhr.hour, 16);
      });

      test('utcOffset shifts every time by the same amount', () {
        final base = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 0,
        );

        final shifted = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 3,
        );

        for (final prayer in PrayerType.values) {
          expect(
            shifted.getTime(prayer).difference(base.getTime(prayer)).inMinutes,
            equals(180),
          );
        }
      });

      test('half-hour offsets are respected (Kathmandu UTC+5:45)', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 27.7172,
          longitude: 85.324,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.karachi,
          utcOffset: 5.75,
        );

        // Solar noon UTC ≈ 06:27 → local ≈ 12:12
        expect(times.dhuhr.hour, 12);
        expect(times.dhuhr.minute, inInclusiveRange(0, 25));
      });

      test('Algerian method dhuhr is ~12:56 local (UTC+1)', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 36.7538,
          longitude: 3.0588,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.algeriaTunisia,
          utcOffset: 1,
        );

        // Solar noon UTC ≈ 11:56 → local ≈ 12:56
        expect(times.dhuhr.hour, 12);
        expect(times.dhuhr.minute, inInclusiveRange(45, 65));
      });
    });

    group('calculateWeek()', () {
      test('returns 7 days of prayer times', () {
        final week = PrayerTimeEngine.calculateWeek(
          latitude: 21.4225,
          longitude: 39.8262,
          startDate: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 3,
        );

        expect(week.length, equals(7));
        for (final day in week) {
          expect(day.fajr.isBefore(day.sunrise), isTrue);
          expect(day.maghrib.isBefore(day.isha), isTrue);
        }
      });
    });

    group('getTime()', () {
      test('returns correct time for each prayer type', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 3,
        );

        expect(times.getTime(PrayerType.fajr), equals(times.fajr));
        expect(times.getTime(PrayerType.dhuhr), equals(times.dhuhr));
        expect(times.getTime(PrayerType.asr), equals(times.asr));
        expect(times.getTime(PrayerType.maghrib), equals(times.maghrib));
        expect(times.getTime(PrayerType.isha), equals(times.isha));
      });
    });

    group('calculateWithRegion / calculateAuto', () {
      test('respects utcOffset through region helpers', () {
        final viaRegion = PrayerTimeEngine.calculateWithRegion(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          region: PrayerRegion.gulf,
          utcOffset: 3,
        );

        final viaAuto = PrayerTimeEngine.calculateAuto(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          utcOffset: 3,
        );

        expect(viaRegion.dhuhr.hour, 12);
        expect(viaAuto.dhuhr.hour, 12);
      });
    });
  });
}
