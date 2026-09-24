import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// These pin LAYOUT, not typography. Making that promise hold on both Windows
/// and the Linux CI image takes three things, and all three have bitten this
/// file already:
///   * the app's own fonts must be loaded here, or the text falls back to
///     whatever system font the machine happens to have;
///   * nothing inside a golden may draw emoji (system font again - the
///     onboarding icons failed on the runner at 0.22% while passing locally);
///   * nothing inside a golden may ask google_fonts for a family the app
///     already ships in assets/fonts/.
///
/// Regenerate with:
///   flutter test --update-goldens test/golden_test.dart
void main() {
  setUpAll(() async {
    await (FontLoader('Cairo')
          ..addFont(rootBundle.load('assets/fonts/Cairo-Variable.ttf')))
        .load();
    await (FontLoader('Amiri')
          ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf')))
        .load();
  });

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
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(fontFamily: 'Cairo'),
        home: const Scaffold(
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
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(fontFamily: 'Cairo'),
        home: const OnboardingPage(onComplete: _noop),
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
