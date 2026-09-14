import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/features/quran/presentation/providers/khatmah_providers.dart';

/// Tests the KhatmahNotifier state machine: starting, progress, persistence,
/// completion, and daily page tracking.
///
/// Deterministic by design: each notifier's constructor kicks off an
/// unawaited Hive load, so every test awaits `notifier.ready` (exposed for
/// this purpose) instead of sleeping a fixed 150ms — the fixed-sleep pattern
/// was flaky under full-suite CPU load.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_khatmah_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    // Hive.close() closes AND unregisters boxes: without it, deleteFromDisk
    // leaves a closed-but-registered box that the next test's openBox reuses,
    // and every put() throws "Box has already been closed" (root cause of
    // the intermittent failures under full-suite load).
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  test('starts with no active khatmah', () async {
    final notifier = KhatmahNotifier();
    await notifier.ready;
    expect(notifier.state, isNull);
  });

  test('startNew creates an active khatmah', () async {
    final notifier = KhatmahNotifier();
    await notifier.ready;
    await notifier.startNew(name: 'ختمة رمضان');
    expect(notifier.state, isNotNull);
    expect(notifier.state!.name, 'ختمة رمضان');
    expect(notifier.state!.currentPage, 1);
    expect(notifier.state!.progressPercentage, 0);
  });

  test('empty name falls back to the default', () async {
    final notifier = KhatmahNotifier();
    await notifier.ready;
    await notifier.startNew(name: '');
    expect(notifier.state!.name, 'ختمتي');
  });

  test('updateProgress advances pages and tracks today count', () async {
    final notifier = KhatmahNotifier();
    await notifier.ready;
    await notifier.startNew(name: 't');
    await notifier.updateProgress(surah: 2, verse: 1, page: 10);
    expect(notifier.state!.currentPage, 10);
    expect(notifier.state!.progressPercentage, greaterThan(0));
    final today = await notifier.getTodayPagesRead();
    expect(today, 9);
  });

  test("backward navigation does not reduce today's count", () async {
    final notifier = KhatmahNotifier();
    await notifier.ready;
    await notifier.startNew(name: 't');
    await notifier.updateProgress(surah: 2, verse: 1, page: 10);
    await notifier.updateProgress(surah: 1, verse: 1, page: 5);
    expect(notifier.state!.currentPage, 5);
    final today = await notifier.getTodayPagesRead();
    expect(today, 9);
  });

  test('reaching page 604 completes and archives the khatmah', () async {
    final notifier = KhatmahNotifier();
    await notifier.ready;
    await notifier.startNew(name: 'الختمة الكبرى');
    await notifier.updateProgress(surah: 114, verse: 6, page: 604);

    expect(notifier.state, isNull);
    final history = await notifier.getCompletedHistory();
    expect(history, hasLength(1));
    expect(history.first.name, 'الختمة الكبرى');
  });

  test('active khatmah is restored from disk on a new notifier', () async {
    final first = KhatmahNotifier();
    await first.ready;
    await first.startNew(name: 'مستمرة');
    await first.updateProgress(surah: 2, verse: 1, page: 20);

    final second = KhatmahNotifier();
    await second.ready;
    expect(second.state, isNotNull);
    expect(second.state!.name, 'مستمرة');
    expect(second.state!.currentPage, 20);
  });
}
