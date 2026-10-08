import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/core/domain/entities/surah.dart';
import 'package:noor_app/features/quran/presentation/pages/surah_page.dart';
import 'package:noor_app/features/quran/presentation/providers/quran_providers.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// QUR-09 / QUR-11 contract: every Qur'an entry point routes through a
/// validated location, and the study reader positions + highlights the exact
/// saved/search-result ayah instead of landing at the surah start.
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

  Surah testSurah() => const Surah(
    number: 1,
    nameArabic: 'الفاتحة',
    nameEnglish: 'Al-Fatihah',
    englishNameTranslation: 'The Opening',
    versesCount: 5,
    revelationType: RevelationType.meccan,
    verses: [
      Verse(
        number: 1,
        numberInSurah: 1,
        textUthmani: 'آية واحد',
        surahNumber: 1,
      ),
      Verse(
        number: 2,
        numberInSurah: 2,
        textUthmani: 'آية اثنان',
        surahNumber: 1,
      ),
      Verse(
        number: 3,
        numberInSurah: 3,
        textUthmani: 'آية ثلاثة',
        surahNumber: 1,
      ),
      Verse(
        number: 4,
        numberInSurah: 4,
        textUthmani: 'آية أربعة',
        surahNumber: 1,
      ),
      Verse(
        number: 5,
        numberInSurah: 5,
        textUthmani: 'آية خمسة',
        surahNumber: 1,
      ),
    ],
  );

  Future<ProviderContainer> pumpSurah(
    WidgetTester tester, {
    int? initialAyah,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [surahProvider.overrideWith((ref, n) async => testSurah())],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SurahPage(surahNumber: 1, initialAyah: initialAyah),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return ProviderScope.containerOf(tester.element(find.byType(SurahPage)));
  }

  testWidgets('initialAyah selects and highlights the exact verse', (
    tester,
  ) async {
    final container = await pumpSurah(tester, initialAyah: 3);
    expect(container.read(surahSelectedVerseProvider(1)), 2);
  });

  testWidgets('no initialAyah leaves selection untouched', (tester) async {
    final container = await pumpSurah(tester);
    expect(container.read(surahSelectedVerseProvider(1)), isNull);
  });
}
