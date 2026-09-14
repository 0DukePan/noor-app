import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/features/quran/data/datasources/quran_datasources.dart';
import 'package:noor_app/features/quran/domain/entities/quran_entities.dart';

/// Quran data models (previously 17% incidental): JSON aliases, revelation /
/// cause mappings, and serialization round-trips. Pure Dart throughout.
void main() {
  test('VerseModel honors key aliases and numeric defaults', () {
    final aliased = VerseModel.fromJson(const {
      'number': 8,
      'verse_number': 1,
      'text_uthmani': 'بِسْمِ',
      'chapter': 2,
    });
    expect(aliased.number, 8);
    expect(aliased.numberInSurah, 1);
    expect(aliased.textUthmani, 'بِسْمِ');
    expect(aliased.surahNumber, 2);
    expect(aliased.page, 0);
    expect(aliased.sajdah, isFalse);

    final primary = VerseModel.fromJson(const {
      'number': 9,
      'verse': 2,
      'text': 'ٱلْحَمْدُ',
      'surah': 1,
      'page': 1,
      'juz': 1,
      'sajdah': true,
    });
    expect(primary.numberInSurah, 2);
    expect(primary.textUthmani, 'ٱلْحَمْدُ');
    expect(primary.surahNumber, 1);
    expect(primary.page, 1);
    expect(primary.sajdah, isTrue);
  });

  test('VerseModel toJson round-trips through fromJson', () {
    final verse = VerseModel.fromJson(const {
      'number': 1,
      'verse': 1,
      'text': 'بِسْمِ',
      'surah': 1,
    });
    final back = VerseModel.fromJson({
      ...verse.toJson(),
      'number': 1,
      'verse': verse.toJson()['verse_number'],
      'text': verse.toJson()['text_uthmani'],
      'surah': 1,
    });
    expect(back.numberInSurah, verse.numberInSurah);
    expect(back.textUthmani, verse.textUthmani);
    expect(verse.toJson()['surah_number'], 1);
  });

  test('SurahModel maps meccan spellings and round-trips', () {
    for (final spelling in ['Meccan', 'makki', 'makkah']) {
      final surah = SurahModel.fromJson({
        'number': 1,
        'name': 'الفاتحة',
        'englishName': 'Al-Fatiha',
        'numberOfAyahs': 7,
        'revelationType': spelling,
      });
      expect(surah.revelationType, RevelationType.meccan);
      expect(surah.nameArabic, 'الفاتحة');
      expect(surah.versesCount, 7);
    }
    final medinan = SurahModel.fromJson(const {
      'number': 2,
      'name_arabic': 'البقرة',
      'name_english': 'Al-Baqarah',
      'verses_count': 286,
      'revelation_type': 'madani',
    });
    expect(medinan.revelationType, RevelationType.medinan);
    expect(medinan.toJson()['revelation_type'], 'madani');

    final withVerses = SurahModel.fromJson(const {
      'number': 1,
      'name': 'الفاتحة',
      'englishName': 'Al-Fatiha',
      'numberOfAyahs': 1,
      'revelationType': 'makki',
      'verses': [
        {'number': 1, 'verse': 1, 'text': 'بِسْمِ', 'surah': 1},
      ],
    });
    expect(withVerses.verses, hasLength(1));
  });

  test('TafsirModel round-trips brief and detailed text', () {
    const json = {
      'surah_number': 1,
      'verse_number': 1,
      'brief_text': 'موجز',
      'detailed_text': 'مفصل',
      'source': 'muyassar',
      'author': 'مؤلف',
    };
    final tafsir = TafsirModel.fromJson(json);
    expect(tafsir.briefText, 'موجز');
    expect(tafsir.detailedText, 'مفصل');
    expect(TafsirModel.fromJson(tafsir.toJson()).briefText, 'موجز');
  });

  test('RevelationCauseModel maps known types, defaults unknown to event',
      () {
    final known = RevelationCauseModel.fromJson(const {
      'surah_number': 2,
      'verse_number': 255,
      'brief_summary': 'س',
      'cause_type': 'legislation',
      'source': 'طبري',
    });
    expect(known.causeType, CauseType.legislation);

    final unknown = RevelationCauseModel.fromJson(const {
      'surah_number': 2,
      'verse_number': 255,
      'brief_summary': 'س',
      'cause_type': 'not_a_type',
      'source': 'طبري',
    });
    expect(unknown.causeType, CauseType.event);
    expect(unknown.toJson()['cause_type'], 'event');
  });
}
