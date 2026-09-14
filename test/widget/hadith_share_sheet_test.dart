import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/core/domain/entities/hadith.dart';
import 'package:noor_app/features/hadith/presentation/widgets/hadith_share_sheet.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Tests for HadithShareSheet (previously zero-covered): the preview renders,
/// and the full share flow (widget capture -> temp file -> share_plus) works
/// with the path_provider and share_plus channels mocked.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_share_test');
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

  const hadith = Hadith(
    id: 42,
    idInBook: 7,
    arabic: 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
    englishText: 'Actions are but by intentions',
    narratorEnglish: 'Umar',
    chapterId: 1,
    collectionId: 'bukhari',
  );

  testWidgets('renders the share preview', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HadithShareSheet(
            hadith: hadith,
            bookTitle: 'صحيح البخاري',
            bookColor: Colors.teal,
          ),
        ),
      ),
    );

    expect(find.byType(HadithShareSheet), findsOneWidget);
    // The preview card shows the hadith text.
    expect(find.textContaining('إِنَّمَا الْأَعْمَال'), findsWidgets);
    // The share button exists.
    expect(find.byType(ElevatedButton), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('tapping share captures the card and calls share_plus',
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

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HadithShareSheet(
            hadith: hadith,
            bookTitle: 'صحيح البخاري',
            bookColor: Colors.teal,
          ),
        ),
      ),
    );

    // The capture + file I/O are real async operations; poll for the share
// call with a deadline instead of sleeping a fixed duration (which flakes
// under full-suite CPU load).
    await tester.runAsync(() async {
      await tester.tap(find.byType(ElevatedButton));
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (shareCalls.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pump();

    expect(
      shareCalls,
      isNotEmpty,
      reason: 'share_plus must be invoked after capture',
    );
    expect(shareCalls.first.method, startsWith('shareFiles'));
    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);
}
