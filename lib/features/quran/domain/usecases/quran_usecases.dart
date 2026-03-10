import 'package:dartz/dartz.dart';
import '../entities/quran_entities.dart';
import '../repositories/quran_repository.dart';

/// حالة استخدام - الحصول على السور
class GetAllSurahsUseCase {
  final QuranRepository repository;

  GetAllSurahsUseCase(this.repository);

  Future<Either<Failure, List<Surah>>> call() {
    return repository.getAllSurahs();
  }
}

/// حالة استخدام - الحصول على سورة مع آياتها
class GetSurahWithVersesUseCase {
  final QuranRepository repository;

  GetSurahWithVersesUseCase(this.repository);

  Future<Either<Failure, Surah>> call(int surahNumber) {
    return repository.getSurahWithVerses(surahNumber);
  }
}

/// حالة استخدام - الحصول على التفسير
class GetTafsirUseCase {
  final QuranRepository repository;

  GetTafsirUseCase(this.repository);

  Future<Either<Failure, Tafsir>> call({
    required int surahNumber,
    required int verseNumber,
    String? tafsirSource,
  }) {
    return repository.getTafsir(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      tafsirSource: tafsirSource,
    );
  }
}

/// حالة استخدام - الحصول على سبب النزول
class GetRevelationCauseUseCase {
  final QuranRepository repository;

  GetRevelationCauseUseCase(this.repository);

  Future<Either<Failure, RevelationCause?>> call({
    required int surahNumber,
    required int verseNumber,
  }) {
    return repository.getRevelationCause(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
    );
  }
}

/// حالة استخدام - حفظ موضع القراءة
class SaveReadingProgressUseCase {
  final QuranRepository repository;

  SaveReadingProgressUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required int surahNumber,
    required int verseNumber,
    required int page,
  }) {
    return repository.saveReadingProgress(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      page: page,
    );
  }
}

/// حالة استخدام - البحث في القرآن
class SearchQuranUseCase {
  final QuranRepository repository;

  SearchQuranUseCase(this.repository);

  Future<Either<Failure, List<Verse>>> call(String query) {
    if (query.trim().isEmpty) {
      return Future.value(const Right([]));
    }
    return repository.searchQuran(query);
  }
}

/// حالة استخدام - حفظ التدبر (مشفر)
class SaveTadabburUseCase {
  final TadabburRepository repository;

  SaveTadabburUseCase(this.repository);

  Future<Either<Failure, void>> call(Tadabbur tadabbur) {
    return repository.saveTadabbur(tadabbur);
  }
}

/// حالة استخدام - الحصول على تدبر الآية
class GetVerseTadabburUseCase {
  final TadabburRepository repository;

  GetVerseTadabburUseCase(this.repository);

  Future<Either<Failure, List<Tadabbur>>> call({
    required int surahNumber,
    required int verseNumber,
  }) {
    return repository.getTadabburForVerse(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
    );
  }
}
