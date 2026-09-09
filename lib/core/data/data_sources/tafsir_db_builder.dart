import 'dart:convert';

// Pure-Dart SQLite API (sqflite_common) — this module must stay free of
// Flutter bindings so the prebuilt-DB build tool can run as a CLI.
import 'package:sqflite_common/sqlite_api.dart';

/// إصدار مخطط قاعدة بيانات التفسير.
const int kTafsirDbVersion = 1;

/// مصادر التفسير الأربعة المجمّعة من ملفات JSON إلى قاعدة واحدة.
/// المفاتيح هي نفس أسماء قيم TafsirSourceId في `tafsir_models.dart`
/// (مكررة هنا عمداً ليبقى هذا الملف خالياً من تبعيات Flutter).
const Map<String, String> kTafsirSourceRepoDirs = {
  'muyassar': 'tool/data/tafsir/muyassar',
  'saadi': 'tool/data/tafsir/saadi',
  'tabari': 'tool/data/tafsir/tabari',
  'ibnKathir': 'tool/data/tafsir/ibn_kathir',
};

/// المسار النسبي لملف JSON لسورة معين في مستودع البناء.
/// ملفات JSON تعيش تحت `tool/data/tafsir` فقط (وقت البناء والاختبار) —
/// لا تُحزَّم في التطبيق؛ ما يُشحَن هو `assets/db/tafsir.db` وحده.
String tafsirSurahRepoPath(String source, int surah) =>
    '${kTafsirSourceRepoDirs[source]}/$surah.json';

/// الأصل المجمع المشحون مع التطبيق.
const String kTafsirDbAssetPath = 'assets/db/tafsir.db';

/// إنشاء مخطط قاعدة البيانات (جدول واحد + فهرس بحث).
class TafsirDbSchema {
  static Future<void> create(Database db) async {
    // One row per JSON entry, in file order (rowid preserves the grouping
    // order some sources use for multi-ayah ranges).
    await db.execute('''
      CREATE TABLE tafsir(
        source TEXT NOT NULL,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        text TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_tafsir_lookup ON tafsir(source, surah)',
    );
  }
}

/// إحصاءات الاستيراد (للتحقق من السلامة وإعادة البناء الحتمية).
class TafsirImportStats {
  final Map<String, int> entriesPerSource = {};
  final List<String> missingFiles = [];
  final List<String> malformedEntries = [];

  int get totalEntries =>
      entriesPerSource.values.fold(0, (a, b) => a + b);
}

/// استيراد ملفات JSON إلى قاعدة البيانات.
class TafsirDbImporter {
  /// يستورد السور 1..114 لكل مصدر. الملفات الغائبة تُتخطَّى مع تسجيلها
  /// (بعض المصادر قد لا تغطي كل السور)؛ المدخلات المشوهة تُتخطَّى كذلك.
  static Future<TafsirImportStats> importAll(
    Database db, {
    required String Function(String source, int surah) loadJson,
  }) async {
    final stats = TafsirImportStats();
    // NOTE: a sqflite Batch replays its whole queue on every commit(), so a
    // fresh batch must be started after each intermediate commit — otherwise
    // every row is inserted N times (caught by the entry-count guard below).
    var batch = db.batch();
    var pending = 0;

    for (final source in kTafsirSourceRepoDirs.keys) {
      var count = 0;
      for (var surah = 1; surah <= 114; surah++) {
        late final String raw;
        try {
          raw = loadJson(source, surah);
        } on Object {
          stats.missingFiles.add('$source/$surah.json');
          continue;
        }
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final ayahs = decoded['ayahs'] as List;
        for (final item in ayahs) {
          final map = item as Map;
          final ayah = map['ayah'];
          final text = map['text'];
          if (ayah is! int || text is! String) {
            stats.malformedEntries.add('$source/$surah: $item');
            continue;
          }
          batch.insert('tafsir', {
            'source': source,
            'surah': surah,
            'ayah': ayah,
            'text': text,
          });
          pending++;
          count++;
        }
        // Commit per surah so a 25k-row import never holds one giant batch.
        if (pending >= 2000) {
          await batch.commit(noResult: true);
          batch = db.batch();
          pending = 0;
        }
      }
      stats.entriesPerSource[source] = count;
    }
    if (pending > 0) {
      await batch.commit(noResult: true);
    }
    return stats;
  }

  /// عدد المدخلات لكل مصدر (يستخدمه اختبار السلامة).
  static Future<Map<String, int>> countPerSource(Database db) async {
    final rows = await db.rawQuery(
      'SELECT source, COUNT(*) AS c FROM tafsir GROUP BY source',
    );
    return {
      for (final row in rows)
        ((row['source'] as String?) ?? ''): ((row['c'] as int?) ?? 0),
    };
  }
}
