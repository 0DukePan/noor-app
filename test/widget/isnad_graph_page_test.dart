import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/isnad_parser_service.dart';
import 'package:noor_app/features/hadith/presentation/pages/isnad_graph_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Widget tests for IsnadGraphPage. The page loads the bundled narrator
/// database (asset) and parses the hadith isnad, then renders a DAG graph.
/// Nodes are drawn to a CustomPaint canvas, so we assert on the surrounding
/// widgets (loading / empty / chip / legend / source banner) and drive a node
/// tap through the canvas coordinates.
void main() {
  // A real Bukhari isnad used by the parser tests (parses to 5 narrators,
  // ending at the Companion 'Abdullah ibn Umar).
  const hadith =
      'حَدَّثَنَا مُحَمَّدُ بْنُ إِسْمَاعِيلَ، حَدَّثَنَا عَبْدُ اللَّهِ بْنُ يُوسُفَ، '
      'أَخْبَرَنَا مَالِكٌ، عَنْ نَافِعٍ، عَنْ عَبْدِ اللَّهِ بْنِ عُمَرَ رَضِيَ '
      'اللَّهُ عَنْهُمَا، أَنَّ رَسُولَ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ '
      'قَالَ: لَا يَقْبَلُ اللَّهُ صَلَاةً بِغَيْرِ طُهُورٍ';

  Future<void> pumpGraph(
    WidgetTester tester, {
    String text = hadith,
    String source = 'صحيح البخاري',
  }) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: IsnadGraphPage(hadithText: text, hadithSource: source),
      ),
    );
  }

  testWidgets('shows the loading indicator while parsing', (tester) async {
    await pumpGraph(tester);
    expect(find.text('جارٍ تحليل الإسناد...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
  });

  testWidgets('renders the parsed chain with a narrator-count chip',
      (tester) async {
    await pumpGraph(tester);
    await tester.pump(const Duration(milliseconds: 1000));

    final n = IsnadParserService.parseChain(hadith).length;
    expect(n, greaterThanOrEqualTo(4));
    expect(find.text('$n راوٍ'), findsOneWidget);
    expect(find.text('الرسم البياني للإسناد'), findsOneWidget);
  });

  testWidgets('shows the source banner and the legend', (tester) async {
    await pumpGraph(tester, source: 'رواه البخاري');
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('رواه البخاري'), findsOneWidget);
    for (final label in ['النبي ﷺ', 'صحابي', 'راوي', 'مؤلف']) {
      expect(find.text(label), findsOneWidget, reason: 'legend: $label');
    }
  });

  testWidgets('shows the empty state when no isnad is found', (tester) async {
    await pumpGraph(tester, text: 'The quick brown fox');
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('لم يتم العثور على إسناد'), findsOneWidget);
  });

  testWidgets('tapping a graph node opens the narrator profile bottom sheet',
      (tester) async {
    await pumpGraph(tester);
    await tester.pump(const Duration(milliseconds: 1000));

    // The first node is at canvas (150, 30..90) => centre ≈ (250, 60).
    final graph = find
        .byWidgetPredicate((w) => w is CustomPaint && w.size.width == 500)
        .first;
    expect(graph, findsOneWidget);
    final topLeft = tester.getTopLeft(graph);
    await tester.tapAt(topLeft + const Offset(250, 60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final chain = IsnadParserService.parseChain(hadith);
    expect(find.text(chain.first.name), findsOneWidget);
    expect(find.textContaining('صيغة التحمل'), findsOneWidget);
  });
}
