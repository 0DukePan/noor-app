import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/models/tafsir_models.dart';
import 'package:noor_app/features/quran/domain/entities/quran_location.dart';
import 'package:noor_app/features/quran/domain/quran_location_resolver.dart';

/// Phase 3 contract: one validated `QuranLocation` intent plus a resolver
/// backed by the verse-count table and the ayah-to-page index. Screens never
/// hand-build partial Qur'an URLs.
void main() {
  group('QuranLocation.validated', () {
    test('keeps valid locations intact', () {
      const location = QuranLocation(surah: 2, ayah: 255, page: 42);
      expect(location.isValid, isTrue);
      expect(location.studyRoute, '/quran/surah/2?ayah=255');
      expect(location.mushafRoute(42), '/quran/mushaf?page=42');
    });

    test('clamps instead of throwing', () {
      final location = QuranLocation.validated(
        surah: 200,
        ayah: -5,
        page: 9999,
      );
      expect(location.surah, 114);
      expect(location.ayah, 1);
      expect(location.page, 604);
      expect(location.isValid, isTrue);
    });

    test('clamps ayahs to their own surah range', () {
      final fatiha = QuranLocation.validated(surah: 1, ayah: 50);
      expect(fatiha.ayah, 7);
      final baqarah = QuranLocation.validated(surah: 2, ayah: 500);
      expect(baqarah.ayah, 286);
    });
  });

  group('TafsirLocation.validated', () {
    test('carries source and return context', () {
      final location = TafsirLocation.validated(
        surah: 36,
        ayah: 58,
        source: 'muyassar',
        returnRoute: '/quran/surah/36?ayah=58',
      );
      expect(location.surah, 36);
      expect(location.ayah, 58);
      expect(location.source, 'muyassar');
      expect(location.returnRoute, '/quran/surah/36?ayah=58');
    });

    test('route round-trips surah, ayah, and source', () {
      final location = TafsirLocation.validated(
        surah: 2,
        ayah: 255,
        source: 'saadi',
      );
      expect(location.route, '/tafsir?surah=2&ayah=255&source=saadi');
    });
  });

  group('tafsirSourceIdFromName', () {
    test('resolves known sources and falls back safely', () {
      expect(tafsirSourceIdFromName('muyassar'), TafsirSourceId.muyassar);
      expect(tafsirSourceIdFromName('saadi'), TafsirSourceId.saadi);
      expect(tafsirSourceIdFromName('tabari'), TafsirSourceId.tabari);
      expect(tafsirSourceIdFromName('ibnKathir'), TafsirSourceId.ibnKathir);
      expect(tafsirSourceIdFromName('ibn_kathir'), TafsirSourceId.ibnKathir);
      expect(tafsirSourceIdFromName('nope'), TafsirSourceId.muyassar);
      expect(tafsirSourceIdFromName(null), TafsirSourceId.muyassar);
      expect(tafsirSourceIdFromName(''), TafsirSourceId.muyassar);
    });
  });

  group('QuranLocationResolver', () {
    final resolver = QuranLocationResolver(
      ayahToPageIndex: const {'1:1': 1, '2:255': 42, '114:6': 604},
    );

    test('buildIndex maps every entry once', () {
      final index = QuranLocationResolver.buildIndex({
        '1': [
          {'surah': 1, 'ayah': 1},
          {'surah': 1, 'ayah': 2},
        ],
        '604': [
          {'surah': 114, 'ayah': 6},
        ],
        'oops': [
          {'surah': 1, 'ayah': 3},
        ],
        '605': [
          {'surah': 1, 'ayah': 4},
        ],
      });
      expect(index, {'1:1': 1, '1:2': 1, '114:6': 604});
    });

    test('pageForAyah answers from the immutable index', () {
      expect(resolver.pageForAyah(1, 1), 1);
      expect(resolver.pageForAyah(2, 255), 42);
      expect(resolver.pageForAyah(114, 6), 604);
      expect(resolver.pageForAyah(3, 3), isNull);
    });

    test('resolve validates and derives the page', () {
      final derived = resolver.resolve(surah: 2, ayah: 255);
      expect(derived?.page, 42);

      final explicit = resolver.resolve(surah: 2, ayah: 255, page: 43);
      expect(explicit?.page, 43);

      expect(resolver.resolve(surah: 0, ayah: 1), isNull);
      expect(resolver.resolve(surah: 1, ayah: 8), isNull);
      expect(resolver.resolve(surah: 1, ayah: 1, page: 605), isNull);
    });
  });
}
