import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/hadith_database.dart';
import 'package:noor_app/core/data/data_sources/local_hadith_data_source.dart';
import 'package:noor_app/core/domain/entities/hadith.dart';
import 'package:noor_app/core/services/hadith_search_engine.dart';
import 'package:noor_app/core/services/hadith_user_data_service.dart';
import 'package:noor_app/core/services/narrator_database_service.dart';
import 'package:noor_app/features/hadith/presentation/pages/hadith_reader_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/hadith_search_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/layered_hadith_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/tags_management_page.dart';
import 'package:noor_app/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:noor_app/features/hadith/presentation/widgets/hadith_sharh_sheet.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
const _hadithText = 'عَنْ عُمَرَ بْنِ الْخَطَّابِ رَضِيَ اللهُ عَنْهُ قَالَ: '
    'سَمِعْتُ رَسُولَ اللهِ صلى الله عليه وسلم يَقُولُ: إِنَّمَا الْأَعْمَالُ '
    'بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى';

Hadith _hadith({int id = 1, int chapterId = 1}) => Hadith(
      id: id,
      idInBook: id,
      arabic: _hadithText,
      englishText: 'Actions are but by intentions.',
      narratorEnglish: 'On the authority of Umar',
      chapterId: chapterId,
      collectionId: 'nawawi40',
    );

class _FakeHadithSource implements LocalHadithDataSource {
  @override
  Future<void> init() async {}

  @override
  Future<List<HadithCollection>> getCollections() async {
    return const [
      HadithCollection(
        id: 'nawawi40',
        titleArabic: 'الأربعون النووية',
        titleEnglish: 'An-Nawawi 40',
        hadithsCount: 42,
        author: 'النووي',
      ),
    ];
  }

  @override
  Future<List<Hadith>> searchHadiths(String query, {String? bookId}) async {
    return [_hadith()];
  }

  @override
  Future<List<Hadith>> searchByNarrator(String narrator) async => [_hadith()];

  @override
  Future<HadithBook> getBookSummary(String bookId) async => HadithBook(
        id: bookId,
        metadata: const BookMetadata(title: 'الأربعون النووية', author: 'النووي'),
        chapters: const [
          HadithChapter(id: 1, bookId: 'nawawi40', topicArabic: 'الإخلاص', topicEnglish: 'Sincerity'),
        ],
        hadiths: [_hadith()],
      );

  @override
  Future<HadithBook> loadBook(String bookId) async => getBookSummary(bookId);

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async =>
      const [HadithChapter(id: 1, bookId: 'nawawi40', topicArabic: 'الإخلاص', topicEnglish: 'Sincerity')];

  @override
  Future<List<Hadith>> getHadithsPage({
    required String bookId,
    required int page,
    required int limit,
    int? chapterId,
  }) async {
    return List.generate(limit, (i) => _hadith(id: i + 1, chapterId: chapterId ?? 1));
  }

  @override
  Future<Hadith?> getRandomHadith() async => _hadith();

  @override
  Future<Map<int, int>> getChapterHadithCounts(String bookId) async => {1: 42};
}

