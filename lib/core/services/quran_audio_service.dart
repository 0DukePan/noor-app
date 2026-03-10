import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

import 'api_fetcher_service.dart';
import 'hive_service.dart';

/// خدمة صوت القرآن - Quran Audio Service
/// Supports multiple reciters, verse-by-verse playback, and background audio
class QuranAudioService {
  static final AudioPlayer _player = AudioPlayer();
  static final ApiFetcherService _api = ApiFetcherService();

  // Current playback state
  static int _currentSurah = 1;
  static int _currentVerse = 1;
  static String _currentReciter = 'ar.alafasy';
  static bool _isPlaying = false;

  // Available reciters
  static final List<Reciter> reciters = [
    Reciter(id: 'ar.alafasy', nameArabic: 'مشاري العفاسي', nameEnglish: 'Mishary Alafasy'),
    Reciter(id: 'ar.abdurrahmaansudais', nameArabic: 'عبد الرحمن السديس', nameEnglish: 'Abdurrahman Sudais'),
    Reciter(id: 'ar.abdulbasitmurattal', nameArabic: 'عبد الباسط (مرتل)', nameEnglish: 'Abdul Basit (Murattal)'),
    Reciter(id: 'ar.husary', nameArabic: 'محمود خليل الحصري', nameEnglish: 'Mahmoud Khalil Al-Husary'),
    Reciter(id: 'ar.minshawi', nameArabic: 'محمد صديق المنشاوي', nameEnglish: 'Mohamed Siddiq Al-Minshawi'),
    Reciter(id: 'ar.maaborali', nameArabic: 'ماهر المعيقلي', nameEnglish: 'Maher Al-Muaiqly'),
    Reciter(id: 'ar.saaborali', nameArabic: 'سعود الشريم', nameEnglish: 'Saud Al-Shuraim'),
    Reciter(id: 'ar.ibrahimakhbar', nameArabic: 'إبراهيم الأخضر', nameEnglish: 'Ibrahim Al-Akhdar'),
    Reciter(id: 'ar.aaborali', nameArabic: 'علي الحذيفي', nameEnglish: 'Ali Al-Hudhaifi'),
  ];

  // Streams
  static Stream<Duration?> get durationStream => _player.durationStream;
  static Stream<Duration> get positionStream => _player.positionStream;
  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  static Stream<bool> get playingStream => _player.playingStream;

  // Getters
  static bool get isPlaying => _isPlaying;
  static int get currentSurah => _currentSurah;
  static int get currentVerse => _currentVerse;
  static String get currentReciter => _currentReciter;
  static Duration? get duration => _player.duration;
  static Duration get position => _player.position;

  /// Initialize audio service
  static Future<void> init() async {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _onVerseComplete();
      }
    });
  }

  /// Set reciter
  static void setReciter(String reciterId) {
    _currentReciter = reciterId;
  }

  /// Play specific verse
  static Future<void> playVerse({
    required int surahNumber,
    required int verseNumber,
  }) async {
    _currentSurah = surahNumber;
    _currentVerse = verseNumber;

    try {
      final audioUrl = await _api.fetchRecitationUrl(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        reciter: _currentReciter,
      );

      if (audioUrl != null) {
        await _player.setUrl(audioUrl);
        await _player.play();
      }
    } catch (e) {
      debugPrint('Error playing verse: $e');
    }
  }

  /// Play entire surah from specific verse
  static Future<void> playSurah({
    required int surahNumber,
    int startVerse = 1,
  }) async {
    _currentSurah = surahNumber;
    _currentVerse = startVerse;

    // Create playlist of all verses
    final playlist = ConcatenatingAudioSource(
      children: await _buildSurahPlaylist(surahNumber, startVerse),
    );

    await _player.setAudioSource(playlist);
    await _player.play();
  }

  static Future<List<AudioSource>> _buildSurahPlaylist(int surah, int startVerse) async {
    final sources = <AudioSource>[];
    
    // Get surah verse count (simplified - should be from actual data)
    final verseCounts = [7, 286, 200, 176, 120, 165, 206, 75, 129, 109];
    final totalVerses = surah <= verseCounts.length ? verseCounts[surah - 1] : 10;

    for (var verse = startVerse; verse <= totalVerses; verse++) {
      final url = 'https://cdn.islamic.network/quran/audio/128/$_currentReciter/$surah$verse.mp3';
      sources.add(AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: '$surah:$verse',
          title: 'آية $verse',
          album: 'سورة $surah',
          artist: _getReciterName(_currentReciter),
        ),
      ));
    }

    return sources;
  }

  static String _getReciterName(String reciterId) {
    return reciters.firstWhere(
      (r) => r.id == reciterId,
      orElse: () => reciters.first,
    ).nameArabic;
  }

  /// Called when a verse finishes playing
  static void _onVerseComplete() {
    // Auto-advance handled by ConcatenatingAudioSource
  }

  /// Pause playback
  static Future<void> pause() async {
    await _player.pause();
  }

  /// Resume playback
  static Future<void> resume() async {
    await _player.play();
  }

  /// Stop playback
  static Future<void> stop() async {
    await _player.stop();
  }

  /// Seek to position
  static Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Skip to next verse
  static Future<void> nextVerse() async {
    await _player.seekToNext();
  }

  /// Skip to previous verse
  static Future<void> previousVerse() async {
    await _player.seekToPrevious();
  }

  /// Set playback speed
  static Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Set repeat mode (none, one, all)
  static Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  /// Dispose
  static Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Reciter model
class Reciter {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String? photoUrl;

  Reciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    this.photoUrl,
  });
}

/// Audio playback state for UI
class AudioPlaybackState {
  final bool isPlaying;
  final int currentSurah;
  final int currentVerse;
  final String reciterId;
  final Duration position;
  final Duration? duration;
  final double speed;

  const AudioPlaybackState({
    this.isPlaying = false,
    this.currentSurah = 1,
    this.currentVerse = 1,
    this.reciterId = 'ar.alafasy',
    this.position = Duration.zero,
    this.duration,
    this.speed = 1.0,
  });

  double get progress {
    if (duration == null || duration!.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration!.inMilliseconds;
  }
}
