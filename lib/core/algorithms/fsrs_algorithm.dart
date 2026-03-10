import 'dart:math';

/// خوارزمية التكرار المتباعد - Free Spaced Repetition Scheduler (FSRS)
/// Based on the research by Jarrett Ye

class FSRSAlgorithm {
  // Default parameters (can be customized per user)
  static const double _w0 = 0.4;
  static const double _w1 = 0.6;
  static const double _w2 = 2.4;
  static const double _w3 = 5.8;
  static const double _w4 = 4.93;
  static const double _w5 = 0.94;
  static const double _w6 = 0.86;
  static const double _w7 = 0.01;
  static const double _w8 = 1.49;
  static const double _w9 = 0.14;
  static const double _w10 = 0.94;
  static const double _w11 = 2.18;
  static const double _w12 = 0.05;
  static const double _w13 = 0.34;
  static const double _w14 = 1.26;
  static const double _w15 = 0.29;
  static const double _w16 = 2.61;

  // Desired retention (probability of recall at next review)
  static const double desiredRetention = 0.9;

  /// Calculate initial stability after first review
  static double initialStability(Rating rating) {
    switch (rating) {
      case Rating.again:
        return _w0;
      case Rating.hard:
        return _w1;
      case Rating.good:
        return _w2;
      case Rating.easy:
        return _w3;
    }
  }

  /// Calculate initial difficulty
  static double initialDifficulty(Rating rating) {
    return _w4 - (rating.index - 3) * _w5;
  }

  /// Calculate retrievability (probability of recall)
  static double retrievability(double elapsedDays, double stability) {
    return pow(1 + elapsedDays / (9 * stability), -1).toDouble();
  }

  /// Calculate next interval in days
  static int nextInterval(double stability) {
    return max(1, (9 * stability * (1 / desiredRetention - 1)).round());
  }

  /// Update stability after review
  static double updateStability({
    required double difficulty,
    required double stability,
    required double retrievability,
    required Rating rating,
  }) {
    final hardPenalty = rating == Rating.hard ? _w15 : 1.0;
    final easyBonus = rating == Rating.easy ? _w16 : 1.0;

    switch (rating) {
      case Rating.again:
        // Stability decreases significantly on failure
        return _w11 *
            pow(difficulty, -_w12).toDouble() *
            (pow(stability + 1, _w13).toDouble() - 1) *
            exp((1 - retrievability) * _w14);
      default:
        // Stability increases on successful recall
        return stability *
            (exp(_w8) *
                (11 - difficulty) *
                pow(stability, -_w9).toDouble() *
                (exp((1 - retrievability) * _w10) - 1) *
                hardPenalty *
                easyBonus +
            1);
    }
  }

  /// Update difficulty after review
  static double updateDifficulty({
    required double difficulty,
    required Rating rating,
  }) {
    final delta = difficulty - _w6 * (rating.index - 3);
    return _clamp(
      _w7 * initialDifficulty(Rating.easy) + (1 - _w7) * delta,
      1.0,
      10.0,
    );
  }

  static double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

/// Rating enum for review quality
enum Rating {
  again, // Complete blackout, need to see again immediately
  hard,  // Recalled with significant difficulty
  good,  // Recalled with moderate effort
  easy,  // Perfect recall, no hesitation
}

extension RatingExtension on Rating {
  String get arabicName {
    switch (this) {
      case Rating.again:
        return 'لم أتذكر';
      case Rating.hard:
        return 'صعب';
      case Rating.good:
        return 'جيد';
      case Rating.easy:
        return 'سهل';
    }
  }

  String get emoji {
    switch (this) {
      case Rating.again:
        return '😔';
      case Rating.hard:
        return '🤔';
      case Rating.good:
        return '😊';
      case Rating.easy:
        return '🎉';
    }
  }
}

/// Card state for spaced repetition
class MemorizationCard {
  final String id;
  final String hadithId;
  double difficulty;
  double stability;
  DateTime lastReview;
  DateTime nextReview;
  int repetitions;
  int lapses; // Number of times "Again" was pressed

