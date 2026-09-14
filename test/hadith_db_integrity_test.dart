import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Integrity guard for the prebuilt hadith database asset.
///
/// The SHA-256 in assets/db/hadith.db.sha256 is regenerated together with the
/// database by tool/build_hadith_db.dart. If the committed DB and its
/// checksum ever disagree (partial regeneration, a stray write, a botched
/// merge), this test fails — the exact "automated diff on regeneration" the
/// plan calls for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the prebuilt hadith.db matches its committed SHA-256 checksum',
      () async {
    final bytes = await rootBundle.load('assets/db/hadith.db');
    final actual = sha256
        .convert(
          bytes.buffer.asUint8List(
            bytes.offsetInBytes,
            bytes.lengthInBytes,
          ),
        )
        .toString();

    final checksumFile = File('assets/db/hadith.db.sha256');
    expect(
      checksumFile.existsSync(),
      isTrue,
      reason:
          'missing checksum file — run dart run tool/hadith_db_checksum.dart',
    );
    final expected = (await checksumFile.readAsString()).trim();

    expect(
      actual,
      expected,
      reason: 'hadith.db changed without regenerating its checksum — '
          'rebuild with dart run tool/build_hadith_db.dart',
    );
  });
}
