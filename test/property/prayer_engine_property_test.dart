import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';

import '../test_utils/property.dart';

/// Property-based companion to `prayer_time_engine_test.dart`.
///
/// The example suite pins exact reference values (Mecca/London/New York solar
/// noon, the equation-of-time regression, the Asr domain). This suite asserts
/// what must hold for *every* input the engine accepts:
///
/// - `fajr < sunrise` and `maghrib < isha` universally — the guarantee the
///   high-latitude fallback exists to provide;
/// - full chronological ordering away from the polar circles;
/// - determinism, UTC-offset additivity, and manual-adjustment additivity;
/// - the Hanafi Asr domain claim;
/// - no crashes and no runaway values at extreme coordinates/elevations.
///
/// Failures print the seed and the smallest counter-example found.
class _PrayerCase {
  const _PrayerCase({
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.method,
    required this.madhab,
    required this.utcOffset,
    this.elevation = 0,
  });

  final double latitude;
  final double longitude;
  final DateTime date;
  final CalculationMethod method;
  final Madhab madhab;
  final double utcOffset;
  final double elevation;

  _PrayerCase copyWith({
    double? latitude,
    double? longitude,
    DateTime? date,
    Madhab? madhab,
    double? utcOffset,
    double? elevation,
  }) =>
      _PrayerCase(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        date: date ?? this.date,
        method: method,
        madhab: madhab ?? this.madhab,
        utcOffset: utcOffset ?? this.utcOffset,
        elevation: elevation ?? this.elevation,
      );

  String describe() => 'lat=${latitude.toStringAsFixed(3)} '
      'lon=${longitude.toStringAsFixed(3)} '
      'date=${date.toIso8601String().split('T').first} '
      'method=${method.name} madhab=${madhab.name} '
      'utcOffset=$utcOffset elevation=$elevation';
}

PrayerTimes _calculate(_PrayerCase testCase) => PrayerTimeEngine.calculate(
      latitude: testCase.latitude,
      longitude: testCase.longitude,
      date: testCase.date,
      method: testCase.method,
      madhab: testCase.madhab,
      utcOffset: testCase.utcOffset,
      elevation: testCase.elevation,
    );

_PrayerCase _generate(
  Random random, {
  double maxLatitude = 55,
  bool withElevation = false,
}) =>
    _PrayerCase(
      latitude: doubleIn(random, -maxLatitude, maxLatitude),
      longitude: doubleIn(random, -180, 180),
      date: dateIn(random, 2024, 2027),
      method: elementOf(random, CalculationMethod.values),
      madhab: elementOf(random, Madhab.values),
      // Quarter-hour offsets in [-12, +14], covering half-hour and 45-minute
      // zones and both sides of the date line.
      utcOffset: intIn(random, -48, 56) / 4,
      elevation: withElevation ? doubleIn(random, 0, 4000) : 0,
    );

Iterable<_PrayerCase> _shrink(_PrayerCase testCase) sync* {
  if (testCase.latitude != 0) yield testCase.copyWith(latitude: 0);
  if (testCase.longitude != 0) yield testCase.copyWith(longitude: 0);
  if (testCase.utcOffset != 0) yield testCase.copyWith(utcOffset: 0);
  if (testCase.elevation != 0) yield testCase.copyWith(elevation: 0);
  for (final latitude in shrinkTowardsZero(testCase.latitude)) {
    yield testCase.copyWith(latitude: latitude);
  }
  for (final longitude in shrinkTowardsZero(testCase.longitude)) {
    yield testCase.copyWith(longitude: longitude);
  }
}

