import 'package:dartz/dartz.dart';
import '../entities/adhkar_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

/// مستودع الأذكار - Adhkar Repository Interface
abstract class AdhkarRepository {
  /// Get all adhkar collections
  Future<Either<Failure, List<AdhkarCollection>>> getAllCollections();

  /// Get adhkar by category
  Future<Either<Failure, AdhkarCollection>> getAdhkarByCategory(DhikrCategory category);

  /// Get adhkar by mood
  Future<Either<Failure, List<Dhikr>>> getAdhkarByMood(MoodType mood);

  /// Get daily suggested adhkar
  Future<Either<Failure, List<Dhikr>>> getDailySuggestions();

  /// Save dhikr progress
  Future<Either<Failure, void>> saveDhikrProgress(DhikrProgress progress);

  /// Get dhikr progress for today
  Future<Either<Failure, List<DhikrProgress>>> getTodayProgress();

  /// Get dhikr completion history
  Future<Either<Failure, List<DhikrProgress>>> getProgressHistory({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Reset today's progress
  Future<Either<Failure, void>> resetTodayProgress();
}

/// مستودع السبحة - Tasbeeh Repository Interface
abstract class TasbeehRepository {
  /// Save tasbeeh settings
  Future<Either<Failure, void>> saveTasbeehSettings(TasbeehSettings settings);

  /// Get tasbeeh settings
  Future<Either<Failure, TasbeehSettings?>> getTasbeehSettings();

  /// Save tasbeeh session
  Future<Either<Failure, void>> saveTasbeehSession({
    required String dhikr,
    required int count,
    required DateTime timestamp,
  });

  /// Get tasbeeh history
  Future<Either<Failure, List<({String dhikr, int count, DateTime timestamp})>>>
      getTasbeehHistory({int limit = 10});

  /// Get total tasbeeh count for a dhikr
  Future<Either<Failure, int>> getTotalCountForDhikr(String dhikr);
}
