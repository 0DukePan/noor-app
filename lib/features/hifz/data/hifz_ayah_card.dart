import 'package:noor_app/core/algorithms/fsrs_algorithm.dart';

/// بطاقة حفظ آية — FSRS-based memorization card for a Quran ayah.
///
/// Keyed by `surah:ayah`; the FSRS math mirrors [MemorizationCard] but is
/// scoped to ayahs (Quran hifz) rather than hadiths.
class HifzAyahCard {

  HifzAyahCard({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.arabicText,
    this.difficulty = 5.0,
    this.stability = 1.0,
    DateTime? lastReview,
    DateTime? nextReview,
    this.repetitions = 0,
    this.lapses = 0,
    this.repeatCount = 3,
  })  : lastReview = lastReview ?? DateTime.now(),
        nextReview = nextReview ?? DateTime.now();

  factory HifzAyahCard.fromJson(Map<dynamic, dynamic> json) {
    return HifzAyahCard(
      id: json['id'] as String,
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      arabicText: json['arabicText'] as String? ?? '',
      difficulty: (json['difficulty'] as num).toDouble(),
      stability: (json['stability'] as num).toDouble(),
      lastReview: DateTime.parse(json['lastReview'] as String),
      nextReview: DateTime.parse(json['nextReview'] as String),
      repetitions: json['repetitions'] as int? ?? 0,
      lapses: json['lapses'] as int? ?? 0,
      repeatCount: json['repeatCount'] as int? ?? 3,
    );
  }
  final String id;
  final int surah;
  final int ayah;
  String arabicText;
  double difficulty;
  double stability;
  DateTime lastReview;
  DateTime nextReview;
  int repetitions;
  int lapses;

  /// عدد تكرارات الاستماع لكل جلسة.
  int repeatCount;

  /// هل البطاقة جديدة (لم تُراجَع بعد)؟
  bool get isNew => repetitions == 0;

  /// هل حان وقت المراجعة؟
  bool get isDue => DateTime.now().isAfter(nextReview);

  /// الأيام حتى المراجعة التالية.
  int get daysUntilReview {
    final diff = nextReview.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// مستوى الإتقان التقريبي بناءً على الاستقرار.
  int get masteryLevel {
    if (repetitions == 0) return 1;
    if (stability < 1) return 1;
    if (stability < 5) return 2;
    if (stability < 20) return 3;
    return 4;
  }

  /// مراجعة البطاقة وتحديث حالة FSRS.
  void review(Rating rating) {
    final elapsedDays = DateTime.now().difference(lastReview).inDays.toDouble();
    final retrievability = FSRSAlgorithm.retrievability(
      elapsedDays,
      stability,
    );

    difficulty = FSRSAlgorithm.updateDifficulty(
      difficulty: difficulty,
      rating: rating,
    );

    if (repetitions == 0) {
      stability = FSRSAlgorithm.initialStability(rating);
    } else {
      stability = FSRSAlgorithm.updateStability(
        difficulty: difficulty,
        stability: stability,
        retrievability: retrievability,
        rating: rating,
      );
    }

    repetitions++;
    if (rating == Rating.again) lapses++;

    lastReview = DateTime.now();
    final interval = FSRSAlgorithm.nextInterval(stability);
    nextReview = DateTime.now().add(Duration(days: interval));
  }

  /// معاينة الفترات القادمة لكل تقييم (أيام).
  Map<Rating, int> previewIntervals() {
    return {
      for (final rating in Rating.values) rating: _previewInterval(rating),
    };
  }

  int _previewInterval(Rating rating) {
    final elapsedDays = DateTime.now().difference(lastReview).inDays.toDouble();
    final retrievability = FSRSAlgorithm.retrievability(
      elapsedDays,
      stability,
    );

    double newStability;
    if (repetitions == 0) {
      newStability = FSRSAlgorithm.initialStability(rating);
    } else {
      newStability = FSRSAlgorithm.updateStability(
        difficulty: difficulty,
        stability: stability,
        retrievability: retrievability,
        rating: rating,
      );
    }

    return FSRSAlgorithm.nextInterval(newStability);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'surah': surah,
    'ayah': ayah,
    'arabicText': arabicText,
    'difficulty': difficulty,
    'stability': stability,
    'lastReview': lastReview.toIso8601String(),
    'nextReview': nextReview.toIso8601String(),
    'repetitions': repetitions,
    'lapses': lapses,
    'repeatCount': repeatCount,
  };

  /// معرف موحد لآية.
  static String keyOf(int surah, int ayah) => '$surah:$ayah';
}
