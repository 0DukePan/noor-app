import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/data/data_sources/tafsir_database.dart';
import 'package:noor_app/core/data/data_sources/tafsir_db_builder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// One seed row for [seedTinyTafsirTestDb].
typedef TafsirSeedRow = ({
  String source,
  int surah,
  int ayah,
  String text,
});

/// Seeds a TINY tafsir database for WIDGET tests and points the singleton at
/// it. Call once from `setUpAll`; combine with [forgetTafsirTestDb] in a
/// sync `setUp` and [abandonTafsirTestDb] in `tearDownAll`.
///
/// Why tiny instead of the real 62 MB copy: widget tests assert UI states
/// (loading/content/empty/paging), not corpus content — a dozen rows prove
/// the same paths in milliseconds with zero asset loads. Corpus fidelity is
/// covered by `test/tafsir_db_integrity_test.dart` (real artifact) and the
/// plain data-source tests (real copy). Uses the no-isolate ffi driver: no
/// worker isolate, no cross-zone messaging, nothing to shut down.
Future<Directory> seedTinyTafsirTestDb(List<TafsirSeedRow> rows) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  final tempDir = await Directory.systemTemp.createTemp('noor_tiny_tafsir');
  final db = await databaseFactory.openDatabase(
    '${tempDir.path}/tafsir_v1.db',
    options: OpenDatabaseOptions(
      version: kTafsirDbVersion,
      onCreate: (db, version) async {
        await TafsirDbSchema.create(db);
        for (final row in rows) {
          await db.insert('tafsir', {
            'source': row.source,
            'surah': row.surah,
            'ayah': row.ayah,
            'text': row.text,
          });
        }
      },
    ),
  );
  // Real zone here (setUpAll): close completes normally.
  await db.close();
  TafsirDatabase.debugDatabaseDirectory = tempDir.path;
  return tempDir;
}
/// Copies the REAL prebuilt database asset into a temp dir for PLAIN tests
/// and points the singleton at it. Call once from `setUpAll`; combine with
/// [resetTafsirTestDb] in `setUp` and [tearDownTafsirTestDb] in
/// `tearDownAll`.
///
/// Exactly ONE rootBundle load happens per test file (here), so the
/// flutter_test asset-cache trap (a second loadString hanging forever) can
/// never trigger; all subsequent reads are SQLite queries. Plain tests have
/// no FakeAsync zones, so open/query/close all behave normally here.
Future<Directory> setUpTafsirTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final tempDir = await Directory.systemTemp.createTemp('noor_tafsir_db');
  final bytes = await rootBundle.load(kTafsirDbAssetPath);
  await File('${tempDir.path}/tafsir_v1.db').writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    flush: true,
  );
  TafsirDatabase.debugDatabaseDirectory = tempDir.path;
  return tempDir;
}

/// Drops the memoized connection inside a real-async window. Call from
/// `setUp` of PLAIN tests and from [tearDownTafsirTestDb]. NEVER from a
/// widget test's setUp/tearDown — closing a live connection there hangs;
/// use [forgetTafsirTestDb] instead.
Future<void> resetTafsirTestDb() async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await binding.runAsync(TafsirDatabase.debugReset);
}

/// Synchronously forgets the memoized connection WITHOUT closing it, so the
/// test's first query opens a fresh connection in the current zone. Call
/// from a widget test's `setUp` (sync — cannot hang in any zone). The
/// previous test's handle leaks until process exit and its temp file is
/// deleted best-effort in [tearDownTafsirTestDb].
void forgetTafsirTestDb() {
  TafsirDatabase.debugForget();
}

/// Closes the singleton, unpoints it, and deletes the temp dir.
/// PLAIN tests only: closing a live connection inside a widget test hangs
/// forever (see [forgetTafsirTestDb]).
Future<void> tearDownTafsirTestDb(Directory tempDir) async {
  await resetTafsirTestDb();
  TafsirDatabase.debugDatabaseDirectory = '';
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}

/// Widget-test teardown: forget (sync, cannot hang) instead of close, unpoint,
/// and delete the temp dir best-effort. A leaked open handle keeps the file
/// locked on Windows, so deletion may fail — the OS reclaims TEMP.
Future<void> abandonTafsirTestDb(Directory tempDir) async {
  forgetTafsirTestDb();
  TafsirDatabase.debugDatabaseDirectory = '';
  try {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  } on Object catch (_) {}
}
