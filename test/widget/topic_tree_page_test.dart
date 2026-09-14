import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/hadith_db_builder.dart';
import 'package:noor_app/core/services/hadith_search_engine.dart';
import 'package:noor_app/features/hadith/presentation/pages/advanced_hadith_browser_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/topic_tree_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// State-depth tests for TopicTreePage (previously ~0% executed): the empty
/// state with no index, the sorted populated list from a tiny seeded index,
/// and tap-through to the browser.
///
/// The search engine is initialized ONCE (second test) from a tiny ffi
/// database opened in setUpAll (real zone). Static index state then serves
/// the rest of the file — no per-test reloads, no zone fights.
void main() {
  late Directory dbDir;
  late Directory hiveDir;
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbDir = await Directory.systemTemp.createTemp('noor_topic_test');
    hiveDir = await Directory.systemTemp.createTemp('noor_topic_hive');
    Hive.init(hiveDir.path);
    // Pre-open the engine's boxes here (real zone): body-zone openBox
    // never completes under testWidgets, but a cache hit does.
    await Hive.openBox<dynamic>('hadith_search_index');
    await Hive.openBox<dynamic>('hadith_search_cache');
    db = await databaseFactory.openDatabase(
      '${dbDir.path}/topics.db',
      options: OpenDatabaseOptions(
        version: kHadithDbVersion,
        onCreate: (db, version) async {
          await HadithDbSchema.create(db);
          // Two prayer hadiths + one fasting hadith -> sorted counts 2, 1.
          var id = 1;
          for (final text in [
            'قال رسول الله صلى الله عليه وسلم في فضل صلاة الجماعة',
            'إن الصلاة كانت على المؤمنين كتابا موقوتا',
            'من صام رمضان إيمانا واحتسابا غفر له',
          ]) {
            await db.insert('hadiths', {
              'id': id,
              'id_in_book': id,
              'collection_id': 'nawawi40',
              'chapter_id': 1,
              'arabic': text,
              'arabic_norm': text,
              'english_narrator': 'Tester',
              'english_text': 'test',
            });
            id++;
          }
        },
      ),
    );
  });

  tearDownAll(() async {
    await db.close();
    await Hive.close();
    for (final dir in [dbDir, hiveDir]) {
      try {
        await dir.delete(recursive: true);
      } on Exception catch (_) {}
    }
  });

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  Future<void> pumpTopics(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TopicTreePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('shows the empty state when no index exists', (tester) async {
    // Runs before any engine init: the static index is still null.
    await pumpTopics(tester);

    expect(find.text('التصنيف الموضوعي'), findsOneWidget);
    expect(find.text('لا توجد مواضيع بعد'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('lists topics sorted by hadith count', (tester) async {
    await tester.runAsync(() => HadithSearchEngine.init(forTesting: db));
    await tester.pump(const Duration(milliseconds: 100));

    await pumpTopics(tester);

    // The three seed hadiths match four topics (substring recall is the
    // engine's design): الصلاة=2, الإيمان=2, الصيام=1, الحج=1. Assert the
    // deterministic parts: presence, counts, and 2-count rows above
    // 1-count rows.
    expect(find.text('الصلاة'), findsOneWidget);
    expect(find.text('الصيام'), findsOneWidget);
    expect(find.text('2 حديث'), findsNWidgets(2));
    expect(find.text('1 حديث'), findsNWidgets(2));
    final salahDy = tester.getCenter(find.text('الصلاة')).dy;
    final sawmDy = tester.getCenter(find.text('الصيام')).dy;
    final hajjDy = tester.getCenter(find.text('الحج')).dy;
    expect(salahDy, lessThan(sawmDy));
    expect(salahDy, lessThan(hajjDy));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping a topic opens the browser page', (tester) async {
    await pumpTopics(tester);

    await tester.tap(find.text('الصلاة'));
    await tester.pumpAndSettle();

    expect(find.byType(AdvancedHadithBrowserPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
