import 'dart:io';

/// Preflight for a store upload: checks everything that has silently broken a
/// release before, in one place.
///
/// Fails (exit 1) when a release build would be broken or dishonest:
/// - `assets/db/hadith.db` missing — it is gitignored, so a clean checkout has
///   no hadith corpus until `dart run tool/build_hadith_db.dart` runs, and the
///   app would ship with an empty library;
/// - `assets/db/tafsir.db` missing or implausibly small;
/// - `android/key.properties` missing — the release build would fall back to
///   the debug key, which Google Play rejects;
/// - the pubspec version has no build number, or CHANGELOG.md has no entry for
///   it;
/// - `docs/scholarly-review.md` still lists pending rows — the documented
///   release blocker for shipped content.
///
/// `--allow-pending-scholar-review` downgrades only the last check to a
/// warning, for dry-running signing/build steps before the sign-offs land.
///
/// Usage: dart run tool/release_preflight.dart [--allow-pending-scholar-review]
void main(List<String> args) {
  final allowPendingReview = args.contains('--allow-pending-scholar-review');
  final failures = <String>[];
  final warnings = <String>[];

  // 1. Bundled databases.
  for (final path in ['assets/db/hadith.db', 'assets/db/tafsir.db']) {
    final file = File(path);
    if (!file.existsSync()) {
      final generator = path.contains('hadith')
          ? 'tool/build_hadith_db.dart'
          : 'tool/build_tafsir_db.dart';
      failures.add('$path is missing — generate it with `dart run $generator`');
      continue;
    }
    if (file.lengthSync() < 1024 * 1024) {
      failures.add('$path is only ${file.lengthSync()} bytes — '
          'the build is probably truncated');
    }
    if (!File('$path.sha256').existsSync()) {
      warnings.add('$path.sha256 is missing (content-freeze hash)');
    }
  }

  // 2. Release signing.
  if (!File('android/key.properties').existsSync()) {
    failures.add('android/key.properties is missing — a release build would be '
        'debug-signed, which Play rejects (see docs/store-checklist.md §4)');
  }

  // 3. Version + changelog.
  final pubspec = File('pubspec.yaml');
  final versionMatch = pubspec.existsSync()
      ? RegExp(r'^version:\s*(\S+)', multiLine: true)
          .firstMatch(pubspec.readAsStringSync())
      : null;
  final version = versionMatch?.group(1);
  if (version == null) {
    failures.add('pubspec.yaml has no version: line');
  } else {
    stdout.writeln('version: $version');
    if (!version.contains('+')) {
      failures.add('version "$version" has no build number (+N) — every '
          'upload needs a fresh one');
    } else if (version.endsWith('+0')) {
      failures.add('version "$version" has build number 0');
    }
    final changelog = File('CHANGELOG.md');
    if (!changelog.existsSync()) {
      failures.add('CHANGELOG.md is missing');
    } else if (!changelog.readAsStringSync().contains(version.split('+').first)) {
      failures.add(
        'CHANGELOG.md has no entry for ${version.split('+').first}',
      );
    }
  }

  // 4. Scholarly sign-off.
  final review = File('docs/scholarly-review.md');
  if (!review.existsSync()) {
    failures.add('docs/scholarly-review.md is missing');
  } else {
    final pending =
        RegExp(r'\|\s*pending\s*\|').allMatches(review.readAsStringSync()).length;
    if (pending > 0) {
      final message = 'docs/scholarly-review.md still lists $pending pending '
          'content row(s) — the documented store-release blocker';
      if (allowPendingReview) {
        warnings.add('$message (allowed by --allow-pending-scholar-review)');
      } else {
        failures.add(message);
      }
    }
  }

  for (final warning in warnings) {
    stderr.writeln('warning: $warning');
  }
  if (failures.isEmpty) {
    stdout.writeln('preflight OK — nothing blocks a release build');
    return;
  }
  stderr.writeln('preflight FAILED:');
  for (final failure in failures) {
    stderr.writeln('  - $failure');
  }
  exit(1);
}
