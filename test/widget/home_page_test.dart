import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/core/models/adhkar_models.dart';
import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/features/home/presentation/pages/home_page.dart';
import 'package:noor_app/features/home/presentation/providers/home_provider.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Tests for HomePage — the first screen every user sees (previously zero
/// coverage). The data providers are overridden to exercise the content,
/// loading, and error branches deterministically.
///
/// Note: the page's inner cards watch periodic StreamProviders and the
/// shimmer/animate effects run indefinitely, so the periodic streams are
/// overridden with one-shot values and tests end by unmounting the widget.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  // One-shot day-state stream (the real provider is Stream.periodic, whose
  // pending Timer would fail the test at teardown).
  final oneShotDayState = dayStateProvider.overrideWith(
    (ref) => Stream.value(
      const StateInfo(
        state: DayState.dhuhr,
        nextState: DayState.asr,
        timeToNextState: Duration(hours: 3),
        suggestedAdhkar: 'استغفر الله',
        suggestedAction: 'صلاة الظهر',
      ),
    ),
  );

  // One-shot clock stream (watched by the next-prayer card; real provider is
  // Stream.periodic every 30s).
  final oneShotClock = currentTimeProvider
      .overrideWith((ref) => Stream.value(DateTime(2026, 3, 15)));

  HomeData fakeData() => HomeData(
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
      );

  Future<void> pumpHome(WidgetTester tester, List<Override> overrides) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        // Arabic locale + delegates: the page renders localized strings via
        // AppLocalizations, and the assertions below pin the Arabic copy.
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('renders the dashboard with data', (tester) async {
    await pumpHome(tester, [
      homeDataProvider.overrideWith((ref) async => fakeData()),
      smartGreetingProvider.overrideWithValue('طاب يومك ☀️'),
      oneShotDayState,
      oneShotClock,
    ]);

    // Header + greeting + location + the visible top sections.
    expect(find.text('نور'), findsOneWidget);
    expect(find.text('طاب يومك ☀️'), findsOneWidget);
    expect(find.text('مكة المكرمة'), findsOneWidget);
    expect(find.text('متابعة القراءة'), findsOneWidget);
    // Lower sections are lazily built; scroll to them.
    await tester.scrollUntilVisible(
      find.text('المفضلة'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('المفضلة'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('أذكار اليوم'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('أذكار اليوم'), findsOneWidget);
    expect(find.text('نور النبوة'), findsOneWidget);
    // All content-branch animations are finite; settle flushes every
    // flutter_animate 0ms timer scheduled by lazy card mounts.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await unmount(tester);
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('shows the loading shimmer while data is pending',
      (tester) async {
    // Un-overridden provider would hit platform channels; a never-completing
    // Completer pins the loading branch without leaving a pending Timer.
    final gate = Completer<HomeData>();
    await pumpHome(tester, [
      homeDataProvider.overrideWith((ref) => gate.future),
    ]);

    // Loading branch renders shimmer boxes, not content.
    expect(find.text('نور'), findsNothing);
    await unmount(tester);
  },
  timeout: const Timeout(Duration(seconds: 60)),
);

  testWidgets('shows the error state with retry when the provider fails',
      (tester) async {
    await pumpHome(tester, [
      homeDataProvider.overrideWith((ref) async {
        throw Exception('network down');
      }),
    ]);

    expect(find.text('تعذر جلب البيانات'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await unmount(tester);
  },
  timeout: const Timeout(Duration(seconds: 60)),
);
}
