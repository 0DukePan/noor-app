import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/features/prayer/domain/entities/prayer_entities.dart';
import 'package:noor_app/features/prayer/presentation/providers/prayer_providers.dart';

/// Tests the QadaNotifier: adding, incrementing, deleting records, and
/// persistence to Hive.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_qada_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('starts empty', () async {
    final notifier = QadaNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(notifier.state.prayerRecords, isEmpty);
    expect(notifier.state.fastingRecords, isEmpty);
  });

  test('addRecord adds to the right list', () async {
    final notifier = QadaNotifier()
      ..addRecord(QadaType.prayer, 'الفجر', 30, null)
      ..addRecord(QadaType.fasting, 'صيام الاثنين', 10, 'قضاء');
    final state = notifier.state;
    expect(state.prayerRecords, hasLength(1));
    expect(state.fastingRecords, hasLength(1));
    expect(state.prayerRecords.first.totalCount, 30);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });

  test('incrementRecord advances the count and reports completion', () async {
    final notifier = QadaNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    notifier.addRecord(QadaType.prayer, 'الظهر', 2, null);
    final id = notifier.state.prayerRecords.first.id;

    final doneEarly = notifier.incrementRecord(id);
    expect(doneEarly, isFalse);
    expect(notifier.state.prayerRecords.first.completedCount, 1);

    final done = notifier.incrementRecord(id);
    expect(done, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });

  test('deleteRecord removes from both lists', () async {
    final notifier = QadaNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    notifier.addRecord(QadaType.prayer, 'العصر', 3, null);
    final id = notifier.state.prayerRecords.first.id;
    notifier.deleteRecord(id);
    expect(notifier.state.prayerRecords, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });

  test('records persist across notifier instances', () async {
    final first = QadaNotifier();
    // Let the constructor's async load settle before mutating.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    first.addRecord(QadaType.fasting, 'قضاء رمضان', 20, 'ملاحظة');
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final second = QadaNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(second.state.fastingRecords, hasLength(1));
    expect(second.state.fastingRecords.first.notes, 'ملاحظة');
  });
}
