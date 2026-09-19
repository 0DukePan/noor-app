import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:noor_app/core/models/adhkar_models.dart';
import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/features/home/presentation/pages/home_page.dart';
import 'package:noor_app/features/home/presentation/providers/home_provider.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Dynamic-type checks (docs/accessibility.md): the home dashboard — the
/// densest screen under test — must survive large text without a RenderFlex
/// overflow, in Arabic (RTL, the default), at 1.3x and 2.0x.
///
/// Overflow errors surface as exceptions in widget tests, so a regression
/// fails here instead of only being noticed on a device. Feature rows that are
/// not covered by this file are listed as tracked gaps in the doc.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpDashboard(WidgetTester tester, double scale) async {
    // Phone-like logical size (360x800), the layout these rows are built for.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDataProvider.overrideWith(
            (ref) async => HomeData(
              prayerTimes: PrayerTimeEngine.calculate(
                latitude: 21.4225,
                longitude: 39.8262,
                date: DateTime(2026, 3, 15),
                method: CalculationMethod.ummAlQura,
                utcOffset: 3,
              ),
              cityName: 'مكة المكرمة',
              adhkarStats: DailyAdhkarStats(
                date: DateTime(2026, 3, 15),
                morningCompleted: true,
              ),
            ),
          ),
          smartGreetingProvider.overrideWithValue('طاب يومك'),
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
            (ref) => Stream.value(DateTime(2026, 3, 15)),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const HomePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }

  for (final scale in const [1.3, 2.0]) {
    testWidgets('home dashboard lays out without overflow at ${scale}x text',
        (tester) async {
      await pumpDashboard(tester, scale);

      expect(tester.takeException(), isNull);
      expect(find.text('مكة المكرمة'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    }, timeout: const Timeout(Duration(seconds: 60)),);
  }
}
