import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';
import 'package:noor_app/core/services/hadith_search_engine.dart';
import 'package:noor_app/features/hadith/presentation/pages/advanced_hadith_browser_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Each real-async hop (Hive/SQLite) needs its own runAsync window and the
/// pending microtasks a pump after each window — so loop until the UI
/// settles.
Future<void> settleSearch(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
}

/// P2.3 wiring: the console drives the upgraded engine — query, mode chips,
/// narrator field and per-book counts all flow through.
void main() {
  late Directory tempDir;
  late Directory hiveDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // One shared Hive home for the whole file: closing Hive boxes between
    // tests hangs under the test binding, so boxes stay open and the engine
    // reuses them (its cache key includes every filter, so no cross-test
    // pollution).
    hiveDir = await Directory.systemTemp.createTemp('noor_console_hive');
    Hive.init(hiveDir.path);
  });

  tearDownAll(() {
    try {
      hiveDir.deleteSync(recursive: true);
    } on Exception catch (_) {}
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_console_test');
    final db = await HadithDatabase.openWithBooks(
      ['nawawi40'],
      directory: tempDir.path,
    );
    await HadithSearchEngine.init(forTesting: db);
  });

  tearDown(() {
    // tearDown runs under the fake-async zone: real async IO (Hive, dart:io)
    // never completes there, so use synchronous cleanup only.
    try {
      tempDir.deleteSync(recursive: true);
    } on Exception catch (_) {}
  });

  testWidgets('query renders results with the grade row and book counts',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdvancedHadithBrowserPage()),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('الحكم:'), findsOneWidget);
    expect(find.textContaining('من المصدر'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'الصلاة');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settleSearch(tester);

    expect(find.text('الموسوعة الحديثية'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains('نووي') ?? false),
      ),
      findsWidgets,
    );
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('narrator field accepts input without crashing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdvancedHadithBrowserPage()),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Baseline: a term that occurs in several chains.
    await tester.enterText(find.byType(TextField).first, 'عن');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settleSearch(tester);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains('نووي') ?? false),
      ),
      findsWidgets,
    );

    // Fill the narrator filter field (the submit path is the same handler
    // as the search field, proven above; narrator filtering semantics are
    // covered by the engine tests).
    await tester.tap(find.byType(TextField).at(1));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField).at(1), 'عمر بن الخطاب');
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byWidgetPredicate(
        (w) => w is TextField && (w.controller?.text.contains('عمر') ?? false),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);
}
