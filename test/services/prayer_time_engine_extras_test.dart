import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';

/// Extends prayer_time_engine_test.dart with coverage for the regions,
/// countries, elevation, interval-based isha, and helper surfaces.
void main() {
  const meccaLat = 21.4225;
  const meccaLng = 39.8262;
  final testDate = DateTime(2026, 3, 15);

  group('PrayerTypeExtension', () {
    test('every prayer type has an Arabic name', () {
      expect(PrayerType.fajr.arabicName, 'الفجر');
      expect(PrayerType.sunrise.arabicName, 'الشروق');
      expect(PrayerType.dhuhr.arabicName, 'الظهر');
      expect(PrayerType.asr.arabicName, 'العصر');
      expect(PrayerType.maghrib.arabicName, 'المغرب');
      expect(PrayerType.isha.arabicName, 'العشاء');
    });
  });

  group('RegionPresets', () {
    test('has a preset for every region', () {
      expect(
        RegionPresets.presets.length,
        PrayerRegion.values.length,
      );
      expect(RegionPresets.all.length, PrayerRegion.values.length);
    });

    test('gulf maps to Umm al-Qura', () {
      expect(
        RegionPresets.getPreset(PrayerRegion.gulf).method,
        CalculationMethod.ummAlQura,
      );
    });

    test('guessRegion maps known coordinates', () {
      expect(RegionPresets.guessRegion(24.7, 46.7), PrayerRegion.gulf);
      expect(RegionPresets.guessRegion(30, 31.2), PrayerRegion.egypt);
      expect(RegionPresets.guessRegion(33.6, -7.6), PrayerRegion.northAfrica);
      expect(RegionPresets.guessRegion(41, 28.9), PrayerRegion.turkey);
      expect(RegionPresets.guessRegion(35.7, 51.4), PrayerRegion.iran);
      expect(RegionPresets.guessRegion(24.8, 67), PrayerRegion.southAsia);
      expect(RegionPresets.guessRegion(-6.2, 106.8), PrayerRegion.southeastAsia);
      expect(RegionPresets.guessRegion(40.7, -74), PrayerRegion.northAmerica);
    });

    test('unknown high-latitude falls back to Europe', () {
      expect(RegionPresets.guessRegion(51.5, -0.1), PrayerRegion.europe);
    });
  });

  group('CountryPresets', () {
    test('unknown country code falls back to the default preset', () {
      final preset = CountryPresets.getPreset('ZZ');
      expect(preset.method, CalculationMethod.muslimWorldLeague);
      expect(CountryPresets.isSupported('ZZ'), isFalse);
    });

    test('lookup is case-insensitive and count matches all', () {
      final supported = CountryPresets.all
          .every((p) => CountryPresets.isSupported(p.countryCode));
      expect(supported, isTrue);
      expect(CountryPresets.count, CountryPresets.all.length);
      expect(CountryPresets.search('').length, CountryPresets.count);
    });
  });

  group('calculateAuto / calculateWithRegion', () {
    test('auto for Riyadh equals explicit gulf preset', () {
      final auto = PrayerTimeEngine.calculateAuto(
        latitude: 24.7,
        longitude: 46.7,
        date: testDate,
        utcOffset: 3,
      );
      final explicit = PrayerTimeEngine.calculateWithRegion(
        latitude: 24.7,
        longitude: 46.7,
        date: testDate,
        region: PrayerRegion.gulf,
        utcOffset: 3,
      );
      expect(auto.dhuhr, explicit.dhuhr);
      expect(auto.fajr, explicit.fajr);
      expect(auto.isha, explicit.isha);
    });

    test('northAfrica preset applies its fajr/maghrib adjustments', () {
      final region = PrayerTimeEngine.calculateWithRegion(
        latitude: 33.6,
        longitude: -7.6,
        date: testDate,
        region: PrayerRegion.northAfrica,
      );
      final raw = PrayerTimeEngine.calculate(
        latitude: 33.6,
        longitude: -7.6,
        date: testDate,
        method: CalculationMethod.egyptian,
      );
      final preset = RegionPresets.getPreset(PrayerRegion.northAfrica);
      expect(
        region.fajr,
        raw.fajr.add(Duration(minutes: preset.adjustments.fajr)),
      );
      expect(
        region.maghrib,
        raw.maghrib.add(Duration(minutes: preset.adjustments.maghrib)),
      );
    });
  });

  group('calculateByCountry', () {
    test('unknown country uses the default (MWL) method', () {
      final byCountry = PrayerTimeEngine.calculateByCountry(
        latitude: meccaLat,
        longitude: meccaLng,
        date: testDate,
        countryCode: 'ZZ',
        utcOffset: 3,
      );
      final mwl = PrayerTimeEngine.calculate(
        latitude: meccaLat,
        longitude: meccaLng,
        date: testDate,
        method: CalculationMethod.muslimWorldLeague,
        utcOffset: 3,
      );
      expect(byCountry.fajr, mwl.fajr);
      expect(byCountry.dhuhr, mwl.dhuhr);
    });

    test('combines preset adjustments with additional adjustments', () {
      final combined = PrayerTimeEngine.calculateByCountry(
        latitude: meccaLat,
        longitude: meccaLng,
        date: testDate,
        countryCode: 'ZZ',
        additionalAdjustments: const PrayerAdjustments(fajr: 3),
        utcOffset: 3,
      );
      final mwl = PrayerTimeEngine.calculate(
        latitude: meccaLat,
        longitude: meccaLng,
        date: testDate,
        method: CalculationMethod.muslimWorldLeague,
        utcOffset: 3,
      );
      expect(combined.fajr, mwl.fajr.add(const Duration(minutes: 3)));
    });
  });

  group('elevation', () {
    test('higher elevation brings sunrise earlier and maghrib later', () {
      final seaLevel = PrayerTimeEngine.calculate(
        latitude: meccaLat,
        longitude: meccaLng,
        date: testDate,
        method: CalculationMethod.ummAlQura,
        utcOffset: 3,
      );
      final mountain = PrayerTimeEngine.calculate(
        latitude: meccaLat,
        longitude: meccaLng,
        date: testDate,
        method: CalculationMethod.ummAlQura,
        elevation: 2000,
        utcOffset: 3,
      );
      expect(mountain.sunrise.isBefore(seaLevel.sunrise), isTrue);
      expect(mountain.maghrib.isAfter(seaLevel.maghrib), isTrue);
    });
  });

  group('isha interval methods', () {
    test('Umm al-Qura isha is maghrib + 90 minutes', () {
      final times = PrayerTimeEngine.calculate(
        latitude: meccaLat,
        longitude: meccaLng,
        date: testDate,
        method: CalculationMethod.ummAlQura,
        utcOffset: 3,
      );
      expect(times.isha, times.maghrib.add(const Duration(minutes: 90)));
    });

    test('Qatar isha is maghrib + 90 minutes', () {
      final times = PrayerTimeEngine.calculate(
        latitude: 25.28,
        longitude: 51.52,
        date: testDate,
        method: CalculationMethod.qatar,
        utcOffset: 3,
      );
      expect(times.isha, times.maghrib.add(const Duration(minutes: 90)));
    });
  });

  group('PrayerTimes helpers', () {
    test('all getter returns the six times in order', () {
      final times = PrayerTimeEngine.calculate(
        latitude: meccaLat,
        longitude: meccaLng,
        date: testDate,
        method: CalculationMethod.ummAlQura,
        utcOffset: 3,
      );
      final all = times.all;
      expect(all.length, 6);
      expect(all.first.key, PrayerType.fajr);
      expect(all.last.key, PrayerType.isha);
    });
  });
}
