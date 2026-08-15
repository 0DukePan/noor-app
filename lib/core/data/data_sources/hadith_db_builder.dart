import 'dart:convert';

// Pure-Dart SQLite API (sqflite_common) — this module must stay free of
// Flutter bindings so the prebuilt-DB build tool can run as a CLI.
import 'package:sqflite_common/sqlite_api.dart';

/// إصدار مخطط قاعدة بيانات الحديث.
const int kHadithDbVersion = 2;

/// كتب مصنفة تحت `assets/hadith/by_book/the_9_books/`.
const List<String> kHadithNineBooks = [
  'bukhari', 'muslim', 'abudawud', 'tirmidhi',
  'nasai', 'ibnmajah', 'malik', 'ahmed', 'darimi',
];

/// كتب أخرى (الأربعون والمصنفات) ومساراتها النسبية.
const List<Map<String, String>> kHadithOtherBooks = [
  {'id': 'nawawi40', 'path': 'forties/nawawi40.json'},
  {'id': 'qudsi40', 'path': 'forties/qudsi40.json'},
  {'id': 'shahwaliullah40', 'path': 'forties/shahwaliullah40.json'},
  {'id': 'riyad_assalihin', 'path': 'other_books/riyad_assalihin.json'},
  {'id': 'bulugh_almaram', 'path': 'other_books/bulugh_almaram.json'},
  {'id': 'aladab_almufrad', 'path': 'other_books/aladab_almufrad.json'},
  {'id': 'mishkat_almasabih', 'path': 'other_books/mishkat_almasabih.json'},
  {'id': 'shamail_muhammadiyah', 'path': 'other_books/shamail_muhammadiyah.json'},
];

/// كل معرفات الكتب في قاعد البيانات.
List<String> get kHadithAllBookIds => [
  ...kHadithNineBooks,
  ...kHadithOtherBooks.map((b) => b['id']!),
];

/// المسار النسبي لملف JSON لكتاب معين داخل حزمة الأصول.
String hadithBookAssetPath(String bookId) {
  final book = kHadithOtherBooks.where((b) => b['id'] == bookId).firstOrNull;
  return book != null
      ? 'assets/hadith/by_book/${book['path']}'
      : 'assets/hadith/by_book/the_9_books/$bookId.json';
}

/// المسار النسبي لملف JSON لكتاب معين في مستودع البناء (خارج حزمة الأصول).
/// تُستخدم ملفات JSON فقط في وقت البناء والاختبار — لا تُحزَّن في التطبيق.
String hadithBookRepoPath(String bookId) {
  final book = kHadithOtherBooks.where((b) => b['id'] == bookId).firstOrNull;
  return book != null
      ? 'tool/data/hadith/by_book/${book['path']}'
      : 'tool/data/hadith/by_book/the_9_books/$bookId.json';
}

/// تطبيع النص العربي للبحث: إزالة التشكيل وتوحيد الهمزات وء.
String normalizeForSearch(String input) {
  const diacritics =
      '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653\u0654\u0655\u0656';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    var ch = String.fromCharCode(rune);
    if (diacritics.contains(ch)) continue;
    if (ch == 'ٱ') ch = 'ا'; // alef-wasla
    if (ch == ' ') {
      if (buffer.isEmpty || buffer.toString().endsWith(' ')) continue;
      buffer.write(' ');
      continue;
    }
    buffer.write(ch);
  }
  return buffer.toString().trim();
}

/// إنشاء مخطط قاعدة البيانات (جدولان + فهارس + FTS5).
class HadithDbSchema {
  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS collections (
        id TEXT PRIMARY KEY,
        title_arabic TEXT NOT NULL,
        title_english TEXT,
        author_arabic TEXT,
        author_english TEXT,
        introduction TEXT,
        hadith_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chapters (
        id INTEGER,
        collection_id TEXT NOT NULL,
        title_arabic TEXT NOT NULL,
        title_english TEXT,
        PRIMARY KEY (id, collection_id),
        FOREIGN KEY (collection_id) REFERENCES collections(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS hadiths (
        id INTEGER,
        id_in_book INTEGER,
        collection_id TEXT NOT NULL,
        chapter_id INTEGER,
        arabic TEXT NOT NULL,
        arabic_norm TEXT,
        english_narrator TEXT,
        english_text TEXT,
        PRIMARY KEY (id, collection_id),
        FOREIGN KEY (collection_id) REFERENCES collections(id)
      )
    ''');

    // Indices for fast lookups
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hadiths_collection ON hadiths(collection_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hadiths_chapter ON hadiths(collection_id, chapter_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_chapters_collection ON chapters(collection_id)');

    // FTS5 virtual table for full-text search.
    // arabic_norm is the de-diacritized Arabic text, so searches work
    // whether or not the user types diacritics.
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS hadiths_fts USING fts5(
        arabic_norm, 
        english_text, 
        english_narrator,
        content='hadiths',
        content_rowid='rowid'
      )
    ''');
  }
}

/// استيراد بيانات الأحاديث إلى قاعدة بيانات مفتوحة.
class HadithDbImporter {
  /// ترقية v1 → v2: عمود arabic_norm وإعادة بناء فهرس FTS.
  static Future<void> migrateToV2(Database db) async {
    try {
      await db.execute('ALTER TABLE hadiths ADD COLUMN arabic_norm TEXT');
    } on Exception catch (_) {
      // Column may already exist on partially migrated databases.
    }

    // Backfill normalized text in batches.
    const batchSize = 1000;
    var offset = 0;
    while (true) {
      final rows = await db.query(
        'hadiths',
        columns: ['rowid', 'arabic'],
        limit: batchSize,
        offset: offset,
      );
      if (rows.isEmpty) break;
      final batch = db.batch();
      for (final row in rows) {
        batch.update(
          'hadiths',
          {'arabic_norm': normalizeForSearch(row['arabic'] as String? ?? '')},
          where: 'rowid = ?',
          whereArgs: [row['rowid']],
        );
      }
      await batch.commit(noResult: true);
      offset += rows.length;
    }

    // Recreate the FTS table over arabic_norm and rebuild it.
    try {
      await db.execute('DROP TABLE hadiths_fts');
    } on Exception catch (_) {}
    await HadithDbSchema.create(db);
    await rebuildFts(db);
  }

