import 'package:adhan/adhan.dart' as adhan;
import '../../features/prayer/domain/entities/prayer_entities.dart';

/// خدمة حساب مواقيت الصلاة - Prayer Calculation Service
class PrayerCalculationService {
  /// Calculate prayer times for a specific date and location
  DailyPrayerTimes calculatePrayerTimes({
    required DateTime date,
    required Location location,
    CalculationMethod method = CalculationMethod.ummAlQura,
  }) {
    final coordinates = adhan.Coordinates(
      location.latitude,
      location.longitude,
    );

    final params = _getCalculationParameters(method);
    final dateComponents = adhan.DateComponents.from(date);
    final prayerTimes = adhan.PrayerTimes(coordinates, dateComponents, params);

    final now = DateTime.now();

    return DailyPrayerTimes(
      date: date,
      fajr: PrayerTime(
        name: 'Fajr',
        nameArabic: 'الفجر',
        time: prayerTimes.fajr,
        isPassed: prayerTimes.fajr.isBefore(now),
        isNext: _isNextPrayer(prayerTimes.fajr, now, prayerTimes),
      ),
      sunrise: PrayerTime(
        name: 'Sunrise',
        nameArabic: 'الشروق',
        time: prayerTimes.sunrise,
        isPassed: prayerTimes.sunrise.isBefore(now),
        isNext: _isNextPrayer(prayerTimes.sunrise, now, prayerTimes),
      ),
      dhuhr: PrayerTime(
        name: 'Dhuhr',
        nameArabic: 'الظهر',
        time: prayerTimes.dhuhr,
        isPassed: prayerTimes.dhuhr.isBefore(now),
        isNext: _isNextPrayer(prayerTimes.dhuhr, now, prayerTimes),
      ),
      asr: PrayerTime(
        name: 'Asr',
        nameArabic: 'العصر',
        time: prayerTimes.asr,
        isPassed: prayerTimes.asr.isBefore(now),
        isNext: _isNextPrayer(prayerTimes.asr, now, prayerTimes),
      ),
      maghrib: PrayerTime(
        name: 'Maghrib',
        nameArabic: 'المغرب',
        time: prayerTimes.maghrib,
        isPassed: prayerTimes.maghrib.isBefore(now),
        isNext: _isNextPrayer(prayerTimes.maghrib, now, prayerTimes),
      ),
      isha: PrayerTime(
        name: 'Isha',
        nameArabic: 'العشاء',
        time: prayerTimes.isha,
        isPassed: prayerTimes.isha.isBefore(now),
        isNext: _isNextPrayer(prayerTimes.isha, now, prayerTimes),
      ),
      location: location,
      method: method,
    );
  }

  /// Get time remaining until next prayer
  Duration? getTimeUntilNextPrayer(DailyPrayerTimes times) {
    final nextPrayer = times.nextPrayer;
    if (nextPrayer == null) return null;

    return nextPrayer.time.difference(DateTime.now());
  }

  /// Format time remaining in Arabic
  String formatTimeRemaining(Duration duration) {
    if (duration.isNegative) return '';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return 'بعد $hours ساعة و $minutes دقيقة';
    } else {
      return 'بعد $minutes دقيقة';
    }
  }

  adhan.CalculationParameters _getCalculationParameters(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.muslimWorldLeague:
        return adhan.CalculationMethod.muslim_world_league.getParameters();
      case CalculationMethod.ummAlQura:
        return adhan.CalculationMethod.umm_al_qura.getParameters();
      case CalculationMethod.egyptian:
        return adhan.CalculationMethod.egyptian.getParameters();
      case CalculationMethod.isna:
        return adhan.CalculationMethod.north_america.getParameters();
      case CalculationMethod.karachi:
        return adhan.CalculationMethod.karachi.getParameters();
      case CalculationMethod.tehran:
        return adhan.CalculationMethod.tehran.getParameters();
      case CalculationMethod.gulf:
        return adhan.CalculationMethod.dubai.getParameters();
      case CalculationMethod.kuwait:
        return adhan.CalculationMethod.kuwait.getParameters();
      case CalculationMethod.qatar:
        return adhan.CalculationMethod.qatar.getParameters();
      case CalculationMethod.singapore:
        return adhan.CalculationMethod.singapore.getParameters();
    }
  }

  bool _isNextPrayer(DateTime prayerTime, DateTime now, adhan.PrayerTimes times) {
    if (prayerTime.isBefore(now)) return false;

    final allTimes = [
      times.fajr,
      times.sunrise,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];

    for (final time in allTimes) {
      if (time.isAfter(now)) {
        return time == prayerTime;
      }
    }
    return false;
  }
}
