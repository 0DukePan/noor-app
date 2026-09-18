import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/features/quran/presentation/pages/tafsir_reader_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

import '../test_utils/tafsir_test_db.dart';

/// State-depth tests for TafsirReaderPage: loading, empty (missing surah),
/// and populated (real tafsir from the prebuilt database) branches. The async
/// database load runs through runAsync.
void main() {
  late Directory dbDir;

  setUpAll(() async {
    dbDir = await seedTinyTafsirTestDb([
      (source: 'muyassar', surah: 1, ayah: 1, text: 'تفسير ميسر 1:1'),
      for (var ayah = 1; ayah <= 3; ayah++)
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

  Future<void> pumpReader(WidgetTester tester, int surah, int ayah) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TafsirReaderPage(
          surahNumber: surah,
          ayahNumber: ayah,
          surahName: '',
        ),
      ),
    );
  }

  /// Lets the async database load finish: a single generous real-event-loop
  /// window (the established pattern for real I/O under testWidgets — sliced
  /// runAsync loops don't drain the pending fake-zone continuations).
  Future<void> waitForLoad(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1500)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows the loading indicator while the tafsir loads',
      (tester) async {
    await pumpReader(tester, 1, 1);
    // First frame: the load is still in flight.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await waitForLoad(tester);
    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('shows the empty state for a surah with no bundled tafsir',
      (tester) async {
    await pumpReader(tester, 999, 1);
    await waitForLoad(tester);

    expect(find.text('التفسير غير متوفر'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('renders the bundled tafsir entries when available',
      (tester) async {
    // Al-Baqarah's full tafsir from the database.
    await pumpReader(tester, 2, 1);
    await waitForLoad(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('التفسير غير متوفر'), findsNothing);
    // The tafsir list renders (Al-Baqara's full tafsir from the bundle).
    expect(find.byType(ListView), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('compare stepper keeps its 48dp tap targets and labels',
      (tester) async {
    await pumpReader(tester, 2, 1);
    await waitForLoad(tester);

    // Open comparative mode from the compare icon on an entry header.
    await tester.tap(find.byIcon(Icons.compare_rounded).first);
    await tester.pump(const Duration(milliseconds: 200));

    for (final label in ['السابق', 'التالي']) {
      final button = find.ancestor(
        of: find.byTooltip(label),
        matching: find.byType(IconButton),
      );
      expect(button, findsOneWidget, reason: label);
      // The stepper used to set VisualDensity.compact, which lays the buttons
      // out at 40dp — below the 48dp Android minimum. The label-only
      // assertion this replaces stayed green through that.
      final size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(48), reason: label);
      expect(size.height, greaterThanOrEqualTo(48), reason: label);
    }

    await tester.pumpWidget(const SizedBox());
  },
  timeout: const Timeout(Duration(seconds: 60)),
);
}
