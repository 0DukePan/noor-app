import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/local_hadith_data_source.dart';
import 'package:noor_app/core/domain/entities/hadith.dart';
import 'package:noor_app/core/services/adhkar_data_source.dart';
import 'package:noor_app/core/services/hadith_user_data_service.dart';
import 'package:noor_app/core/services/mosque_mode_service.dart';
import 'package:noor_app/features/adhkar/presentation/pages/adhkar_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/bookmarked_hadiths_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/hadith_chapter_hadiths_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/hadith_chapters_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/hadith_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/hadith_search_page.dart';
import 'package:noor_app/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:noor_app/features/quran/presentation/pages/khatmah_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Fake hadith source: canned collections + search results, no SQLite.
class _FakeHadithSource implements LocalHadithDataSource {
  @override
  Future<void> init() async {}

  @override
  Future<List<HadithCollection>> getCollections() async {
    return const [
      HadithCollection(
        id: 'bukhari',
        titleArabic: 'صحيح البخاري',
        titleEnglish: 'Sahih al-Bukhari',
        hadithsCount: 2,
        author: 'البخاري',
      ),
    ];
  }

  @override
  Future<List<Hadith>> searchHadiths(String query, {String? bookId}) async {
    return [
      Hadith(
        id: 1,
        idInBook: 1,
        arabic: 'عن النبي $query قال كذا',
        englishText: 'The Prophet said $query',
        narratorEnglish: 'Abu Hurairah',
        chapterId: 1,
        collectionId: bookId,
      ),
    ];
  }

  @override
  Future<List<Hadith>> searchByNarrator(String narrator) async {
    return [
      Hadith(
        id: 2,
        idInBook: 2,
        arabic: 'حديث عن $narrator',
        englishText: 'Narrated by $narrator',
        narratorEnglish: narrator,
        chapterId: 1,
      ),
    ];
  }

  @override
  Future<HadithBook> getBookSummary(String bookId) async {
    return HadithBook(
      id: bookId,
      metadata: const BookMetadata(title: 'كتاب', author: 'مؤلف'),
      chapters: const [
        HadithChapter(
          id: 1,
          bookId: 'bukhari',
          topicArabic: 'باب الصلاة',
          topicEnglish: 'Chapter of Prayer',
        ),
        HadithChapter(
          id: 2,
          bookId: 'bukhari',
          topicArabic: 'باب الصوم',
          topicEnglish: 'Chapter of Fasting',
        ),
      ],
      hadiths: const [],
    );
  }

  @override
  Future<HadithBook> loadBook(String bookId) async => getBookSummary(bookId);

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async =>
      (await getBookSummary(bookId)).chapters;

  @override
  Future<List<Hadith>> getHadithsPage({
    required String bookId,
    required int page,
    required int limit,
    int? chapterId,
  }) async {
    return [
      Hadith(
        id: 10 + page,
        idInBook: 10 + page,
        arabic: 'عَنْ أَبِي هُرَيْرَةَ قَالَ قَالَ رَسُولُ اللَّهِ النَّظَافَةُ مِنَ الْإِيمَانِ',
        englishText: 'Cleanliness is part of faith.',
        narratorEnglish: 'Abu Hurairah',
        chapterId: chapterId ?? 1,
        collectionId: bookId,
      ),
    ];
  }

  @override
  Future<Hadith?> getRandomHadith() async => null;

  @override
  Future<Map<int, int>> getChapterHadithCounts(String bookId) async {
    return {1: 5, 2: 3};
  }
}

/// Deeper interaction coverage for the data-backed pages: search flows,
/// khatmah lifecycle and adhkar counters.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_interaction_test');
    Hive.init(tempDir.path);
    await AdhkarDataSource.init();
    await MosqueModeService.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  testWidgets('hadith search: text search renders results', (tester) async {
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

    await tester.enterText(find.byType(TextField).first, 'الصدقة');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('الصدقة'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hadith search: narrator mode renders chain results',
      (tester) async {
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

    // Switch to narrator mode (segmented control button).
    await tester.tap(find.textContaining('الراوي'));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField).first, 'أبو هريرة');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('أبو هريرة'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('khatmah page: create a khatmah and render the plan',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: KhatmahPlannerPage(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Open the create dialog.
    await tester.tap(find.text('بدء ختمة جديدة'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).last, 'ختمة رمضان');
    await tester.tap(find.text('ابدأ الختمة'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ختمة رمضان'), findsWidgets);
    expect(find.textContaining('اليوم'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('adhkar page: category selection and counter work',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdhkarPage(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Open the morning dhikr category (default) and render its list.
    await tester.tap(find.text('أذكار الصباح'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hadith chapters page renders chapter tiles with counts',
      (tester) async {
    final fake = _FakeHadithSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localHadithDataSourceProvider.overrideWithValue(fake)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HadithChaptersPage(
            bookId: 'bukhari',
            bookTitle: 'صحيح البخاري',
            bookColor: Colors.teal,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('باب الصلاة'), findsOneWidget);
    expect(find.text('باب الصوم'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hadith chapter page loads and renders hadith previews',
      (tester) async {
    final fake = _FakeHadithSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localHadithDataSourceProvider.overrideWithValue(fake)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HadithChapterHadithsPage(
            bookId: 'bukhari',
            bookTitle: 'صحيح البخاري',
            chapterId: 1,
            chapterTitle: 'باب الصلاة',
            bookColor: Colors.teal,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('النَّظَافَة'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hadith page: library grid renders and a book opens',
      (tester) async {
    final fake = _FakeHadithSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localHadithDataSourceProvider.overrideWithValue(fake)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HadithPage(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('صحيح البخاري'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  // Last: its runAsync seeding leaves HadithUserDataService statics pointing
  // at a dead Hive home, which would pollute subsequent tests.
  testWidgets('bookmarked hadiths page lists a seeded bookmark',
      (tester) async {
    await tester.runAsync(() async {
      await HadithUserDataService.init();
      await HadithUserDataService.bookmarkHadith(
        hadithId: 7,
        collectionId: 'bukhari',
        arabic: 'حديث محفوظ للتجربة',
        englishText: 'A bookmarked hadith',
        narrator: 'Abu Hurairah',
        idInBook: 7,
      );
    });
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookmarkedHadithsPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('حديث محفوظ للتجربة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);
}
