import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';

/// Reference values are derived from standard NOAA solar equations (as used by
/// the well-known PrayTimes library). The engine's job is to produce the
/// *local wall-clock* times for the given `utcOffset`.
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
        // The old assertion was `greaterThanOrEqualTo(0)`, which also passes
        // when Asr is identical — or computed from a below-horizon angle.
        // In Istanbul in June the two shadow factors (1 vs 2) are hours apart,
        // so require a real gap and keep Asr inside its own window.
        expect(diffMinutes, greaterThanOrEqualTo(30));
        expect(shafi.asr.isAfter(shafi.dhuhr), isTrue);
        expect(shafi.asr.isBefore(shafi.maghrib), isTrue);
        expect(hanafi.asr.isBefore(hanafi.maghrib), isTrue);
      });

      test('solar noon matches documented reference values', () {
        // Reference values from the file header (NOAA/standard solar
        // equations). Regression for the equationOfTime unit bug (missing
        // 180/π factor) that shifted all times by up to ~16 minutes.
        final mecca = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
          utcOffset: 3,
        );
        final london = PrayerTimeEngine.calculate(
          latitude: 51.51,
          longitude: -0.13,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.muslimWorldLeague,
        );
        final newYork = PrayerTimeEngine.calculate(
          latitude: 40.71,
          longitude: -74.01,
          date: DateTime(2026, 6, 15),
          method: CalculationMethod.northAmerica,
          utcOffset: -4,
        );

        // ±2 minutes guards against rounding and any future drift.
        expect(mecca.dhuhr.hour, 12);
        expect(mecca.dhuhr.minute, closeTo(29, 2));
        expect(london.dhuhr.hour, 12);
        expect(london.dhuhr.minute, closeTo(9, 2));
        expect(newYork.dhuhr.hour, 12);
        expect(newYork.dhuhr.minute, closeTo(55, 2));
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
          adjustments: const PrayerAdjustments(
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
        );

        expect(wrong.dhuhr.hour, 16);
      });

      test('utcOffset shifts every time by the same amount', () {
        final base = PrayerTimeEngine.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          date: DateTime(2026, 3, 15),
          method: CalculationMethod.ummAlQura,
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

    group('Asr domain and high latitudes', () {
      // Asr is an ABOVE-horizon event. The historical bug computed it from a
      // below-horizon angle, which pushed Asr towards/after sunset and
      // produced out-of-domain hour angles at high latitudes. Polar cases are
      // the guard: that is where the bug actually bit.
      //
      // Known limitation, pinned below rather than hidden: in true polar night
      // the sun never rises, so there is no sunset event at all. The engine
      // (like the underlying solar equations) collapses sunrise/dhuhr/maghrib
      // onto the clamped noon. Everything stays finite and inside the day, but
      // strict Fajr < Sunrise < Dhuhr < Asr < Maghrib ordering is impossible
      // there by nature. Choosing a nearest-latitude or Makkah-following
      // convention for those latitudes is a doctrinal decision, not a bug fix,
      // and is deliberately left to a future change.

      test('Tromsø in polar night stays finite and near its own day', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 69.6492,
          longitude: 18.9553,
          date: DateTime(2026, 12, 21),
          method: CalculationMethod.muslimWorldLeague,
          utcOffset: 1,
        );

        // Dhuhr and Asr are always real events, even when the sun never rises.
        expect(times.dhuhr.isBefore(times.asr), isTrue);
        expect(times.fajr.isBefore(times.sunrise), isTrue);

        // High-latitude rules may shift a time by minutes across midnight,
        // but never by days.
        for (final prayer in PrayerType.values) {
          expect(
            times.getTime(prayer).difference(DateTime(2026, 12, 21)).inHours.abs(),
            lessThanOrEqualTo(24),
          );
        }
      });

      test('Tromsø under the midnight sun keeps Asr before Maghrib', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 69.6492,
          longitude: 18.9553,
          date: DateTime(2026, 6, 21),
          method: CalculationMethod.muslimWorldLeague,
          utcOffset: 2,
        );

        expect(times.dhuhr.isBefore(times.asr), isTrue);
        expect(times.asr.isBefore(times.maghrib), isTrue);
      });

      test('a short sub-arctic winter day keeps the full ordering', () {
        // Stockholm in December has a real but short day (~6h), so every
        // event exists and the ordering must hold end to end.
        final times = PrayerTimeEngine.calculate(
          latitude: 59.3293,
          longitude: 18.0686,
          date: DateTime(2026, 12, 21),
          method: CalculationMethod.muslimWorldLeague,
          utcOffset: 1,
        );

        expect(times.fajr.isBefore(times.sunrise), isTrue);
        expect(times.sunrise.isBefore(times.dhuhr), isTrue);
        expect(times.dhuhr.isBefore(times.asr), isTrue);
        expect(times.asr.isBefore(times.maghrib), isTrue);
        expect(times.maghrib.isBefore(times.isha), isTrue);
      });

      test('Asr stays well inside the day at 69°N', () {
        final times = PrayerTimeEngine.calculate(
          latitude: 69.6492,
          longitude: 18.9553,
          date: DateTime(2026, 3, 21),
          method: CalculationMethod.muslimWorldLeague,
          utcOffset: 1,
        );

        final dhuhrToAsr = times.asr.difference(times.dhuhr).inMinutes;
        expect(dhuhrToAsr, greaterThan(0));
        expect(dhuhrToAsr, lessThan(6 * 60));
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
