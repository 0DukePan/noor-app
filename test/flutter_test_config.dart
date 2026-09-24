import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Where `matchesGoldenFile('goldens/x.png')` paths are resolved from.
final Uri _testDirectory = Directory(
  '${Directory.current.path}${Platform.pathSeparator}test',
).uri;

/// Goldens in this repo pin LAYOUT, not typography, and the two platforms do
/// not rasterise text identically: the same TTF goes through DirectWrite on
/// Windows and FreeType on the Ubuntu runner, and the two disagree by 0.07-0.82%
/// of pixels - every one of them inside a glyph. Failing on that would mean the
/// golden suite only passes on the machine that generated it, so compare with a
/// small per-pixel tolerance instead, and keep failing on anything structural
/// (a moved element, a changed colour or a missing widget moves far more than
/// 1.5% of the image).
///
/// Decoding uses dart:ui, so this costs no dependency. It is installed for every
/// test file by `test/flutter_test_config.dart`.
class TolerantGoldenFileComparator extends LocalFileComparator {
  TolerantGoldenFileComparator(super.testFile, {this.maxDiff = 0.015});

  /// Largest fraction of differing pixels still treated as a match.
  final double maxDiff;

  /// Per-channel difference below which a pixel counts as unchanged: loose
  /// enough for anti-aliasing at glyph edges, tight enough that a colour change
  /// still registers.
  static const int _channelTolerance = 8;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenFile = File.fromUri(
      golden.isAbsolute ? golden : _testDirectory.resolveUri(golden),
    );
    if (!goldenFile.existsSync()) {
      return super.compare(imageBytes, golden);
    }

    final expected = await _rawRgba(await goldenFile.readAsBytes());
    final actual = await _rawRgba(imageBytes);
    if (expected == null || actual == null) {
      return super.compare(imageBytes, golden);
    }

    // Both buffers are 4 bytes per pixel (RGBA); a length mismatch means the
    // images differ in size, which is structural by definition.
    if (expected.length != actual.length) {
      return super.compare(imageBytes, golden);
    }

    var differing = 0;
    for (var i = 0; i < expected.length; i += 4) {
      if ((expected[i] - actual[i]).abs() > _channelTolerance ||
          (expected[i + 1] - actual[i + 1]).abs() > _channelTolerance ||
          (expected[i + 2] - actual[i + 2]).abs() > _channelTolerance) {
        differing++;
      }
    }

    final total = expected.length ~/ 4;
    if (differing / total <= maxDiff) {
      return true;
    }
    // Over budget: let the default comparator write the usual diff image and
    // failure message.
    return super.compare(imageBytes, golden);
  }

  Future<Uint8List?> _rawRgba(List<int> pngBytes) async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(pngBytes));
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData();
    codec.dispose();
    return data?.buffer.asUint8List();
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  goldenFileComparator = TolerantGoldenFileComparator(
    Uri.file(
      '${Directory.current.path}${Platform.pathSeparator}test'
      '${Platform.pathSeparator}golden_test.dart',
    ),
  );
  await testMain();
}
