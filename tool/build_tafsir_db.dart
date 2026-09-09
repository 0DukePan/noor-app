import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:noor_app/core/data/data_sources/tafsir_db_builder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Builds the prebuilt tafsir SQLite database shipped as an asset so release
/// installs don't carry 25,401 loose JSON files (113 MB of per-ayah/per-surah
/// fragments across four sources) and first launch needs no import at all.
///
/// Reads the build-time corpus from `tool/data/tafsir/<source>/<surah>.json`
/// (NOT shipped in the app bundle).
///
/// Usage: dart run tool/build_tafsir_db.dart
void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Directory('assets/db').createSync(recursive: true);
  final outFile = File('assets/db/tafsir.db');
  final dbPath = outFile.absolute.path;
  if (outFile.existsSync()) outFile.deleteSync();

  final stopwatch = Stopwatch()..start();
  stdout.writeln('Building prebuilt tafsir database (4 sources x 114 surahs)...');

  try {
    TafsirImportStats? importStats;
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: kTafsirDbVersion,
        onCreate: (db, version) async {
          await TafsirDbSchema.create(db);
          importStats = await TafsirDbImporter.importAll(
            db,
            loadJson: (source, surah) =>
                File(tafsirSurahRepoPath(source, surah)).readAsStringSync(),
          );
          final stats = importStats!;
          for (final entry in stats.entriesPerSource.entries) {
            stdout.writeln('  ${entry.key}: ${entry.value} entries');
          }
          stdout.writeln('  total: ${stats.totalEntries} entries');
          if (stats.missingFiles.isNotEmpty) {
            stdout.writeln(
              '  missing files (${stats.missingFiles.length}): '
              '${stats.missingFiles.take(10).join(', ')}'
              '${stats.missingFiles.length > 10 ? ' ...' : ''}',
            );
          }
          if (stats.malformedEntries.isNotEmpty) {
            stdout.writeln(
              '  MALFORMED (${stats.malformedEntries.length}): '
              '${stats.malformedEntries.take(10).join(' | ')}',
            );
            throw StateError(
              '${stats.malformedEntries.length} malformed entries — refusing '
              'to ship a corrupt database.',
            );
          }
        },
      ),
    );
    stdout.writeln('db version: ${await db.getVersion()}');
    final count = await db.rawQuery('SELECT COUNT(*) AS c FROM tafsir');
    final dbTotal = (count.first['c'] as int?) ?? 0;
    stdout.writeln('tafsir entries: $dbTotal');
    // Guard against duplicate-insert bugs (e.g. batch replay): the table
    // must hold exactly what the importer reported.
    if (importStats != null && dbTotal != importStats!.totalEntries) {
      throw StateError(
        'DB holds $dbTotal rows but the importer reported '
        '${importStats!.totalEntries} — build is corrupt.',
      );
    }
    await db.close();
  } on Exception catch (e, st) {
    stdout.writeln('BUILD FAILED: $e\n$st');
    exit(1);
  }
  stopwatch.stop();

  final sizeMb = outFile.lengthSync() / (1024 * 1024);
  stdout.writeln(
    'Built $dbPath (${sizeMb.toStringAsFixed(1)} MB) in ${stopwatch.elapsed.inSeconds}s',
  );

  // Record the SHA-256 checksum next to the database so the integrity guard
  // (test/tafsir_db_integrity_test.dart) can detect drift on regeneration.
  final checksum = sha256.convert(await outFile.readAsBytes()).toString();
  await File('assets/db/tafsir.db.sha256').writeAsString('$checksum\n');
  stdout.writeln('Checksum: $checksum');
}
