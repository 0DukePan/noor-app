import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:noor_app/core/widgets/main_shell.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Validates the EXACT navigation approach used by
/// integration_test/app_test.dart: tabs are tapped by their nav ICON, scoped
/// to the bottom 20% band of the screen (labels only show when selected).
///
/// The quran page intentionally reuses Icons.menu_book_rounded in its header
/// (like the real QuranPage) to prove the band filter ignores content icons.
void main() {
  const tabIcons = <IconData>[
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.auto_stories_rounded,
    Icons.favorite_rounded,
    Icons.grid_view_rounded,
  ];
  const labels = <String>['الرئيسية', 'القرآن', 'الحديث', 'الأذكار', 'الأدوات'];

  Future<void> tapTab(WidgetTester tester, IconData icon) async {
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
    await tester.pumpAndSettle();
  }

  testWidgets('nav icons in the bottom band drive the five tabs',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            for (final (i, path) in const [
              '/',
              '/quran',
              '/hadith',
              '/adhkar',
              '/tools',
            ].indexed)
              GoRoute(
                path: path,
                builder: (context, state) => Scaffold(
                  body: Stack(
                    children: [
                      Center(child: Text('content-$i')),
                      if (i == 1)
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 180,
                          color: Color(0x0D107A57),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);

    for (var i = 1; i < tabIcons.length; i++) {
      await tapTab(tester, tabIcons[i]);
      expect(
        find.text(labels[i]),
        findsOneWidget,
        reason: 'tab ${labels[i]} should be selected after tapping its icon',
      );
      expect(find.text('content-$i'), findsOneWidget);
    }

    await tapTab(tester, tabIcons[0]);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('content-0'), findsOneWidget);
  });
}
