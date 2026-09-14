import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/domain/entities/tafsir.dart';
import 'package:noor_app/features/quran/domain/entities/quran_entities.dart';
import 'package:noor_app/features/search/domain/entities/search_result.dart';

/// Tests for the small domain entities (Equatable value semantics + enum
/// metadata) that carry no logic of their own.
void main() {
  group('TafsirVerse', () {
    test('equality and props', () {
      const a = TafsirVerse(surahId: 1, verseId: 2, text: 'x', source: 'm');
      const b = TafsirVerse(surahId: 1, verseId: 2, text: 'x', source: 'm');
      const c = TafsirVerse(surahId: 1, verseId: 3, text: 'x', source: 'm');
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('TafsirBook', () {
    test('has the four bundled books with stable metadata', () {
      expect(TafsirBook.values.length, 4);
      expect(TafsirBook.muyassar.id, 'muyassar');
      expect(TafsirBook.ibnKathir.folderName, 'full/ar-tafsir-ibn-kathir');
      expect(TafsirBook.saadi.nameEnglish, 'Al-Saadi');
      expect(TafsirBook.tabari.nameArabic, 'تفسير الطبري');
      expect(TafsirBook.values.map((e) => e.id).toSet().length, 4);
    });
  });

  group('Quran entities', () {
    test('Tafsir equality uses surah/verse/source', () {
      const a = Tafsir(
          surahNumber: 2,
          verseNumber: 255,
          briefText: 'b',
          source: 'm',
          author: 'x',
      );
      const b = Tafsir(
          surahNumber: 2,
          verseNumber: 255,
          briefText: 'other',
          source: 'm',
          author: 'y',
      );
      expect(a, b, reason: 'briefText/author are not part of equality');
    });

    test('RevelationCause equality and CauseType values', () {
      const a = RevelationCause(
          surahNumber: 1,
          verseNumber: 1,
          briefSummary: 's',
          causeType: CauseType.event,
          source: 'm',
      );
      const b = RevelationCause(
          surahNumber: 1,
          verseNumber: 1,
          briefSummary: 'z',
          causeType: CauseType.event,
          source: 'm',
      );
      const c = RevelationCause(
          surahNumber: 1,
          verseNumber: 1,
          briefSummary: 's',
          causeType: CauseType.question,
          source: 'm',
      );
      expect(a, b);
      expect(a, isNot(c));
      expect(CauseType.values, [
        CauseType.event,
        CauseType.question,
        CauseType.personalIncident,
        CauseType.legislation,
      ]);
    });

    test('Tadabbur equality uses id + surah/verse', () {
      final t = DateTime(2026);
      final a = Tadabbur(
          id: 'a',
          surahNumber: 18,
          verseNumber: 1,
          encryptedNote: 'n',
          createdAt: t,
      );
      final b = Tadabbur(
          id: 'a',
          surahNumber: 18,
          verseNumber: 1,
          encryptedNote: 'different',
          createdAt: t,
      );
      expect(a, b);
    });
  });

  group('SearchResult', () {
    test('carries text, source and metadata', () {
      const r = SearchResult(
        text: 'snippet',
        source: 'quran',
        metadata: {'surah': 1, 'verse': 1},
      );
      expect(r.text, 'snippet');
      expect(r.source, 'quran');
      expect(r.metadata, {'surah': 1, 'verse': 1});
    });
  });
}
