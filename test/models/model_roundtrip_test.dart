import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/models/adhkar_models.dart';
import 'package:noor_app/core/models/tafsir_models.dart';

/// Round-trip and resilience tests for the adhkar and tafsir models:
/// well-formed JSON parses, missing/garbage fields fall back safely, and
/// toJson/fromJson are inverses.
void main() {
  group('Zekr', () {
    test('parses a complete zekr', () {
      final zekr = Zekr.fromJson(
        {'zekr': 'سبحان الله', 'repeat': 33, 'bless': 'فضل الذكر'},
        0,
        AdhkarType.general,
      );
      expect(zekr.text, 'سبحان الله');
      expect(zekr.repeat, 33);
      expect(zekr.bless, 'فضل الذكر');
    });

    test('missing fields fall back to defaults', () {
      final zekr = Zekr.fromJson({}, 0, AdhkarType.general);
      expect(zekr.text, '');
      expect(zekr.repeat, 1);
      expect(zekr.bless, isNull);
    });

    test('empty bless is treated as absent', () {
      final zekr = Zekr.fromJson({'bless': ''}, 0, AdhkarType.general);
      expect(zekr.bless, isNull);
    });
  });

  group('AdhkarCollection', () {
    test('parses content list', () {
      final collection = AdhkarCollection.fromJson({
        'title': 'أذكار الصباح',
        'content': [
          {'zekr': 'أ', 'repeat': 1},
          {'zekr': 'ب', 'repeat': 3},
        ],
      }, AdhkarType.morning,);
      expect(collection.title, 'أذكار الصباح');
      expect(collection.count, 2);
      expect(collection.totalRepeat, 4);
    });

    test('missing content yields an empty collection', () {
      final collection = AdhkarCollection.fromJson({}, AdhkarType.evening);
      expect(collection.title, '');
      expect(collection.adhkar, isEmpty);
    });
  });

  group('AdhkarProgress', () {
    test('toJson/fromJson round-trips', () {
      final progress = AdhkarProgress(
        type: AdhkarType.sleep,
        currentIndex: 2,
        currentCount: 5,
        isCompleted: true,
        startedAt: DateTime(2026, 8, 1, 22),
        completedAt: DateTime(2026, 8, 1, 22, 5),
      );
      final restored = AdhkarProgress.fromJson(progress.toJson());
      expect(restored.type, AdhkarType.sleep);
      expect(restored.currentIndex, 2);
      expect(restored.currentCount, 5);
      expect(restored.isCompleted, isTrue);
      expect(restored.startedAt, progress.startedAt);
      expect(restored.completedAt, progress.completedAt);
    });

    test('unknown type falls back to general', () {
      final restored = AdhkarProgress.fromJson({'type': 'nope'});
      expect(restored.type, AdhkarType.general);
    });

    test('increment and complete transition correctly', () {
      var p = const AdhkarProgress(type: AdhkarType.morning);
      p = p.increment();
      expect(p.currentCount, 1);
      p = p.nextZekr();
      expect(p.currentIndex, 1);
      p = p.complete();
      expect(p.isCompleted, isTrue);
      expect(p.completedAt, isNotNull);
    });
  });

  group('DailyAdhkarStats', () {
    test('toJson/fromJson round-trips', () {
      final stats = DailyAdhkarStats(
        date: DateTime(2026, 8, 13),
        morningCompleted: true,
        afterPrayerCount: 3,
        totalAdhkarCount: 4,
      );
      final restored = DailyAdhkarStats.fromJson(stats.toJson());
      expect(restored.morningCompleted, isTrue);
      expect(restored.afterPrayerCount, 3);
      expect(restored.isComplete, isFalse);
    });
  });

  group('AdhkarDisplaySettings', () {
    test('toJson/fromJson round-trips', () {
      const settings = AdhkarDisplaySettings(
        fontSize: 30,
        showBless: false,
        vibrateOnComplete: false,
        autoAdvance: true,
        autoAdvanceDelay: 900,
      );
      final restored = AdhkarDisplaySettings.fromJson(settings.toJson());
      expect(restored.fontSize, 30);
      expect(restored.showBless, isFalse);
      expect(restored.autoAdvanceDelay, 900);
    });
  });

  group('TafsirEntry / SurahTafsir', () {
    test('entry parses from valid JSON', () {
      final entry = TafsirEntry.fromJson({
        'surah': 1,
        'ayah': 1,
        'text': 'نص التفسير',
      }, TafsirSourceId.muyassar,);
      expect(entry.surah, 1);
      expect(entry.ayah, 1);
      expect(entry.text, 'نص التفسير');
    });

    test('surah tafsir maps entries and finds ayahs', () {
      final surah = SurahTafsir.fromJson({
        'ayahs': [
          {'surah': 1, 'ayah': 1, 'text': 'أ'},
          {'surah': 1, 'ayah': 2, 'text': 'ب'},
        ],
      }, TafsirSourceId.saadi,);
      expect(surah.surah, 1);
      expect(surah.length, 2);
      expect(surah.getAyah(2)?.text, 'ب');
      expect(surah.getAyah(99), isNull);
    });
  });

  group('TafsirBookmark', () {
    test('toJson/fromJson round-trips', () {
      final bookmark = TafsirBookmark(
        surah: 2,
        ayah: 255,
        source: TafsirSourceId.ibnKathir,
        createdAt: DateTime(2026, 1, 2),
        note: 'آية الكرسي',
      );
      final restored = TafsirBookmark.fromJson(bookmark.toJson());
      expect(restored.surah, 2);
      expect(restored.ayah, 255);
      expect(restored.source, TafsirSourceId.ibnKathir);
      expect(restored.note, 'آية الكرسي');
    });
  });

  group('TafsirHighlight', () {
    test('toJson/fromJson round-trips', () {
      final highlight = TafsirHighlight(
        id: 'h1',
        surah: 1,
        ayah: 1,
        source: TafsirSourceId.muyassar,
        highlightedText: 'بسم الله',
        color: HighlightColor.green,
        createdAt: DateTime(2026),
      );
      final restored = TafsirHighlight.fromJson(highlight.toJson());
      expect(restored.id, 'h1');
      expect(restored.color, HighlightColor.green);
      expect(restored.highlightedText, 'بسم الله');
    });
  });

  group('TafsirAnnotation', () {
    test('toJson/fromJson round-trips', () {
      final annotation = TafsirAnnotation(
        id: 'a1',
        surah: 18,
        ayah: 1,
        source: TafsirSourceId.tabari,
        noteText: 'تدبر',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 1, 3),
      );
      final restored = TafsirAnnotation.fromJson(annotation.toJson());
      expect(restored.source, TafsirSourceId.tabari);
      expect(restored.noteText, 'تدبر');
      expect(restored.updatedAt, DateTime(2026, 1, 3));
    });
  });

  group('adhkar asset integrity', () {
    test('every AdhkarType asset path resolves to a bundled JSON', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final type in AdhkarType.values) {
        final path = type.assetPath;
        expect(path, endsWith('.json'));
        final data = await rootBundle.loadString(path);
        final json = jsonDecode(data) as Map<String, dynamic>;
        expect(json['title'], isNotNull);
        expect(json['content'], isA<List<dynamic>>());
      }
    });
  });
}
