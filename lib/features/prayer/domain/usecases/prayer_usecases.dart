import 'package:dartz/dartz.dart';
import '../entities/prayer_entities.dart';
import '../repositories/prayer_repository.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

/// حالة استخدام - الحصول على مواقيت الصلاة
class GetPrayerTimesUseCase {
  final PrayerRepository repository;

  GetPrayerTimesUseCase(this.repository);

  Future<Either<Failure, DailyPrayerTimes>> call({
    required DateTime date,
    required Location location,
    CalculationMethod? method,
  }) async {
    // Get preferred method if not specified
    final preferredMethod = method ??
        (await repository.getPreferredCalculationMethod())
            .getOrElse(() => CalculationMethod.ummAlQura);

    return repository.getPrayerTimes(
      date: date,
      location: location,
      method: preferredMethod,
    );
  }
}

/// حالة استخدام - الحصول على اتجاه القبلة
class GetQiblaDirectionUseCase {
  final QiblaRepository repository;

  GetQiblaDirectionUseCase(this.repository);

  Future<Either<Failure, QiblaData>> call(Location location) async {
    final directionResult = await repository.calculateQiblaDirection(location);
    final distanceResult = await repository.calculateDistanceToKaaba(location);

    return directionResult.fold(
      (failure) => Left(failure),
      (direction) => distanceResult.fold(
        (failure) => Left(failure),
        (distance) => Right(QiblaData(
          qiblaDirection: direction,
          currentHeading: 0, // Will be updated by compass
          distanceToKaaba: distance,
        )),
      ),
    );
  }
}

/// حالة استخدام - تثبيت اتجاه القبلة
class LockQiblaDirectionUseCase {
  final QiblaRepository repository;

  LockQiblaDirectionUseCase(this.repository);

  Future<Either<Failure, void>> call(double direction) {
    return repository.saveLockedDirection(direction);
  }
}

/// حالة استخدام - إنشاء سجل قضاء
class CreateQadaRecordUseCase {
  final QadaRepository repository;

  CreateQadaRecordUseCase(this.repository);

  Future<Either<Failure, QadaRecord>> call({
    required QadaType type,
    required int totalCount,
    String? notes,
  }) {
    if (totalCount <= 0) {
      return Future.value(
        const Left(ValidationFailure('العدد يجب أن يكون أكبر من صفر')),
      );
    }
    return repository.createQadaRecord(
      type: type,
      totalCount: totalCount,
      notes: notes,
    );
  }
}

/// حالة استخدام - تحديث تقدم القضاء
class UpdateQadaProgressUseCase {
  final QadaRepository repository;

  UpdateQadaProgressUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String recordId,
    required int completedCount,
  }) {
    return repository.updateQadaProgress(
      recordId: recordId,
      completedCount: completedCount,
    );
  }
}
