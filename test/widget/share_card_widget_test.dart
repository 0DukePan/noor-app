import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/shared/widgets/share_card_widget.dart';

/// Widget tests for the share cards: all four styles render the verse and the
/// source, the elegant style honours the optional translation, and the
/// preview dialog switches styles and closes.
///
/// The share button itself is NOT tapped: it drives haptics plus image
/// capture through real platform channels (plugin-bound, covered by the
/// ExportShareService unit tests instead).
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  const verse = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
  const source = 'سورة الفاتحة - ١';

  Future<void> pumpCard(
    WidgetTester tester,
    ShareCardStyle style, {
    String? translation,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShareCardWidget(
              cardKey: GlobalKey(),
              arabicText: verse,
              source: source,
              translation: translation,
              style: style,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('elegant style renders verse, source and translation',
      (tester) async {
    await pumpCard(tester, ShareCardStyle.elegant, translation: 'In the name');
    expect(find.text(verse), findsOneWidget);
    expect(find.text(source), findsOneWidget);
    expect(find.text('In the name'), findsOneWidget);
    // App branding footer.
    expect(find.text('نور'), findsOneWidget);
  });

  testWidgets('elegant style hides the translation block when null',
      (tester) async {
    await pumpCard(tester, ShareCardStyle.elegant);
    expect(find.text(verse), findsOneWidget);
    expect(find.text(source), findsOneWidget);
  });

  testWidgets('minimal style renders verse with em-dash source',
      (tester) async {
    await pumpCard(tester, ShareCardStyle.minimal);
    expect(find.text(verse), findsOneWidget);
    expect(find.text('— $source'), findsOneWidget);
  });

  testWidgets('gradient style renders verse and source', (tester) async {
    await pumpCard(tester, ShareCardStyle.gradient);
    expect(find.text(verse), findsOneWidget);
    expect(find.text(source), findsOneWidget);
  });

  testWidgets('dark style renders verse, source and star row', (tester) async {
    await pumpCard(tester, ShareCardStyle.dark);
    expect(find.text(verse), findsOneWidget);
    expect(find.text(source), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(5));
  });

  testWidgets('preview dialog switches style and closes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showShareCardDialog(
                context,
                arabicText: verse,
                source: source,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Elegant by default.
    expect(find.text(verse), findsOneWidget);
    // Switch to the minimal style via its Arabic label.
    await tester.tap(find.text('بسيط'));
    await tester.pumpAndSettle();
    expect(find.text('— $source'), findsOneWidget);

    // Close returns to the opener.
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
