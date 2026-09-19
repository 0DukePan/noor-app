import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/utils/arabic_text.dart';

import '../test_utils/property.dart';

/// Property-based companion to `hadith_search_normalization_test.dart`.
///
/// The example suite pins the worked cases (`ٱلرحمن` → `الرحمن`, diacritics,
/// whitespace). This suite asserts the invariants those examples imply:
///
/// - idempotence: normalising twice changes nothing;
/// - the output is always diacritic-free;
/// - text differing only by a variant letter (alef/hamza family, ta marbuta,
///   alef maqsura) or by injected tashkeel normalises identically;
/// - whitespace is collapsed and trimmed;
/// - pure-Latin text without odd whitespace passes through untouched;
/// - the output never grows.
void main() {
  // Every character the implementation documents as stripped, enumerated
  // rather than sampled: a missing codepoint in a range is a silent search
  // bug (a verse that no longer matches its own query string).
  final strippedChars = <int>[
    for (var code = 0x0610; code <= 0x061A; code++) code,
    for (var code = 0x064B; code <= 0x065F; code++) code,
    0x0670,
    for (var code = 0x06D6; code <= 0x06DC; code++) code,
    for (var code = 0x06DF; code <= 0x06E8; code++) code,
    for (var code = 0x06EA; code <= 0x06ED; code++) code,
  ];

  const arabicLetters = 'ابتثجحخدذرزسشصضطظعغفقكلمنوي';
  const variantClasses = <String>[
    'اأإآٱ',
    'هة',
    'يى',
  ];

  test('every documented tashkeel codepoint is stripped from between letters',
      () {
    for (final code in strippedChars) {
      final marked = 'م${String.fromCharCode(code)}ن';
      expect(
        normalizeArabic(marked),
        'من',
        reason: 'U+${code.toRadixString(16).toUpperCase()} must be stripped',
      );
    }
  });

  test('normalisation is idempotent', () {
    final alphabet = '$arabicLetters${variantClasses.join()}'
        '${String.fromCharCodes(strippedChars)} \t abcXYZ.,!?';
    forAll<String>(
      (random) => stringOf(random, alphabet, maxLength: 40),
      check: (text) {
        final once = normalizeArabic(text);
        expect(normalizeArabic(once), once);
      },
      describe: (text) => 'input=${text.runes.map((r) => r.toRadixString(16)).join(' ')}',
    );
  });

  test('normalised output never contains a stripped character', () {
    final alphabet =
        arabicLetters + variantClasses.join() + String.fromCharCodes(strippedChars);
    forAll<String>(
      (random) => stringOf(random, alphabet, maxLength: 40),
      check: (text) {
        final normalized = normalizeArabic(text);
        for (final code in strippedChars) {
          expect(
            normalized.contains(String.fromCharCode(code)),
            isFalse,
          );
        }
      },
    );
  });

  test('variant letters of the same class normalise identically', () {
    forAll<String>(
      (random) {
        final base = stringOf(random, arabicLetters, minLength: 1, maxLength: 30);
        final letters = base.runes.toList();
        for (var i = 0; i < letters.length; i++) {
          for (final variantClass in variantClasses) {
            if (variantClass.runes.contains(letters[i])) {
              letters[i] = variantClass.runes
                  .elementAt(random.nextInt(variantClass.runes.length));
            }
          }
        }
        return String.fromCharCodes(letters);
      },
      check: (variantText) {
        // The base string the variant came from is rebuilt by folding every
        // variant back to its class's first member.
        final folded = String.fromCharCodes(
          variantText.runes.map((rune) {
            for (final variantClass in variantClasses) {
              if (variantClass.runes.contains(rune)) {
                return variantClass.runes.first;
              }
            }
            return rune;
          }),
        );
        expect(
          normalizeArabic(variantText),
          normalizeArabic(folded),
        );
      },
      describe: (text) => 'input=$text',
    );
  });

  test('injected tashkeel never changes the normalised form', () {
    forAll<String>(
      (random) {
        final base = stringOf(random, arabicLetters, minLength: 1, maxLength: 30);
        final buffer = StringBuffer();
        for (final rune in base.runes) {
          buffer.writeCharCode(rune);
          // 0-2 marks after every letter, at arbitrary positions.
          for (var i = 0; i < intIn(random, 0, 2); i++) {
            buffer.writeCharCode(
              strippedChars[random.nextInt(strippedChars.length)],
            );
          }
        }
        return buffer.toString();
      },
      check: (marked) {
        final folded = String.fromCharCodes(
          marked.runes.where((rune) => !strippedChars.contains(rune)),
        );
        expect(normalizeArabic(marked), normalizeArabic(folded));
      },
      describe: (text) => 'input=$text',
    );
  });

  test('whitespace is collapsed and trimmed', () {
    forAll<String>(
      (random) => stringOf(random, 'ات\t\n ', maxLength: 30),
      check: (text) {
        final normalized = normalizeArabic(text);
        expect(normalized, normalized.trim());
        expect(normalized.contains('  '), isFalse);
        // Only plain spaces survive; tabs and newlines are collapsed into them.
        expect(RegExp(r'[\t\n\r\f\v]').hasMatch(normalized), isFalse);
      },
      describe: (text) =>
          'input=${text.runes.map((r) => r.toRadixString(16)).join(' ')}',
    );
  });

  test('latin text with single spaces is untouched', () {
    forAll<String>(
      (random) => listOf(random, 1, 6, (r) => stringOf(r, 'abcdefghXYZ', minLength: 1, maxLength: 8)).join(' '),
      check: (text) => expect(normalizeArabic(text), text),
      describe: (text) => 'input=$text',
    );
  });

  test('normalisation never grows the input', () {
    final alphabet = '$arabicLetters${variantClasses.join()}'
        '${String.fromCharCodes(strippedChars)} ';
    forAll<String>(
      (random) => stringOf(random, alphabet, maxLength: 40),
      check: (text) => expect(
        normalizeArabic(text).length,
        lessThanOrEqualTo(text.length),
      ),
    );
  });

  test('query and stored text meet after normalisation (search closure)', () {
    // The README's worked example, generalised: a query that differs from the
    // stored text only by diacritics or variant letters must normalise to the
    // same string — that equality is what the FTS-backed search relies on.
    forAll<String>(
      (random) {
        final stored = stringOf(random, arabicLetters, minLength: 1, maxLength: 20);
        final buffer = StringBuffer();
        for (final rune in stored.runes) {
          buffer.writeCharCode(rune);
          if (random.nextBool()) {
            buffer.writeCharCode(
              strippedChars[random.nextInt(strippedChars.length)],
            );
          }
        }
        return buffer.toString();
      },
      check: (query) {
        final stored = String.fromCharCodes(
          query.runes.where((rune) => !strippedChars.contains(rune)),
        );
        expect(normalizeArabic(query), normalizeArabic(stored));
      },
      describe: (text) => 'query=$text',
    );
  });
}
