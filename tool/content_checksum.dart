import 'dart:io';

import 'package:crypto/crypto.dart';

/// Content-freeze checksums for the scholarly-review tracker
/// (docs/scholarly-review.md). Freezes a shipped content set so a reviewer's
/// sign-off stays valid until the content actually changes.
///
/// Two output shapes:
/// - one input file -> a bare hex line (mirrors `hadith_db_checksum.dart`,
///   e.g. `assets/db/hadith.db.sha256`);
/// - a directory / multiple inputs -> one `"<sha256>  <rel-path>"` line per
///   file, sorted by relative path, so regenerating is deterministic.
///
/// `*.sha256` files are skipped when walking directories so a manifest stored
/// inside its own tree does not hash itself.
///
/// Usage: dart run tool/content_checksum.dart `<output>` `<file-or-dir>`...
Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('usage: dart run tool/content_checksum.dart '
        '<output.sha256> <file-or-dir>...');
    exit(64);
  }
  final output = File(args[0]);
  final inputs = args.sublist(1);

  final files = <String>{};
  for (final input in inputs) {
    final file = File(input);
    if (file.existsSync()) {
      files.add(file.path);
      continue;
    }
    final dir = Directory(input);
    if (!dir.existsSync()) {
      stderr.writeln('missing input: $input');
      exit(1);
    }
    await for (final entry in dir.list(recursive: true, followLinks: false)) {
      if (entry is File &&
          !entry.path.endsWith('.sha256') &&
          !entry.path.endsWith('README.md')) {
        files.add(entry.path);
      }
    }
  }

  final sorted = files.toList()..sort();
  final lines = <String>[];
  for (final path in sorted) {
    final bytes = await File(path).readAsBytes();
    // Forward slashes so manifests are byte-identical across platforms.
    final rel = path.replaceAll(r'\', '/');
    lines.add('${sha256.convert(bytes)}  $rel');
  }

  // Single input file -> bare hex (matches the DB checksum convention);
  // multiple files -> one "<hex>  <rel-path>" line each.
  final body = sorted.length == 1
      ? '${lines.first.split('  ').first}\n'
      : '${lines.join('\n')}\n';

  await output.writeAsString(body);
  stdout.writeln('${output.path}: ${sorted.length} file(s) frozen');
}
