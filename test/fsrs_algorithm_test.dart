import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/algorithms/fsrs_algorithm.dart';

void main() {
  group('FSRSAlgorithm', () {
    test('initial difficulty follows canonical ordering', () {
      // Higher grades must yield lower difficulty.
      final again = FSRSAlgorithm.initialDifficulty(Rating.again);
      final easy = FSRSAlgorithm.initialDifficulty(Rating.easy);
      expect(again, greaterThan(easy));
    });

    test('nextInterval is at least 1 day', () {
      expect(FSRSAlgorithm.nextInterval(0.1), greaterThanOrEqualTo(1));
      expect(FSRSAlgorithm.nextInterval(100), greaterThan(1));
    });

    test('successful review increases stability', () {
      final stability = FSRSAlgorithm.updateStability(
        difficulty: 5,
        stability: 1,
        retrievability: 0.9,
        rating: Rating.good,
      );
      expect(stability, greaterThan(1.0));
    });

    test('MemorizationCard advances to a future review after a good rating',
        () {
      final card = MemorizationCard(id: '1', hadithId: 'h1')
        ..review(Rating.good);
      expect(card.repetitions, 1);
      expect(card.nextReview.isAfter(DateTime.now()), isTrue);
      expect(card.lapses, 0);
    });

    test('Rating "again" increments lapses', () {
      final card = MemorizationCard(id: '1', hadithId: 'h1')
        ..review(Rating.again);
      expect(card.lapses, 1);
    });

    test('serialization round-trips card state', () {
      final card = MemorizationCard(id: '2', hadithId: 'h2')
        ..review(Rating.easy);
      final restored = MemorizationCard.fromJson(card.toJson());
      expect(restored.id, card.id);
      expect(restored.difficulty, card.difficulty);
      expect(restored.stability, card.stability);
      expect(restored.nextReview, card.nextReview);
      expect(restored.repetitions, card.repetitions);
      expect(restored.lapses, card.lapses);
    });

    test('StreakTracker tracks consecutive days', () {
      final streak = StreakTracker()..recordPractice();
      expect(streak.currentStreak, 1);
      expect(streak.practicedToday, isTrue);
      // Same-day practice does not double-count.
      streak.recordPractice();
      expect(streak.currentStreak, 1);
    });
  });

  group('FSRSAlgorithm reference values (canonical FSRS-4.5 formulas)', () {
    // Reference numbers are derived by hand from the published FSRS-4.5
    // formulas with the default weights (w0..w16) embedded in the class.

    test('initialStability matches the canonical w0..w3 table', () {
      expect(FSRSAlgorithm.initialStability(Rating.again), closeTo(0.4, 1e-9));
      expect(FSRSAlgorithm.initialStability(Rating.hard), closeTo(0.6, 1e-9));
      expect(FSRSAlgorithm.initialStability(Rating.good), closeTo(2.4, 1e-9));
      expect(FSRSAlgorithm.initialStability(Rating.easy), closeTo(5.8, 1e-9));
    });

    test('initialDifficulty matches D0(G) = w4 - (G-3)*w5', () {
      // G = index + 1: again=1..easy=4.
      expect(
        FSRSAlgorithm.initialDifficulty(Rating.again),
        closeTo(6.81, 1e-9),
      );
      expect(FSRSAlgorithm.initialDifficulty(Rating.hard), closeTo(5.87, 1e-9));
      expect(FSRSAlgorithm.initialDifficulty(Rating.good), closeTo(4.93, 1e-9));
      expect(FSRSAlgorithm.initialDifficulty(Rating.easy), closeTo(3.99, 1e-9));
    });

    test('retrievability: R(0)=1 and R(9S)=0.5', () {
      expect(FSRSAlgorithm.retrievability(0, 10), closeTo(1.0, 1e-9));
      expect(FSRSAlgorithm.retrievability(9 * 10, 10), closeTo(0.5, 1e-9));
    });

    test('nextInterval = max(1, round(S)) at the default retention', () {
      // 9*(1/0.9 - 1) == 1, so the interval equals the stability in days.
      expect(FSRSAlgorithm.nextInterval(2.4), 2);
      expect(FSRSAlgorithm.nextInterval(5.8), 6);
      expect(FSRSAlgorithm.nextInterval(0.4), 1);
      expect(FSRSAlgorithm.nextInterval(100), 100);
    });

    test(
        "updateDifficulty matches D' = clamp(w7*D0(easy) + (1-w7)*(D - w6*(G-3)))",
        () {
      // Starting difficulty 5.0, first review.
      expect(
        FSRSAlgorithm.updateDifficulty(difficulty: 5, rating: Rating.again),
        closeTo(6.6927, 1e-4),
      );
      expect(
        FSRSAlgorithm.updateDifficulty(difficulty: 5, rating: Rating.good),
        closeTo(4.9899, 1e-4),
      );
      expect(
        FSRSAlgorithm.updateDifficulty(difficulty: 5, rating: Rating.easy),
        closeTo(4.1385, 1e-4),
      );
    });

    test('updateStability(success) matches the canonical growth formula', () {
      // S' = S*(1 + exp(w8)*(11-D)*S^-w9*(exp((1-R)*w10)-1)), S=1,D=5,R=0.9.
      final s = FSRSAlgorithm.updateStability(
        difficulty: 5,
        stability: 1,
        retrievability: 0.9,
        rating: Rating.good,
      );
      expect(s, closeTo(3.6239, 1e-3));
    });

    test('updateStability(again) matches the canonical failure formula', () {
      // S' = w11 * D^-w12 * ((S+1)^w13 - 1) * exp((1-R)*w14).
      final s = FSRSAlgorithm.updateStability(
        difficulty: 5,
        stability: 1,
        retrievability: 0.9,
        rating: Rating.again,
      );
      expect(s, closeTo(0.607, 1e-3));
    });

    test(
        'previewIntervals on a fresh card yields the canonical first intervals',
        () {
      // First review uses initialStability: again/hard→1, good→2, easy→6 days.
      final card = MemorizationCard(id: 'c', hadithId: 'h');
      expect(card.previewIntervals(), {
        Rating.again: 1,
        Rating.hard: 1,
        Rating.good: 2,
        Rating.easy: 6,
      });
    });

    test('a failed review lowers stability below a successful one', () {
      final failed = FSRSAlgorithm.updateStability(
        difficulty: 5,
        stability: 2,
        retrievability: 0.9,
        rating: Rating.again,
      );
      final passed = FSRSAlgorithm.updateStability(
        difficulty: 5,
        stability: 2,
        retrievability: 0.9,
        rating: Rating.good,
      );
      expect(failed, lessThan(passed));
      expect(failed, lessThan(2), reason: 'failure must reduce stability');
    });
  });

  group('StreakTracker edge cases', () {
    test('a missed day breaks and resets the streak to 1', () {
      final streak = StreakTracker.fromJson({
        'currentStreak': 5,
        'longestStreak': 10,
        // Last practiced two days ago → the streak is broken.
        'lastPracticeDate':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      })
        ..recordPractice();
      final (current, longest) =
          (streak.currentStreak, streak.longestStreak);
      expect(current, 1);
      expect(longest, 10, reason: 'longest streak is kept');
    });

    test('a consecutive day increments the streak and longest', () {
      final streak = StreakTracker.fromJson({
        'currentStreak': 3,
        'longestStreak': 3,
        'lastPracticeDate':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      })
        ..recordPractice();
      final (current, longest) =
          (streak.currentStreak, streak.longestStreak);
      expect(current, 4);
      expect(longest, 4);
    });

    test('practicedToday is false when last practice was not today', () {
      final streak = StreakTracker.fromJson({
        'currentStreak': 1,
        'longestStreak': 1,
        'lastPracticeDate':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });
      expect(streak.practicedToday, isFalse);
    });
  });
}
