import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/statistics_service.dart';
import 'package:noor_app/features/profile/presentation/pages/profile_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// State-depth tests for ProfilePage (previously ~0% executed): renders the
/// zeroed dashboard on a fresh box, in both themes.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    tempDir = await Directory.systemTemp.createTemp('noor_profile_test');
    Hive.init(tempDir.path);
    await StatisticsService.init();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  Future<void> pumpProfile(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(brightness: brightness),
          home: const ProfilePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders the zeroed dashboard on a fresh box', (tester) async {
    await pumpProfile(tester);

    expect(find.text('ملفي الشخصي'), findsOneWidget);
    expect(find.text('📊 إحصائيات اليوم'), findsOneWidget);
    // Fresh Hive -> every counter renders zero, never a crash.
    expect(find.text('آيات مقروءة'), findsOneWidget);
    expect(find.text('وقت القراءة'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders in the dark theme without crashing', (tester) async {
    await pumpProfile(tester, brightness: Brightness.dark);

    expect(find.text('ملفي الشخصي'), findsOneWidget);
    expect(find.text('📊 إحصائيات اليوم'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
