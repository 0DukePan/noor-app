import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/features/home/presentation/widgets/day_state_card.dart';
import 'package:noor_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Golden (visual regression) tests.
///
/// NOTE: widget tests render all text with the Ahem placeholder font unless
/// real fonts are loaded, so these goldens are deterministic across platforms
/// and CI — they pin LAYOUT, not typography. Regenerate with:
///   flutter test --update-goldens test/golden_test.dart
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('day state card golden (2/5 prayers done)', (tester) async {
    await tester.runAsync(() async {
      final tempDir = await Directory.systemTemp.createTemp('noor_golden');
      Hive.init(tempDir.path);
      await DayStateMachine.init();
      await DayStateMachine.markPrayerCompleted(PrayerType.fajr);
      await DayStateMachine.markPrayerCompleted(PrayerType.dhuhr);
    });

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          backgroundColor: Color(0xFFF5F2EA),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: DayStateCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(DayStateCard),
      matchesGoldenFile('goldens/day_state_card.png'),
    );

    DayStateMachine.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)),);

  testWidgets('onboarding first step golden', (tester) async {
    await tester.runAsync(() async {
      final tempDir = await Directory.systemTemp.createTemp('noor_golden_ob');
      Hive.init(tempDir.path);
    });

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingPage(onComplete: _noop),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await expectLater(
      find.byType(OnboardingPage),
      matchesGoldenFile('goldens/onboarding_page.png'),
    );
  }, timeout: const Timeout(Duration(seconds: 30)),);
}

void _noop() {}
