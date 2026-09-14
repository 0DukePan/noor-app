import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/features/tafsir/presentation/pages/tafsir_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

import '../test_utils/tafsir_test_db.dart';

/// Smoke tests for TafsirPage (previously zero-covered, the largest remaining
/// file at 335 lines). The page loads the real tafsir from the prebuilt
/// database, so the async database I/O runs through `runAsync`.
void main() {
  late Directory dbDir;

  setUpAll(() async {
    dbDir = await seedTinyTafsirTestDb([
      for (var ayah = 1; ayah <= 2; ayah++)
        (source: 'muyassar', surah: 1, ayah: ayah, text: 'تفسير ميسر 1:$ayah'),
      for (var ayah = 1; ayah <= 2; ayah++)
        (source: 'muyassar', surah: 2, ayah: ayah, text: 'تفسير ميسر 2:$ayah'),
    ]);
  });

  tearDownAll(() async {
    await abandonTafsirTestDb(dbDir);
  });

  setUp(() {
    // Sync forget per test: fresh current-zone connection (see the zone
    // note in test_utils/tafsir_test_db.dart).
    forgetTafsirTestDb();
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  Future<void> pumpLoaded(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('renders the default surah tafsir from bundled assets',
      (tester) async {
    await pumpLoaded(tester, const TafsirPage());

    expect(find.byType(TafsirPage), findsOneWidget);
    // Loading indicator resolved into content: the surah title renders.
    expect(
      find.byType(CircularProgressIndicator).evaluate().isEmpty,
      isTrue,
    );
    // The page's title row shows the current surah name.
    expect(find.textContaining('الفاتحة'), findsWidgets);
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('honours the initialSurah parameter', (tester) async {
    await pumpLoaded(tester, const TafsirPage(initialSurah: 2));

    expect(find.textContaining('البقرة'), findsWidgets);
  },
  timeout: const Timeout(Duration(seconds: 60)),
);
}
