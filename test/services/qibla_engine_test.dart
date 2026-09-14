import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/qibla_engine.dart';

/// Direct tests for QiblaEngine — safety-critical geodesy that had zero
/// coverage and was never loaded by any test before Phase 3.
///
/// Reference values: great-circle bearings to the Kaaba (21.4225N, 39.8262E)
/// computed with the standard atan2 formula (verified against online qibla
/// calculators within ±1°).
void main() {
  group('QiblaEngine.calculateQiblaDirection', () {
    test('from the Kaaba itself is 0°', () {
      final bearing = QiblaEngine.calculateQiblaDirection(
        latitude: 21.4225,
        longitude: 39.8262,
      );
      expect(bearing, closeTo(0, 0.001));
    });

    test('from London ≈ 119° (ESE)', () {
      final bearing = QiblaEngine.calculateQiblaDirection(
        latitude: 51.5074,
        longitude: -0.1278,
      );
      expect(bearing, closeTo(119, 1));
    });

    test('from New York ≈ 58.5° (ENE)', () {
      final bearing = QiblaEngine.calculateQiblaDirection(
        latitude: 40.7128,
        longitude: -74.006,
      );
      expect(bearing, closeTo(58.5, 1));
    });

    test('from Sydney ≈ 277.5° (WNW)', () {
      final bearing = QiblaEngine.calculateQiblaDirection(
        latitude: -33.8688,
        longitude: 151.2093,
      );
      expect(bearing, closeTo(277.5, 1));
    });

    test('is always normalized to [0, 360)', () {
      for (final (lat, lon) in [
        (0.0, 0.0),
        (89.9, 179.9),
        (-89.9, -179.9),
        (45.0, 120.0),
      ]) {
        final b = QiblaEngine.calculateQiblaDirection(latitude: lat, longitude: lon);
        expect(b, greaterThanOrEqualTo(0));
        expect(b, lessThan(360));
      }
    });
  });

  group('QiblaEngine.calculateDistanceToKaaba', () {
    test('from the Kaaba itself is ~0 km', () {
      final d = QiblaEngine.calculateDistanceToKaaba(
        latitude: 21.4225,
        longitude: 39.8262,
      );
      expect(d, lessThan(1));
    });

    test('London ≈ 4,770 km', () {
      final d = QiblaEngine.calculateDistanceToKaaba(
        latitude: 51.5074,
        longitude: -0.1278,
      );
      expect(d, closeTo(4770, 50));
    });

    test('New York ≈ 10,306 km', () {
      final d = QiblaEngine.calculateDistanceToKaaba(
        latitude: 40.7128,
        longitude: -74.006,
      );
      expect(d, closeTo(10306, 100));
    });

    test('never negative', () {
      for (final (lat, lon) in [
        (0.0, 0.0),
        (89.9, 179.9),
        (-89.9, -179.9),
      ]) {
        final d = QiblaEngine.calculateDistanceToKaaba(latitude: lat, longitude: lon);
        expect(d, greaterThanOrEqualTo(0));
        expect(d, lessThan(20050)); // max half-circumference
      }
    });
  });

  group('QiblaEngine.getMagneticDeclination', () {
    test('region lookup: Middle East +2.5°', () {
      expect(QiblaEngine.getMagneticDeclination(latitude: 24.7, longitude: 46.7), 2.5);
    });

    test('region lookup: North Africa +1.5° (Tripoli, outside the ME box)', () {
      expect(QiblaEngine.getMagneticDeclination(latitude: 32.9, longitude: 13.2), 1.5);
    });

    test('region lookup: Europe 0°', () {
      expect(QiblaEngine.getMagneticDeclination(latitude: 51.5, longitude: -0.13), 0);
    });

    test('region lookup: East North America -14°', () {
      expect(QiblaEngine.getMagneticDeclination(latitude: 40.7, longitude: -74), -14);
    });

    test('region lookup: West North America +12°', () {
      expect(QiblaEngine.getMagneticDeclination(latitude: 34, longitude: -118.2), 12);
    });

    test('region lookup: South Asia -1°', () {
      expect(QiblaEngine.getMagneticDeclination(latitude: 24.9, longitude: 67), -1);
    });

    test('region lookup: default 0° outside regions', () {
      expect(QiblaEngine.getMagneticDeclination(latitude: 64.1, longitude: -21.9), 0);
    });
  });

  group('QiblaEngine.correctForDeclination', () {
    test('adds declination and normalizes to [0, 360)', () {
      expect(QiblaEngine.correctForDeclination(magneticHeading: 100, declination: 2.5), 102.5);
      expect(QiblaEngine.correctForDeclination(magneticHeading: 359, declination: 5), 4);
      expect(QiblaEngine.correctForDeclination(magneticHeading: 0, declination: -14), 346);
    });
  });

  group('QiblaEngine.evaluateAccuracy', () {
    test('maps ranges to levels', () {
      expect(QiblaEngine.evaluateAccuracy(-1), CompassAccuracy.unknown);
      expect(QiblaEngine.evaluateAccuracy(0), CompassAccuracy.high);
      expect(QiblaEngine.evaluateAccuracy(5), CompassAccuracy.high);
      expect(QiblaEngine.evaluateAccuracy(6), CompassAccuracy.medium);
      expect(QiblaEngine.evaluateAccuracy(15), CompassAccuracy.medium);
      expect(QiblaEngine.evaluateAccuracy(16), CompassAccuracy.low);
      expect(QiblaEngine.evaluateAccuracy(30), CompassAccuracy.low);
      expect(QiblaEngine.evaluateAccuracy(31), CompassAccuracy.unreliable);
    });
  });

  test('needsCalibration is true only above 15°', () {
    expect(QiblaEngine.needsCalibration(15), isFalse);
    expect(QiblaEngine.needsCalibration(15.1), isTrue);
    expect(QiblaEngine.needsCalibration(40), isTrue);
  });

  group('QiblaEngine alignment helpers', () {
    test('getDeviationFromQibla normalizes to [-180, 180]', () {
      expect(QiblaEngine.getDeviationFromQibla(currentHeading: 100, qiblaDirection: 120), 20);
      expect(QiblaEngine.getDeviationFromQibla(currentHeading: 350, qiblaDirection: 10), 20);
      expect(QiblaEngine.getDeviationFromQibla(currentHeading: 10, qiblaDirection: 350), -20);
      expect(QiblaEngine.getDeviationFromQibla(currentHeading: 180, qiblaDirection: 0), -180);
    });

    test('getAlignment uses tolerance and fixed bands', () {
      expect(
        QiblaEngine.getAlignment(currentHeading: 100, qiblaDirection: 104),
        QiblaAlignment.aligned,
      );
      expect(
        QiblaEngine.getAlignment(currentHeading: 100, qiblaDirection: 110),
        QiblaAlignment.close,
      );
      expect(
        QiblaEngine.getAlignment(currentHeading: 100, qiblaDirection: 130),
        QiblaAlignment.moderate,
      );
      expect(
        QiblaEngine.getAlignment(currentHeading: 100, qiblaDirection: 200),
        QiblaAlignment.far,
      );
    });

    test('getAlignment honors a custom tolerance', () {
      expect(
        QiblaEngine.getAlignment(
          currentHeading: 100,
          qiblaDirection: 108,
          tolerance: 10,
        ),
        QiblaAlignment.aligned,
      );
    });

    test('getRotationDirection handles wrap-around', () {
      expect(
        QiblaEngine.getRotationDirection(currentHeading: 100, qiblaDirection: 103),
        'مُوجَّه',
      );
      expect(
        QiblaEngine.getRotationDirection(currentHeading: 350, qiblaDirection: 10),
        'أدر لليمين',
      );
      expect(
        QiblaEngine.getRotationDirection(currentHeading: 10, qiblaDirection: 350),
        'أدر لليسار',
      );
    });
  });

  group('QiblaEngine formatting', () {
    test('formatDirection covers all eight sectors', () {
      expect(QiblaEngine.formatDirection(0), 'شمال');
      expect(QiblaEngine.formatDirection(45), 'شمال شرق');
      expect(QiblaEngine.formatDirection(90), 'شرق');
      expect(QiblaEngine.formatDirection(135), 'جنوب شرق');
      expect(QiblaEngine.formatDirection(180), 'جنوب');
      expect(QiblaEngine.formatDirection(225), 'جنوب غرب');
      expect(QiblaEngine.formatDirection(270), 'غرب');
      expect(QiblaEngine.formatDirection(315), 'شمال غرب');
      expect(QiblaEngine.formatDirection(360), 'شمال');
      expect(QiblaEngine.formatDirection(-90), 'غرب');
    });

    test('formatDistance switches units by magnitude', () {
      expect(QiblaEngine.formatDistance(0.5), '500 م');
      expect(QiblaEngine.formatDistance(50), '50.0 كم');
      expect(QiblaEngine.formatDistance(4770), '4770 كم');
    });
  });

  group('QiblaResult.calculate', () {
    test('at the Kaaba: ~0°, declination 2.5, ~0 km, north text', () {
      final result = QiblaResult.calculate(latitude: 21.4225, longitude: 39.8262);
      expect(result.trueQiblaDirection, closeTo(0, 0.001));
      expect(result.declination, 2.5);
      expect(result.magneticQiblaDirection, closeTo(357.5, 0.001));
      expect(result.distanceToKaaba, lessThan(1));
      expect(result.directionText, 'شمال');
    });

    test('in London: matches engine values and wraps magnetic correctly', () {
      final result = QiblaResult.calculate(latitude: 51.5074, longitude: -0.1278);
      final expectedTrue = QiblaEngine.calculateQiblaDirection(
        latitude: 51.5074,
        longitude: -0.1278,
      );
      expect(result.trueQiblaDirection, expectedTrue);
      expect(result.magneticQiblaDirection, closeTo(expectedTrue, 0.001));
      expect(result.distanceToKaaba, closeTo(4770, 50));
    });
  });

  group('MosqueMode', () {
    test('defaults are the conservative safety settings', () {
      const mode = MosqueMode();
      expect(mode.enabled, isFalse);
      expect(mode.permanentLock, isTrue);
      expect(mode.ignoreVibrations, isTrue);
      expect(mode.noAutoTimeout, isTrue);
      expect(mode.lockedDirection, 0);
    });

    test('copyWith updates only the given fields', () {
      const mode = MosqueMode();
      final updated = mode.copyWith(enabled: true, lockedDirection: 123);
      expect(updated.enabled, isTrue);
      expect(updated.lockedDirection, 123);
      expect(updated.permanentLock, isTrue);
      expect(updated.ignoreVibrations, isTrue);
      expect(updated.noAutoTimeout, isTrue);
    });
  });

  group('CompassAccuracy / QiblaAlignment extensions', () {
    test('arabicName and icon exist for every level', () {
      for (final level in CompassAccuracy.values) {
        expect(level.arabicName, isNotEmpty);
        expect(level.icon, isNotEmpty);
      }
    });

    test('needsCalibration on accuracy levels', () {
      expect(CompassAccuracy.high.needsCalibration, isFalse);
      expect(CompassAccuracy.medium.needsCalibration, isFalse);
      expect(CompassAccuracy.low.needsCalibration, isTrue);
      expect(CompassAccuracy.unreliable.needsCalibration, isTrue);
    });

    test('alignment messages and isAligned', () {
      expect(QiblaAlignment.aligned.isAligned, isTrue);
      expect(QiblaAlignment.close.isAligned, isFalse);
      expect(QiblaAlignment.far.message, isNotEmpty);
    });
  });
}
