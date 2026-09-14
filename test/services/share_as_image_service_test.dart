import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/core/services/share_as_image_service.dart';

/// Tests for ShareAsImageService (previously zero-covered): the off-screen
/// widget-to-image pipeline produces a real PNG and share_plus is invoked,
/// with path_provider + share channels mocked.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_sai_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      )
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempDir.path,
      );
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  testWidgets('shareQuranVerse renders to a PNG and invokes share_plus',
      (tester) async {
    final shareCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shareCalls.add(call);
        return null;
      },
    );

    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

    await tester.runAsync(() async {
      await ShareAsImageService.shareQuranVerse(
        context: tester.element(find.byType(Scaffold)),
        verseText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        surah: 1,
        ayah: 1,
        surahName: 'الفاتحة',
      );
    });
    await tester.pump();

    expect(
      shareCalls,
      isNotEmpty,
      reason: 'share_plus must be invoked after capture',
    );
    expect(shareCalls.first.method, startsWith('shareFiles'));
    // The PNG file was written to the temp directory.
    final files = tempDir.listSync().whereType<File>().toList();
    expect(files, isNotEmpty, reason: 'a share image file must be written');
    expect(files.first.path, contains('quran_1_1'));
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('shareHadith renders to a PNG and invokes share_plus',
      (tester) async {
    final shareCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shareCalls.add(call);
        return null;
      },
    );

    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

    await tester.runAsync(() async {
      await ShareAsImageService.shareHadith(
        context: tester.element(find.byType(Scaffold)),
        hadithText: 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
        source: 'صحيح البخاري',
        narrator: 'عمر بن الخطاب',
        grade: 'صحيح',
      );
    });
    await tester.pump();

    expect(shareCalls, isNotEmpty);
    expect(shareCalls.first.method, startsWith('shareFiles'));
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  test('design enums expose all variants', () {
    expect(VerseDesign.values, [
      VerseDesign.classic,
      VerseDesign.golden,
      VerseDesign.minimal,
      VerseDesign.night,
    ]);
    expect(HadithDesign.values, [
      HadithDesign.elegant,
      HadithDesign.simple,
      HadithDesign.scholarly,
    ]);
  });
}
