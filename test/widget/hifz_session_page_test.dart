import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/algorithms/fsrs_algorithm.dart';
import 'package:noor_app/features/hifz/data/hifz_ayah_card.dart';
import 'package:noor_app/features/hifz/presentation/pages/hifz_session_page.dart';
import 'package:noor_app/features/hifz/presentation/providers/hifz_providers.dart';
import 'package:noor_app/l10n/generated/app_localizations.dart';

/// Records reviews synchronously without touching Hive: the real notifier's
/// `_save()` put would hang in the widget-test zone and stall `_rate()`
/// before the queue advances. The page under test only needs the call to
/// complete — queue movement is local state.
class FakeHifzNotifier extends HifzNotifier {
  final reviewed = <String>[];

  @override
  Future<void> reviewAyah(String id, Rating rating) async {
    reviewed.add('$id:${rating.name}');
  }
}

/// HifzSessionPage (previously zero-covered): no audio mocking — the engine
/// is never initialized, so `playAyah` pends on the just_audio channel
/// (harmless, timer-free) while `_playing` state applies synchronously
/// first. Dummy mp3s are pre-seeded so no real network fires.
void main() {
  late Directory tempDir;

  List<HifzAyahCard> cards() => [
        HifzAyahCard(
          id: '1:1',
          surah: 1,
          ayah: 1,
          arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        ),
        HifzAyahCard(
          id: '1:2',
          surah: 1,
          ayah: 2,
          arabicText: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        ),
      ];

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('noor_hifz_test');
    Hive.init(tempDir.path);
    // Same generic the notifier uses, so its lazy open hits the cache.
    await Hive.openBox<dynamic>('hifz_box');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      )
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return null;
        },
      );
    // Seed cached audio so playAyah takes the local-file path (no network).
    for (final card in cards()) {
      final file = File(
        '${tempDir.path}/audio/ar.alafasy/${card.surah}/${card.ayah}.mp3',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes([0x49, 0x44, 0x33]);
    }
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, null)
      ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  Future<FakeHifzNotifier> pumpSession(WidgetTester tester) async {
    final fake = FakeHifzNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hifzProvider.overrideWith((ref) => fake)],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HifzSessionPage(cards: cards()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    return fake;
  }

  testWidgets('renders the first card with session counter', (tester) async {
    await pumpSession(tester);
    expect(find.text('جلسة حفظ (1/2)'), findsOneWidget);
    expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
    expect(find.text('سورة 1 — آية 1'), findsOneWidget);
    expect(find.text('كيف كان تذكُّرُك؟'), findsOneWidget);
  });

  testWidgets('a passing rating advances to the next card', (tester) async {
    final fake = await pumpSession(tester);
    await tester.tap(find.text('جيد'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(fake.reviewed, ['1:1:good']);
    expect(find.text('جلسة حفظ (2/2)'), findsOneWidget);
    expect(find.text('الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ'), findsOneWidget);
  });

  testWidgets('an again rating re-queues the card at the end', (tester) async {
    final fake = await pumpSession(tester);
    await tester.tap(find.text('لم أتذكر'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(fake.reviewed, ['1:1:again']);
    // Failed card moved to the end: the second card shows, queue stays 2.
    expect(find.text('جلسة حفظ (1/2)'), findsOneWidget);
    expect(find.text('الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ'), findsOneWidget);
  });

  testWidgets('rating the final card shows the completion dialog',
      (tester) async {
    await pumpSession(tester);
    await tester.tap(find.text('جيد'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('جيد'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ما شاء الله 🎉'), findsOneWidget);
  });
}
