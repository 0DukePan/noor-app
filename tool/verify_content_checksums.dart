import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Release-time verification that every shipped content set matches its
/// frozen SHA-256 in `docs/content-manifest.json`.
///
/// The manifest is the machine-readable half of `docs/scholarly-review.md`
/// and `docs/content-pipeline.md`: one entry per bundled set, carrying the
/// exact hashes recorded when the content was frozen, plus the provenance
/// fields (source, license, retrieved_at, review_status). The scholarly
/// tracker says *what a reviewer approved*; the manifest says *what bytes
/// must be on disk for that approval to still be valid*.
///
/// Fails when:
/// - the manifest is missing, unreadable, or an entry lacks a required field;
/// - a listed file is missing or its SHA-256 differs from the frozen hash
///   (this is what catches a regenerated database drifting from the reviewed
///   build — the sidecar is rewritten by the generator, the manifest is not);
/// - a sidecar's recorded hash disagrees with the manifest;
/// - a content file (*.json, *.db) under a covered root is not listed by any
///   set, or a *.sha256 sidecar is not referenced by any set.
///
/// Usage: dart run tool/verify_content_checksums.dart
Future<void> main() async {
  final failures = <String>[];
  final warnings = <String>[];

  final manifestFile = File('docs/content-manifest.json');
  if (!manifestFile.existsSync()) {
    _report(['docs/content-manifest.json is missing'], warnings);
    exit(1);
  }

  final Map<String, dynamic> manifest;
  try {
    manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  } on Object catch (error) {
    _report(['docs/content-manifest.json is not valid JSON: $error'], warnings);
    exit(1);
  }

  final sets = (manifest['sets'] as List<dynamic>? ?? [])
      .map((entry) => entry as Map<String, dynamic>)
      .toList();
  final coveredRoots = (manifest['covered_roots'] as List<dynamic>? ?? [])
      .map((entry) => entry as String)
      .toList();

  if (sets.isEmpty || coveredRoots.isEmpty) {
    final message = 'manifest declares ${sets.length} set(s) and '
        '${coveredRoots.length} covered root(s) — both must be non-empty';
    _report([message], warnings);
    exit(1);
  }

  final coveredFiles = <String>{};
  final referencedSidecars = <String>{};

  for (final set in sets) {
    final id = set['id'] as String? ?? '<missing id>';
    for (final field in ['title', 'source', 'license', 'retrieved_at',
      'review_status', 'review_ref']) {
      final value = set[field];
      if (value is! String || value.trim().isEmpty) {
        failures.add('$id: required field "$field" is missing or empty');
      }
    }
    final reviewStatus = set['review_status'] as String?;
    if (reviewStatus != null && !const {'pending', 'approved'}.contains(reviewStatus)) {
      failures.add(
        '$id: review_status "$reviewStatus" is not one of pending/approved',
      );
    }
    for (final field in ['source', 'license', 'retrieved_at']) {
      if ((set[field] as String?) == 'unrecorded') {
        warnings.add(
          '$id: $field is not recorded — required before a store release',
        );
      }
    }

    final sha256ByPath = (set['sha256'] as Map<String, dynamic>? ?? {})
        .map((path, hash) => MapEntry(path, hash as String));
    if (sha256ByPath.isEmpty) {
      failures.add('$id: no sha256 entries');
    }
    final reproducible = set['reproducible'] as bool? ?? true;

    for (final entry in sha256ByPath.entries) {
      final path = entry.key;
      if (!coveredFiles.add(path)) {
        failures.add('$id: $path is listed by more than one set');
      }
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          '$id: $path is missing'
          '${path.contains('hadith.db') ? ' — run dart run tool/build_hadith_db.dart' : ''}',
        );
        continue;
      }
      final actual = sha256.convert(file.readAsBytesSync()).toString();
      if (actual == entry.value) continue;
      if (reproducible) {
        failures.add(
          '$id: $path hash differs from the frozen manifest\n'
          '    frozen: ${entry.value}\n'
          '    actual: $actual\n'
          '    (content changed — re-review and update the manifest, or the '
          'sidecar if the change was a deliberate regeneration)',
        );
      } else {
        warnings.add(
          '$id: $path is generated at build time and not byte-reproducible; '
          'verified against its sidecar instead',
        );
      }
    }

    for (final binding in (set['checksum_files'] as List<dynamic>? ?? [])) {
      final map = binding as Map<String, dynamic>;
      final sidecarPath = map['path'] as String?;
      final covers = (map['covers'] as List<dynamic>? ?? [])
          .map((entry) => entry as String)
          .toList();
      if (sidecarPath == null || covers.isEmpty) {
        failures.add('$id: malformed checksum_files entry $binding');
        continue;
      }
      referencedSidecars.add(sidecarPath);
      final sidecar = File(sidecarPath);
      if (!sidecar.existsSync()) {
        failures.add('$id: checksum file $sidecarPath is missing');
        continue;
      }
      _verifySidecar(
        setId: id,
        sidecarPath: sidecarPath,
        covers: covers,
        sha256ByPath: sha256ByPath,
        failures: failures,
      );
    }
  }

  _verifyCoverage(
    roots: coveredRoots,
    coveredFiles: coveredFiles,
    referencedSidecars: referencedSidecars,
    failures: failures,
  );

  _report(failures, warnings);
  exit(failures.isEmpty ? 0 : 1);
}

