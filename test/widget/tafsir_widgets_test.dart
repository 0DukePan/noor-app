import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/core/models/tafsir_models.dart';
import 'package:noor_app/features/tafsir/presentation/widgets/tafsir_widgets.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

import '../test_utils/tafsir_test_db.dart';

/// State-depth tests for the shared tafsir widgets: inline view (loading,
/// expand, bookmark), full-screen page (paging, font dialog), compare sheet
/// (both sources loaded) and bottom sheet.
///
/// Data comes from a tiny seeded database (see `seedTinyTafsirTestDb`): every
/// widget load is an indexed SQLite query, so the old flutter_test
/// asset-cache trap (a second rootBundle loadString hanging forever) cannot
/// trigger. A sync [forgetTafsirTestDb] in `setUp` gives each test a fresh
/// current-zone connection — reusing or closing a previous test's connection
/// hangs forever. Tests still unmount at the end to dispose controllers.
void main() {
  late Directory dbDir;

  setUpAll(() async {
    dbDir = await seedTinyTafsirTestDb([
      for (var ayah = 1; ayah <= 7; ayah++)
        (source: 'muyassar', surah: 1, ayah: ayah, text: 'تفسير ميسر 1:$ayah'),
      (source: 'saadi', surah: 1, ayah: 1, text: 'تفسير السعدي 1:1'),
      for (var ayah = 1; ayah <= 3; ayah++)
        (source: 'muyassar', surah: 2, ayah: ayah, text: 'تفسير ميسر 2:$ayah'),
      (source: 'muyassar', surah: 4, ayah: 1, text: 'تفسير ميسر 4:1'),
    ]);
  });

  tearDownAll(() async {
    await abandonTafsirTestDb(dbDir);
  });

  // Sync forget is intentional: it cannot hang in any zone (see above).
  setUp(() {
    forgetTafsirTestDb();
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  /// Lets the async database load finish (established pattern: one generous
  /// real-event-loop window, then a pump for the post-await setState).
  Future<void> waitForLoad(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1500)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('inline view loads, expands and shows the tafsir text',
      (tester) async {
    var expanded = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TafsirInlineView(
              surah: 1,
              ayah: 1,
              onExpand: () => expanded = true,
            ),
          ),
        ),
      ),
    );

    // First frame: header plus loading spinner, no content yet.
    expect(find.byType(TafsirInlineView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);

    await waitForLoad(tester);

    // Expand via the header row.
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();

    expect(expanded, isTrue);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('فشل في تحميل التفسير'), findsNothing);
    expect(find.text('لا يوجد تفسير لهذه الآية'), findsNothing);

    // Hive is never initialised in tests: the bookmark box is null, the icon
    // shows the unbookmarked state, and tapping must not crash.
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    // Tap targets on this header are asserted by rendered size rather than by
    // the page-level guideline: the body is a SelectableText, whose
    // long-press/focus actions make the guideline treat the whole text block
    // as a "tap target" (inherently under 48 dp tall). These three controls
    // did measure 40 dp with compact density (docs/accessibility.md).
    for (final target in [
      find.ancestor(
        of: find.byIcon(Icons.bookmark_border),
        matching: find.byType(IconButton),
      ),
      find.widgetWithText(TextButton, 'عرض كامل'),
      find.widgetWithText(TextButton, 'مقارنة'),
    ]) {
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pump();
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  },
      timeout: const Timeout(Duration(seconds: 60)),);

  testWidgets('full-screen page pages verses and opens the font dialog',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TafsirFullScreenPage(
          surah: 2,
          ayah: 1,
          source: TafsirSourceId.muyassar,
        ),
      ),
    );
    await waitForLoad(tester);

    // First verse of Al-Baqarah renders in the PageView.
    expect(find.text('الآية 1'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);

    // Font-size dialog opens and cancels cleanly (no asset reload involved).
    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();
    expect(find.text('حجم الخط'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('حجم الخط'), findsNothing);

    // Next-page arrow advances (muyassar groups ayat, so the next entry is
    // NOT verse 2 — assert the page actually turned instead).
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();
    expect(find.text('الآية 1'), findsNothing);
    expect(find.byType(PageView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  },
      timeout: const Timeout(Duration(seconds: 90)),);

  testWidgets('compare sheet loads both sources', (tester) async {
    // Surah 1 is small, so both sources load inside the standard window.
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TafsirCompareSheet(surah: 1, ayah: 1)),
      ),
    );

    expect(find.text('مقارنة التفاسير'), findsOneWidget);
    await waitForLoad(tester);
    await tester.pumpAndSettle();

    // Muyassar card renders its real text (name appears twice: chip + card)…
    expect(find.text('التفسير الميسر'), findsNWidgets(2));
    // …and scrolling reveals the Saadi card (lists build lazily; the chip
    // label matches too, so scope the scroll target to the card).
    await tester.scrollUntilVisible(
      find.descendant(
        of: find.byType(Card),
        matching: find.text('تفسير السعدي'),
      ),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('تفسير السعدي'), findsNWidgets(2));
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.byType(SelectableText), findsNWidgets(2));
    expect(find.text('لا يوجد تفسير'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  },
      timeout: const Timeout(Duration(seconds: 60)),);

  testWidgets('bottom sheet shows the verse tafsir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TafsirBottomSheet.show(
                context,
                surah: 4,
                ayah: 1,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // Settle the sheet entrance with fixed pumps: pumpAndSettle would wait
    // forever on the loading spinner's infinite animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await waitForLoad(tester);
    await tester.pumpAndSettle();

    expect(find.text('سورة 4 - الآية 1'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  },
      timeout: const Timeout(Duration(seconds: 60)),);
}
