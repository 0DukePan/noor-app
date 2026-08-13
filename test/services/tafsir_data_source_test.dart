import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/models/tafsir_models.dart';
import 'package:noor_app/core/services/tafsir_data_source.dart';

/// Tests TafsirDataSource: bundled asset loading, bookmarks, highlights,
/// annotations, reading history, and settings persistence.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_tafsir_test');
    Hive.init(tempDir.path);
    await TafsirDataSource.init();
    await TafsirDataSource.initPhase6();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('Muyassar tafsir for Al-Fatihah loads from bundled assets', () async {
    final surah = await TafsirDataSource.getSurahTafsir(
      surah: 1,
    );
    expect(surah, isNotNull);
    expect(surah!.entries, isNotEmpty);
    final firstAyah = surah.getAyah(1);
    expect(firstAyah, isNotNull);
    expect(firstAyah!.text, isNotEmpty);
  });

  test('getAyahTafsir returns a single entry', () async {
    final entry = await TafsirDataSource.getAyahTafsir(
      surah: 1,
      ayah: 2,
    );
    expect(entry, isNotNull);
    expect(entry!.ayah, 2);
    expect(entry.text, isNotEmpty);
  });

  test('bookmarks are added, found, listed and removed', () async {
    await TafsirDataSource.addBookmark(
      surah: 2,
      ayah: 255,
      note: 'آية الكرسي',
    );
    expect(
      TafsirDataSource.isBookmarked(surah: 2, ayah: 255),
      isTrue,
    );
    final bookmarks = TafsirDataSource.getAllBookmarks();
    expect(bookmarks, hasLength(1));
    expect(bookmarks.first.note, 'آية الكرسي');

    await TafsirDataSource.removeBookmark(surah: 2, ayah: 255);
    expect(
      TafsirDataSource.isBookmarked(surah: 2, ayah: 255),
      isFalse,
    );
  });

  test('highlights are added, scoped by ayah, and removed', () async {
    await TafsirDataSource.addHighlight(
      TafsirHighlight(
        id: 'h1',
        surah: 1,
        ayah: 1,
        source: TafsirSourceId.muyassar,
        highlightedText: 'بسم الله',
        createdAt: DateTime(2026),
      ),
    );
    final forAyah = TafsirDataSource.getHighlightsForAyah(
      surah: 1,
      ayah: 1,
      source: TafsirSourceId.muyassar,
    );
    expect(forAyah, hasLength(1));
    expect(forAyah.first.highlightedText, 'بسم الله');

    await TafsirDataSource.removeHighlight(forAyah.first.key);
    expect(
      TafsirDataSource.getHighlightsForAyah(
        surah: 1,
        ayah: 1,
        source: TafsirSourceId.muyassar,
      ),
      isEmpty,
    );
  });

  test('annotations are added, updated, listed and removed', () async {
    await TafsirDataSource.addAnnotation(
      TafsirAnnotation(
        id: 'a1',
        surah: 1,
        ayah: 1,
        source: TafsirSourceId.muyassar,
        noteText: 'ملاحظة أولى',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    expect(
      TafsirDataSource.getAnnotationsForAyah(
        surah: 1,
        ayah: 1,
        source: TafsirSourceId.muyassar,
      ),
      hasLength(1),
    );

    await TafsirDataSource.updateAnnotation(
      TafsirAnnotation(
        id: 'a1',
        surah: 1,
        ayah: 1,
        source: TafsirSourceId.muyassar,
        noteText: 'ملاحظة محدثة',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 1, 2),
      ),
    );
    final updated = TafsirDataSource.getAnnotationsForAyah(
      surah: 1,
      ayah: 1,
      source: TafsirSourceId.muyassar,
    );
    expect(updated.first.noteText, 'ملاحظة محدثة');
    expect(TafsirDataSource.getAllAnnotations(), hasLength(1));

    await TafsirDataSource.removeAnnotation(updated.first.key);
    expect(
      TafsirDataSource.getAnnotationsForAyah(
        surah: 1,
        ayah: 1,
        source: TafsirSourceId.muyassar,
      ),
      isEmpty,
    );
  });

  test('reading history records, lists and finds the last read', () async {
    await TafsirDataSource.recordReading(
      surah: 1,
      ayah: 1,
    );
    await TafsirDataSource.recordReading(
      surah: 2,
      ayah: 255,
    );
    await TafsirDataSource.recordReading(
      surah: 2,
      ayah: 255,
    );

    final recent = TafsirDataSource.getRecentHistory();
    expect(recent, hasLength(2));
    final last = TafsirDataSource.getLastRead();
    expect(last, isNotNull);
    expect(last!.surah, 2);
    expect(last.ayah, 255);
    expect(last.readCount, 2);
  });

  test('display settings round-trip', () async {
    await TafsirDataSource.saveSettings(
      const TafsirDisplaySettings(
        primarySource: TafsirSourceId.saadi,
        compareSources: [TafsirSourceId.muyassar, TafsirSourceId.ibnKathir],
        showReferences: false,
        fontSize: 26,
        displayMode: TafsirDisplayMode.bottomSheet,
      ),
    );
    final loaded = TafsirDataSource.getSettings();
    expect(loaded.primarySource, TafsirSourceId.saadi);
    expect(loaded.compareSources, [TafsirSourceId.muyassar, TafsirSourceId.ibnKathir]);
    expect(loaded.showReferences, isFalse);
    expect(loaded.fontSize, 26);
    expect(loaded.displayMode, TafsirDisplayMode.bottomSheet);
  });
}
