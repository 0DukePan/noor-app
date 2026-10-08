import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/router/route_decoder.dart';

/// NAV-01 + QUR-04 contract: one typed, range-aware route decoder.
/// Valid locations are present before first paint; invalid input reaches a
/// localized recovery state — never an uncaught `int.parse` exception.
void main() {
  group('decodeSurahRoute', () {
    test('accepts valid edges 1 and 114', () {
      final first = decodeSurahRoute(surahRaw: '1', ayahRaw: null);
      expect(first, isA<DecodedQuranLocation>());
      expect((first as DecodedQuranLocation).location.surah, 1);

      final last = decodeSurahRoute(surahRaw: '114', ayahRaw: '6');
      expect(last, isA<DecodedQuranLocation>());
      final location = (last as DecodedQuranLocation).location;
      expect(location.surah, 114);
      expect(location.ayah, 6);
    });

    test('defaults a missing ayah to 1', () {
      final decoded = decodeSurahRoute(surahRaw: '2', ayahRaw: null);
      expect((decoded as DecodedQuranLocation).location.ayah, 1);
    });

    test('rejects zero, negative, and too-large surahs', () {
      for (final raw in ['0', '-3', '115', '999']) {
        final decoded = decodeSurahRoute(surahRaw: raw, ayahRaw: null);
        expect(decoded, isA<RouteFailure>(), reason: 'surah=$raw');
        expect((decoded as RouteFailure).reason, 'surah-out-of-range');
      }
    });

    test('rejects non-numeric surah and ayah without throwing', () {
      expect(
        decodeSurahRoute(surahRaw: 'abc', ayahRaw: null),
        isA<RouteFailure>(),
      );
      expect(
        decodeSurahRoute(surahRaw: '2', ayahRaw: 'xyz'),
        isA<RouteFailure>(),
      );
      expect(
        decodeSurahRoute(surahRaw: '', ayahRaw: null),
        isA<RouteFailure>(),
      );
    });

    test('rejects out-of-range ayahs per surah', () {
      // Al-Fatihah has 7 ayahs.
      final eighth = decodeSurahRoute(surahRaw: '1', ayahRaw: '8');
      expect(eighth, isA<RouteFailure>());
      expect((eighth as RouteFailure).reason, 'ayah-out-of-range');

      final zero = decodeSurahRoute(surahRaw: '1', ayahRaw: '0');
      expect(zero, isA<RouteFailure>());

      // Al-Baqarah has 286 ayahs.
      final last = decodeSurahRoute(surahRaw: '2', ayahRaw: '286');
      expect(last, isA<DecodedQuranLocation>());
      final over = decodeSurahRoute(surahRaw: '2', ayahRaw: '287');
      expect(over, isA<RouteFailure>());
    });
  });

  group('decodeMushafPage', () {
    test('accepts valid edges 1 and 604', () {
      expect(decodeMushafPage('1').page, 1);
      expect(decodeMushafPage('604').page, 604);
      expect(decodeMushafPage('604').wasClamped, isFalse);
    });

    test('clamps zero, negative, and too-large input', () {
      expect(decodeMushafPage('0'), (page: 1, wasClamped: true));
      expect(decodeMushafPage('-5'), (page: 1, wasClamped: true));
      expect(decodeMushafPage('605'), (page: 604, wasClamped: true));
      expect(decodeMushafPage('99999'), (page: 604, wasClamped: true));
    });

    test('malformed and missing input fall back to page 1', () {
      expect(decodeMushafPage('abc').page, 1);
      expect(decodeMushafPage('').page, 1);
      expect(decodeMushafPage(null), (page: 1, wasClamped: false));
    });
  });

  group('decodeTafsirRoute / decodeTadabburRoute', () {
    test('missing tafsir location is a distinct failure', () {
      final decoded = decodeTafsirRoute(surahRaw: null, ayahRaw: null);
      expect(decoded, isA<RouteFailure>());
      expect((decoded as RouteFailure).reason, 'tafsir-missing-location');
    });

    test('tadabbur validates both path params', () {
      final ok = decodeTadabburRoute(surahRaw: '36', verseRaw: '58');
      expect(ok, isA<DecodedQuranLocation>());
      final bad = decodeTadabburRoute(surahRaw: '36', verseRaw: '84');
      expect(bad, isA<RouteFailure>());
    });
  });
}
