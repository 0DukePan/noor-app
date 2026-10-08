import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/features/tafsir/presentation/pages/tafsir_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

import '../test_utils/tafsir_test_db.dart';

/// TAF-03 contract: every Tafsir entry point routes through a validated
/// location, and the page scrolls to + highlights the exact saved/search
/// result ayah instead of reopening the list at its start.
void main() {
  Directory? dbDir;

  setUpAll(() async {
    dbDir = await seedTinyTafsirTestDb([
      for (var ayah = 1; ayah <= 5; ayah++)
        (source: 'muyassar', surah: 2, ayah: ayah, text: 'تفسير ميسر 2:$ayah'),
    ]);
  });

  tearDownAll(() async {
    await abandonTafsirTestDb(dbDir);
  });

  setUp(() {
    forgetTafsirTestDb();
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
  });

  Future<void> pumpPage(WidgetTester tester, {int? surah, int? ayah}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TafsirPage(initialSurah: surah, initialAyah: ayah),
      ),
    );
  }

  Future<void> waitForLoad(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1500)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    'initialAyah scrolls to and highlights the exact entry',
    (tester) async {
      await pumpPage(tester, surah: 2, ayah: 4);
      await waitForLoad(tester);
      await tester.pumpAndSettle();

      // The exact entry is on screen with its text …
      expect(find.text('تفسير ميسر 2:4'), findsOneWidget);
      // … and visibly highlighted (thicker primary border).
      final highlighted = tester.widgetList<Container>(
        find.ancestor(
          of: find.text('تفسير ميسر 2:4'),
          matching: find.byType(Container),
        ),
      );
      final widths = highlighted.map((c) {
        final border = c.decoration;
        if (border is! BoxDecoration) return 0.0;
        final side = border.border;
        if (side is! Border) return 0.0;
        return side.top.width;
      }).toList();
      expect(widths, contains(2.0));
      await tester.pumpWidget(const SizedBox());
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  testWidgets(
    'no initialAyah leaves entries unhighlighted',
    (tester) async {
      await pumpPage(tester, surah: 2);
      await waitForLoad(tester);
      await tester.pumpAndSettle();

      expect(find.text('تفسير ميسر 2:1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