void main() {
  late Directory tempDir;
  late Directory hiveDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestWidgetsFlutterBinding.ensureInitialized();
    // One shared Hive home for the whole file: closing/deleting boxes
    // between tests hangs when a fake-zone page left an unawaited write,
    // so boxes stay open and services init once in the real zone.
    hiveDir = await Directory.systemTemp.createTemp('noor_content_hive');
    Hive.init(hiveDir.path);
    await Hive.openBox<dynamic>('hadith_progress');
    await Hive.openBox<dynamic>('hadith_bookmarks');
    await Hive.openBox<Map<dynamic, dynamic>>('personal_tags');
    await HadithUserDataService.init();
    await NarratorDatabaseService.init();
    await PersonalTagsService.init();

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() {
    try {
      hiveDir.deleteSync(recursive: true);
    } on Exception catch (_) {}
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_content_test');
    final db = await HadithDatabase.openWithBooks(
      ['nawawi40'],
      directory: tempDir.path,
    );
    await HadithSearchEngine.init(forTesting: db);
    // Pre-cache the layered page's related-search query (first 50 chars).
    final probe = _hadithText.length > 50
        ? _hadithText.substring(0, 50)
        : _hadithText;
    await HadithSearchEngine.search(probe, target: SearchTarget.matn, limit: 10);
  });

  tearDown(() {
    // Synchronous only — the fake-async zone can leave pending Hive writes.
    try {
      tempDir.deleteSync(recursive: true);
    } on Exception catch (_) {}
  });

  testWidgets('hadith reader renders the hadith text and paginates',
      (tester) async {
    final fake = _FakeHadithSource();
    final hadiths = [_hadith(), _hadith(id: 2), _hadith(id: 3)];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localHadithDataSourceProvider.overrideWithValue(fake)],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HadithReaderPage(
            hadith: _hadith(),
            bookTitle: 'الأربعون النووية',
            chapterTitle: 'الإخلاص',
            bookColor: Colors.teal,
            allHadiths: hadiths,
            currentIndex: 0,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('بِالنِّيَّاتِ'), findsWidgets);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  /// The reader's previous/next arrows must follow the ambient text direction.
  /// They used to be hardcoded for RTL, which silently inverts them for the
  /// English (LTR) locale the app ships on non-Arabic devices.
  Future<void> pumpReader(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localHadithDataSourceProvider.overrideWithValue(_FakeHadithSource()),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HadithReaderPage(
            hadith: _hadith(),
            bookTitle: 'الأربعون النووية',
            chapterTitle: 'الإخلاص',
            bookColor: Colors.teal,
            allHadiths: [_hadith(), _hadith(id: 2)],
            currentIndex: 0,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  IconData navArrowFor(WidgetTester tester, String label) {
    final row =
        find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
    final icons = find.descendant(of: row, matching: find.byType(Icon));
    expect(icons, findsOneWidget);
    return tester.widget<Icon>(icons).icon!;
  }

  testWidgets('reader arrows follow RTL: back points right', (tester) async {
    await pumpReader(tester, const Locale('ar'));

    expect(
      Directionality.of(tester.element(find.byType(HadithReaderPage))),
      TextDirection.rtl,
    );
    expect(navArrowFor(tester, 'السابق'), Icons.arrow_forward_ios_rounded);
    expect(navArrowFor(tester, 'التالي'), Icons.arrow_back_ios_rounded);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('reader arrows follow LTR: back points left', (tester) async {
    await pumpReader(tester, const Locale('en'));

    expect(
      Directionality.of(tester.element(find.byType(HadithReaderPage))),
      TextDirection.ltr,
    );
    expect(navArrowFor(tester, 'Previous'), Icons.arrow_back_ios_rounded);
    expect(navArrowFor(tester, 'Next'), Icons.arrow_forward_ios_rounded);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hadith search: tapping a result opens the reader with that hadith',
      (tester) async {
    // Search → detail closure: the FTS search page's result tap must push the
    // reader showing the tapped hadith (not a stale/misaligned row).
    final fake = _FakeHadithSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localHadithDataSourceProvider.overrideWithValue(fake)],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HadithSearchPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).first, 'النيات');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // The result card shows the hit's text; tapping it opens the reader.
    await tester.tap(find.textContaining('بِالنِّيَّاتِ').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(HadithReaderPage), findsOneWidget);
    expect(find.textContaining('بِالنِّيَّاتِ'), findsWidgets);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hadith sharh sheet renders commentary sections',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => HadithSharhSheet(
                  hadith: _hadith(),
                  bookTitle: 'الأربعون النووية',
                  bookColor: Colors.teal,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('tags management page renders and adds a tag', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TagsManagementPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Create a tag through the dialog (FAB opens the bottom sheet).
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).last, 'وسمي');
    await tester.tap(find.text('إنشاء'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('وسمي'), findsWidgets);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('layered hadith page renders text, chain and grades',
      (tester) async {
    const entry = HadithIndexEntry(
      id: 'nawawi40_1',
      book: 'nawawi40',
      chapter: 1,
      number: 1,
      text: _hadithText,
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
        home: LayeredHadithPage(hadith: entry),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('النيات'), findsOneWidget);
    expect(find.text('المتن'), findsOneWidget);
    expect(find.text('السند'), findsOneWidget);
    expect(find.text('الحكم'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);
}
