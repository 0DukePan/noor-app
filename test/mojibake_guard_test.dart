import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against mojibake (U+FFFD replacement characters) creeping back into
/// any source, asset, or doc file. A U+FFFD means a file was written with the
/// wrong encoding at some point — the bug this test exists for.
void main() {
  test('no file contains U+FFFD replacement characters', () async {
    const roots = ['lib', 'assets', 'integration_test', 'test'];
    const files = ['README.md', 'CHANGELOG.md'];

    final offenders = <String>[];

    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && _isTextFile(entity.path)) {
          final bytes = await entity.readAsBytes();
          if (bytes.any((b) => b == 0xEF)) {
            // Only decoded as U+FFFD if followed by 0xBF 0xBD.
            for (var i = 0; i < bytes.length - 2; i++) {
              if (bytes[i] == 0xEF &&
                  bytes[i + 1] == 0xBF &&
                  bytes[i + 2] == 0xBD) {
                offenders.add(entity.path);
                break;
              }
            }
          }
        }
      }
    }

    for (final path in files) {
      final file = File(path);
      if (file.existsSync()) {
        final content = await file.readAsString();
        if (content.contains('\uFFFD')) offenders.add(path);
      }
    }

    expect(offenders, isEmpty,
        reason: 'U+FFFD (mojibake) found in: ${offenders.join(', ')}',);
  });

  test('README does not claim features that do not exist', () async {
    final readme = await File('README.md').readAsString();
    // Dead/removed capabilities must not be advertised.
    expect(readme.contains('supabase'), isFalse,
        reason: 'README must not advertise Supabase cloud sync',);
    expect(readme.contains('firebase_messaging'), isFalse,
        reason: 'README must not advertise Firebase push',);
    expect(readme.contains('fl_chart'), isFalse,
        reason: 'README must not advertise fl_chart charts',);
  });
}

bool _isTextFile(String path) {
  const extensions = {'.dart', '.json', '.yaml', '.yml', '.md', '.txt', '.html'};
  return extensions.contains(path.split('.').last);
}
