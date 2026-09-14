import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor_app/features/settings/presentation/pages/notifications_settings_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// State-depth tests for NotificationsSettingsPage (previously ~0%
/// executed): sections render from defaults, toggles flip state, and the
/// prayer-minutes slider reveals only when prayer notifications are on.
///
/// No engine init here on purpose: with a null settings box the reads return
/// defaults and the saves no-op, so toggles exercise pure UI state. The
/// apply button is NOT tapped (it drives real notification scheduling
/// through platform channels).
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationsSettingsPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Scrolls down until the target is built (slivers don't build below-fold
  /// children; shared header/tile titles can't use scrollUntilVisible —
  /// they resolve to two elements once built). Caps the drags so a missing
  /// widget fails fast instead of hanging.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    for (var i = 0;
        i < 8 && finder.evaluate().isEmpty;
        i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
  }

  /// The Switch inside the tile with the given title (index-free: switch
  /// positions shift as lazily-built rows come and go).
  Finder switchFor(String title) {
    return find.descendant(
      of: find.ancestor(
        of: find.text(title),
        matching: find.byType(SwitchListTile),
      ),
      matching: find.byType(Switch),
    );
  }

  testWidgets('renders all sections with default values', (tester) async {
    await pumpSettings(tester);

    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('تذكيرات الأذكار'), findsOneWidget);
    expect(find.text('إشعارات الصلاة'), findsOneWidget);
    expect(find.text('تذكير القراءة اليومية'), findsOneWidget);
    // Defaults: prayer notifications on (slider visible, above the fold).
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('قبل الصلاة بـ'), findsOneWidget);
    // Quiet-hours section is below the fold: scroll until both the header
    // and the tile titles are built, then the apply button.
    await scrollTo(tester, find.text('ساعات الهدوء'));
    expect(find.text('ساعات الهدوء'), findsNWidgets(2));
    await scrollTo(tester, find.text('تطبيق الإعدادات'));
    expect(find.text('تطبيق الإعدادات'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('toggling morning adhkar flips its switch', (tester) async {
    await pumpSettings(tester);

    final morningSwitch = switchFor('أذكار الصباح');
    expect(tester.widget<Switch>(morningSwitch).value, isTrue);
    await tester.tap(morningSwitch);
    await tester.pump();
    expect(tester.widget<Switch>(morningSwitch).value, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('disabling prayer notifications hides the slider',
      (tester) async {
    await pumpSettings(tester);

    final prayerSwitch = switchFor('تنبيه قبل الصلاة');
    expect(tester.widget<Switch>(prayerSwitch).value, isTrue);
    await tester.tap(prayerSwitch);
    await tester.pump();
    expect(tester.widget<Switch>(prayerSwitch).value, isFalse);
    expect(find.byType(Slider), findsNothing);
    expect(find.text('قبل الصلاة بـ'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('enabling the khatmah reminder reveals the time picker',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('معطل'), findsWidgets);
    await scrollTo(tester, find.text('تذكير الختمة اليومي'));
    final khatmahSwitch = switchFor('تذكير الختمة اليومي');
    expect(khatmahSwitch, findsOneWidget);
    await tester.tap(khatmahSwitch);
    await tester.pump();
    // Default reminder time 20:00 now shown on the picker button.
    expect(find.text('20:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
