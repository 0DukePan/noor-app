import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/export_share_service.dart';

/// Tests for ExportShareService (previously zero-covered). generatePdf now
/// loads the bundled Amiri font first, so PDF generation is hermetic (no
/// network); the share flows are tested with path_provider + share_plus
/// channels mocked.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_export_test');
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

  final item = ExportItem(
    arabicText: 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
    source: 'صحيح البخاري',
    grade: 'صحيح',
  );

  test('generatePdf produces a valid PDF from the bundled font', () async {
    final pdf = await ExportShareService.generatePdf(
      title: 'مجموعة أذكار',
      items: [item],
    );

    expect(pdf, isNotEmpty);
    // PDF magic header.
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    expect(pdf.length, greaterThan(1000));
  });

  test('more items produce a larger PDF', () async {
    final small = await ExportShareService.generatePdf(
      title: 't',
      items: [item],
    );
    final large = await ExportShareService.generatePdf(
      title: 't',
      items: [item, item, item, item],
    );
    expect(large.length, greaterThan(small.length));
  });

  test('grade colours change the rendered output', () async {
    final sahih = await ExportShareService.generatePdf(
      title: 't',
      items: [
        ExportItem(arabicText: 'x', source: 's', grade: 'صحيح'),
      ],
    );
    final hasan = await ExportShareService.generatePdf(
      title: 't',
      items: [
        ExportItem(arabicText: 'x', source: 's', grade: 'حسن'),
      ],
    );
    expect(sahih.length, isNot(equals(hasan.length)));
  });

  test('shareText invokes the share channel', () async {
    final shareCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shareCalls.add(call);
        return null;
      },
    );

    await ExportShareService.shareText('نص للمشاركة');
    expect(shareCalls, isNotEmpty);
    expect(shareCalls.first.method, 'share');
  });

  test('sharePdf writes a file and invokes shareFiles', () async {
    final pdf = await ExportShareService.generatePdf(
      title: 't',
      items: [item],
    );
    final shareCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shareCalls.add(call);
        return null;
      },
    );

    await ExportShareService.sharePdf(pdf, 'adhkar');
    expect(shareCalls, isNotEmpty);
    expect(shareCalls.first.method, startsWith('shareFiles'));
    final files = tempDir.listSync().whereType<File>().toList();
    expect(files, isNotEmpty, reason: 'a PDF file must be written');
    expect(files.first.path, contains('.pdf'));
  });

  test('shareImage writes a PNG and invokes shareFiles', () async {
    final shareCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shareCalls.add(call);
        return null;
      },
    );

    // Minimal valid PNG bytes (1x1).
    final png = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG magic
      0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52, // IHDR
    ]);
    await ExportShareService.shareImage(png, 'card');
    expect(shareCalls, isNotEmpty);
    expect(shareCalls.first.method, startsWith('shareFiles'));
  });

  test('generateShareCard returns null without a valid boundary', () async {
    final key = GlobalKey();
    final bytes = await ExportShareService.generateShareCard(key);
    expect(bytes, isNull);
  });
}
