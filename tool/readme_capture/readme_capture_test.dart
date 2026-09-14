import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:noor_app/core/data/data_sources/local_hadith_data_source.dart';
import 'package:noor_app/core/domain/entities/hadith.dart';
import 'package:noor_app/core/models/adhkar_models.dart';
import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/hadith_user_data_service.dart';
import 'package:noor_app/core/services/narrator_database_service.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/core/services/quran_data_source.dart';
import 'package:noor_app/features/adhkar/presentation/pages/adhkar_library_page.dart';
import 'package:noor_app/features/hadith/presentation/pages/hadith_reader_page.dart';
import 'package:noor_app/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:noor_app/features/home/presentation/pages/home_page.dart';
import 'package:noor_app/features/home/presentation/providers/home_provider.dart';
import 'package:noor_app/features/prayer/presentation/pages/prayer_page.dart';
import 'package:noor_app/features/prayer/presentation/providers/prayer_providers.dart';
import 'package:noor_app/features/quran/data/datasources/local_quran_data_source.dart';
import 'package:noor_app/features/quran/domain/entities/quran_entities.dart';
import 'package:noor_app/features/quran/presentation/pages/quran_mushaf_page.dart';
import 'package:noor_app/features/quran/presentation/providers/quran_providers.dart';
import 'package:noor_app/features/tools/presentation/pages/tools_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// README/demo capture harness — NOT part of the normal test suite.
///
/// It lives outside `test/` on purpose: `flutter test` only scans `test/`, so
/// CI never runs this and never depends on platform font rendering. Run it
/// explicitly, then assemble the GIF:
///
///   flutter test tool/readme_capture/readme_capture_test.dart
///   dart run tool/readme_capture/build_gif.dart
///
/// Frames land in `docs/media/frames/`. Unlike the deterministic golden tests
/// (which render text as Ahem boxes so they can pin layout), this harness loads
/// the real Cairo and Amiri fonts, so the Arabic actually shapes.
///
/// Captures real app data where it can: the mushaf scene renders the bundled
/// Uthmani text and the adhkar scene the bundled library. Nothing here invents
/// scripture or hadith.
void main() {
  const phoneWidth = 390.0;
  const phoneHeight = 844.0;
  const pixelRatio = 2.0;
  const frameDir = 'docs/media/frames';

  final boundaryKey = GlobalKey();
  final today = DateTime(2026, 3, 15);
  late Directory hiveDir;
  late List<Verse> mushafVerses;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;

    // Real fonts: Cairo (UI) + Amiri (Quran/hadith text) + the icon font
    // (without MaterialIcons every icon in the app renders as an empty box).
    final cairo = FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo-Variable.ttf'));
    final amiri = FontLoader('Amiri')
      ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([cairo.load(), amiri.load(), icons.load()]);

    // The design system also names Outfit/Inter, which are NOT bundled — on a
    // device they resolve to the system font. There is no system font in the
    // test environment, so those glyphs would render as tofu boxes; alias the
    // families to the bundled Cairo variable font for capture purposes only.
    for (final family in const ['Outfit', 'Inter']) {
      final alias = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/Cairo-Variable.ttf'));
      await alias.load();
    }

    // Hive first: QuranDataSource caches the parsed Quran text in a box.
    hiveDir = await Directory.systemTemp.createTemp('noor_readme_hive');
    Hive.init(hiveDir.path);
    await Hive.openBox<dynamic>('hadith_progress');
    await Hive.openBox<dynamic>('hadith_bookmarks');
    await Hive.openBox<Map<dynamic, dynamic>>('settings');

    // Bundled data the captured pages read.
    await QuranDataSource.init();
    await HadithUserDataService.init();
    await NarratorDatabaseService.init();

    // Real Uthmani verses for the mushaf scene: the page's own data source
    // loads the bundled Quran, and overriding its provider keeps the scene
    // independent of provider wiring. Nothing here invents scripture.
    // A mid-Quran page is chosen over Al-Fatiha because the latter only has
    // seven verses and leaves most of a real mushaf page blank.
    final quran = LocalQuranDataSourceImpl();
    mushafVerses = await quran.getVersesByPage(1);
    for (final page in const [2, 100, 200, 300, 400, 500, 600]) {
      final verses = await quran.getVersesByPage(page);
      if (verses.length > mushafVerses.length) mushafVerses = verses;
    }
    // Which page was chosen is worth reporting: it is the one non-deterministic
    // input in this harness (the densest bundled page fills the frame best).
    // ignore: avoid_print
    print('[capture] mushaf scene: ${mushafVerses.length} verses');
  });

  tearDownAll(() {
    // Deliberately no Hive.close(): the captured pages leave unawaited box
    // writes behind and closing the boxes blocks the process forever (the same
    // reason hadith_content_pages_test keeps its boxes open for the whole file).
    try {
      hiveDir.deleteSync(recursive: true);
    } on FileSystemException catch (_) {}
  });

  /// Pumps [page] at phone size inside a repaint boundary and writes a PNG.
  Future<void> capture(
    WidgetTester tester,
    String name,
    Widget page, {
    List<Override> overrides = const [],
    Duration settle = const Duration(milliseconds: 600),
  }) async {
    tester.view.physicalSize = const Size(
      phoneWidth * pixelRatio,
      phoneHeight * pixelRatio,
    );
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Cairo',
              scaffoldBackgroundColor: const Color(0xFFF5F2EA),
            ),
            home: page,
          ),
        ),
      ),
    );

    // Let the entrance animations finish. This has to be a run of frames, not
    // one big jump: flutter_animate starts each card on a delayed Timer, and a
    // single pump past the delay only *fires* the timer — the fade then still
    // needs frames to progress, so a one-shot pump captures an invisible page.
    await tester.pump();

    // Asset-backed pages (mushaf, adhkar library) resolve their data through
    // rootBundle in REAL async time: inside the fake test zone that I/O never
    // completes, so the page would be captured blank. Give it a moment in the
    // real loop before letting the animations run.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 700)),
    );
    await tester.pump();

    final frames = (settle.inMilliseconds ~/ 50).clamp(8, 60);
    for (var frame = 0; frame < frames; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Written through the framework's golden comparator: RenderRepaintBoundary
    // .toImage() does not complete on the automated test binding, but
    // --update-goldens does exactly what this harness needs (writes the PNG).
    // Run this file with --update-goldens.
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('../../$frameDir/$name.png'),
    );
    // Progress goes to the console because this runs interactively (never in
    // CI), and knowing which frame is being written is the point.
    // ignore: avoid_print
    print('[capture] wrote $name.png');

    // Unmount: leaves periodic timers/streams from the page behind.
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('frames', (tester) async {
    // 1 — Home dashboard.
    await capture(
      tester,
      '01_home',
      const HomePage(),
      overrides: [
        homeDataProvider.overrideWith(
          (ref) async => HomeData(
            prayerTimes: PrayerTimeEngine.calculate(
              latitude: 21.4225,
              longitude: 39.8262,
              date: today,
              method: CalculationMethod.ummAlQura,
              utcOffset: 3,
            ),
            cityName: 'مكة المكرمة',
            adhkarStats: DailyAdhkarStats(
              date: today,
              morningCompleted: true,
            ),
          ),
        ),
        smartGreetingProvider.overrideWithValue('صباح الخير'),
        dayStateProvider.overrideWith(
          (ref) => Stream.value(
            const StateInfo(
              state: DayState.dhuhr,
              nextState: DayState.asr,
              timeToNextState: Duration(hours: 3),
              suggestedAdhkar: 'استغفر الله',
              suggestedAction: 'صلاة الظهر',
            ),
          ),
        ),
        currentTimeProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 3, 15, 12, 30)),
        ),
      ],
      settle: const Duration(milliseconds: 1600),
    );

    // 2 — Mushaf (bundled Uthmani text, real page 1).
    await capture(
      tester,
      '02_mushaf',
      const QuranMushafPage(),
      overrides: [
        quranPageProvider.overrideWith((ref, page) async => mushafVerses),
      ],
      settle: const Duration(milliseconds: 1200),
    );

    // 3 — Hadith reader.
    await capture(
      tester,
      '03_hadith',
      HadithReaderPage(
        hadith: _hadith(),
        bookTitle: 'الأربعون النووية',
        chapterTitle: 'الإخلاص',
        bookColor: const Color(0xFF1F6E5A),
        allHadiths: [_hadith(), _hadith(id: 2)],
        currentIndex: 0,
      ),
      overrides: [
        localHadithDataSourceProvider.overrideWithValue(_FakeHadithSource()),
      ],
      settle: const Duration(milliseconds: 1200),
    );

    // 4 — Prayer times.
    await capture(
      tester,
      '04_prayer',
      const PrayerPage(),
      overrides: [
        prayerDataProvider.overrideWith(
          (ref) async => PrayerPageData(
            prayerTimes: PrayerTimeEngine.calculate(
              latitude: 21.4225,
              longitude: 39.8262,
              date: today,
              method: CalculationMethod.ummAlQura,
              utcOffset: 3,
            ),
            cityName: 'مكة المكرمة',
            countryName: 'السعودية',
          ),
        ),
        prayerTimeTickProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 3, 15, 12, 30)),
        ),
      ],
      settle: const Duration(milliseconds: 1600),
    );

    // 5 — Adhkar library (bundled asset; the capture helper waits for it).
    await capture(
      tester,
      '05_adhkar',
      const AdhkarLibraryPage(),
      settle: const Duration(milliseconds: 800),
    );

    // 6 — Tools grid.
    await capture(
      tester,
      '06_tools',
      const ToolsPage(),
    );
  }, timeout: const Timeout(Duration(seconds: 180)),);
}

