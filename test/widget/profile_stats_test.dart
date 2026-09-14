import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/statistics_service.dart';
import 'package:noor_app/features/home/presentation/widgets/hadith_of_day_card.dart';
import 'package:noor_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Tests for HadithOfDayCard and profileStatsProvider — both previously
/// zero-covered.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_hodc_test');
    Hive.init(tempDir.path);
    await StatisticsService.init();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  testWidgets('HadithOfDayCard renders the hadith text', (tester) async {
    const text = 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ';
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HadithOfDayCard(hadith: {'arabic': text}),
        ),
      ),
    );

    expect(find.textContaining('إِنَّمَا الْأَعْمَال'), findsOneWidget);
  });

  test('profileStatsProvider builds stats from an empty fresh box', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final stats = container.read(profileStatsProvider);
    // Fresh Hive -> zeroed stats, never a crash.
    expect(stats.todayReading.versesRead, 0);
    expect(stats.adhkarStreak, 0);
    expect(stats.completedKhatmah, 0);
  });
}
