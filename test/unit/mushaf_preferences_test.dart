import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/models/tafsir_models.dart';
import 'package:noor_app/features/quran/presentation/pages/quran_mushaf_page.dart';

/// QUR-07 + TAF-01 contracts: versioned reader preferences recover from
/// corrupt values, and Tafsir availability distinguishes content gaps from
/// storage failures.
void main() {
  group('MushafPreferences.fromStored', () {
    test('null and empty input yield safe defaults', () {
      const fallback = MushafPreferences();
      expect(MushafPreferences.fromStored(null).theme, fallback.theme);
      expect(MushafPreferences.fromStored(null).zoom, 1.0);
      expect(MushafPreferences.fromStored(null).lastPage, 1);
      expect(
        MushafPreferences.fromStored(const {}).toStored()['version'],
        MushafPreferences.currentVersion,
      );
    });

    test('corrupt values fall back instead of throwing', () {
      final prefs = MushafPreferences.fromStored(const {
        'version': 1,
        'theme': 99,
        'zoom': 42.0,
        'showControls': 'yes',
        'lastPage': -12,
      });
      expect(prefs.theme, MushafTheme.madaniCream);
      expect(prefs.zoom, 1.0);
      expect(prefs.lastPage, 1);
    });

    test('stale versions reset to defaults', () {
      final prefs = MushafPreferences.fromStored(const {
        'version': 999,
        'theme': 2,
        'zoom': 1.15,
        'showControls': false,
        'lastPage': 300,
      });
      expect(prefs.theme, MushafTheme.madaniCream);
      expect(prefs.zoom, 1.0);
      expect(prefs.lastPage, 1);
    });

    test('approved values round-trip', () {
      const prefs = MushafPreferences(
        theme: MushafTheme.midnightBlack,
        zoom: 1.15,
        showControls: false,
        lastPage: 300,
      );
      final restored = MushafPreferences.fromStored(
        Map<dynamic, dynamic>.from(prefs.toStored()),
      );
      expect(restored.theme, MushafTheme.midnightBlack);
      expect(restored.zoom, 1.15);
      expect(restored.showControls, isFalse);
      expect(restored.lastPage, 300);
    });

    test('zoom levels are the approved discrete set', () {
      expect(kMushafZoomLevels, contains(1.0));
      expect(kMushafZoomLevels, hasLength(5));
    });

    test('toArabicNumeral never throws and matches markers', () {
      expect(toArabicNumeral(1), '١');
      expect(toArabicNumeral(286), '٢٨٦');
      expect(toArabicNumeral(0), '٠');
      expect(toArabicNumeral(-5), '٠');
    });
  });

  group('resolveTafsirAvailability', () {
    test('entry present means available', () {
      expect(
        resolveTafsirAvailability(
          entry: Object(),
          sourceBundled: true,
          servingEmptyFallback: false,
          corrupt: false,
          error: null,
        ),
        TafsirAvailability.available,
      );
    });

    test('missing row is not a storage failure', () {
      expect(
        resolveTafsirAvailability(
          entry: null,
          sourceBundled: true,
          servingEmptyFallback: false,
          corrupt: false,
          error: null,
        ),
        TafsirAvailability.rowMissing,
      );
    });

    test('disabled source, failures, and corruption are distinct', () {
      expect(
        resolveTafsirAvailability(
          entry: null,
          sourceBundled: false,
          servingEmptyFallback: false,
          corrupt: false,
          error: null,
        ),
        TafsirAvailability.sourceDisabled,
      );
      expect(
        resolveTafsirAvailability(
          entry: null,
          sourceBundled: true,
          servingEmptyFallback: true,
          corrupt: false,
          error: null,
        ),
        TafsirAvailability.storageFailure,
      );
      expect(
        resolveTafsirAvailability(
          entry: null,
          sourceBundled: true,
          servingEmptyFallback: false,
          corrupt: true,
          error: null,
        ),
        TafsirAvailability.corrupt,
      );
      expect(
        resolveTafsirAvailability(
          entry: Object(),
          sourceBundled: true,
          servingEmptyFallback: false,
          corrupt: false,
          error: Exception('copy failed'),
        ),
        TafsirAvailability.storageFailure,
      );
    });
  });
}
