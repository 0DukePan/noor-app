import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/features/quran/presentation/pages/tadabbur_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Smoke tests for TadabburMihrabPage (previously zero-covered). The page
/// reads its encryption key from flutter_secure_storage and notes from the
/// Hive tadabbur box; both channels are mocked and real I/O runs through
/// `runAsync`.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_tadabbur_test');
    Hive.init(tempDir.path);
    // Same generic type HiveService uses.
    await Hive.openBox<Map<dynamic, dynamic>>('tadabbur');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      )
      // flutter_secure_storage: report no stored key; writes succeed silently.
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async {
          switch (call.method) {
            case 'read':
              return null;
            case 'write':
            case 'delete':
            case 'deleteAll':
              return null;
            case 'containsKey':
              return false;
            case 'readAll':
              return <String, dynamic>{};
          }
          return null;
        },
      );
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  testWidgets('renders the verse and its tadabbur editor', (tester) async {
    const verseText = 'بسم الله الرحمن الرحيم';
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TadabburMihrabPage(
            surahNumber: 1,
            verseNumber: 1,
            verseText: verseText,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TadabburMihrabPage), findsOneWidget);
    expect(find.textContaining(verseText), findsWidgets);
    // The note editor is present.
    expect(find.byType(TextField), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);
}
