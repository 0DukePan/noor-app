import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/services/statistics_service.dart';

/// Tests StatisticsService persistence: reading stats, adhkar streaks,
/// listening, khatmah progress, and the weekly summary.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_stats_test');
    Hive.init(tempDir.path);
    await StatisticsService.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('reading stats accumulate today and total', () async {
    await StatisticsService.recordVerseRead(1, 1);
    await StatisticsService.recordVerseRead(2, 255);
    await StatisticsService.recordReadingTime(const Duration(minutes: 5));

    final today = StatisticsService.getTodayReadingStats();
    final total = StatisticsService.getTotalReadingStats();
    expect(today.versesRead, 2);
    expect(total.versesRead, 2);
    expect(today.readingTimeSeconds, 300);
    expect(total.readingTimeSeconds, 300);
  });

  test('last read position persists surah and ayah', () async {
    await StatisticsService.recordVerseRead(18, 9);
    final position = StatisticsService.getLastReadPosition();
    expect(position?['surah'], 18);
    expect(position?['ayah'], 9);
  });

  test('adhkar streak starts at 1 after a full day', () async {
    await StatisticsService.recordAdhkarComplete('morning');
    await StatisticsService.recordAdhkarComplete('evening');
    expect(StatisticsService.getAdhkarStreak(), 1);
    final status = StatisticsService.getTodayAdhkarStatus();
    expect(status.morningComplete, isTrue);
    expect(status.eveningComplete, isTrue);
  });

  test('adhkar streak continues when yesterday was complete', () async {
    final box = await Hive.openBox<dynamic>('app_statistics');
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    await box.put('adhkar_morning_$yesterday', true);
    await box.put('adhkar_evening_$yesterday', true);
    await box.put('adhkar_streak', 1);

    await StatisticsService.recordAdhkarComplete('morning');
    await StatisticsService.recordAdhkarComplete('evening');
    expect(StatisticsService.getAdhkarStreak(), 2);
  });

  test('listening stats accumulate', () async {
    await StatisticsService.recordListening(
      surah: 2,
      ayah: 255,
      duration: const Duration(minutes: 3),
      reciter: 'ar.alafasy',
    );
    await StatisticsService.recordListening(
      surah: 2,
      ayah: 256,
      duration: const Duration(minutes: 2),
      reciter: 'ar.alafasy',
    );
    final stats = StatisticsService.getListeningStats();
    expect(stats.todayVerses, 2);
    expect(stats.todayTimeSeconds, 300);
    expect(stats.totalTimeSeconds, 300);
  });

  test('khatmah progress percentage tracks completed verses', () async {
    await StatisticsService.updateKhatmahProgress(surah: 1, ayah: 7);
    final progress = StatisticsService.getKhatmahProgress();
    expect(progress.surah, 1);
    expect(progress.ayah, 7);
    expect(progress.percentage, greaterThan(0));
  });

  test('startNewKhatmah counts a completed khatmah and resets', () async {
    await StatisticsService.updateKhatmahProgress(surah: 114, ayah: 6);
    await StatisticsService.startNewKhatmah();
    expect(StatisticsService.getCompletedKhatmahCount(), 1);
    final reset = StatisticsService.getKhatmahProgress();
    expect(reset.surah, 1);
    expect(reset.ayah, 1);
  });

  test("weekly summary reflects today's activity", () async {
    await StatisticsService.recordVerseRead(1, 1);
    await StatisticsService.recordReadingTime(const Duration(minutes: 10));
    final summary = StatisticsService.getWeeklySummary();
    expect(summary.versesRead, 1);
    expect(summary.readingTimeSeconds, 600);
  });
}
