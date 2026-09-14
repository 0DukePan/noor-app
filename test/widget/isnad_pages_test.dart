import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';
import 'package:noor_app/core/services/hadith_search_engine.dart';
import 'package:noor_app/core/services/narrator_database_service.dart';
import 'package:noor_app/features/hadith/presentation/pages/isnad_chain_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/isnad_graph_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/narration_comparison_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/scholar_mode_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The isnad pages render purely from the vocalized Arabic text (no SQLite)
/// via IsnadParserService — pump them with a real chain and assert the
/// parsed narrators surface.
void main() {
  const chainText = 'حَدَّثَنَا مُحَمَّدُ بْنُ بَشَّارٍ قَالَ حَدَّثَنَا يَحْيَى '
      'بْنُ سَعِيدٍ قَالَ حَدَّثَنَا شُعْبَةُ قَالَ حَدَّثَنِي أَبُو التَّيَّاحِ '
      'عَنْ أَنَسِ بْنِ مَالِكٍ رَضِيَ اللهُ عَنْهُ قَالَ قَالَ رَسُولُ اللهِ '
      'صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ: يُسِّرُوا وَلَا تُعَسِّرُوا';
  const narrator = 'أنس بن مالك';
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestWidgetsFlutterBinding.ensureInitialized();
    // The chain page awaits NarratorDatabaseService.init() in initState;
    // pre-warm it in the real zone so the fake-async pump resolves.
    await NarratorDatabaseService.init();
    // The comparison page searches via HadithSearchEngine — give it the
    // nawawi corpus like the engine tests do.
    tempDir = await Directory.systemTemp.createTemp('noor_isnad_test');
    Hive.init(tempDir.path);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await HadithDatabase.openWithBooks(
      ['nawawi40'],
      directory: tempDir.path,
    );
    await HadithSearchEngine.init(forTesting: db);
    // Pre-open the scholar-mode notes box in the real zone, and pre-cache
    // the comparison page's exact query: the pages then resolve their async
    // work synchronously and never leave pending Hive writes behind.
    await Hive.openBox<dynamic>('hadith_notes');
    await HadithSearchEngine.search(
      'الصلاة',
      target: SearchTarget.matn,
      limit: 20,
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  testWidgets('isnad chain page renders the parsed chain narrators',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: IsnadChainPage(hadithId: 'bukhari_1', hadithText: chainText),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(_findText(tester, 'محمد بن بشار'), findsWidgets);
    expect(_findText(tester, narrator), findsWidgets);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('isnad graph page renders without crashing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: IsnadGraphPage(hadithText: chainText, hadithSource: 'صحيح البخاري'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('narration comparison page searches and renders narrations',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NarrationComparisonPage(hadithKeyword: 'الصلاة'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('scholar mode page renders the hadith with grade and chain',
      (tester) async {
    const entry = HadithIndexEntry(
      id: 'nawawi40_1',
      book: 'nawawi40',
      chapter: 1,
      number: 1,
      text: 'عَنْ عُمَرَ بْنِ الْخَطَّابِ قَالَ سَمِعْتُ رَسُولَ اللهِ يَقُولُ '
          'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
      normalizedText: 'عن عمر بن الخطاب قال سمعت رسول الله يقول إنما الأعمال بالنيات',
      narrator: 'On the authority of Umar',
      normalizedNarrator: 'عمر بن الخطاب',
      companion: 'عمر بن الخطاب',
      grade: 'من المصدر',
      topics: ['النيات'],
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScholarModePage(hadith: entry),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('من المصدر'), findsOneWidget);
    expect(_findText(tester, 'عُمَرَ بْنِ الْخَطَّاب'), findsWidgets);
    expect(find.text('تحليل الإسناد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);
}

/// Finds Text widgets containing [needle] with tashkeel stripped — the pages
/// render narrator names in their vocalized form.
Finder _findText(WidgetTester tester, String needle) {
  final stripped = needle.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
  return find.byWidgetPredicate(
    (w) => w is Text &&
        (w.data?.replaceAll(RegExp(r'[\u064B-\u0652]'), '').contains(stripped) ??
            false),
  );
}