  MemorizationCard({
    required this.id,
    required this.hadithId,
    this.difficulty = 5.0,
    this.stability = 1.0,
    DateTime? lastReview,
    DateTime? nextReview,
    this.repetitions = 0,
    this.lapses = 0,
  })  : lastReview = lastReview ?? DateTime.now(),
        nextReview = nextReview ?? DateTime.now();

  /// Check if card is due for review
  bool get isDue => DateTime.now().isAfter(nextReview);

  /// Days until next review
  int get daysUntilReview {
    final diff = nextReview.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Review the card and update state
  void review(Rating rating) {
    final elapsedDays = DateTime.now().difference(lastReview).inDays.toDouble();
    final retrievability = FSRSAlgorithm.retrievability(
      elapsedDays,
      stability,
    );

    // Update states
    difficulty = FSRSAlgorithm.updateDifficulty(
      difficulty: difficulty,
      rating: rating,
    );

    if (repetitions == 0) {
      // First review
      stability = FSRSAlgorithm.initialStability(rating);
    } else {
      stability = FSRSAlgorithm.updateStability(
        difficulty: difficulty,
        stability: stability,
        retrievability: retrievability,
        rating: rating,
      );
    }

    // Update counters
    repetitions++;
    if (rating == Rating.again) {
      lapses++;
    }

    // Calculate next review date
    lastReview = DateTime.now();
    final interval = FSRSAlgorithm.nextInterval(stability);
    nextReview = DateTime.now().add(Duration(days: interval));
  }

  /// Preview next intervals for all ratings
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

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'hadithId': hadithId,
        'difficulty': difficulty,
        'stability': stability,
        'lastReview': lastReview.toIso8601String(),
        'nextReview': nextReview.toIso8601String(),
        'repetitions': repetitions,
        'lapses': lapses,
      };

  /// Create from JSON
  factory MemorizationCard.fromJson(Map<String, dynamic> json) {
    return MemorizationCard(
      id: json['id'] as String,
      hadithId: json['hadithId'] as String,
      difficulty: (json['difficulty'] as num).toDouble(),
      stability: (json['stability'] as num).toDouble(),
      lastReview: DateTime.parse(json['lastReview'] as String),
      nextReview: DateTime.parse(json['nextReview'] as String),
      repetitions: json['repetitions'] as int,
      lapses: json['lapses'] as int,
    );
  }
}

/// Streak tracker for daily practice
class StreakTracker {
  int currentStreak;
  int longestStreak;
  DateTime? lastPracticeDate;

  StreakTracker({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
  });

  /// Record a practice session
  void recordPractice() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (lastPracticeDate != null) {
      final lastDate = DateTime(
        lastPracticeDate!.year,
        lastPracticeDate!.month,
        lastPracticeDate!.day,
      );

      final daysDiff = todayDate.difference(lastDate).inDays;

      if (daysDiff == 0) {
        // Already practiced today
        return;
      } else if (daysDiff == 1) {
        // Consecutive day
        currentStreak++;
      } else {
        // Streak broken
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    // Update longest streak
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    lastPracticeDate = todayDate;
  }

  /// Check if practiced today
  bool get practicedToday {
    if (lastPracticeDate == null) return false;
    final today = DateTime.now();
    return lastPracticeDate!.year == today.year &&
        lastPracticeDate!.month == today.month &&
        lastPracticeDate!.day == today.day;
  }

  /// Get streak emoji based on length
  String get streakEmoji {
    if (currentStreak >= 365) return '🏆';
    if (currentStreak >= 100) return '💎';
    if (currentStreak >= 30) return '🔥';
    if (currentStreak >= 7) return '⭐';
    if (currentStreak >= 3) return '✨';
    return '🌱';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastPracticeDate': lastPracticeDate?.toIso8601String(),
      };

  /// Create from JSON
  factory StreakTracker.fromJson(Map<String, dynamic> json) {
    return StreakTracker(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastPracticeDate: json['lastPracticeDate'] != null
          ? DateTime.parse(json['lastPracticeDate'] as String)
          : null,
    );
  }
}
