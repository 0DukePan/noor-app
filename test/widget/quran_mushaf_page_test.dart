import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/features/quran/domain/entities/quran_entities.dart';
import 'package:noor_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:noor_app/features/quran/presentation/pages/quran_mushaf_page.dart';
import 'package:noor_app/features/quran/presentation/providers/quran_providers.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

const _verses = [
  Verse(
    number: 1,
    numberInSurah: 1,
    textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    surahNumber: 1,
  ),
  Verse(
    number: 2,
    numberInSurah: 2,
    textUthmani: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    surahNumber: 1,
  ),
];

class FakeQuranRepository implements QuranRepository {
  final savedPages = <int>[];

  @override
  Future<Either<Failure, void>> saveReadingProgress({
    required int surahNumber,
    required int verseNumber,
    required int page,
  }) async {
    savedPages.add(page);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Surah>>> getAllSurahs() async => const Right([]);
  @override
  Future<Either<Failure, Surah>> getSurahWithVerses(int n) async =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, List<Verse>>> getVersesByPage(int p) async =>
      const Right([]);
  @override
  Future<Either<Failure, Tafsir>> getTafsir({
    required int surahNumber,
    required int verseNumber,
    String? tafsirSource,
  }) async =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, RevelationCause?>> getRevelationCause({
    required int surahNumber,
    required int verseNumber,
  }) async =>
      const Right(null);
  @override
  Future<Either<Failure, ({int page, int surahNumber, int verseNumber})>>
      getLastReadingPosition() async =>
          const Right((surahNumber: 1, verseNumber: 1, page: 1));
  @override
  Future<Either<Failure, List<Verse>>> searchQuran(String query) async =>
      const Right([]);
}

/// QuranMushafPage (previously smoke-only): verse render, controls toggle,
/// and theme-skin switching through provider overrides with a fake
/// repository. Page-turn persistence is best-effort Hive I/O in the paging
/// path and stays on-device (see coverage-exclusions.md).
void main() {
  final fakeRepo = FakeQuranRepository();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pumpMushaf(
    WidgetTester tester, {
    List<Verse> verses = _verses,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quranPageProvider.overrideWith((ref, page) async => verses),
          quranRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranMushafPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders page verses with controls visible', (tester) async {
    await pumpMushaf(tester);
    // Verses render word-split with markers, so match distinctive words.
    expect(find.textContaining('الرَّحْمَٰنِ'), findsWidgets);
    expect(find.textContaining('الْعَالَمِينَ'), findsWidgets);
    expect(find.byTooltip('المظهر'), findsOneWidget);
  });

  testWidgets('tapping the page toggles the control overlays', (tester) async {
    await pumpMushaf(tester);
    expect(find.byTooltip('المظهر'), findsOneWidget);
    await tester.tapAt(const Offset(400, 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('المظهر'), findsNothing);
    await tester.tapAt(const Offset(400, 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('المظهر'), findsOneWidget);
  });

  testWidgets('theme sheet opens; dark skin renders via provider',
      (tester) async {
    await pumpMushaf(tester);
    await tester.tap(find.byTooltip('المظهر'));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('مظهر القراءة'), findsOneWidget);
    expect(find.text('داكن'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    // Skin mapping itself (the sheet tiles only set this provider).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quranPageProvider.overrideWith((ref, page) async => _verses),
          quranRepositoryProvider.overrideWithValue(fakeRepo),
          mushafThemeProvider
              .overrideWith((ref) => MushafTheme.midnightBlack),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranMushafPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFF0D0D0D));
  });

  testWidgets('empty verses render without crashing', (tester) async {
    await pumpMushaf(tester, verses: const []);
    expect(find.byType(QuranMushafPage), findsOneWidget);
  });
}
