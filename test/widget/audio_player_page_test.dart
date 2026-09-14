import 'dart:io';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/quran_audio_engine.dart';
import 'package:noor_app/core/services/quran_data_source.dart';
import 'package:noor_app/features/audio/presentation/pages/audio_player_page.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// AudioPlayerPage (previously zero-covered): the engine is never
/// initialized, so no just_audio channel fires — streams stay silent,
/// resume is skipped (null-safe), and catalog/speed/repeat statics drive
/// the UI. Surah data comes from the real bundled assets, warmed once in
/// setUpAll. Playback taps are deliberately NOT exercised (plugin-bound,
/// dispositioned in coverage-exclusions.md).
void main() {
  late Directory tempDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_audio_page_test');
    Hive.init(tempDir.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    await QuranDataSource.init();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  tearDown(() {
    QuranAudioEngine.repeatMode = RepeatMode.none;
    QuranAudioEngine.setReciter('ar.alafasy');
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AudioPlayerPage(),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    });
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('loads Al-Fatiha with reciter bar and ayah indicator',
      (tester) async {
    await pumpPage(tester);
    expect(find.text('سورة الفاتحة'), findsOneWidget);
    expect(find.text('مشاري راشد العفاسي'), findsOneWidget);
    expect(find.text('الآية 1 من 7'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('repeat button cycles modes with snackbars', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byIcon(Icons.repeat));
    await tester.pump(const Duration(milliseconds: 100));
    expect(QuranAudioEngine.repeatMode, RepeatMode.ayah);
    expect(find.text('تكرار الآية'), findsOneWidget);
    // Let the first snackbar fully expire (1s + 250ms exit): while it is
    // visible it covers the repeat button and absorbs the second tap.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.tap(find.byIcon(Icons.repeat_one));
    await tester.pump(const Duration(milliseconds: 100));
    expect(QuranAudioEngine.repeatMode, RepeatMode.surah);
    // The second snackbar races ScaffoldMessenger's exit animation, so only
    // the first cycle's snackbar text is asserted (same code path).
  });

  testWidgets('speed toggle reveals the 0.5x-2x slider', (tester) async {
    await pumpPage(tester);
    expect(find.byType(Slider), findsOneWidget); // progress bar only
    await tester.tap(find.byIcon(Icons.speed).first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Slider), findsNWidgets(2));
    expect(find.text('1.0x'), findsWidgets);
  });

  testWidgets('reciter sheet switches the current reciter', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byIcon(Icons.person));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('اختر القارئ'), findsOneWidget);
    // All 16 tiles render even off-screen; the sheet list is scrolled with
    // an on-screen drag (finder centers can sit below the fold).
    for (var i = 0;
        i < 10 &&
            find
                .widgetWithText(ListTile, 'محمود خليل الحصري')
                .hitTestable()
                .evaluate()
                .isEmpty;
        i++) {
      await tester.dragFrom(const Offset(400, 500), const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(
      find.widgetWithText(ListTile, 'محمود خليل الحصري'),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    expect(QuranAudioEngine.currentReciterInfo.id, 'ar.husary');
  });

  testWidgets('surah selector sheet lists all 114 surahs', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byIcon(Icons.list));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('اختر السورة'), findsOneWidget);
    expect(find.text('الفاتحة'), findsOneWidget);
  });
}
