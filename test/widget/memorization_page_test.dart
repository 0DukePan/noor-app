import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/data/data_sources/local_hadith_data_source.dart';
import 'package:noor_app/core/domain/entities/hadith.dart';
import 'package:noor_app/features/hadith/presentation/pages/memorization_page.dart';
import 'package:noor_app/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Canned data source: two hadiths, no SQLite, no zones to fight.
class _FakeHadithDataSource extends LocalHadithDataSource {
  @override
  Future<List<Hadith>> getHadithsPage({
    required String bookId,
    required int page,
    required int limit,
    int? chapterId,
  }) async {
    return const [
      Hadith(
        id: 1,
        idInBook: 1,
        arabic: 'حديث تجريبي أول للحفظ',
        englishText: 'First test hadith',
        narratorEnglish: 'Tester',
        chapterId: 1,
        collectionId: 'nawawi40',
      ),
      Hadith(
        id: 2,
        idInBook: 2,
        arabic: 'حديث تجريبي ثان للحفظ',
        englishText: 'Second test hadith',
        narratorEnglish: 'Tester',
        chapterId: 1,
        collectionId: 'nawawi40',
      ),
    ];
  }
}

/// State-depth tests for MemorizationPage (previously ~0% executed):
/// deck load, card flip, rating advance, and completion.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    // The notifier persists FSRS cards in Hive. Boxes must be opened here
    // (real zone): a body-zone openBox never completes under testWidgets,
    // but a cache hit does.
    tempDir = await Directory.systemTemp.createTemp('noor_memorize_test');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>('memorization_cards');
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  Future<void> pumpDeck(WidgetTester tester) async {
    // Phone-sized surface: the card layout overflows the default 800x600
    // test viewport (real devices are taller).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localHadithDataSourceProvider.overrideWithValue(
            _FakeHadithDataSource(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MemorizationPage(),
        ),
      ),
    );
    // Deck load is async (provider + notifier futures).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('loads the deck and flips the first card', (tester) async {
    await pumpDeck(tester);

    expect(find.text('حفظ الأحاديث'), findsOneWidget);
    expect(find.text('اضغط لإظهار الإجابة'), findsOneWidget);

    // Tap the flashcard to reveal the answer.
    await tester.tap(find.text('اضغط لإظهار الإجابة'));
    await tester.pumpAndSettle();
    expect(find.text('حديث تجريبي أول للحفظ'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reviews driven through the real notifier complete the deck',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        localHadithDataSourceProvider.overrideWithValue(
          _FakeHadithDataSource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Phone-sized surface (see pumpDeck note).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MemorizationPage(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('اضغط لإظهار الإجابة'), findsOneWidget);

    // Drive both reviews through the real notifier inside a real-zone
    // window: Hive puts issued in the fake zone poison it permanently
    // (pending write timers kill settle, timeouts and close), but complete
    // normally here. Pumps then render the resulting states.
    await tester.runAsync(
      () => container.read(memorizationProvider.notifier).reviewCard(3),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => container.read(memorizationProvider.notifier).reviewCard(4),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Deck exhausted -> the completion empty state, no cards left.
    expect(find.text('🎉'), findsOneWidget);
    expect(find.text('اضغط لإظهار الإجابة'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
