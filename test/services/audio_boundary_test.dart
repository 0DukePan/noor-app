import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/core/services/quran_audio_engine.dart';
import 'package:noor_app/core/utils/verse_counts.dart';

/// AUD-02 contract: completion for the final ayah of a surah must never
/// construct an out-of-range identity or retain an invalid label.
/// Exhaustive across all 114 surahs and every repeat/queue mode.
void main() {
  test('none mode advances inside the surah and stops at its final ayah', () {
    for (var surah = 1; surah <= 114; surah++) {
      final count = verseCountForSurah(surah);
      // Mid-surah: next ayah in the same surah.
      expect(
        QuranAudioEngine.nextAyahIdentity(
          surah: surah,
          ayah: 1,
          mode: RepeatMode.none,
        ),
        count > 1 ? (surah, 2) : null,
        reason: 'surah $surah first ayah',
      );
      // Final ayah: stop (null) — never (surah, count+1).
      expect(
        QuranAudioEngine.nextAyahIdentity(
          surah: surah,
          ayah: count,
          mode: RepeatMode.none,
        ),
        isNull,
        reason: 'surah $surah final ayah must stop',
      );
    }
  });

  test('surah mode advances and loops the same surah at its end', () {
    for (var surah = 1; surah <= 114; surah++) {
      final count = verseCountForSurah(surah);
      expect(
        QuranAudioEngine.nextAyahIdentity(
          surah: surah,
          ayah: count,
          mode: RepeatMode.surah,
        ),
        (surah, 1),
        reason: 'surah $surah must restart itself, not leak into ${surah + 1}',
      );
    }
  });

  test('ayah mode repeats the same valid identity', () {
    for (var surah = 1; surah <= 114; surah++) {
      final count = verseCountForSurah(surah);
      expect(
        QuranAudioEngine.nextAyahIdentity(
          surah: surah,
          ayah: count,
          mode: RepeatMode.ayah,
        ),
        (surah, count),
      );
    }
  });

  test('invalid identities yield null in every mode', () {
    for (final mode in RepeatMode.values) {
      expect(
        QuranAudioEngine.nextAyahIdentity(surah: 0, ayah: 1, mode: mode),
        isNull,
      );
      expect(
        QuranAudioEngine.nextAyahIdentity(surah: 1, ayah: 8, mode: mode),
        isNull,
      );
      expect(
        QuranAudioEngine.nextAyahIdentity(surah: 115, ayah: 1, mode: mode),
        isNull,
      );
    }
  });

  test('no out-of-range pair is ever produced at the Quran end', () {
    // An-Nas 114:6 is the final ayah of the entire corpus.
    expect(
      QuranAudioEngine.nextAyahIdentity(
        surah: 114,
        ayah: 6,
        mode: RepeatMode.none,
      ),
      isNull,
    );
    expect(
      QuranAudioEngine.nextAyahIdentity(
        surah: 114,
        ayah: 6,
        mode: RepeatMode.surah,
      ),
      (114, 1),
    );
    expect(absoluteVerseNumber(114, 6), 6236);
  });

  test('PlaybackFailure carries typed kinds', () {
    final invalid = PlaybackFailure.invalidLocation(surah: 1, ayah: 8);
    expect(invalid.kind, PlaybackFailureKind.invalidLocation);
    expect(invalid.surah, 1);

    final offline = PlaybackFailure.offline(surah: 2, ayah: 255);
    expect(offline.kind, PlaybackFailureKind.offline);
  });
}
