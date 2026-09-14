import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';
import 'package:noor_app/core/data/data_sources/hadith_db_builder.dart';
import 'package:noor_app/core/data/data_sources/local_hadith_data_source.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tests for LocalHadithDataSource (previously zero-covered) against a seeded
/// SQLite database: the singleton is pointed at a temp dir whose hadith_v1.db
/// is created with the real schema plus deterministic rows, so the data-source
/// methods run without the 17-book import or platform channels.
void main() {
  late Directory tempDir;
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    tempDir = await Directory.systemTemp.createTemp('noor_lhds_test');
    final dbPath = '${tempDir.path}${Platform.pathSeparator}hadith_v1.db';
    db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: kHadithDbVersion,
        onCreate: (db, version) async {
          await HadithDbSchema.create(db);
          await db.insert('collections', {
            'id': 'bukhari',
            'title_arabic': 'صحيح البخاري',
            'title_english': 'Sahih al-Bukhari',
            'author_arabic': 'محمد بن إسماعيل البخاري',
            'hadith_count': 2,
          });
          await db.insert('chapters', {
            'id': 1,
            'collection_id': 'bukhari',
            'title_arabic': 'كتاب الوضوء',
            'title_english': 'Ablution',
          });
          for (var i = 1; i <= 2; i++) {
            await db.insert('hadiths', {
              'id': i,
              'id_in_book': i,
              'collection_id': 'bukhari',
              'chapter_id': 1,
              'arabic':
                  'حَدَّثَنَا مَالِكٌ عَنْ نَافِعٍ عَنْ عَبْدِ اللَّهِ بْنِ عُمَرَ',
              'arabic_norm': 'حدثنا مالك عن نافع عن عبد الله بن عمر',
              'english_narrator': 'Umar ibn al-Khattab',
              'english_text': 'Actions are but by intentions',
            });
          }
        },
      ),
    );
    HadithDatabase.debugDatabaseDirectory = tempDir.path;
  });

  tearDownAll(() async {
    await db.close();
    HadithDatabase.debugDatabaseDirectory = '';
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('getCollections returns the seeded collection metadata', () async {
    final collections = await LocalHadithDataSource().getCollections();
    expect(collections, hasLength(1));
    expect(collections.first.id, 'bukhari');
    expect(collections.first.titleArabic, 'صحيح البخاري');
    expect(collections.first.hadithsCount, 2);
  });

  test('getBookSummary loads metadata and chapters without hadiths', () async {
    final book = await LocalHadithDataSource().getBookSummary('bukhari');
    expect(book.metadata.title, 'صحيح البخاري');
    expect(book.chapters, hasLength(1));
    expect(book.chapters.first.topicArabic, 'كتاب الوضوء');
    expect(book.hadiths, isEmpty);
  });

  test('getHadithsPage paginates the seeded hadiths', () async {
    final ds = LocalHadithDataSource();
    final page = await ds.getHadithsPage(
      bookId: 'bukhari',
      page: 1,
      limit: 10,
    );
    expect(page, hasLength(2));
    expect(page.first.idInBook, 1);
    expect(page.first.collectionId, 'bukhari');
    expect(page.first.arabic, contains('عَنْ نَافِعٍ'));
  });

  test('searchByNarrator filters by the narrator field', () async {
    final results = await LocalHadithDataSource().searchByNarrator('Umar');
    expect(results, hasLength(2));
    for (final h in results) {
      expect(h.narratorEnglish, contains('Umar'));
    }
  });

  test('getRandomHadith returns one of the seeded hadiths', () async {
    final hadith = await LocalHadithDataSource().getRandomHadith();
    expect(hadith, isNotNull);
    expect(hadith!.collectionId, 'bukhari');
  });
}
