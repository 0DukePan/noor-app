import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/algorithms/fsrs_algorithm.dart';
import 'package:noor_app/features/hifz/data/hifz_ayah_card.dart';
import 'package:noor_app/features/hifz/presentation/providers/hifz_providers.dart';

void main() {
  group('HifzAyahCard', () {
    test('new card is due immediately and has no repetitions', () {
      final card = HifzAyahCard(
        id: '1:1',
        surah: 1,
        ayah: 1,
        arabicText: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      );
      expect(card.isNew, isTrue);
      expect(card.isDue, isTrue);
      expect(card.repetitions, 0);
      expect(card.masteryLevel, 1);
    });

    test('first review schedules a future interval', () {
      final card = HifzAyahCard(
        id: '1:1',
        surah: 1,
        ayah: 1,
        arabicText: 'text',
      )..review(Rating.easy);
      expect(card.isNew, isFalse);
      expect(card.repetitions, 1);
      expect(card.isDue, isFalse);
      expect(card.nextReview.isAfter(card.lastReview), isTrue);
    });

    test('again rating increments lapses and keeps the card due soon', () {
      final card = HifzAyahCard(
        id: '1:1',
        surah: 1,
        ayah: 1,
        arabicText: 'text',
      )..review(Rating.again);
      expect(card.lapses, 1);
      // An "again" rating yields a very short interval (≤2 days).
      expect(card.daysUntilReview, lessThanOrEqualTo(2));
    });

    test('hard < good < easy intervals', () {
      final intervals = HifzAyahCard(
        id: '1:1',
        surah: 1,
        ayah: 1,
        arabicText: 'text',
      ).previewIntervals();
      expect(intervals[Rating.easy], greaterThanOrEqualTo(intervals[Rating.good]!));
      expect(intervals[Rating.good], greaterThanOrEqualTo(intervals[Rating.hard]!));
      expect(intervals[Rating.hard], greaterThanOrEqualTo(intervals[Rating.again]!));
    });

    test('json round-trip preserves state', () {
      final card = HifzAyahCard(
        id: '2:255',
        surah: 2,
        ayah: 255,
        arabicText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
        repeatCount: 5,
      )..review(Rating.good);
      final restored = HifzAyahCard.fromJson(card.toJson());
      expect(restored.id, card.id);
      expect(restored.arabicText, card.arabicText);
      expect(restored.repetitions, card.repetitions);
      expect(restored.stability, closeTo(card.stability, 0.001));
      expect(restored.difficulty, closeTo(card.difficulty, 0.001));
      expect(restored.nextReview, card.nextReview);
      expect(restored.repeatCount, 5);
    });

    test('keyOf joins surah and ayah', () {
      expect(HifzAyahCard.keyOf(112, 1), '112:1');
    });
  });

  group('HifzNotifier', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('noor_hifz_test');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      // Close first: Hive keeps open boxes in its registry and openBox
      // would otherwise return the previous test's stale instance.
      await Hive.close();
      await Hive.deleteFromDisk();
      try {
        await tempDir.delete(recursive: true);
      } on Exception catch (_) {}
    });

    test('addAyah stores cards and dedupes by surah:ayah', () async {
      final notifier = HifzNotifier();
      await notifier.addAyah(surah: 1, ayah: 1, arabicText: 'آية 1');
      await notifier.addAyah(surah: 1, ayah: 1, arabicText: 'آية محدثة');
      await notifier.addAyah(surah: 1, ayah: 2, arabicText: 'آية 2');

      expect(notifier.state.cards.length, 2);
      expect(notifier.state.cards.first.arabicText, 'آية محدثة');
      expect(notifier.cardFor(1, 2), isNotNull);
    });

    test('reviewAyah applies FSRS and records the daily streak', () async {
      final notifier = HifzNotifier();
      await notifier.addAyah(surah: 1, ayah: 1, arabicText: 'آية');
      await notifier.addAyah(surah: 1, ayah: 2, arabicText: 'آية');

      await notifier.reviewAyah('1:1', Rating.good);

      final reviewed = notifier.cardFor(1, 1)!;
      expect(reviewed.repetitions, 1);
      expect(notifier.state.streak.currentStreak, 1);
      expect(notifier.cardFor(1, 2)!.repetitions, 0,
          reason: 'reviewing one ayah must not touch the others',);
    });

    test('removeAyah deletes the card', () async {
      final notifier = HifzNotifier();
      await notifier.addAyah(surah: 1, ayah: 1, arabicText: 'آية');
      await notifier.removeAyah('1:1');
      expect(notifier.state.cards, isEmpty);
    });

    test('setRepeatCount clamps to 1..20', () async {
      final notifier = HifzNotifier();
      await notifier.addAyah(surah: 1, ayah: 1, arabicText: 'آية');
      await notifier.setRepeatCount('1:1', 99);
      expect(notifier.cardFor(1, 1)!.repeatCount, 20);
      await notifier.setRepeatCount('1:1', 0);
      expect(notifier.cardFor(1, 1)!.repeatCount, 1);
    });

    test('dueCards sorts by next review ascending', () async {
      final notifier = HifzNotifier();
      await notifier.addAyah(surah: 1, ayah: 1, arabicText: 'آية');
      await notifier.addAyah(surah: 1, ayah: 2, arabicText: 'آية');
      await notifier.reviewAyah('1:1', Rating.hard);
      await notifier.reviewAyah('1:2', Rating.easy);

      final due = notifier.state.dueCards;
      expect(due, isEmpty, reason: 'fresh reviews are not due today');

      // Backdate the first card to be due.
      notifier.cardFor(1, 1)!
        ..nextReview = DateTime.now().subtract(const Duration(days: 1))
        ..repetitions = 1;
      expect(notifier.state.dueCards.map((c) => c.id).toList(), ['1:1']);
    });

    test('state persists across notifier instances', () async {
      final first = HifzNotifier();
      await first.addAyah(surah: 1, ayah: 1, arabicText: 'آية');
      await first.reviewAyah('1:1', Rating.easy);

      final second = HifzNotifier();
      await second.ready;
      expect(second.state.cards.length, 1);
      expect(second.state.cards.first.repetitions, 1);
      expect(second.state.streak.currentStreak, 1);
    });
  });
}
