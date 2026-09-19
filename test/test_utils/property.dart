import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Minimal, hand-rolled property testing — deliberately not a package.
///
/// Dart's property-based testing options are all young and low-adoption, and
/// this repository scrutinises dependencies (see SECURITY.md). The generator
/// and shrinker surface needed here is small, so it lives in the repo instead:
///
/// - generation is driven by a seeded [Random]; the seed is fixed by default
///   and printed on failure, so any counter-example reproduces exactly;
/// - `check` fails a case by throwing (an `expect`, normally);
/// - an optional `shrink` returns simpler candidates and the smallest
///   still-failing candidate is reported.
const int kPropertySeed = 20260918;

typedef Generative<T> = T Function(Random random);

void forAll<T>(
  Generative<T> generate, {
  required void Function(T value) check,
  int iterations = 200,
  int seed = kPropertySeed,
  String Function(T value)? describe,
  Iterable<T> Function(T value)? shrink,
}) {
  final random = Random(seed);
  T? firstFailure;
  Object? failure;
  StackTrace? failureTrace;

  for (var index = 0; index < iterations; index++) {
    final value = generate(random);
    try {
      check(value);
    } on Object catch (error, trace) {
      firstFailure = value;
      failure = error;
      failureTrace = trace;
      break;
    }
  }

  if (firstFailure == null) return;

  var smallest = firstFailure;
  final candidates = shrink;
  if (candidates != null) {
    var improved = true;
    var rounds = 0;
    while (improved && rounds < 64) {
      improved = false;
      rounds++;
      for (final candidate in candidates(smallest)) {
        try {
          check(candidate);
        } on Object {
          smallest = candidate;
          improved = true;
          break;
        }
      }
    }
  }

  final details = describe == null ? '$smallest' : describe(smallest);
  fail(
    'property failed (seed $seed; reported value is the smallest found)\n'
    '$details\n'
    '$failure\n'
    '$failureTrace',
  );
}

int intIn(Random random, int min, int max) =>
    min + random.nextInt(max - min + 1);

double doubleIn(Random random, double min, double max) =>
    min + random.nextDouble() * (max - min);

T elementOf<T>(Random random, List<T> values) =>
    values[random.nextInt(values.length)];

List<T> listOf<T>(
  Random random,
  int minLength,
  int maxLength,
  T Function(Random random) generate,
) {
  final length = intIn(random, minLength, maxLength);
  return List.generate(length, (_) => generate(random));
}

String stringOf(
  Random random,
  String alphabet, {
  int minLength = 0,
  int maxLength = 24,
}) {
  final runes = alphabet.runes.toList(growable: false);
  return String.fromCharCodes(
    List.generate(
      intIn(random, minLength, maxLength),
      (_) => runes[random.nextInt(runes.length)],
    ),
  );
}

DateTime dateIn(Random random, int minYear, int maxYear) => DateTime(
      intIn(random, minYear, maxYear),
      intIn(random, 1, 12),
      intIn(random, 1, 28),
    );

/// Halving-toward-zero candidates for a numeric component; used by tests that
/// shrink coordinates or offsets to a minimal failing value.
Iterable<double> shrinkTowardsZero(double value) sync* {
  if (value == 0) return;
  yield 0;
  final half = value / 2;
  if (half != value) yield half;
  final truncated = value.truncateToDouble();
  if (truncated != value) yield truncated;
}