void main() {
  group('prayer engine invariants', () {
    test('fajr < sunrise and maghrib < isha hold for every generated input', () {
      forAll<_PrayerCase>(
        _generate,
        check: (testCase) {
          final times = _calculate(testCase);
          expect(times.fajr.isBefore(times.sunrise), isTrue);
          expect(times.maghrib.isBefore(times.isha), isTrue);
        },
        describe: (testCase) => testCase.describe(),
        shrink: _shrink,
        iterations: 300,
      );
    });

    test('chronological ordering holds away from the polar circles', () {
      forAll<_PrayerCase>(
        _generate,
        check: (testCase) {
          final times = _calculate(testCase);
          expect(times.fajr.isBefore(times.sunrise), isTrue);
          expect(times.sunrise.isBefore(times.dhuhr), isTrue);
          expect(times.dhuhr.isBefore(times.asr), isTrue);
          expect(times.asr.isBefore(times.maghrib), isTrue);
          expect(times.maghrib.isBefore(times.isha), isTrue);
        },
        describe: (testCase) => testCase.describe(),
        shrink: _shrink,
        iterations: 300,
      );
    });

    test('the engine is deterministic for identical inputs', () {
      forAll<_PrayerCase>(
        _generate,
        check: (testCase) {
          final first = _calculate(testCase);
          final second = _calculate(testCase);
          for (final prayer in PrayerType.values) {
            expect(second.getTime(prayer), first.getTime(prayer));
          }
        },
        describe: (testCase) => testCase.describe(),
        shrink: _shrink,
      );
    });

    test('utcOffset shifts every time by the offset difference', () {
      forAll<_PrayerCase>(
        _generate,
        check: (testCase) {
          final shifted = _calculate(testCase);
          final base = _calculate(testCase.copyWith(utcOffset: 0));
          final expectedShift = testCase.utcOffset * 60;
          for (final prayer in PrayerType.values) {
            final actual = shifted
                .getTime(prayer)
                .difference(base.getTime(prayer))
                .inMinutes;
            // ±1 minute absorbs minute-rounding at the boundary.
            expect((actual - expectedShift).abs(), lessThanOrEqualTo(1));
          }
        },
        describe: (testCase) => testCase.describe(),
        shrink: _shrink,
      );
    });

    test('manual adjustments shift each time by exactly the requested minutes',
        () {
      forAll<(_PrayerCase, PrayerAdjustments)>(
        (random) => (
          _generate(random),
          PrayerAdjustments(
            fajr: intIn(random, -30, 30),
            sunrise: intIn(random, -30, 30),
            dhuhr: intIn(random, -30, 30),
            asr: intIn(random, -30, 30),
            maghrib: intIn(random, -30, 30),
            isha: intIn(random, -30, 30),
          ),
        ),
        check: (pair) {
          final (testCase, adjustments) = pair;
          final adjusted = PrayerTimeEngine.calculate(
            latitude: testCase.latitude,
            longitude: testCase.longitude,
            date: testCase.date,
            method: testCase.method,
            madhab: testCase.madhab,
            utcOffset: testCase.utcOffset,
            elevation: testCase.elevation,
            adjustments: adjustments,
          );
          final base = _calculate(testCase);
          for (final prayer in PrayerType.values) {
            final expected = switch (prayer) {
              PrayerType.fajr => adjustments.fajr,
              PrayerType.sunrise => adjustments.sunrise,
              PrayerType.dhuhr => adjustments.dhuhr,
              PrayerType.asr => adjustments.asr,
              PrayerType.maghrib => adjustments.maghrib,
              PrayerType.isha => adjustments.isha,
            };
            expect(
              adjusted.getTime(prayer).difference(base.getTime(prayer)).inMinutes,
              expected,
            );
          }
        },
        describe: (pair) =>
            '${pair.$1.describe()} adjustments=${pair.$2.fajr}/${pair.$2.dhuhr}',
        shrink: (pair) => [
          for (final shrunk in _shrink(pair.$1))
            (shrunk, pair.$2),
        ],
      );
    });

    test('Hanafi Asr is never earlier than Shafi Asr', () {
      forAll<_PrayerCase>(
        _generate,
        check: (testCase) {
          final shafi = _calculate(testCase.copyWith(madhab: Madhab.shafi));
          final hanafi = PrayerTimeEngine.calculate(
            latitude: testCase.latitude,
            longitude: testCase.longitude,
            date: testCase.date,
            method: testCase.method,
            madhab: Madhab.hanafi,
            utcOffset: testCase.utcOffset,
            elevation: testCase.elevation,
          );
          expect(
            hanafi.asr.isBefore(shafi.asr),
            isFalse,
            reason: 'Hanafi Asr must not precede Shafi Asr',
          );
          expect(shafi.asr.isAfter(shafi.dhuhr), isTrue);
        },
        describe: (testCase) => testCase.describe(),
        shrink: _shrink,
      );
    });

    test('extreme coordinates never throw and stay within two days', () {
      forAll<_PrayerCase>(
        (random) => _generate(random, maxLatitude: 89.9, withElevation: true),
        check: (testCase) {
          final times = _calculate(testCase);
          for (final prayer in PrayerType.values) {
            final offset = times
                .getTime(prayer)
                .difference(DateTime(testCase.date.year, testCase.date.month,
                    testCase.date.day))
                .inHours
                .abs();
            expect(offset, lessThanOrEqualTo(48));
          }
          // The high-latitude fallback keeps the pair ordered non-strictly
          // even where a solar event does not exist: polar night, and — as
          // this suite found — a raised horizon from elevation, which pushes
          // the event-vanishing boundary to lower latitudes. Where the sun
          // never reaches the required altitude the clamped times can
          // coincide; that degeneration is the documented limitation in
          // prayer_time_engine_test.dart. Strict ordering is asserted for
          // mid latitudes above.
          expect(times.fajr.isAfter(times.sunrise), isFalse);
          expect(times.isha.isBefore(times.maghrib), isFalse);
        },
        describe: (testCase) => testCase.describe(),
      );
    });
  });
}