void _verifySidecar({
  required String setId,
  required String sidecarPath,
  required List<String> covers,
  required Map<String, String> sha256ByPath,
  required List<String> failures,
}) {
  final lines = File(sidecarPath)
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    failures.add('$setId: $sidecarPath is empty');
    return;
  }

  // Bare-hex sidecar: exactly one covered file.
  if (!lines.first.contains('  ')) {
    if (covers.length != 1) {
      failures.add(
        '$setId: $sidecarPath is a bare hash but covers ${covers.length} files',
      );
      return;
    }
    final expected = sha256ByPath[covers.single];
    if (expected != null && lines.first != expected) {
      failures.add(
        '$setId: $sidecarPath records ${lines.first} but the manifest '
        'freezes $expected for ${covers.single}',
      );
    }
    return;
  }

  final recorded = <String, String>{};
  for (final line in lines) {
    final parts = line.split('  ');
    if (parts.length != 2) {
      failures.add('$setId: $sidecarPath has a malformed line: $line');
      continue;
    }
    final path = parts[1].replaceAll(r'\', '/');
    recorded[path] = parts[0];
  }
  for (final covered in covers) {
    final hash = recorded[covered];
    if (hash == null) {
      failures.add('$setId: $sidecarPath does not cover $covered');
      continue;
    }
    final expected = sha256ByPath[covered];
    if (expected != null && hash != expected) {
      failures.add(
        '$setId: $sidecarPath records $hash for $covered but the manifest '
        'freezes $expected',
      );
    }
  }
}

void _verifyCoverage({
  required List<String> roots,
  required Set<String> coveredFiles,
  required Set<String> referencedSidecars,
  required List<String> failures,
}) {
  for (final root in roots) {
    final directory = Directory(root);
    if (!directory.existsSync()) {
      failures.add('covered root $root does not exist');
      continue;
    }
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.endsWith('.sha256')) {
        if (!referencedSidecars.contains(path)) {
          failures.add(
            'covered root $root: sidecar $path is not referenced by any set '
            'in the manifest',
          );
        }
        continue;
      }
      if (!path.endsWith('.json') && !path.endsWith('.db')) continue;
      if (!coveredFiles.contains(path)) {
        failures.add(
          'covered root $root: content file $path is not listed by any set '
          'in the manifest',
        );
      }
    }
  }
}

void _report(List<String> failures, List<String> warnings) {
  for (final warning in warnings) {
    stdout.writeln('warning: $warning');
  }
  if (failures.isEmpty) {
    stdout.writeln(
      'content checksums OK — every set matches its frozen manifest hash',
    );
    return;
  }
  stderr.writeln('content checksum verification FAILED:');
  for (final failure in failures) {
    stderr.writeln('  - $failure');
  }
}
