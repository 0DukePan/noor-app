import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

class QuranAudioService {
  static final _player = AudioPlayer();
  
  // Singleton pattern mainly for simple access, but ideally use Provider
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  QuranAudioService._internal();

  Stream<int?> get currentVerseIndexStream => _player.currentIndexStream;
  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;

  Future<void> playSurah(int surahNumber, List<int> verses, {String reciter = 'Abdul_Basit_Mujawwad_128kbps'}) async {
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: verses.map((verseNum) {
        final surahPad = surahNumber.toString().padLeft(3, '0');
        final versePad = verseNum.toString().padLeft(3, '0');
        final url = 'https://everyayah.com/data/$reciter/$surahPad$versePad.mp3';
        
        return AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: '${surahNumber}_$verseNum',
            title: 'Ayah $verseNum',
            album: 'Surah $surahNumber',
          ),
        );
      }).toList(),
    );

    await _player.setAudioSource(playlist);
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() => _player.stop();
  Future<void> seekToVerse(int index) => _player.seek(Duration.zero, index: index);
  
  void dispose() => _player.dispose();
}
