import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:noor_app/core/domain/entities/hadith.dart';
import 'package:noor_app/features/hadith/presentation/providers/hadith_providers.dart';

/// Unit tests for MemorizationNotifier review + persistence (previously
/// uncovered): advancing, completion, streak, reset, and the Hive
/// round-trip. Runs in the plain zone where Hive writes complete — the
/// widget test covers deck/flip rendering, which is all the fake zone
/// allows (puts there poison it permanently).
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noor_memnot_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    try {
      await tempDir.delete(recursive: true);
    } on Exception catch (_) {}
  });

  const hadiths = [
    Hadith(
      id: 1,
      idInBook: 1,
      arabic: 'أ',
      englishText: 'a',
      narratorEnglish: 'n',
      chapterId: 1,
    ),
    Hadith(
      id: 2,
      idInBook: 2,
      arabic: 'ب',
      englishText: 'b',
      narratorEnglish: 'n',
      chapterId: 1,
    ),
  ];

  test('review advances the index and completes the deck', () async {
    final notifier = MemorizationNotifier();
    await notifier.loadCards(hadiths);
    expect(notifier.state.currentCard?.id, 1);
    expect(notifier.state.isComplete, isFalse);

    await notifier.reviewCard(3);
    expect(notifier.state.currentCard?.id, 2);
    expect(notifier.state.isComplete, isFalse);

    await notifier.reviewCard(4);
    expect(notifier.state.isComplete, isTrue);
    // Index stays on the last card once complete.
    expect(notifier.state.currentCard?.id, 2);
  });

  test('review persists FSRS state and reloads it', () async {
    final notifier = MemorizationNotifier();
    await notifier.loadCards(hadiths);
    await notifier.reviewCard(3);

    // A fresh notifier against the same box restores repetitions.
    final reloaded = MemorizationNotifier();
    await reloaded.loadCards(hadiths);
    expect(reloaded.state.fsrsCards['1']?.repetitions, 1);
    expect(reloaded.state.fsrsCards['2']?.repetitions ?? 0, 0);
  });

  test('reviewing an empty deck is a safe no-op', () async {
    final notifier = MemorizationNotifier();
    await notifier.loadCards(const []);
    await notifier.reviewCard(3);
    expect(notifier.state.isComplete, isFalse);
    expect(notifier.state.currentCard, isNull);
  });

  test('reset rewinds the deck', () async {
    final notifier = MemorizationNotifier();
    await notifier.loadCards(hadiths);
    await notifier.reviewCard(3);
    await notifier.reviewCard(3);
    expect(notifier.state.isComplete, isTrue);

    notifier.reset();
    expect(notifier.state.isComplete, isFalse);
    expect(notifier.state.currentCard?.id, 1);
  });
}
