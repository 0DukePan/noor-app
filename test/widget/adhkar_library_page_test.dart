import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/features/adhkar/presentation/pages/adhkar_library_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// State-depth tests for AdhkarLibraryPage (previously ~0% executed):
/// loading, review banner + category grid, drill-in, and the per-zekr
/// counter. The library asset loads once per file (static cache).
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  /// Lets the real library-asset load finish.
  Future<void> waitForLoad(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1500)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows loading then the review banner and categories',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdhkarLibraryPage(),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await waitForLoad(tester);

    expect(find.text('مكتبة الأذكار'), findsOneWidget);
    expect(
      find.text('محتوى المكتبة قيد المراجعة العلمية'),
      findsOneWidget,
    );
    // 20 categories render (grid is inside a ListView; first ones visible).
    expect(find.textContaining('ذكر'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  },
      timeout: const Timeout(Duration(seconds: 60)),);

  testWidgets('tapping a category opens its items with counters',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdhkarLibraryPage(),
      ),
    );
    await waitForLoad(tester);

    // Drill into the first category card.
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    // Items page: back navigation available and zekr rows render.
    expect(find.byType(BackButton), findsOneWidget);

    // Counters with repeat == 1 stay at zero by design (0+1 >= 1 resets),
    // so exercise the unique repeat-4 counter in the morning category:
    // '0 / 4' must become '1 / 4'.
    await tester.scrollUntilVisible(
      find.text('0 / 4'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('0 / 4'));
    await tester.pump();
    expect(find.text('0 / 4'), findsNothing);
    expect(find.text('1 / 4'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  },
      timeout: const Timeout(Duration(seconds: 60)),);
}
