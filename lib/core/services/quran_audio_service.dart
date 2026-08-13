import 'package:just_audio/just_audio.dart';

import 'quran_audio_engine.dart';

/// خدمة صوت القرآن - Quran Audio Service (facade)
///
/// Thin facade over [QuranAudioEngine] (the single audio implementation with
/// offline caching, resume and background playback). Kept so the surah-page
/// mini player and the legacy providers share ONE engine instead of two
/// independent players.
class QuranAudioService {
  // Getters
  static bool get isPlaying => QuranAudioEngine.isPlaying;
  static int get currentSurah => QuranAudioEngine.currentSurah;
  static int get currentVerse => QuranAudioEngine.currentAyah;
  static String get currentReciter => QuranAudioEngine.currentReciterInfo.id;
  static Duration? get duration => QuranAudioEngine.duration;
  static Duration get position => QuranAudioEngine.position;

  // Available reciters (built from the engine's catalog)
  static List<Reciter> get reciters => QuranAudioEngine.reciters.values
      .map((r) => Reciter(
            id: r.id,
            nameArabic: r.arabicName,
            nameEnglish: r.englishName,
          ),)
      .toList();

  // Streams
  static Stream<Duration?> get durationStream => QuranAudioEngine.durationStream;
  static Stream<Duration> get positionStream => QuranAudioEngine.positionStream;
  static Stream<bool> get playingStream =>
      QuranAudioEngine.playStateStream.map((s) => s.isPlaying);
  static Stream<PlayerState> get playerStateStream =>
      QuranAudioEngine.playStateStream.map(
        (s) => PlayerState(s.isPlaying, s.processingState),
      );

  /// Initialize audio service (delegates to the engine).
  static Future<void> init() => QuranAudioEngine.init();

  /// Set reciter
  static void setReciter(String reciterId) =>
      QuranAudioEngine.setReciter(reciterId);

  /// Play specific verse
  static Future<void> playVerse({
    required int surahNumber,
    required int verseNumber,
  }) =>
      QuranAudioEngine.playAyah(surah: surahNumber, ayah: verseNumber);

  /// Play entire surah from specific verse (auto-advances via the engine)
  static Future<void> playSurah({
    required int surahNumber,
    int startVerse = 1,
  }) =>
      QuranAudioEngine.playAyah(surah: surahNumber, ayah: startVerse);

  /// Pause playback
  static Future<void> pause() => QuranAudioEngine.pause();

  /// Resume playback
  static Future<void> resume() => QuranAudioEngine.resume();

  /// Stop playback
  static Future<void> stop() => QuranAudioEngine.stop();

  /// Seek to position
  static Future<void> seek(Duration position) =>
      QuranAudioEngine.seek(position);

  /// Skip to next verse
  static Future<void> nextVerse() => QuranAudioEngine.nextAyah();

  /// Skip to previous verse
  static Future<void> previousVerse() => QuranAudioEngine.previousAyah();

  /// Set playback speed
  static Future<void> setSpeed(double speed) =>
      QuranAudioEngine.setSpeed(speed);

  /// Set repeat mode (just_audio LoopMode → engine RepeatMode)
  static Future<void> setLoopMode(LoopMode mode) async {
    switch (mode) {
      case LoopMode.off:
        QuranAudioEngine.repeatMode = RepeatMode.none;
      case LoopMode.all:
        QuranAudioEngine.repeatMode = RepeatMode.surah;
      case LoopMode.one:
        QuranAudioEngine.repeatMode = RepeatMode.ayah;
    }
  }
}

/// Reciter model
class Reciter {

  Reciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    this.photoUrl,
  });
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String? photoUrl;
}
