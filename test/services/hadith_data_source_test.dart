import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';
import 'package:noor_app/core/data/data_sources/hadith_db_builder.dart';
import 'package:noor_app/core/services/hadith_data_source.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// HadithDataSource (previously zero-covered): static facade over the
/// HadithDatabase singleton, pointed at a temp dir seeded with the real
/// schema + two Bukhari rows (same pattern as local_hadith_data_source_test).
void main() {
  late Directory tempDir;
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    tempDir = await Directory.systemTemp.createTemp('noor_hds_test');
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
              'arabic': 'حديث رقم $i',
              'arabic_norm': 'حديث رقم $i',
              'english_narrator': 'Narrator $i',
              'english_text': 'Text $i',
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

  test('getBooks exposes the nine-book catalog with spot counts', () {
    final books = HadithDataSource.getBooks();
    expect(books, hasLength(9));
    final byId = {for (final b in books) b.id: b};
    expect(byId['bukhari']!.hadithCount, 7277);
    expect(byId['ahmed']!.hadithCount, 26363);
    for (final book in books) {
      expect(book.arabicName, isNotEmpty);
      expect(book.englishName, isNotEmpty);
      expect(book.author, isNotEmpty);
    }
  });

  test('getRandomHadith enriches the row with book metadata', () async {
    final hadith = await HadithDataSource.getRandomHadith();
    expect(hadith, isNotNull);
    expect(hadith!['bookId'], 'bukhari');
    expect(hadith['bookName'], 'صحيح البخاري');
  });

  test('getRandomHadith with a book filter respects it', () async {
    final hadith = await HadithDataSource.getRandomHadith(bookId: 'bukhari');
    expect(hadith, isNotNull);
    expect(hadith!['bookId'], 'bukhari');
  });

  test('getDailyHadith is deterministic within the same day', () async {
    final first = await HadithDataSource.getDailyHadith();
    final second = await HadithDataSource.getDailyHadith();
    expect(first, isNotNull);
    expect(first!['id'], second!['id']);
    expect(first['bookName'], 'صحيح البخاري');
  });
}
