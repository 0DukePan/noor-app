import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/algorithms/fsrs_algorithm.dart';

/// Independent cross-check of FSRSAlgorithm against the published FSRS-4.5
/// formulas (Jarrett Ye, open-spaced-repetition/fsrs4anki). The reference
/// implementation below is transcribed straight from the spec — deliberately
/// not from this codebase — and compared against the app's implementation
/// across a dense input grid, so a conceptual error shared between "the code"
/// and "a test written from the code" cannot hide.
///
/// Default FSRS-4.5 weights (as published):
///   w = [0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01, 1.49, 0.14,
///        0.94, 2.18, 0.05, 0.34, 1.26, 0.29, 2.61]
void main() {
  const w = <double>[
    0.4,
    0.6,
    2.4,
    5.8,
    4.93,
    0.94,
    0.86,
    0.01,
    1.49,
    0.14,
    0.94,
    2.18,
    0.05,
    0.34,
    1.26,
    0.29,
    2.61,
  ];

  // ── Reference transcription (from the spec, independent of this repo) ──

  double refInitialDifficulty(int g) => w[4] - (g - 3) * w[5];

  double refInitialStability(int g) => w[g - 1];

  double refRetrievability(double t, double s) =>
      pow(1 + t / (9 * s), -1).toDouble();

  double refUpdateDifficulty(double d, int g) {
    final delta = d - w[6] * (g - 3);
    return (w[7] * refInitialDifficulty(4) + (1 - w[7]) * delta)
        .clamp(1.0, 10.0);
  }

  double refUpdateStability(double d, double s, double r, int g) {
    if (g == 1) {
      // Failure: S' = w11 * D^-w12 * ((S+1)^w13 - 1) * exp((1-R)*w14)
      return w[11] *
          pow(d, -w[12]).toDouble() *
          (pow(s + 1, w[13]).toDouble() - 1) *
          exp((1 - r) * w[14]);
    }
    // Success: S' = S * (1 + exp(w8)*(11-D)*S^-w9*(exp((1-R)*w10)-1)*hp*eb)
    final hardPenalty = g == 2 ? w[15] : 1.0;
    final easyBonus = g == 4 ? w[16] : 1.0;
    return s *
        (exp(w[8]) *
                (11 - d) *
                pow(s, -w[9]).toDouble() *
                (exp((1 - r) * w[10]) - 1) *
                hardPenalty *
                easyBonus +
            1);
  }

  int refNextInterval(double s) => max(1, (9 * s * (1 / 0.9 - 1)).round());

  int gOf(Rating rating) => rating.index + 1;

  group('FSRSAlgorithm vs published FSRS-4.5 spec (grid cross-check)', () {
    test('initial stability & difficulty match the spec for all ratings', () {
      for (final rating in Rating.values) {
        final g = gOf(rating);
        expect(
          FSRSAlgorithm.initialStability(rating),
          closeTo(refInitialStability(g), 1e-12),
          reason: 'S0 for G=$g',
        );
        expect(
          FSRSAlgorithm.initialDifficulty(rating),
          closeTo(refInitialDifficulty(g), 1e-12),
          reason: 'D0 for G=$g',
        );
      }
    });

    test('retrievability matches R(t,S) = (1 + t/9S)^-1 over the grid', () {
      for (final t in [0.0, 0.1, 1.0, 5.0, 20.0, 100.0, 1000.0]) {
        for (final s in [0.1, 0.4, 1.0, 2.4, 5.8, 30.0, 100.0]) {
          expect(
            FSRSAlgorithm.retrievability(t, s),
            closeTo(refRetrievability(t, s), 1e-12),
            reason: 'R(t=$t, S=$s)',
          );
        }
      }
    });

    test("updateDifficulty matches D' = clamp(w7*D0(4)+(1-w7)*(D-w6*(G-3)))",
        () {
      for (final d in [1.0, 2.5, 4.93, 6.0, 8.5, 10.0]) {
        for (final rating in Rating.values) {
          expect(
            FSRSAlgorithm.updateDifficulty(difficulty: d, rating: rating),
            closeTo(refUpdateDifficulty(d, gOf(rating)), 1e-9),
            reason: 'D=$d, G=${gOf(rating)}',
          );
        }
      }
    });

    test('updateStability matches the spec failure & success formulas', () {
      for (final d in [1.0, 3.0, 5.0, 7.0, 9.0]) {
        for (final s in [0.1, 0.5, 1.0, 3.0, 10.0, 50.0]) {
          for (final r in [0.5, 0.7, 0.9, 0.99, 1.0]) {
            for (final rating in Rating.values) {
              final actual = FSRSAlgorithm.updateStability(
                difficulty: d,
                stability: s,
                retrievability: r,
                rating: rating,
              );
              final expected = refUpdateStability(d, s, r, gOf(rating));
              expect(
                actual,
                closeTo(expected, 1e-6),
                reason: 'D=$d, S=$s, R=$r, G=${gOf(rating)} '
                    '(actual $actual vs spec $expected)',
              );
            }
          }
        }
      }
    });

    test('nextInterval matches I(S) = round(9S(1/retention - 1)), min 1', () {
      for (final s in [0.1, 0.4, 1.0, 2.4, 5.8, 13.4, 100.0]) {
        expect(
          FSRSAlgorithm.nextInterval(s),
          refNextInterval(s),
          reason: 'S=$s',
        );
      }
    });
  });
}
