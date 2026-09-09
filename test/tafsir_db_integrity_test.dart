import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/data/data_sources/tafsir_db_builder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integrity guard for the prebuilt tafsir database asset.
///
/// The SHA-256 in assets/db/tafsir.db.sha256 is regenerated together with the
/// database by `dart run tool/build_tafsir_db.dart` (corpus:
/// `tool/data/tafsir/<source>/<surah>.json`). If the committed DB and its
/// checksum ever disagree, or the content drifts from the corpus contract
/// (6,236 verses x 4 sources), this test fails.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the prebuilt tafsir.db matches its committed SHA-256 checksum',
      () async {
    final bytes = await rootBundle.load(kTafsirDbAssetPath);
    final actual = sha256
        .convert(
          bytes.buffer.asUint8List(
            bytes.offsetInBytes,
            bytes.lengthInBytes,
          ),
        )
        .toString();

    final checksumFile = File('assets/db/tafsir.db.sha256');
    expect(
      checksumFile.existsSync(),
      isTrue,
      reason: 'missing checksum file — run dart run tool/build_tafsir_db.dart',
    );
    final expected = (await checksumFile.readAsString()).trim();

    expect(
      actual,
      expected,
      reason: 'tafsir.db changed without regeneration — '
          'rebuild with dart run tool/build_tafsir_db.dart',
    );
  });

  test('tafsir.db holds the full 6,236-verse corpus in all four sources',
      () async {
    sqfliteFfiInit();
    // ffi resolves relative paths against its own databases dir, so open by
    // absolute path.
    final dbFile = File('assets/db/tafsir.db').absolute;
    final db = await databaseFactoryFfi.openDatabase(
      dbFile.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    addTearDown(db.close);

    final counts = await TafsirDbImporter.countPerSource(db);
    expect(
      counts.keys.toSet(),
      {'muyassar', 'saadi', 'tabari', 'ibnKathir'},
      reason: 'all four tafsir sources must be present',
    );
    for (final entry in counts.entries) {
      expect(
        entry.value,
        6236,
        reason: '${entry.key} must cover all 6,236 Quranic verses',
      );
    }

    // Every source covers all 114 surahs.
    for (final source in counts.keys) {
      final rows = await db.rawQuery(
        'SELECT COUNT(DISTINCT surah) AS c FROM tafsir WHERE source = ?',
        [source],
      );
      expect(
        (rows.first['c'] as int?) ?? 0,
        114,
        reason: '$source must cover all 114 surahs',
      );
    }

    // Spot-checks: Al-Fatiha 1:1 exists with real text in every source, and
    // the last verse of the mushaf (114:6) is present too.
    for (final source in counts.keys) {
      final first = await db.query(
        'tafsir',
        columns: const ['text'],
        where: 'source = ? AND surah = ? AND ayah = ?',
        whereArgs: [source, 1, 1],
      );
      expect(first, hasLength(1), reason: '$source missing Al-Fatiha 1:1');
      expect(
        ((first.first['text'] as String?) ?? '').trim().isNotEmpty,
        isTrue,
        reason: '$source Al-Fatiha 1:1 text is empty',
      );
      final last = await db.query(
        'tafsir',
        columns: const ['text'],
        where: 'source = ? AND surah = ? AND ayah = ?',
        whereArgs: [source, 114, 6],
      );
      expect(last, hasLength(1), reason: '$source missing An-Nas 114:6');
    }
  });
}
