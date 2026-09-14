import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/hadith_user_data_service.dart';
import 'package:noor_app/features/hadith/presentation/pages/learning_statistics_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// State-depth tests for LearningStatisticsPage (previously ~0% executed):
/// zeroed dashboard on fresh boxes, and real numbers once bookmarks + quiz
/// history are seeded.
///
/// All boxes the page opens are pre-opened here (real zone): a body-zone
/// openBox never completes under testWidgets, but a cache hit does.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    tempDir = await Directory.systemTemp.createTemp('noor_learnstat_test');
    Hive.init(tempDir.path);
    await HadithUserDataService.init();
    for (final name in [
      'hadith_notes',
      'quiz_history',
      'memorization_cards',
      'day_state',
      'app_statistics',
    ]) {
      await Hive.openBox<dynamic>(name);
    }
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  /// Pumps the page and lets the multi-box stats load finish.
  Future<void> pumpStats(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LearningStatisticsPage(),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders the zeroed dashboard on fresh boxes', (tester) async {
    await pumpStats(tester);

    expect(find.text('إحصائياتي'), findsOneWidget);
    expect(find.text('سلسلة الأيام'), findsOneWidget);
    expect(find.text('محفوظات'), findsOneWidget);
    expect(find.text('ملاحظات'), findsOneWidget);
    expect(find.text('اختبارات'), findsOneWidget);
    expect(find.text('نشاط الأسبوع'), findsOneWidget);
    // No bookmarks -> no per-book section.
    expect(find.text('المحفوظات حسب الكتب'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  },
      timeout: const Timeout(Duration(seconds: 60)),);

  testWidgets('seeded bookmarks and quiz history render real numbers',
      (tester) async {
    // Seed inside a real-zone window: Hive puts issued in the fake zone
    // poison it permanently (pending write timers kill settle, timeouts
    // and close), but complete normally here.
    await tester.runAsync(() async {
      await HadithUserDataService.bookmarkHadith(
        hadithId: 1,
        collectionId: 'nawawi40',
        arabic: 'حديث',
        englishText: 'test',
        narrator: 'tester',
        idInBook: 1,
      );
      final quizBox = Hive.box<dynamic>('quiz_history');
      await quizBox.put('q1', {'score': 8, 'total': 10});
    });

    await pumpStats(tester);

    expect(find.text('إحصائياتي'), findsOneWidget);
    // Per-book section lives at the bottom: scroll until built.
    await tester.scrollUntilVisible(
      find.text('المحفوظات حسب الكتب'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('المحفوظات حسب الكتب'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  },
      timeout: const Timeout(Duration(seconds: 60)),);
}