const _hadithText = 'عَنْ عُمَرَ بْنِ الْخَطَّابِ رَضِيَ اللهُ عَنْهُ قَالَ: '
    'سَمِعْتُ رَسُولَ اللهِ صلى الله عليه وسلم يَقُولُ: إِنَّمَا الْأَعْمَالُ '
    'بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى';

Hadith _hadith({int id = 1}) => Hadith(
      id: id,
      idInBook: id,
      arabic: _hadithText,
      englishText: 'Actions are but by intentions.',
      narratorEnglish: 'On the authority of Umar',
      chapterId: 1,
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
  Future<List<Hadith>> searchHadiths(String query, {String? bookId}) async =>
      [_hadith()];

  @override
  Future<List<Hadith>> searchByNarrator(String narrator) async => [_hadith()];

  @override
  Future<HadithBook> getBookSummary(String bookId) async => HadithBook(
        id: bookId,
        metadata: const BookMetadata(
          title: 'الأربعون النووية',
          author: 'النووي',
        ),
        chapters: const [],
        hadiths: [_hadith()],
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
  }) async =>
      [_hadith()];

  @override
  Future<Hadith?> getRandomHadith() async => _hadith();

  @override
  Future<Map<int, int>> getChapterHadithCounts(String bookId) async => {1: 42};
}
