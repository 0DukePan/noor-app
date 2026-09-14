import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/local_hadith_data_source.dart';
import 'package:noor_app/core/domain/entities/hadith.dart';
import 'package:noor_app/core/services/adhkar_data_source.dart';
import 'package:noor_app/core/services/mosque_mode_service.dart';
import 'package:noor_app/features/adhkar/presentation/pages/adhkar_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/advanced_hadith_browser_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/hadith_page.dart';
import 'package:noor_app/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:noor_app/features/hifz/presentation/pages/hifz_page.dart';
import 'package:noor_app/features/prayer/presentation/pages/prayer_settings_page.dart';
import 'package:noor_app/features/quran/presentation/pages/khatmah_page.dart';
import 'package:noor_app/features/quran/presentation/pages/quran_page.dart';
import 'package:noor_app/features/search/domain/entities/search_result.dart';
import 'package:noor_app/features/search/domain/repositories/search_repository.dart';
import 'package:noor_app/features/search/presentation/pages/search_page.dart';
import 'package:noor_app/features/search/presentation/providers/search_provider.dart';
import 'package:noor_app/features/tools/presentation/pages/tools_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Stub notifier that never touches SQLite.
class _StubSearchNotifier extends SearchNotifier {
  _StubSearchNotifier() : super(_StubRepository());

  @override
  Future<void> search(String query) async {
    state = const AsyncValue.data(<SearchResult>[]);
  }
}

class _StubRepository implements SearchRepository {
  @override
  Future<void> initializeIndex() async {}

  @override
  Future<List<SearchResult>> search(String query) async => const [];
}

/// Renders the main feature pages and asserts their stable headers render —
/// with the heavy data layers replaced or initialized against temp Hive/SQLite
/// stores, never touching platform channels.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_pages_test');
    Hive.init(tempDir.path);
    await AdhkarDataSource.init();
    await MosqueModeService.init();
    // Pre-open the hifz box in the real zone: the notifier's openBox during
    // the fake-async pump then resolves instantly instead of hanging.
    await Hive.openBox<dynamic>('hifz_box');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  testWidgets('quran page renders the surah index', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranPage(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('القرآن الكريم'), findsOneWidget);
    expect(find.text('114 سورة'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 60)),);

  testWidgets('adhkar page shows the six collection cards', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('أذكار المساء'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('tools page shows the tool grid', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ToolsPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('مواقيت الصلاة'), findsOneWidget);
    expect(find.text('القبلة'), findsOneWidget);
    expect(find.text('المسبحة'), findsOneWidget);
    expect(find.text('البحث'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('prayer settings page renders with the method section',
      (tester) async {
    await tester.runAsync(() async {
      await Hive.openBox<Map<dynamic, dynamic>>('settings');
    });
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrayerSettingsPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('إعدادات الصلاة'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hadith page renders the library header with a fake source',
      (tester) async {
    final fake = _FakeHadithDataSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localHadithDataSourceProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HadithPage(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('الكتب والمجاميع'), findsOneWidget);
    expect(find.text('صحيح البخاري'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 60)),);

  testWidgets('search page shows the search field', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The real notifier eagerly indexes the whole corpus into SQLite;
          // the page smoke test only asserts the UI shell.
          searchResultsProvider.overrideWith(
            (ref) => _StubSearchNotifier(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SearchPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ابحث في القرآن والحديث...'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hadith console exposes the P2.1 search modes and filters',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdvancedHadithBrowserPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('البحث المتقدم'), findsOneWidget);
    expect(find.text('وضع البحث:'), findsOneWidget);
    expect(find.text('عبارة'), findsOneWidget);
    expect(find.text('بالجذر'), findsOneWidget);
    expect(find.text('راوٍ في السند...'), findsOneWidget);
    expect(find.text('الصحابة'), findsOneWidget);
    expect(find.text('المواضيع'), findsOneWidget);
    expect(find.text('الكتب'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hifz page renders the dashboard with an empty library',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HifzPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('الحفظ والمراجعة'), findsOneWidget);
    expect(find.textContaining('سلسلة الممارسة'), findsOneWidget);
    expect(find.textContaining('للحفظ'), findsOneWidget);
    expect(find.textContaining('للمراجعة'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('khatmah page renders the planner', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('خطة الختمة'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)),);
}

/// Canned data source so the hadith library renders without SQLite.
class _FakeHadithDataSource implements LocalHadithDataSource {
  @override
  Future<void> init() async {}

  @override
  Future<List<HadithCollection>> getCollections() async {
    return [
      const HadithCollection(
        id: 'bukhari',
        titleArabic: 'صحيح البخاري',
        titleEnglish: 'Sahih al-Bukhari',
        hadithsCount: 7000,
        author: 'البخاري',
      ),
    ];
  }

  @override
  Future<HadithBook> getBookSummary(String bookId) async {
    return HadithBook(
      id: bookId,
      metadata: const BookMetadata(title: 'صحيح البخاري', author: 'البخاري'),
      chapters: const [],
      hadiths: const [],
    );
  }

  @override
  Future<HadithBook> loadBook(String bookId) => getBookSummary(bookId);

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async => const [];

  @override
  Future<List<Hadith>> getHadithsPage({
    required String bookId,
    required int page,
    required int limit,
    int? chapterId,
  }) async => const [];

  @override
  Future<List<Hadith>> searchHadiths(String query, {String? bookId}) async =>
      const [];

  @override
  Future<List<Hadith>> searchByNarrator(String narrator) async => const [];

  @override
  Future<Hadith?> getRandomHadith() async => null;

  @override
  Future<Map<int, int>> getChapterHadithCounts(String bookId) async => {};
}
