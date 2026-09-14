import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/features/prayer/presentation/pages/qada_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// State-depth tests for QadaTrackerPage (previously ~0% executed): empty
/// states on both tabs, add-dialog validation, add/increment/complete/delete.
void main() {
  late Directory tempDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    tempDir = await Directory.systemTemp.createTemp('noor_qada_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  /// Pumps the page and lets the notifier's Hive `ready` future finish.
  Future<void> pumpQada(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QadaTrackerPage(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows empty states on both tabs', (tester) async {
    await pumpQada(tester);

    expect(find.text('متتبع القضاء'), findsOneWidget);
    expect(find.text('لا توجد صلوات فائتة للقضاء'), findsOneWidget);

    await tester.tap(find.text('الصيام'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد أيام صيام للقضاء'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('add dialog rejects an invalid count', (tester) async {
    await pumpQada(tester);

    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة صلوات للقضاء'), findsOneWidget);

    await tester.tap(find.text('إضافة').last);
    await tester.pump();
    expect(find.text('الرجاء إدخال عدد صحيح'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('add, increment to completion, then delete', (tester) async {
    await pumpQada(tester);

    // Add a single-makeup record.
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '1');
    await tester.tap(find.text('إضافة').last);
    await tester.pumpAndSettle();
    expect(find.text('تم: 0 من 1'), findsOneWidget);

    // Increment once -> complete -> congratulations dialog.
    await tester.tap(find.text('قضيت صلاة واحدة'));
    await tester.pumpAndSettle();
    expect(find.text('🎉 تهانينا!'), findsOneWidget);
    await tester.tap(find.text('الحمد لله'));
    await tester.pumpAndSettle();
    expect(find.text('✓ مكتمل'), findsOneWidget);

    // Delete the record -> back to the empty state.
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد صلوات فائتة للقضاء'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
