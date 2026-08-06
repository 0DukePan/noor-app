import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';

void main() {
  group('HadithDatabase.normalizeForSearch', () {
    test('strips Arabic diacritics (tashkeel)', () {
      const input = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ';
      // Expect all diacritic marks removed; base letters preserved.
      expect(
        HadithDatabase.normalizeForSearch(input),
        contains('بسم'),
      );
      expect(
        HadithDatabase.normalizeForSearch(input),
        contains('الله'),
      );
      expect(
        HadithDatabase.normalizeForSearch(input),
        isNot(contains('\u064E')), // fatha
      );
      expect(
        HadithDatabase.normalizeForSearch(input),
        isNot(contains('\u0651')), // shadda
      );
    });

    test('collapses repeated whitespace and trims', () {
      expect(
        HadithDatabase.normalizeForSearch('  قال   رسول  الله  '),
        'قال رسول الله',
      );
    });

    test('keeps ordinary Arabic words intact', () {
      expect(HadithDatabase.normalizeForSearch('صحيح البخاري'), 'صحيح البخاري');
    });

    test('empty and whitespace-only inputs collapse to empty', () {
      expect(HadithDatabase.normalizeForSearch(''), '');
      expect(HadithDatabase.normalizeForSearch('   '), '');
    });
  });
}
