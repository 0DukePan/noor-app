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

/// Redirects test temp directories, e.g. to a larger volume on a runner:
/// `set NOOR_TEST_TMP=D:\Android\test-tmp` (Windows) or
/// `export NOOR_TEST_TMP=/mnt/scratch` (POSIX). Unset means the OS temp dir.
/// The REAL database asset is still copied and queried either way - this only
/// moves where the copy lives.
const String kTestTempDirEnvVar = 'NOOR_TEST_TMP';

/// How long the best-effort free-space probe may take. It runs an OS command,
/// so it is bounded: a slow or wedged child must never hang the suite.
const Duration _spaceProbeTimeout = Duration(seconds: 5);

/// Creates a fresh temp directory for one test file, honouring
/// [kTestTempDirEnvVar] when it points at a usable location.
Future<Directory> createTafsirTestTempDir(String prefix) async {
  final configured = Platform.environment[kTestTempDirEnvVar]?.trim();
  if (configured == null || configured.isEmpty) {
    return Directory.systemTemp.createTemp(prefix);
  }
  final base = Directory(configured);
  if (!base.existsSync()) {
    base.createSync(recursive: true);
  }
  return base.createTemp(prefix);
}

/// Free bytes at [path], or null when the platform cannot report them in time.
/// Best effort by design: it exists to turn a mid-copy "no space left on
/// device" into a message that names the required and available numbers, so
/// every failure path (missing command, unparseable output, timeout) returns
/// null and lets the copy decide.
Future<int?> availableBytesAt(String path) async {
  try {
    if (Platform.isWindows) {
      final escaped = path.replaceAll("'", "''");
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        "(Get-PSDrive (Get-Item -LiteralPath '$escaped').PSDrive.Name).Free",
      ]).timeout(_spaceProbeTimeout);
      return int.tryParse('${result.stdout}'.trim());
    }
    final result = await Process.run(
      'df',
      ['-Pk', path],
    ).timeout(_spaceProbeTimeout);
    if (result.exitCode != 0) return null;
    final lines = '${result.stdout}'.trim().split('\n');
    if (lines.length < 2) return null;
    final fields = lines.last.trim().split(RegExp(r'\s+'));
    if (fields.length < 4) return null;
    final availableKb = int.tryParse(fields[3]);
    return availableKb == null ? null : availableKb * 1024;
  } on Object {
    return null;
  }
}

String _megabytes(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

/// Seeds a TINY tafsir database for WIDGET tests and points the singleton at
/// it. Call once from `setUpAll`; combine with [forgetTafsirTestDb] in a
/// sync `setUp` and [abandonTafsirTestDb] in `tearDownAll`.
///
/// Why tiny instead of the real 62 MB copy: widget tests assert UI states
/// (loading/content/empty/paging), not corpus content - a dozen rows prove the
/// same paths in milliseconds with zero asset loads. Corpus fidelity is covered
/// by `test/tafsir_db_integrity_test.dart` (real artifact) and the plain
/// data-source tests (real copy). Uses the no-isolate ffi driver: no worker
/// isolate, no cross-zone messaging, nothing to shut down.
Future<Directory> seedTinyTafsirTestDb(List<TafsirSeedRow> rows) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  final tempDir = await createTafsirTestTempDir('noor_tiny_tafsir');
  try {
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
  } on Object {
    _deleteQuietly(tempDir);
    rethrow;
  }
}

/// Copies the REAL prebuilt database asset into a temp dir for PLAIN tests and
/// points the singleton at it. Call once from `setUpAll`; combine with
/// [resetTafsirTestDb] in `setUp` and [tearDownTafsirTestDb] in `tearDownAll`.
///
/// Exactly ONE rootBundle load happens per test file (here), so the
/// flutter_test asset-cache trap (a second loadString hanging forever) can
/// never trigger; all subsequent reads are SQLite queries. Plain tests have no
/// FakeAsync zones, so open/query/close all behave normally here.
///
/// Space is checked BEFORE the copy, so a small temp volume fails with the
/// required and available byte counts instead of a half-written database.
Future<Directory> setUpTafsirTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final tempDir = await createTafsirTestTempDir('noor_tafsir_db');
  try {
    final bytes = await rootBundle.load(kTafsirDbAssetPath);
    final required = bytes.lengthInBytes;
    // Probe only when a temp directory is configured: running an OS helper on
    // every default-path run wedged the suite, and the default TEMP dir is not
    // the one that runs out of room on a runner. Unconfigured runs let the
    // copy itself report ENOSPC.
    final configuredDir = Platform.environment[kTestTempDirEnvVar]?.trim();
    final available = (configuredDir == null || configuredDir.isEmpty)
        ? null
        : await availableBytesAt(tempDir.path);
    if (available != null && available < required) {
      throw StateError(
        'Tafsir test database needs ${_megabytes(required)} but only '
        '${_megabytes(available)} is free under ${tempDir.parent.path}. '
        'Set $kTestTempDirEnvVar to a directory with space and re-run '
        '(the real database is still copied - only its location changes).',
      );
    }
    await File('${tempDir.path}/tafsir_v1.db').writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    TafsirDatabase.debugDatabaseDirectory = tempDir.path;
    return tempDir;
  } on Object {
    // Setup failed: never leak the directory this call created.
    _deleteQuietly(tempDir);
    rethrow;
  }
}

/// Drops the memoized connection inside a real-async window. Call from `setUp`
/// of PLAIN tests and from [tearDownTafsirTestDb]. NEVER from a widget test's
/// setUp/tearDown - closing a live connection there hangs; use
/// [forgetTafsirTestDb] instead.
Future<void> resetTafsirTestDb() async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await binding.runAsync(TafsirDatabase.debugReset);
}

/// Synchronously forgets the memoized connection WITHOUT closing it, so the
/// test's first query opens a fresh connection in the current zone. Call from a
/// widget test's `setUp` (sync - cannot hang in any zone). The previous test's
/// handle leaks until process exit and its temp file is deleted best-effort in
/// [abandonTafsirTestDb].
void forgetTafsirTestDb() {
  TafsirDatabase.debugForget();
}

/// Closes the singleton, unpoints it, and deletes the temp dir it created.
/// PLAIN tests only: closing a live connection inside a widget test hangs
/// forever (see [forgetTafsirTestDb]). Accepts null so a `tearDownAll` still
/// works when `setUpAll` threw before it produced a directory.
Future<void> tearDownTafsirTestDb(Directory? tempDir) async {
  await resetTafsirTestDb();
  TafsirDatabase.debugDatabaseDirectory = '';
  if (tempDir == null) return;
  _deleteQuietly(tempDir);
}

/// Widget-test teardown: forget (sync, cannot hang) instead of close, unpoint,
/// and delete the temp dir best-effort. A leaked open handle keeps the file
/// locked on Windows, so deletion may fail - the OS reclaims TEMP. Nullable for
/// the same reason as [tearDownTafsirTestDb].
Future<void> abandonTafsirTestDb(Directory? tempDir) async {
  forgetTafsirTestDb();
  TafsirDatabase.debugDatabaseDirectory = '';
  if (tempDir == null) return;
  _deleteQuietly(tempDir);
}

void _deleteQuietly(Directory dir) {
  try {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  } on Object catch (_) {}
}
