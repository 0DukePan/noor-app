import 'dart:io';

import 'package:crypto/crypto.dart';

/// Computes and writes `assets/db/hadith.db.sha256` for the current prebuilt
/// database. The build tool (tool/build_hadith_db.dart) does this
/// automatically on regeneration; run this manually after any manual change.
///
/// Usage: dart run tool/hadith_db_checksum.dart
void main() async {
  final dbFile = File('assets/db/hadith.db');
  if (!dbFile.existsSync()) {
    stderr.writeln('assets/db/hadith.db not found');
    exit(1);
  }
  final checksum = sha256.convert(await dbFile.readAsBytes()).toString();
  await File('assets/db/hadith.db.sha256').writeAsString('$checksum\n');
  stdout.writeln(checksum);
}
