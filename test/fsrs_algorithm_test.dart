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
      final stability =
          FSRSAlgorithm.updateStability(
        difficulty: 5,
        stability: 1,
        retrievability: 0.9,
        rating: Rating.good,
      );
      expect(stability, greaterThan(1.0));
    });

    test('MemorizationCard advances to a future review after a good rating', () {
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
      final streak = StreakTracker()
        ..recordPractice();
      expect(streak.currentStreak, 1);
      expect(streak.practicedToday, isTrue);
      // Same-day practice does not double-count.
      streak.recordPractice();
      expect(streak.currentStreak, 1);
    });
  });
}
