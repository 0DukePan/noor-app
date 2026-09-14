import 'dart:math';

import 'prayer_time_models.dart';

/// Pure solar math behind the prayer engine - prayer_solar_calculator.dart
///
/// Extracted from prayer_time_engine.dart (Phase 1 god-file split) so the
/// safety-critical astronomy is directly unit-testable instead of private
/// methods reachable only through PrayerTimeEngine.calculate.
class SolarCalculator {
  SolarCalculator._();

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // JULIAN DAY & SOLAR POSITION
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static double julianDay(DateTime date) {
    var year = date.year;
    var month = date.month;
    final d = date.day;

    // ØªØµØ­ÙŠØ­ Ø§Ù„Ø´Ù‡Ø± (Ø¨Ø¯ÙˆÙ† recursion)
    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();

    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        d +
        b -
        1524.5;
  }

  static double sunDeclination(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final l0 = 280.46646 + t * (36000.76983 + 0.0003032 * t);
    final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);

    final c = (1.914602 - t * (0.004817 + 0.000014 * t)) * sinDeg(m) +
        (0.019993 - 0.000101 * t) * sinDeg(2 * m) +
        0.000289 * sinDeg(3 * m);

    final sunLong = l0 + c;
    final omega = 125.04 - 1934.136 * t;
    final lambda = sunLong - 0.00569 - 0.00478 * sinDeg(omega);

    final eps0 =
        23.439291 - t * (0.013004167 + t * (0.00000016389 - t * 0.0000005036));
    final eps = eps0 + 0.00256 * cosDeg(omega);

    return arcsin(sinDeg(eps) * sinDeg(lambda));
  }

  static double equationOfTime(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final l0 = 280.46646 + t * (36000.76983 + 0.0003032 * t);
    final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

    var y = tanDeg(23.439291 / 2);
    y *= y;

    final eqTime = y * sinDeg(2 * l0) -
        2 * e * sinDeg(m) +
        4 * e * y * sinDeg(m) * cosDeg(2 * l0) -
        0.5 * y * y * sinDeg(4 * l0) -
        1.25 * e * e * sinDeg(2 * m);

    // The equation above sums radian-unit terms; convert to degrees (Ã—180/Ï€)
    // and then to minutes (Ã—4). The 180/Ï€ factor was missing, shifting every
    // prayer time by up to ~16 minutes (found 2026-08-18 by direct
    // SolarCalculator tests; see CHANGELOG).
    return eqTime * 4 * 180 / pi;
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PRAYER TIME CALCULATIONS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static DateTime dhuhrTime(
      double longitude, double eqTime, DateTime date, double utcOffset,) {
    // Solar noon in UTC is at 12:00 - longitude/15 - equationOfTime/60.
    // Add the civil UTC offset to obtain the local wall-clock time.
    final noon = 12 - longitude / 15 - eqTime / 60 + utcOffset;
    return toDateTime(date, noon);
  }

  static DateTime sunAngleTime(
    double latitude,
    double declination,
    double angle,
    DateTime dhuhr, {
    required bool isAfternoon,
  }) {
    // Guard against floating-point drift pushing the cosine ratio outside
    // [-1, 1] (which would make acos() return NaN at high latitudes).
    final ratio = ((sinDeg(angle) - sinDeg(latitude) * sinDeg(declination)) /
            (cosDeg(latitude) * cosDeg(declination)))
        .clamp(-1.0, 1.0);
    final hourAngle = arccos(ratio) / 15;

    if (isAfternoon) {
      return dhuhr.add(Duration(minutes: (hourAngle * 60).round()));
    } else {
      return dhuhr.subtract(Duration(minutes: (hourAngle * 60).round()));
    }
  }

  static DateTime asrTime(
    double latitude,
    double declination,
    DateTime dhuhr,
    Madhab madhab,
  ) {
    final shadowLength = madhab == Madhab.hanafi ? 2 : 1;
    // Asr is an ABOVE-horizon event: the sun altitude angle is positive.
    // (A negative angle would place Asr below the horizon, pushing it after
    // sunset and producing out-of-domain hour angles at higher latitudes.)
    final angle = arccot(shadowLength + tanDeg((latitude - declination).abs()));

    return sunAngleTime(latitude, declination, angle, dhuhr, isAfternoon: true);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // HIGH LATITUDE ADJUSTMENTS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static PrayerTimes applyHighLatitudeRule(
    HighLatitudeRule rule, {
    required DateTime fajr,
    required DateTime sunrise,
    required DateTime dhuhr,
    required DateTime asr,
    required DateTime maghrib,
    required DateTime isha,
  }) {
    // If times are valid, no adjustment needed
    if (fajr.isBefore(sunrise) && isha.isAfter(maghrib)) {
      return PrayerTimes(
        fajr: fajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        date: dhuhr,
      );
    }

    final nightDuration =
        sunrise.difference(maghrib.subtract(const Duration(days: 1)));

    switch (rule) {
      case HighLatitudeRule.middleOfNight:
        final halfNight = nightDuration.inMinutes ~/ 2;
        return PrayerTimes(
          fajr: sunrise.subtract(Duration(minutes: halfNight)),
          sunrise: sunrise,
          dhuhr: dhuhr,
          asr: asr,
          maghrib: maghrib,
          isha: maghrib.add(Duration(minutes: halfNight)),
          date: dhuhr,
        );

      case HighLatitudeRule.seventhOfNight:
        final seventh = nightDuration.inMinutes ~/ 7;
        return PrayerTimes(
          fajr: sunrise.subtract(Duration(minutes: seventh)),
          sunrise: sunrise,
          dhuhr: dhuhr,
          asr: asr,
          maghrib: maghrib,
          isha: maghrib.add(Duration(minutes: seventh)),
          date: dhuhr,
        );

      case HighLatitudeRule.twilightAngle:
        // Use twilight angle method
        return PrayerTimes(
          fajr: fajr,
          sunrise: sunrise,
          dhuhr: dhuhr,
          asr: asr,
          maghrib: maghrib,
          isha: isha,
          date: dhuhr,
        );
    }
  }

  static PrayerTimes applyAdjustments(
      PrayerTimes times, PrayerAdjustments? adj,) {
    if (adj == null) return times;

    return PrayerTimes(
      fajr: times.fajr.add(Duration(minutes: adj.fajr)),
      sunrise: times.sunrise.add(Duration(minutes: adj.sunrise)),
      dhuhr: times.dhuhr.add(Duration(minutes: adj.dhuhr)),
      asr: times.asr.add(Duration(minutes: adj.asr)),
      maghrib: times.maghrib.add(Duration(minutes: adj.maghrib)),
      isha: times.isha.add(Duration(minutes: adj.isha)),
      date: times.date,
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // MATH HELPERS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static double sinDeg(double deg) => sin(deg * pi / 180);
  static double cosDeg(double deg) => cos(deg * pi / 180);
  static double tanDeg(double deg) => tan(deg * pi / 180);
  static double arcsin(double x) => asin(x) * 180 / pi;
  static double arccos(double x) => acos(x) * 180 / pi;
  static double arccot(double x) => atan(1 / x) * 180 / pi;

  static DateTime toDateTime(DateTime date, double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return DateTime(date.year, date.month, date.day, h, m);
  }
}
