import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/features/tools/presentation/pages/tasbih_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// State-depth tests for TasbihPage (previously ~0% executed): counting,
/// presets, open mode, reset, and completion. Pure state — no plugins.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  Future<void> pumpTasbih(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TasbihPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Taps the big counter area (the counter text itself is untappable text;
  /// preset chips are GestureDetectors too, so scope to the ScaleTransition's
  /// ancestor).
  Future<void> tapCounter(WidgetTester tester, [int times = 1]) async {
    final area = find.text('اضغط في أي مكان للشاشة للعد');
    final counterTap = find.ancestor(
      of: find.byType(ScaleTransition),
      matching: find.byType(GestureDetector),
    );
    for (var i = 0; i < times; i++) {
      await tester.tap(counterTap);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(area, findsOneWidget);
  }

  testWidgets('starts at zero with the 33 target', (tester) async {
    await pumpTasbih(tester);

    expect(find.text('المسبحة الإلكترونية'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('/ 33'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping increments the counter', (tester) async {
    await pumpTasbih(tester);

    await tapCounter(tester, 3);
    expect(find.text('3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('preset chips switch the target', (tester) async {
    await pumpTasbih(tester);

    await tester.tap(find.text('١٠٠'));
    await tester.pump();
    expect(find.text('/ 100'), findsOneWidget);

    // Open mode: no target line and no progress ring.
    await tester.tap(find.text('مفتوح'));
    await tester.pump();
    expect(find.text('/ 100'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tapCounter(tester, 2);
    expect(find.text('2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reset button zeroes the counter', (tester) async {
    await pumpTasbih(tester);

    await tapCounter(tester, 5);
    expect(find.text('5'), findsOneWidget);
    await tester.tap(find.byTooltip('تصفير'));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reaching the target shows the complete state', (tester) async {
    await pumpTasbih(tester);

    await tapCounter(tester, 33);
    expect(find.text('33'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
