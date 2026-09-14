import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/core/domain/entities/surah.dart';
import 'package:noor_app/core/models/adhkar_models.dart';
import 'package:noor_app/core/services/day_state_machine.dart';
import 'package:noor_app/core/services/prayer_time_engine.dart';
import 'package:noor_app/core/theme/noor_theme.dart';
import 'package:noor_app/features/home/presentation/pages/home_page.dart';
import 'package:noor_app/features/home/presentation/providers/home_provider.dart';
import 'package:noor_app/features/quran/presentation/widgets/surah_verse_widgets.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Functional golden matrix: key widgets render in light and dark themes at
/// three text scales without layout exceptions or missing content. (The
/// font-fetch is disabled, so rendering is deterministic.)
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  Future<void> pumpScaled(
    WidgetTester tester,
    Widget child, {
    required Brightness brightness,
    required double textScale,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          theme:
              brightness == Brightness.dark ? NoorTheme.dark : NoorTheme.light,
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  const verse = Verse(
    number: 1,
    numberInSurah: 1,
    textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    surahNumber: 1,
  );

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('BismillahHeader renders ${brightness.name} @ ${scale}x',
          (tester) async {
        await pumpScaled(
          tester,
          const BismillahHeader(surahNumber: 1),
          brightness: brightness,
          textScale: scale,
        );
        expect(find.textContaining('بِسْمِ اللَّهِ'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('DynamicVerseCard renders ${brightness.name} @ ${scale}x',
          (tester) async {
        await pumpScaled(
          tester,
          DynamicVerseCard(
            verse: verse,
            isKhushuMode: false,
            isSelected: false,
            onTap: () {},
            onLongPress: () {},
          ),
          brightness: brightness,
          textScale: scale,
        );
        expect(find.textContaining('بِسْمِ اللَّهِ'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('HomePage renders in light and dark themes', (tester) async {
    final overrides = <Override>[
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
          adhkarStats: DailyAdhkarStats(date: DateTime(2026, 3, 15)),
        ),
      ),
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
    ];

    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: brightness == Brightness.dark
                ? NoorTheme.dark
                : NoorTheme.light,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('نور'),
        findsOneWidget,
        reason: 'home header in ${brightness.name}',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
    }
  },
  timeout: const Timeout(Duration(seconds: 60)),
);
}
