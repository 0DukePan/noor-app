import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/hive_service.dart';
import 'package:noor_app/features/settings/presentation/pages/storage_settings_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// State-depth tests for StorageSettingsPage (previously ~0% executed):
/// cache stats render from real boxes, refresh re-reads, and the silent-UI
/// previews show their overlays.
///
/// The clear-cache tile is NOT tapped: it drives the audio engine and the
/// search index through real plugins/channels.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_storage_test');
    Hive.init(tempDir.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      )
      // HiveService resolves its directory through path_provider.
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return null;
        },
      );
    await HiveService.initialize();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  Future<void> pumpStorage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StorageSettingsPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Scrolls a UNIQUE target fully into view (slivers skip below-fold
  /// rows). For ambiguous finders (shared header/tile titles) use manual
  /// drags + findsWidgets instead — scrollUntilVisible demands uniqueness.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  /// Lets overlay auto-dismiss timers fire so teardown finds no pending
  /// timers, then unmounts.
  Future<void> settleOverlays(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('renders zeroed cache stats on fresh boxes', (tester) async {
    await pumpStorage(tester);

    expect(find.text('التخزين والأداء'), findsOneWidget);
    expect(find.text('سور محفوظة'), findsOneWidget);
    expect(find.text('أحاديث محفوظة'), findsOneWidget);
    expect(find.text('أذكار محفوظة'), findsOneWidget);
    expect(find.text('مسح التخزين المؤقت'), findsOneWidget);
    expect(find.text('تحديث الإحصائيات'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('refresh re-reads stats and shows success', (tester) async {
    await pumpStorage(tester);

    await reveal(tester, find.text('تحديث الإحصائيات'));
    await tester.tap(find.text('تحديث الإحصائيات'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('تم تحديث الإحصائيات'), findsOneWidget);
    await settleOverlays(tester);
  });

  testWidgets('silent-UI previews show their overlays', (tester) async {
    await pumpStorage(tester);

    await reveal(tester, find.text('معاينة الإشعار الهادئ'));
    await tester.tap(find.text('معاينة الإشعار الهادئ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('مثال على الإشعار الهادئ'), findsOneWidget);

    await reveal(tester, find.text('معاينة إشعار النجاح'));
    await tester.tap(find.text('معاينة إشعار النجاح'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('تم الحفظ بنجاح!'), findsWidgets);
    await settleOverlays(tester);
  });
}
