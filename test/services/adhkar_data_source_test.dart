import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/models/adhkar_models.dart';
import 'package:noor_app/core/services/adhkar_data_source.dart';

/// Tests AdhkarDataSource: asset loading, progress persistence, daily stats,
/// streaks, and settings round-trips.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_adhkar_test');
    Hive.init(tempDir.path);
    await AdhkarDataSource.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('morning collection loads from bundled assets', () async {
    final collection = await AdhkarDataSource.getCollection(AdhkarType.morning);
    expect(collection, isNotNull);
    expect(collection!.title, 'أذكار الصباح');
    expect(collection.adhkar, isNotEmpty);
  });

  test('sleep and wakeup collections load (authored content)', () async {
    final sleep = await AdhkarDataSource.getCollection(AdhkarType.sleep);
    final wakeUp = await AdhkarDataSource.getCollection(AdhkarType.wakeUp);
    expect(sleep, isNotNull);
    expect(wakeUp, isNotNull);
    expect(sleep!.adhkar, isNotEmpty);
    expect(wakeUp!.adhkar, isNotEmpty);
  });

  test('getZekr returns the right item and guards bounds', () async {
    final first = await AdhkarDataSource.getZekr(AdhkarType.morning, 0);
    expect(first, isNotNull);
    expect(await AdhkarDataSource.getZekr(AdhkarType.morning, 999), isNull);
  });

  test('incrementCount and nextZekr persist progress', () async {
    final incremented = await AdhkarDataSource.incrementCount(AdhkarType.morning);
    expect(incremented.currentCount, 1);
    final next = await AdhkarDataSource.nextZekr(AdhkarType.morning);
    expect(next.currentIndex, 1);
    final reloaded = AdhkarDataSource.getProgress(AdhkarType.morning);
    expect(reloaded.currentIndex, 1);
    // Advancing to a new zekr starts its counter at zero (by design).
    expect(reloaded.currentCount, 0);
  });

  test('completeAdhkar marks completion and updates daily stats', () async {
    await AdhkarDataSource.completeAdhkar(AdhkarType.morning);
    final progress = AdhkarDataSource.getProgress(AdhkarType.morning);
    expect(progress.isCompleted, isTrue);
    final stats = AdhkarDataSource.getTodayStats();
    expect(stats.morningCompleted, isTrue);
    expect(stats.totalAdhkarCount, 1);
  });

  test('streak counts consecutive complete days', () async {
    final box = await Hive.openBox<dynamic>('adhkar_stats');
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    await box.put(yesterday, {
      'date': yesterday,
      'morningCompleted': true,
      'eveningCompleted': true,
    });

    await AdhkarDataSource.completeAdhkar(AdhkarType.morning);
    await AdhkarDataSource.completeAdhkar(AdhkarType.evening);
    expect(AdhkarDataSource.getStreak(), 2);
  });

  test('display settings round-trip', () async {
    await AdhkarDataSource.saveSettings(
      const AdhkarDisplaySettings(
        fontSize: 28,
        showBless: false,
        vibrateOnComplete: false,
        autoAdvance: true,
        autoAdvanceDelay: 700,
      ),
    );
    final loaded = AdhkarDataSource.getSettings();
    expect(loaded.fontSize, 28);
    expect(loaded.showBless, isFalse);
    expect(loaded.vibrateOnComplete, isFalse);
    expect(loaded.autoAdvance, isTrue);
    expect(loaded.autoAdvanceDelay, 700);
  });
}
