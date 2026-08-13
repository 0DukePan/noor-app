import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:noor_app/main.dart' as app;

/// Real-device/emulator smoke test (run via `flutter test integration_test`).
///
/// Boots the REAL app: initializes every service, runs the one-time hadith
/// DB import, completes onboarding, and verifies all five main tabs render
/// without crashing. This is the first "the app actually runs on Android"
/// evidence — CI runs it on an emulator (see .github/workflows/ci.yml).
///
/// The bottom nav only shows a label for the SELECTED tab, so navigation taps
/// target the nav icons — scoped to the bottom band of the screen so page
/// content using the same Material icons (e.g. the Quran header) is ignored.
/// The geometry is pinned by test/widget/nav_bar_geometry_test.dart.

const _bootTimeout = Duration(minutes: 8);
const _stepTimeout = Duration(seconds: 45);

/// The five tabs' nav icons: home, quran, hadith, adhkar, tools.
const _tabIcons = <IconData>[
  Icons.home_rounded,
  Icons.menu_book_rounded,
  Icons.auto_stories_rounded,
  Icons.favorite_rounded,
  Icons.grid_view_rounded,
];

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = _stepTimeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out after $timeout waiting for $finder');
}

Future<void> _tapTab(WidgetTester tester, IconData icon) async {
  final size = tester.getSize(find.byType(Scaffold).first);
  final navIcon = find.byIcon(icon).evaluate().firstWhere(
    (element) {
      final rect = tester.getRect(
        find.byElementPredicate((el) => el == element),
      );
      return rect.top > size.height * 0.8;
    },
  );
  await tester.tapAt(
    tester.getCenter(find.byElementPredicate((el) => el == navIcon)),
  );
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and all five main tabs render', (tester) async {
    // Boot the real app (service init runs in real async time).
    unawaited(app.main());
    await tester.pump();
    await _pumpUntil(tester, find.byType(Scaffold), timeout: _bootTimeout);
    await tester.pump(const Duration(seconds: 2));

    // First launch: the one-time hadith import gate, then onboarding.
    // (Boot may skip onboarding entirely on a re-run device.)
    await _pumpUntil(
      tester,
      find.byWidgetPredicate((widget) {
        if (widget is! Text) return false;
        final text = widget.data;
        return text == 'أهلاً بك في نور' || text == 'الرئيسية';
      }),
      timeout: _bootTimeout,
    );

    if (find.text('أهلاً بك في نور').evaluate().isNotEmpty) {
      await tester.tap(find.text('تخطي'));
      await _pumpUntil(tester, find.text('الرئيسية'));
    }

    // Home tab is selected by default.
    expect(find.text('الرئيسية'), findsOneWidget);

    // Quran tab.
    await _tapTab(tester, _tabIcons[1]);
    await _pumpUntil(tester, find.text('القرآن'));
    await _pumpUntil(tester, find.text('القرآن الكريم'));

    // Hadith tab (book library header).
    await _tapTab(tester, _tabIcons[2]);
    await _pumpUntil(tester, find.text('الحديث'));
    await _pumpUntil(tester, find.text('الكتب والمجاميع'));

    // Adhkar tab (category cards).
    await _tapTab(tester, _tabIcons[3]);
    await _pumpUntil(tester, find.text('الأذكار'));
    await _pumpUntil(tester, find.text('أذكار الصباح'));

    // Tools tab (tool grid).
    await _tapTab(tester, _tabIcons[4]);
    await _pumpUntil(tester, find.text('الأدوات'));
    await _pumpUntil(tester, find.text('مواقيت الصلاة'));

    // Back to home.
    await _tapTab(tester, _tabIcons[0]);
    await _pumpUntil(tester, find.text('الرئيسية'));

    // No unhandled exceptions during the whole run.
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 12)),);
}
