import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';

/// Direct unit tests for SolarCalculator — the safety-critical astronomy
/// extracted from prayer_time_engine.dart in Phase 1. Previously these
/// methods were private and reachable only through the engine; testing them
/// directly pins the math that the changelog records real bugs in
/// (Asr-angle, timezone, high-latitude NaN).
void main() {
  group('SolarCalculator.julianDay', () {
    test('epoch: 2000-01-01 is JD 2451544.5 (00:00 UTC)', () {
      // The Fliegel–Van Flandern variant used here yields the JD at
      // local midnight; 2000-01-01 12:00 UTC is the standard 2451545.0.
      expect(SolarCalculator.julianDay(DateTime(2000)), 2451544.5);
    });

    test('is strictly increasing over consecutive days', () {
      final a = SolarCalculator.julianDay(DateTime(2026, 3, 15));
      final b = SolarCalculator.julianDay(DateTime(2026, 3, 16));
      expect(b - a, 1.0);
    });

    test('handles year boundary', () {
      final dec31 = SolarCalculator.julianDay(DateTime(2025, 12, 31));
      final jan1 = SolarCalculator.julianDay(DateTime(2026));
      expect(jan1 - dec31, 1.0);
    });
  });

  group('SolarCalculator.sunDeclination', () {
    test('near zero at the March equinox', () {
      // 2026 March equinox: 2026-03-20 14:46 UTC.
      final dec = SolarCalculator.sunDeclination(
        SolarCalculator.julianDay(DateTime(2026, 3, 20)),
      );
      expect(dec.abs(), lessThan(1));
    });

    test('≈ +23.44° at the June solstice', () {
      final dec = SolarCalculator.sunDeclination(
        SolarCalculator.julianDay(DateTime(2026, 6, 21)),
      );
      expect(dec, closeTo(23.44, 0.15));
    });

    test('≈ -23.44° at the December solstice', () {
      final dec = SolarCalculator.sunDeclination(
        SolarCalculator.julianDay(DateTime(2026, 12, 21)),
      );
      expect(dec, closeTo(-23.44, 0.15));
    });

    test('within ±23.5° for the whole year', () {
      for (var day = 1; day <= 365; day += 7) {
        final dec = SolarCalculator.sunDeclination(
          SolarCalculator.julianDay(DateTime(2026).add(Duration(days: day))),
        );
        expect(dec.abs(), lessThan(23.5));
      }
    });
  });

  group('SolarCalculator.equationOfTime', () {
    test('≈ -14 minutes in mid-February', () {
      final eot = SolarCalculator.equationOfTime(
        SolarCalculator.julianDay(DateTime(2026, 2, 13)),
      );
      expect(eot, closeTo(-14.2, 2.5));
    });

    test('≈ +16 minutes in early November', () {
      final eot = SolarCalculator.equationOfTime(
        SolarCalculator.julianDay(DateTime(2026, 11, 3)),
      );
      expect(eot, closeTo(16.4, 2.5));
    });
  });

  group('SolarCalculator.sunAngleTime', () {
    final date = DateTime(2026, 6, 15);
    final dhuhr = SolarCalculator.dhuhrTime(
      39.8262,
      SolarCalculator.equationOfTime(SolarCalculator.julianDay(date)),
      date,
      3,
    );

    test('morning and afternoon times mirror around solar noon', () {
      final decl = SolarCalculator.sunDeclination(SolarCalculator.julianDay(date));
      final morning = SolarCalculator.sunAngleTime(
        21.4225, decl, -0.833, dhuhr, isAfternoon: false,
      );
      final afternoon = SolarCalculator.sunAngleTime(
        21.4225, decl, -0.833, dhuhr, isAfternoon: true,
      );
      final noon = DateTime(dhuhr.year, dhuhr.month, dhuhr.day, dhuhr.hour, dhuhr.minute);
      final morningDelta = noon.difference(morning).inMinutes;
      final afternoonDelta = afternoon.difference(noon).inMinutes;
      expect((morningDelta - afternoonDelta).abs(), lessThanOrEqualTo(1));
    });

    test('never returns NaN at high latitude (clamped acos domain)', () {
      final decl = SolarCalculator.sunDeclination(
        SolarCalculator.julianDay(DateTime(2026, 12, 21)),
      );
      final polar = SolarCalculator.sunAngleTime(
        71, decl, -18, dhuhr, isAfternoon: false,
      );
      expect(polar.isBefore(DateTime(2200)), isTrue);
    });

    test('returns DateTime on the same day as dhuhr', () {
      final decl = SolarCalculator.sunDeclination(SolarCalculator.julianDay(date));
      final t = SolarCalculator.sunAngleTime(
        21.4225, decl, -18, dhuhr, isAfternoon: false,
      );
      expect(t.year, dhuhr.year);
      expect(t.month, dhuhr.month);
      expect(t.day, dhuhr.day);
    });
  });

  group('SolarCalculator.asrTime', () {
    test('Hanafi Asr is strictly later than Shafi', () {
      final date = DateTime(2026, 6, 15);
      final dhuhr = SolarCalculator.dhuhrTime(
        28.9784,
        SolarCalculator.equationOfTime(SolarCalculator.julianDay(date)),
        date,
        3,
      );
      final decl = SolarCalculator.sunDeclination(SolarCalculator.julianDay(date));
      final shafi = SolarCalculator.asrTime(41.0082, decl, dhuhr, Madhab.shafi);
      final hanafi = SolarCalculator.asrTime(41.0082, decl, dhuhr, Madhab.hanafi);
      expect(shafi.isBefore(hanafi), isTrue);
    });

    test('Asr is after dhuhr and before sunset', () {
      final date = DateTime(2026, 6, 15);
      final dhuhr = SolarCalculator.dhuhrTime(
        28.9784,
        SolarCalculator.equationOfTime(SolarCalculator.julianDay(date)),
        date,
        3,
      );
      final decl = SolarCalculator.sunDeclination(SolarCalculator.julianDay(date));
      final asr = SolarCalculator.asrTime(41.0082, decl, dhuhr, Madhab.shafi);
      final maghrib = SolarCalculator.sunAngleTime(
        41.0082, decl, -0.833, dhuhr, isAfternoon: true,
      );
      expect(dhuhr.isBefore(asr), isTrue);
      expect(asr.isBefore(maghrib), isTrue);
    });
  });

  group('SolarCalculator.applyHighLatitudeRule', () {
    final fajr = DateTime(2026, 6, 15, 2);
    final sunrise = DateTime(2026, 6, 15, 6);
    final dhuhr = DateTime(2026, 6, 15, 12);
    final asr = DateTime(2026, 6, 15, 15);
    final maghrib = DateTime(2026, 6, 15, 18);
    final isha = DateTime(2026, 6, 15, 20);

    test('returns times unchanged when valid (fajr < sunrise, isha > maghrib)', () {
      final result = SolarCalculator.applyHighLatitudeRule(
        HighLatitudeRule.middleOfNight,
        fajr: fajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
      );
      expect(result.fajr, fajr);
      expect(result.sunrise, sunrise);
      expect(result.dhuhr, dhuhr);
      expect(result.asr, asr);
      expect(result.maghrib, maghrib);
      expect(result.isha, isha);
    });

    test('middleOfNight places fajr/isha at equal distance from the night edges', () {
      // Force invalid times so the rule applies (fajr after sunrise).
      final badFajr = DateTime(2026, 6, 15, 7);
      final result = SolarCalculator.applyHighLatitudeRule(
        HighLatitudeRule.middleOfNight,
        fajr: badFajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
      );
      final nightMinutes = sunrise.difference(maghrib.subtract(const Duration(days: 1))).inMinutes;
      final half = nightMinutes ~/ 2;
      expect(result.fajr, sunrise.subtract(Duration(minutes: half)));
      expect(result.isha, maghrib.add(Duration(minutes: half)));
    });

    test('seventhOfNight uses one seventh of the night', () {
      final badFajr = DateTime(2026, 6, 15, 7);
      final result = SolarCalculator.applyHighLatitudeRule(
        HighLatitudeRule.seventhOfNight,
        fajr: badFajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
      );
      final nightMinutes = sunrise.difference(maghrib.subtract(const Duration(days: 1))).inMinutes;
      final seventh = nightMinutes ~/ 7;
      expect(result.fajr, sunrise.subtract(Duration(minutes: seventh)));
      expect(result.isha, maghrib.add(Duration(minutes: seventh)));
    });
  });

  group('SolarCalculator.applyAdjustments', () {
    final base = PrayerTimes(
      fajr: DateTime(2026, 6, 15, 4),
      sunrise: DateTime(2026, 6, 15, 5, 30),
      dhuhr: DateTime(2026, 6, 15, 12),
      asr: DateTime(2026, 6, 15, 15, 30),
      maghrib: DateTime(2026, 6, 15, 19),
      isha: DateTime(2026, 6, 15, 20, 30),
      date: DateTime(2026, 6, 15),
    );

    test('null adjustments return the same times', () {
      final result = SolarCalculator.applyAdjustments(base, null);
      expect(result, same(base));
    });

    test('adds minutes per prayer and preserves the date', () {
      final result = SolarCalculator.applyAdjustments(
        base,
        const PrayerAdjustments(fajr: 2, maghrib: -1, isha: 5),
      );
      expect(result.fajr, DateTime(2026, 6, 15, 4, 2));
      expect(result.sunrise, base.sunrise);
      expect(result.maghrib, DateTime(2026, 6, 15, 18, 59));
      expect(result.isha, DateTime(2026, 6, 15, 20, 35));
      expect(result.date, base.date);
    });
  });

  group('SolarCalculator math helpers', () {
    test('sin/cos/tan of known angles', () {
      expect(SolarCalculator.sinDeg(30), closeTo(0.5, 1e-9));
      expect(SolarCalculator.cosDeg(60), closeTo(0.5, 1e-9));
      expect(SolarCalculator.tanDeg(45), closeTo(1.0, 1e-9));
    });

    test('inverse functions invert the forward ones', () {
      expect(SolarCalculator.arcsin(0.5), closeTo(30, 1e-9));
      expect(SolarCalculator.arccos(0.5), closeTo(60, 1e-9));
      expect(SolarCalculator.arccot(1), closeTo(45, 1e-9));
    });

    test('toDateTime converts fractional hours to wall clock', () {
      expect(SolarCalculator.toDateTime(DateTime(2026), 5.5), DateTime(2026, 1, 1, 5, 30));
      expect(SolarCalculator.toDateTime(DateTime(2026), 12.25), DateTime(2026, 1, 1, 12, 15));
      expect(SolarCalculator.toDateTime(DateTime(2026), 0), DateTime(2026));
    });
  });
}
