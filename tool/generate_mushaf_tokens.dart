import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:noor_app/features/quran/data/mushaf_token_codec.dart';

/// Deterministic Mushaf token generator (Phase 1.4).
///
/// Reads the approved content and emits the page-token asset plus manifest
/// data. Do NOT generate on the device — run this tool and ship the output.
///
/// - Inputs: `assets/quran/quran_pages.json`, `assets/quran/quran_uthmani.json`
/// - Outputs: `assets/quran/mushaf_tokens.json`,
///   `assets/quran/mushaf_tokens.sha256` (sidecar)
/// - Deterministic: same inputs produce byte-identical output. Sorted keys,
///   fixed indentation, no timestamps in the artifact.
///
/// Usage: `dart run tool/generate_mushaf_tokens.dart [--root <dir>] [--check]`
/// `--check` rebuilds in memory and fails when the on-disk artifact differs.
Future<void> main(List<String> args) async {
  var root = '.';
  var check = false;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--root' && i + 1 < args.length) root = args[++i];
    if (args[i] == '--check') check = true;
  }

  final pagesFile = File('$root/assets/quran/quran_pages.json');
  final canonicalFile = File('$root/assets/quran/quran_uthmani.json');
  final outFile = File('$root/assets/quran/mushaf_tokens.json');
  final sidecarFile = File('$root/assets/quran/mushaf_tokens.sha256');

  final pagesMap =
      jsonDecode(pagesFile.readAsStringSync()) as Map<String, dynamic>;
  final canonicalMap =
      jsonDecode(canonicalFile.readAsStringSync()) as Map<String, dynamic>;

  final build = buildMushafTokens(
    pagesMap: pagesMap,
    canonicalMap: canonicalMap,
  );

  final sourceHashes = {
    'quran_pages.json': sha256.convert(pagesFile.readAsBytesSync()).toString(),
    'quran_uthmani.json': sha256
        .convert(canonicalFile.readAsBytesSync())
        .toString(),
  };

  final sortedPages = <String, Object?>{};
  final pageKeys = build.pages.keys.toList()
    ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  for (final key in pageKeys) {
    sortedPages[key] = build.pages[key]!.toJson();
  }

  final document = <String, Object?>{
    'schema': 1,
    'generator': 'tool/generate_mushaf_tokens.dart',
    'sourceHashes': sourceHashes,
    'report': build.report.toJson()..remove('basmalaPages'),
    'basmalaPages': build.report.basmalaPages,
    'pages': sortedPages,
  };

  const encoder = JsonEncoder.withIndent('  ');
  final bytes = utf8.encode('${encoder.convert(document)}\n');

  if (check) {
    if (!outFile.existsSync()) {
      stderr.writeln('CHECK FAILED: ${outFile.path} does not exist');
      exit(1);
    }
    final current = outFile.readAsBytesSync();
    if (!_bytesEqual(current, bytes)) {
      stderr.writeln(
        'CHECK FAILED: ${outFile.path} differs from a fresh deterministic '
        'build — regenerate with dart run tool/generate_mushaf_tokens.dart '
        'and review the diff with scholarship before updating the manifest.',
      );
      exit(1);
    }
    stdout.writeln(
      'mushaf tokens check passed: 604 pages, '
      '${build.report.uniqueIdentities} identities, '
      '${build.report.basmalaPages.length} basmala tokens, '
      '${build.report.anomalies.length} anomalies.',
    );
    return;
  }

  outFile.writeAsBytesSync(bytes);
  final digest = sha256.convert(bytes).toString();
  // Bare-hex sidecar, matching the other Quran sidecars
  // (assets/quran/quran_uthmani.sha256): exactly one covered file.
  sidecarFile.writeAsStringSync('$digest\n');

  stdout
    ..writeln('wrote ${outFile.path} (${bytes.length} bytes)')
    ..writeln('sha256: $digest');
  stdout.writeln(
    'report: pages=${build.report.pageCount} '
    'identities=${build.report.uniqueIdentities} '
    'exact=${build.report.exactMatches} diffs=${build.report.differences} '
    'basmalaPages=${build.report.basmalaPages.length} '
    'anomalies=${build.report.anomalies.length}',
  );
  for (final anomaly in build.report.anomalies) {
    stdout.writeln('anomaly: $anomaly');
  }
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
