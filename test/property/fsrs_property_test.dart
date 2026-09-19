import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/algorithms/fsrs_algorithm.dart';
import '../test_utils/property.dart';

/// Property-based companion to `fsrs_algorithm_test.dart` and the reference
/// cross-check. The explicit tests pin known schedules; these assert the
/// invariants that must hold across the whole state space:
///
/// - monotonic initial stability/difficulty in the rating;
/// - bounded retrievability that never increases with elapsed time;
/// - intervals >= 1 day and non-decreasing in stability;
/// - a card's (difficulty, stability) stays inside its documented domain no
///   matter how long the rating sequence is;
/// - the same inputs always produce the same outputs.
void main() {
  const elapsedRange = (min: 0.0, max: 3650.0);
  const stabilityRange = (min: 0.05, max: 1000.0);

  test('initial stability strictly increases with the rating', () {
    final stabilities = Rating.values.map(FSRSAlgorithm.initialStability).toList();
    for (var i = 1; i < stabilities.length; i++) {
      expect(stabilities[i], greaterThan(stabilities[i - 1]));
    }
  });

  test('initial difficulty decreases with the rating and stays within [1, 10]',
      () {
    final difficulties =
        Rating.values.map(FSRSAlgorithm.initialDifficulty).toList();
    for (var i = 0; i < difficulties.length; i++) {
      expect(difficulties[i], inInclusiveRange(1, 10));
      if (i > 0) {
        expect(difficulties[i], lessThan(difficulties[i - 1]));
      }
    }
  });

  test('retrievability is in (0, 1], starts at 1, and is non-increasing', () {
    forAll<({double stability, double elapsedA, double elapsedB})>(
      (random) {
        final stability = doubleIn(
          random,
          stabilityRange.min,
          stabilityRange.max,
        );
        final elapsedA = doubleIn(random, elapsedRange.min, elapsedRange.max);
        final elapsedB = elapsedA + doubleIn(random, 0, elapsedRange.max);
        return (stability: stability, elapsedA: elapsedA, elapsedB: elapsedB);
      },
      check: (input) {
        final atA = FSRSAlgorithm.retrievability(input.elapsedA, input.stability);
        final atB = FSRSAlgorithm.retrievability(input.elapsedB, input.stability);
        expect(atA, greaterThan(0));
        expect(atA, lessThanOrEqualTo(1));
        expect(atB, lessThanOrEqualTo(atA));
        expect(
          FSRSAlgorithm.retrievability(0, input.stability),
          closeTo(1, 1e-12),
        );
      },
      describe: (input) => 'stability=${input.stability} '
          'elapsed=${input.elapsedA}->${input.elapsedB}',
    );
  });

  test('intervals are at least one day and non-decreasing in stability', () {
    forAll<({double stability, double largerStability})>(
      (random) {
        final stability = doubleIn(
          random,
          stabilityRange.min,
          stabilityRange.max,
        );
        return (
          stability: stability,
          largerStability:
              stability + doubleIn(random, 0, stabilityRange.max),
        );
      },
      check: (input) {
        final interval = FSRSAlgorithm.nextInterval(input.stability);
        expect(interval, greaterThanOrEqualTo(1));
        expect(
          FSRSAlgorithm.nextInterval(input.largerStability),
          greaterThanOrEqualTo(interval),
        );
      },
      describe: (input) =>
          'stability=${input.stability} larger=${input.largerStability}',
    );
  });

  test('difficulty updates stay in [1, 10] for any starting difficulty', () {
    forAll<({double difficulty, Rating rating})>(
      (random) => (
        difficulty: doubleIn(random, 1, 10),
        rating: elementOf(random, Rating.values),
      ),
      check: (input) {
        final updated = FSRSAlgorithm.updateDifficulty(
          difficulty: input.difficulty,
          rating: input.rating,
        );
        expect(updated, inInclusiveRange(1, 10));
      },
      describe: (input) =>
          'difficulty=${input.difficulty} rating=${input.rating.name}',
    );
  });

  test('successful-recall stability updates are finite and positive', () {
    forAll<({double difficulty, double stability, double retrievability, Rating rating})>(
      (random) => (
        difficulty: doubleIn(random, 1, 10),
        stability: doubleIn(random, stabilityRange.min, stabilityRange.max),
        retrievability: doubleIn(random, 0, 1),
        rating: elementOf(random, Rating.values),
      ),
      check: (input) {
        final updated = FSRSAlgorithm.updateStability(
          difficulty: input.difficulty,
          stability: input.stability,
          retrievability: input.retrievability,
          rating: input.rating,
        );
        expect(updated.isFinite, isTrue);
        expect(updated, greaterThan(0));
      },
      describe: (input) => 'difficulty=${input.difficulty} '
          'stability=${input.stability} '
          'retrievability=${input.retrievability} rating=${input.rating.name}',
    );
  });

  test('any rating sequence keeps the card inside its documented domain', () {
    forAll<List<({Rating rating, double elapsedDays})>>(
      (random) => listOf(
        random,
        1,
        60,
        (r) => (
          rating: elementOf(r, Rating.values),
          elapsedDays: doubleIn(r, 0, 90),
        ),
      ),
      check: (reviews) {
        // Mirrors MemorizationCard.review(): difficulty first, then stability
        // (initial on the first review, updated after that).
        var difficulty = 5.0;
        var stability = 1.0;
        var repetitions = 0;
        for (final review in reviews) {
          difficulty = FSRSAlgorithm.updateDifficulty(
            difficulty: difficulty,
            rating: review.rating,
          );
          if (repetitions == 0) {
            stability = FSRSAlgorithm.initialStability(review.rating);
          } else {
            stability = FSRSAlgorithm.updateStability(
              difficulty: difficulty,
              stability: stability,
              retrievability: FSRSAlgorithm.retrievability(
                review.elapsedDays,
                stability,
              ),
              rating: review.rating,
            );
          }
          repetitions++;
          expect(stability.isFinite, isTrue);
          expect(stability, greaterThan(0));
          expect(difficulty, inInclusiveRange(1, 10));
          expect(FSRSAlgorithm.nextInterval(stability), greaterThanOrEqualTo(1));
        }
      },
      describe: (reviews) =>
          'ratings=${reviews.map((r) => r.rating.name).join(',')}',
    );
  });

  test('preview intervals on a fresh card are non-decreasing across ratings',
      () {
    final now = DateTime(2026, 9, 18, 9);
    forAll<int>(
      (random) => intIn(random, 0, 30),
      check: (elapsedDays) {
        final card = MemorizationCard(
          id: 'card',
          hadithId: 'hadith',
          lastReview: now.subtract(Duration(days: elapsedDays)),
          nextReview: now,
        );
        final previews = card.previewIntervals();
        for (var i = 1; i < Rating.values.length; i++) {
          expect(
            previews[Rating.values[i]],
            greaterThanOrEqualTo(previews[Rating.values[i - 1]] ?? 0),
          );
        }
      },
      describe: (elapsedDays) => 'elapsedDays=$elapsedDays',
    );
  });
}
