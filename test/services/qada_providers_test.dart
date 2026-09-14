import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/features/prayer/domain/entities/prayer_entities.dart';
import 'package:noor_app/features/prayer/presentation/providers/prayer_providers.dart';

/// Tests the QadaNotifier: adding, incrementing, deleting records, and
/// persistence to Hive.
///
/// Deterministic by design: each notifier's constructor kicks off an
/// unawaited Hive load, so every test awaits `notifier.ready` (exposed for
/// this purpose) instead of sleeping a fixed 150ms — the fixed-sleep pattern
/// was flaky under full-suite CPU load.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_qada_test');
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

  test('starts empty', () async {
    final notifier = QadaNotifier();
    await notifier.ready;
    expect(notifier.state.prayerRecords, isEmpty);
    expect(notifier.state.fastingRecords, isEmpty);
  });

  test('addRecord adds to the right list', () async {
    final notifier = QadaNotifier();
    await notifier.ready;
    notifier
      ..addRecord(QadaType.prayer, 'الفجر', 30, null)
      ..addRecord(QadaType.fasting, 'صيام الاثنين', 10, 'قضاء');
    final state = notifier.state;
    expect(state.prayerRecords, hasLength(1));
    expect(state.fastingRecords, hasLength(1));
    expect(state.prayerRecords.first.totalCount, 30);
  });

  test('incrementRecord advances the count and reports completion', () async {
    final notifier = QadaNotifier();
    await notifier.ready;
    notifier.addRecord(QadaType.prayer, 'الظهر', 2, null);
    final id = notifier.state.prayerRecords.first.id;

    final doneEarly = notifier.incrementRecord(id);
    expect(doneEarly, isFalse);
    expect(notifier.state.prayerRecords.first.completedCount, 1);

    final done = notifier.incrementRecord(id);
    expect(done, isTrue);
  });

  test('deleteRecord removes from both lists', () async {
    final notifier = QadaNotifier();
    await notifier.ready;
    notifier.addRecord(QadaType.prayer, 'العصر', 3, null);
    final id = notifier.state.prayerRecords.first.id;
    notifier.deleteRecord(id);
    expect(notifier.state.prayerRecords, isEmpty);
  });

  test('records persist across notifier instances', () async {
    final first = QadaNotifier();
    await first.ready;
    first.addRecord(QadaType.fasting, 'قضاء رمضان', 20, 'ملاحظة');

    // addRecord's Hive save is fire-and-forget by design; poll the box
    // until the record lands instead of sleeping an arbitrary duration.
    final box = await Hive.openBox<dynamic>('qada_records');
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(deadline)) {
      final list = box.get('fasting_records', defaultValue: <dynamic>[]);
      if (list is List && list.isNotEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    final second = QadaNotifier();
    await second.ready;
    expect(second.state.fastingRecords, hasLength(1));
    expect(second.state.fastingRecords.first.notes, 'ملاحظة');
  });
}
