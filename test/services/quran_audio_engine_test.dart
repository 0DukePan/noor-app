import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:noor_app/core/services/quran_audio_engine.dart';

/// The audio engine's plugin-bound playback is not unit-testable, but the
/// pure surface (verse numbering, reciter catalog, repeat/play-state models)
/// is. Download/cache/playback paths drive just_audio + http directly and
/// are dispositioned to on-device QA (see coverage-exclusions.md).
void main() {
  test('absoluteVerseNumber is 1 for the first ayah of Al-Fatihah', () {
    expect(QuranAudioEngine.absoluteVerseNumber(1, 1), 1);
  });

  test('absoluteVerseNumber accounts for prior surah verse counts', () {
    // Al-Baqarah starts right after Al-Fatihah (7 verses).
    expect(QuranAudioEngine.absoluteVerseNumber(2, 1), 8);
    // Al-Fatihah (7) + Al-Baqarah (286) = 293, so Aal-Imran starts at 294.
    expect(QuranAudioEngine.absoluteVerseNumber(3, 1), 294);
  });

  test('absoluteVerseNumber is 6236 for the final ayah of An-Nas', () {
    expect(QuranAudioEngine.absoluteVerseNumber(114, 6), 6236);
  });

  test('absoluteVerseNumber is monotonic in surah order', () {
    var previous = 0;
    for (var surah = 1; surah <= 114; surah++) {
      final start = QuranAudioEngine.absoluteVerseNumber(surah, 1);
      expect(start, greaterThan(previous));
      previous = start;
    }
  });

  test('reciter catalog holds 16 entries with usable stream URLs', () {
    const reciters = QuranAudioEngine.reciters;
    expect(reciters, hasLength(16));
    for (final entry in reciters.entries) {
      expect(entry.key, entry.value.id);
      expect(entry.value.arabicName, isNotEmpty);
      expect(entry.value.englishName, isNotEmpty);
      expect(entry.value.baseUrl, startsWith('https://'));
    }
  });

  test('default reciter is valid; unknown setReciter ids are ignored', () {
    expect(
      QuranAudioEngine.reciters,
      contains(QuranAudioEngine.currentReciterInfo.id),
    );
    final before = QuranAudioEngine.currentReciterInfo.id;
    QuranAudioEngine.setReciter('ar.husary');
    expect(QuranAudioEngine.currentReciterInfo.id, 'ar.husary');
    QuranAudioEngine.setReciter('no.such.reciter');
    expect(QuranAudioEngine.currentReciterInfo.id, 'ar.husary');
    QuranAudioEngine.setReciter(before);
  });

  test('RepeatMode carries Arabic names and distinct icons', () {
    expect(RepeatMode.none.arabicName, 'بدون تكرار');
    expect(RepeatMode.ayah.arabicName, 'تكرار الآية');
    expect(RepeatMode.surah.arabicName, 'تكرار السورة');
    expect(RepeatMode.none.icon, Icons.repeat);
    expect(RepeatMode.ayah.icon, Icons.repeat_one);
    expect(RepeatMode.surah.icon, Icons.repeat);
  });

  test('PlayState flags derive from the processing state', () {
    const loading = PlayState(
      isPlaying: false,
      processingState: ProcessingState.loading,
    );
    expect(loading.isLoading, isTrue);
    expect(loading.isCompleted, isFalse);

    const buffering = PlayState(
      isPlaying: true,
      processingState: ProcessingState.buffering,
    );
    expect(buffering.isLoading, isTrue);

    const completed = PlayState(
      isPlaying: false,
      processingState: ProcessingState.completed,
    );
    expect(completed.isLoading, isFalse);
    expect(completed.isCompleted, isTrue);

    const ready = PlayState(
      isPlaying: true,
      processingState: ProcessingState.ready,
    );
    expect(ready.isLoading, isFalse);
    expect(ready.isCompleted, isFalse);
  });
}
