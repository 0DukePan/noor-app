import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/features/quran/domain/entities/quran_entities.dart';
import 'package:noor_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:noor_app/features/quran/presentation/pages/quran_mushaf_page.dart';
import 'package:noor_app/features/quran/presentation/providers/quran_providers.dart';
import 'package:noor_app/features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';
import 'package:dartz/dartz.dart';

const _verses = [
  Verse(
    number: 1,
    numberInSurah: 1,
    textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    surahNumber: 1,
    juz: 1,
    surahName: 'الفاتحة',
  ),
];

class _FakeRepo implements QuranRepository {
  @override
  Future<Either<Failure, void>> saveReadingProgress({
    required int surahNumber,
    required int verseNumber,
    required int page,
  }) async => const Right(null);
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
  }) async => throw UnimplementedError();
  @override
  Future<Either<Failure, RevelationCause?>> getRevelationCause({
    required int surahNumber,
    required int verseNumber,
  }) async => const Right(null);
  @override
  Future<Either<Failure, ({int page, int surahNumber, int verseNumber})>>
  getLastReadingPosition() async =>
      const Right((surahNumber: 1, verseNumber: 1, page: 1));
  @override
  Future<Either<Failure, void>> addBookmark({
    required int surahNumber,
    required int verseNumber,
  }) async => const Right(null);
  @override
  Future<Either<Failure, void>> removeBookmark({
    required int surahNumber,
    required int verseNumber,
  }) async => const Right(null);
  @override
  Future<Either<Failure, bool>> isBookmarked({
    required int surahNumber,
    required int verseNumber,
  }) async => const Right(false);
  @override
  Future<Either<Failure, List<({int surahNumber, int verseNumber})>>>
  getBookmarks() async => const Right([]);
  @override
  Future<Either<Failure, List<Verse>>> searchQuran(String query) async =>
      const Right([]);
}

/// WCAG relative luminance.
double _luminance(Color c) {
  double lin(int v) {
    final s = v / 255.0;
    return s <= 0.03928 ? s / 12.92 : (s + 0.055) / 1.055 * (s + 0.055) / 1.055;
  }

  return 0.2126 * lin(c.red) + 0.7152 * lin(c.green) + 0.0722 * lin(c.blue);
}

double _contrast(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

/// Phase 4 contract: every Mushaf skin meets WCAG text contrast, chrome is
/// localized in both languages, semantic labels exist, and controls meet the
/// 48dp target policy.
void main() {
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

  test('all five skins meet text contrast (4.5) and marker contrast (3.0)', () {
    expect(MushafTheme.values, hasLength(5));
    for (final theme in MushafTheme.values) {
      final data = MushafThemeData.themes[theme]!;
      expect(
        _contrast(data.textColor, data.backgroundColor),
        greaterThanOrEqualTo(4.5),
        reason: '$theme text/background',
      );
      expect(
        _contrast(data.verseMarkerColor, data.backgroundColor),
        greaterThanOrEqualTo(3.0),
        reason: '$theme marker/background',
      );
    }
  });

  test('high-contrast skin is pure black/white with luminous marker', () {
    const data = MushafThemeData.highContrastTheme;
    expect(data.backgroundColor, const Color(0xFF000000));
    expect(data.textColor, const Color(0xFFFFFFFF));
    expect(
      _contrast(data.textColor, data.backgroundColor),
      greaterThanOrEqualTo(15.0),
    );
  });

  Future<void> pumpMushaf(
    WidgetTester tester, {
    Locale locale = const Locale('ar'),
    List<Override> extra = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quranPageProvider.overrideWith((ref, page) async => _verses),
          quranRepositoryProvider.overrideWithValue(_FakeRepo()),
          ...extra,
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const QuranMushafPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('English chrome is localized (no Arabic-only controls)', (
    tester,
  ) async {
    await pumpMushaf(tester, locale: const Locale('en'));
    expect(find.byTooltip('Appearance'), findsOneWidget);
    expect(find.text('Page 1 / 604'), findsOneWidget);
  });

  testWidgets('page exposes a semantic label with page/surah/juz context', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMushaf(tester, locale: const Locale('en'));
    expect(find.bySemanticsLabel(RegExp('Page 1 of 604')), findsWidgets);
    handle.dispose();
  });

  testWidgets('theme sheet controls meet 48dp targets', (tester) async {
    await pumpMushaf(tester);
    await tester.tap(find.byTooltip('المظهر'));
    await tester.pump(const Duration(milliseconds: 1200));
    for (final tooltip in ['تكبير خط المصحف', 'تصغير خط المصحف']) {
      final finder = find.byTooltip(tooltip);
      expect(finder, findsOneWidget, reason: tooltip);
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(48), reason: tooltip);
      expect(size.height, greaterThanOrEqualTo(48), reason: tooltip);
    }
    // Five skins incl. high contrast, all selectable.
    expect(find.text('تباين عالٍ'), findsOneWidget);
  });

  testWidgets('high-contrast skin renders a black canvas', (tester) async {
    await pumpMushaf(
      tester,
      extra: [
        mushafThemeProvider.overrideWith((ref) => MushafTheme.highContrast),
      ],
    );
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFF000000));
  });

  testWidgets('small portrait and landscape render without overflow', (
    tester,
  ) async {
    for (final size in [const Size(320, 568), const Size(800, 360)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpMushaf(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
      expect(find.byType(MushafPageCanvas), findsOneWidget);
    }
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('ayah sheet actions are keyboard-focusable in order', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: AyahActionsSheet(
              verse: Verse(
                number: 1,
                numberInSurah: 1,
                textUthmani: 'آية',
                surahNumber: 1,
              ),
              themeData: MushafThemeData.madaniCreamTheme,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Focus the first action without activating it (activation would pop).
    Focus.of(tester.element(find.text('نسخ'))).requestFocus();
    await tester.pump();
    expect(Focus.of(tester.element(find.text('نسخ'))).hasFocus, isTrue);

    // Tab order follows the visual copy → save → share order.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('حفظ'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('مشاركة'))).hasFocus, isTrue);
  });

  testWidgets('reader chrome is focusable for keyboard users', (tester) async {
    await pumpMushaf(tester);
    // Appearance control participates in focus traversal.
    final button = find.widgetWithIcon(IconButton, Icons.palette_rounded);
    expect(button, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.byType(Focus)),
      findsWidgets,
    );
    expect(
      tester.widget<Slider>(find.byType(Slider)).onChanged,
      isNotNull,
      reason: 'slider must stay keyboard-operable',
    );
  });
}
