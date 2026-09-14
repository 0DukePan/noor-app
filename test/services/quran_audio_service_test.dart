import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:noor_app/core/services/quran_audio_engine.dart';
import 'package:noor_app/core/services/quran_audio_service.dart';

/// QuranAudioService facade (previously zero-covered): only the init-free
/// surface is tested — catalog projection, LoopMode mapping, reciter
/// selection. Playback passthrough (`playVerse/pause/seek/…`) drives the
/// just_audio player and is dispositioned to on-device QA (see
/// coverage-exclusions.md).
void main() {
  tearDown(() {
    QuranAudioEngine.repeatMode = RepeatMode.none;
    QuranAudioEngine.setReciter('ar.alafasy');
  });

  test('reciters project the engine catalog one-to-one', () {
    final reciters = QuranAudioService.reciters;
    expect(reciters, hasLength(QuranAudioEngine.reciters.length));
    expect(reciters, hasLength(16));
    for (final entry in QuranAudioEngine.reciters.entries) {
      final projected =
          reciters.singleWhere((r) => r.id == entry.key);
      expect(projected.nameArabic, entry.value.arabicName);
      expect(projected.nameEnglish, entry.value.englishName);
      expect(projected.photoUrl, isNull);
    }
  });

  test('setLoopMode maps just_audio modes onto engine repeat modes',
      () async {
    await QuranAudioService.setLoopMode(LoopMode.off);
    expect(QuranAudioEngine.repeatMode, RepeatMode.none);
    await QuranAudioService.setLoopMode(LoopMode.all);
    expect(QuranAudioEngine.repeatMode, RepeatMode.surah);
    await QuranAudioService.setLoopMode(LoopMode.one);
    expect(QuranAudioEngine.repeatMode, RepeatMode.ayah);
  });

  test('setReciter switches the current reciter; unknown ids are ignored',
      () {
    QuranAudioService.setReciter('ar.husary');
    expect(QuranAudioService.currentReciter, 'ar.husary');
    QuranAudioService.setReciter('no.such.reciter');
    expect(QuranAudioService.currentReciter, 'ar.husary');
  });
}
