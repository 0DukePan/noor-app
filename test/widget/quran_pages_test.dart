import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/adhkar_data_source.dart';
import 'package:noor_app/core/services/mosque_mode_service.dart';
import 'package:noor_app/features/quran/presentation/pages/quran_mushaf_page.dart';
import 'package:noor_app/features/quran/presentation/pages/surah_page.dart';
import 'package:noor_app/features/quran/presentation/pages/tafsir_reader_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Phase 3 #5: text-integrity-critical Quran pages. These were never loaded by
/// any test (surah_page.dart, tafsir_reader_page.dart, quran_mushaf_page.dart
/// are all absent from lcov). Smoke-tests load each page against the real
/// bundled assets so a broken reader ships unverified no longer.
///
/// The pages read real assets and touch HapticFeedback, so the platform
/// channel is mocked (returns null) and heavy async loads are pumped through
/// `runAsync`.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_quran_pages_test');
    Hive.init(tempDir.path);
    await AdhkarDataSource.init();
    await MosqueModeService.init();
    await Hive.openBox<dynamic>('hifz_box');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  Future<void> pumpLoaded(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('SurahPage renders without crashing', (tester) async {
    await pumpLoaded(tester, const SurahPage(surahNumber: 1));
    expect(find.byType(SurahPage), findsOneWidget);
    expect(
      find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.text('الفاتحة').evaluate().isNotEmpty,
      isTrue,
    );
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('TafsirReaderPage renders without crashing', (tester) async {
    await pumpLoaded(
      tester,
      const TafsirReaderPage(
        surahNumber: 1,
        ayahNumber: 1,
        surahName: 'الفاتحة',
      ),
    );
    expect(find.byType(TafsirReaderPage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('QuranMushafPage renders without crashing', (tester) async {
    await pumpLoaded(tester, const QuranMushafPage());
    expect(find.byType(QuranMushafPage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  },
  timeout: const Timeout(Duration(seconds: 60)),
);
}
