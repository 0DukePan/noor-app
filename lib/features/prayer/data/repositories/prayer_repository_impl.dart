import 'package:dartz/dartz.dart';
import '../../domain/entities/prayer_entities.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../../core/services/services.dart' hide CalculationMethod;

/// تنفيذ مستودع الصلاة - Prayer Repository Implementation
class PrayerRepositoryImpl implements PrayerRepository {
  final PrayerCalculationService calculationService;
  final LocationService locationService;

  PrayerRepositoryImpl({
    required this.calculationService,
    required this.locationService,
  });

  @override
  Future<Either<Failure, DailyPrayerTimes>> getPrayerTimes({
    required DateTime date,
    required Location location,
    CalculationMethod method = CalculationMethod.ummAlQura,
  }) async {
    try {
      final times = calculationService.calculatePrayerTimes(
        date: date,
        location: location,
        method: method,
      );
      return Right(times);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyPrayerTimes>>> getPrayerTimesRange({
    required DateTime startDate,
    required DateTime endDate,
    required Location location,
    CalculationMethod method = CalculationMethod.ummAlQura,
  }) async {
    try {
      final List<DailyPrayerTimes> allTimes = [];
      var currentDate = startDate;

      while (!currentDate.isAfter(endDate)) {
        final times = calculationService.calculatePrayerTimes(
          date: currentDate,
          location: location,
          method: method,
        );
        allTimes.add(times);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return Right(allTimes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePreferredLocation(Location location) async {
    try {
      // Save to Hive
      // await HiveService.saveSetting('preferred_location', {
      //   'latitude': location.latitude,
      //   'longitude': location.longitude,
      //   'city_name': location.cityName,
      //   'country_name': location.countryName,
      // });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Location?>> getPreferredLocation() async {
    try {
      // Try to get from Hive first
      // final saved = HiveService.getSetting<Map>('preferred_location');
      // if (saved != null) {
      //   return Right(Location(
      //     latitude: saved['latitude'],
      //     longitude: saved['longitude'],
      //     cityName: saved['city_name'],
      //     countryName: saved['country_name'],
      //   ));
      // }

      // Fall back to current location
      final currentLocation = await locationService.getCurrentLocation();
      return Right(currentLocation);
    } catch (e) {
      return Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> saveCalculationMethod(CalculationMethod method) async {
    try {
      // await HiveService.saveSetting('calculation_method', method.name);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CalculationMethod>> getPreferredCalculationMethod() async {
    try {
      // final saved = HiveService.getSetting<String>('calculation_method');
      // if (saved != null) {
      //   return Right(CalculationMethod.values.firstWhere(
      //     (m) => m.name == saved,
      //     orElse: () => CalculationMethod.ummAlQura,
      //   ));
      // }
      return const Right(CalculationMethod.ummAlQura);
    } catch (e) {
      return const Right(CalculationMethod.ummAlQura);
    }
  }
}

/// تنفيذ مستودع القبلة - Qibla Repository Implementation
class QiblaRepositoryImpl implements QiblaRepository {
  final CompassService compassService;

  QiblaRepositoryImpl({required this.compassService});

  @override
  Future<Either<Failure, double>> calculateQiblaDirection(Location location) async {
    try {
      final direction = compassService.calculateQiblaDirection(location);
      return Right(direction);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> calculateDistanceToKaaba(Location location) async {
    try {
      final distance = compassService.calculateDistanceToKaaba(location);
      return Right(distance);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveLockedDirection(double direction) async {
    try {
      // await HiveService.saveSetting('locked_qibla_direction', direction);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double?>> getLockedDirection() async {
    try {
      // final direction = HiveService.getSetting<double>('locked_qibla_direction');
      // return Right(direction);
      return const Right(null);
    } catch (e) {
      return Right(null);
    }
  }
}

/// تنفيذ مستودع القضاء - Qada Repository Implementation
class QadaRepositoryImpl implements QadaRepository {
  @override
  Future<Either<Failure, QadaRecord>> createQadaRecord({
    required QadaType type,
    required int totalCount,
    String? notes,
  }) async {
    try {
      final record = QadaRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        totalCount: totalCount,
        completedCount: 0,
        startDate: DateTime.now(),
        notes: notes,
      );
      // await HiveService.saveQadaRecord(record.toJson());
      return Right(record);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QadaRecord>>> getAllQadaRecords() async {
    try {
      // final records = HiveService.getAllQadaRecords();
      // return Right(records.map((r) => QadaRecord.fromJson(r)).toList());
      return const Right([]);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QadaRecord>>> getQadaRecordsByType(QadaType type) async {
    final allRecords = await getAllQadaRecords();
    return allRecords.map(
      (records) => records.where((r) => r.type == type).toList(),
    );
  }

  @override
  Future<Either<Failure, void>> updateQadaProgress({
    required String recordId,
    required int completedCount,
  }) async {
    try {
      // Update in Hive
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteQadaRecord(String id) async {
    try {
      // await HiveService.deleteQadaRecord(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