  /// استيراد كتب متعددة (بالمعرفات) من مصادر JSON محلية.
  static Future<void> importAll(
    Database db,
    List<String> bookIds, {
    required String Function(String bookId) loadJson,
  }) async {
    for (final bookId in bookIds) {
      await importBookJson(db, bookId, loadJson(bookId));
    }
    await rebuildFts(db);
  }

  /// استيراد كتاب واحد من نص JSON كامل.
  static Future<void> importBookJson(
    Database db,
    String bookId,
    String jsonString,
  ) async {
    final json = Map<String, dynamic>.from(jsonDecode(jsonString) as Map);

    // --- Collection metadata ---
    final meta = json['metadata'] as Map<String, dynamic>;
    final arabicMeta = meta['arabic'] as Map<String, dynamic>? ?? {};
    final englishMeta = meta['english'] as Map<String, dynamic>? ?? {};
    final hadithsList = (json['hadiths'] as List?) ?? [];

    await db.insert('collections', {
      'id': bookId,
      'title_arabic': arabicMeta['title'] ?? bookId,
      'title_english': englishMeta['title'] ?? bookId,
      'author_arabic': arabicMeta['author'] ?? '',
      'author_english': englishMeta['author'] ?? '',
      'introduction': arabicMeta['introduction'] ?? '',
      'hadith_count': hadithsList.length,
    }, conflictAlgorithm: ConflictAlgorithm.replace,);

    // --- Chapters ---
    final chaptersList = (json['chapters'] as List?) ?? [];
    final chapterBatch = db.batch();
    for (final c in chaptersList) {
      chapterBatch.insert('chapters', {
        'id': (c as Map)['id'],
        'collection_id': bookId,
        'title_arabic': c['arabic'] ?? '',
        'title_english': c['english'] ?? '',
      }, conflictAlgorithm: ConflictAlgorithm.replace,);
    }
    await chapterBatch.commit(noResult: true);

    // --- Hadiths (batches of 500 to avoid memory spikes) ---
    const batchSize = 500;
    for (var i = 0; i < hadithsList.length; i += batchSize) {
      final end = (i + batchSize > hadithsList.length)
          ? hadithsList.length
          : i + batchSize;
      final batch = db.batch();

      for (var j = i; j < end; j++) {
        final h = hadithsList[j] as Map<String, dynamic>;
        final engMap = h['english'] as Map<String, dynamic>? ?? {};

        batch.insert('hadiths', {
          'id': h['id'] ?? j,
          'id_in_book': h['idInBook'] ?? h['id'] ?? j,
          'collection_id': bookId,
          'chapter_id': h['chapterId'] ?? 0,
          'arabic': h['arabic'] ?? '',
          'arabic_norm': normalizeForSearch((h['arabic'] ?? '') as String),
          'english_narrator': engMap['narrator'] ?? '',
          'english_text': engMap['text'] ?? '',
        }, conflictAlgorithm: ConflictAlgorithm.replace,);
      }

      await batch.commit(noResult: true);
    }
  }

  /// إعادة بناء فهرس FTS5 ليتوافق مع جدول المحتوى.
  static Future<void> rebuildFts(Database db) async {
    try {
      await db.execute("INSERT INTO hadiths_fts(hadiths_fts) VALUES('rebuild')");
    } on Exception catch (e) {
      // The import continues; search falls back to LIKE on arabic_norm.
      assert(false, 'FTS rebuild failed: $e');
    }
  }
}
