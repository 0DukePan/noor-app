import 'package:dartz/dartz.dart';
import '../entities/prayer_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

/// مستودع الصلاة - Prayer Repository Interface
abstract class PrayerRepository {
  /// Get prayer times for a specific date and location
  Future<Either<Failure, DailyPrayerTimes>> getPrayerTimes({
    required DateTime date,
    required Location location,
    CalculationMethod method = CalculationMethod.ummAlQura,
  });

  /// Get prayer times for date range
  Future<Either<Failure, List<DailyPrayerTimes>>> getPrayerTimesRange({
    required DateTime startDate,
    required DateTime endDate,
    required Location location,
    CalculationMethod method = CalculationMethod.ummAlQura,
  });

  /// Save user's preferred location
  Future<Either<Failure, void>> savePreferredLocation(Location location);

  /// Get user's preferred location
  Future<Either<Failure, Location?>> getPreferredLocation();

  /// Save preferred calculation method
  Future<Either<Failure, void>> saveCalculationMethod(CalculationMethod method);

  /// Get preferred calculation method
  Future<Either<Failure, CalculationMethod>> getPreferredCalculationMethod();
}

/// مستودع القبلة - Qibla Repository Interface
abstract class QiblaRepository {
  /// Calculate Qibla direction from location
  Future<Either<Failure, double>> calculateQiblaDirection(Location location);

  /// Calculate distance to Kaaba
  Future<Either<Failure, double>> calculateDistanceToKaaba(Location location);

  /// Save locked Qibla direction
  Future<Either<Failure, void>> saveLockedDirection(double direction);

  /// Get last locked direction
  Future<Either<Failure, double?>> getLockedDirection();
}

/// مستودع القضاء - Qada Repository Interface
abstract class QadaRepository {
  /// Create new Qada record
  Future<Either<Failure, QadaRecord>> createQadaRecord({
    required QadaType type,
    required int totalCount,
    String? notes,
  });

  /// Get all Qada records
  Future<Either<Failure, List<QadaRecord>>> getAllQadaRecords();

  /// Get Qada records by type
  Future<Either<Failure, List<QadaRecord>>> getQadaRecordsByType(QadaType type);

  /// Update Qada progress
  Future<Either<Failure, void>> updateQadaProgress({
    required String recordId,
    required int completedCount,
  });

  /// Delete Qada record
  Future<Either<Failure, void>> deleteQadaRecord(String id);
}
