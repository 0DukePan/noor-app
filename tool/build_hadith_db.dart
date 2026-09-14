import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:noor_app/core/data/data_sources/hadith_db_builder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Builds the prebuilt hadith SQLite database shipped as an asset so release
/// installs start instantly (first launch copies the file instead of
/// importing 17 books from JSON).
///
/// Usage: dart run tool/build_hadith_db.dart
void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Directory('assets/db').createSync(recursive: true);
  final outFile = File('assets/db/hadith.db');
  final dbPath =
      outFile.absolute.path; // ffi resolves relative paths to its own dir
  if (outFile.existsSync()) outFile.deleteSync();

  final stopwatch = Stopwatch()..start();
  stdout.writeln(
    'Building prebuilt hadith database (${kHadithAllBookIds.length} books)...',
  );

  try {
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: kHadithDbVersion,
        onCreate: (db, version) async {
          await HadithDbSchema.create(db);
          await HadithDbImporter.importAll(
            db,
            kHadithAllBookIds,
            loadJson: (bookId) =>
                File(hadithBookRepoPath(bookId)).readAsStringSync(),
          );
        },
      ),
    );
    stdout.writeln('db version: ${await db.getVersion()}');
    final count = await db.rawQuery('SELECT COUNT(*) AS c FROM hadiths');
    stdout.writeln('hadiths: ${count.first['c']}');
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
  // (test/hadith_db_integrity_test.dart) can detect drift on regeneration.
  final checksum = sha256.convert(await outFile.readAsBytes()).toString();
  await File('assets/db/hadith.db.sha256').writeAsString('$checksum\n');
  stdout.writeln('Checksum: $checksum');
}
