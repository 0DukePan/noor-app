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
import 'package:noor_app/features/hadith/presentation/pages/hadith_page.dart';
import 'package:noor_app/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:noor_app/features/hifz/presentation/pages/hifz_page.dart';
import 'package:noor_app/features/prayer/presentation/pages/prayer_page.dart';
import 'package:noor_app/features/quran/presentation/pages/khatmah_page.dart';
import 'package:noor_app/features/quran/presentation/pages/quran_page.dart';
import 'package:noor_app/features/tools/presentation/pages/tools_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Dark-mode sweep: the pages that only need light data layers are pumped
/// with a dark [ThemeData] and must render without exceptions or overflows.
void main() {
  late Directory hiveDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveDir = await Directory.systemTemp.createTemp('noor_dark_hive');
    Hive.init(hiveDir.path);
    await AdhkarDataSource.init();
    await MosqueModeService.init();
    await Hive.openBox<dynamic>('hifz_box');
  });

  tearDownAll(() {
    try {
      hiveDir.deleteSync(recursive: true);
    } on Exception catch (_) {}
  });

  final theme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A4D3A),
      brightness: Brightness.dark,
    ),
  );

  Widget darkApp(Widget home) => MaterialApp(
        theme: theme,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  testWidgets('tools page renders clean in dark mode', (tester) async {
    await tester.pumpWidget(darkApp(const ToolsPage()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('الأدوات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hifz page renders clean in dark mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: darkApp(const HifzPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('الحفظ والمراجعة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('khatmah page renders clean in dark mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: darkApp(const KhatmahPlannerPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('quran page renders clean in dark mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: darkApp(const QuranPage())),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('hadith page renders clean in dark mode', (tester) async {
    final fake = _FakeHadithSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localHadithDataSourceProvider.overrideWithValue(fake)],
        child: darkApp(const HadithPage()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('adhkar page renders clean in dark mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: darkApp(const AdhkarPage())),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('prayer page renders clean in dark mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: darkApp(const PrayerPage())),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)),);
}

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
  Future<List<Hadith>> searchHadiths(String query, {String? bookId}) async =>
      const [];

  @override
  Future<List<Hadith>> searchByNarrator(String narrator) async => const [];

  @override
  Future<HadithBook> getBookSummary(String bookId) async => HadithBook(
        id: bookId,
        metadata: const BookMetadata(title: 'كتاب', author: 'مؤلف'),
        chapters: const [],
        hadiths: const [],
      );

  @override
  Future<HadithBook> loadBook(String bookId) async => getBookSummary(bookId);

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async => const [];

  @override
  Future<List<Hadith>> getHadithsPage({
    required String bookId,
    required int page,
    required int limit,
    int? chapterId,
  }) async {
    return const [];
  }

  @override
  Future<Hadith?> getRandomHadith() async => null;

  @override
  Future<Map<int, int>> getChapterHadithCounts(String bookId) async => const {};
}
