import 'dart:io';

import 'package:image/image.dart' as img;

/// Assembles `docs/media/frames/*.png` into the README demo GIF.
///
///   1. flutter test --update-goldens tool/readme_capture/readme_capture_test.dart
///   2. dart run tool/readme_capture/build_gif.dart
///
/// Frames are used at their captured size (390x844, one phone at 1x) rather
/// than upscaled: resampling would only make the file bigger and softer. To
/// replace this with a real device recording, drop the GIF at docs/media/demo.gif
/// — see docs/media/README.md.
const framesDir = 'docs/media/frames';
const outputPath = 'docs/media/demo.gif';

/// Per-frame hold, in 1/100 s (the GIF unit).
const frameDelay = 130;

void main() {
  final dir = Directory(framesDir);
  if (!dir.existsSync()) {
    stderr.writeln('No $framesDir — run the capture harness first.');
    exitCode = 1;
    return;
  }

  final frames = dir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (frames.isEmpty) {
    stderr.writeln('No PNG frames in $framesDir.');
    exitCode = 1;
    return;
  }

  final encoder = img.GifEncoder(delay: frameDelay);

  for (final file in frames) {
    final decoded = img.decodePng(file.readAsBytesSync());
    if (decoded == null) {
      stderr.writeln('Could not decode ${file.path}');
      exitCode = 1;
      return;
    }
    encoder.addFrame(decoded, duration: frameDelay);
    stdout.writeln('+ ${file.path} (${decoded.width}x${decoded.height})');
  }

  final bytes = encoder.finish();
  if (bytes == null) {
    stderr.writeln('GIF encoding failed.');
    exitCode = 1;
    return;
  }

  File(outputPath).writeAsBytesSync(bytes);
  final kb = (bytes.length / 1024).round();
  stdout.writeln('Wrote $outputPath — ${frames.length} frames, $kb KB');
}
