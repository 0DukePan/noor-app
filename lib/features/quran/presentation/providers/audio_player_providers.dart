import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/quran_audio_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AUDIO PLAYER STATE
// ═══════════════════════════════════════════════════════════════════════════

class AudioPlayerState {
  final bool isExpanded;
  final Reciter selectedReciter;
  final double playbackSpeed;

  const AudioPlayerState({
    this.isExpanded = false,
    required this.selectedReciter,
    this.playbackSpeed = 1.0,
  });

  AudioPlayerState copyWith({
    bool? isExpanded,
    Reciter? selectedReciter,
    double? playbackSpeed,
  }) {
    return AudioPlayerState(
      isExpanded: isExpanded ?? this.isExpanded,
      selectedReciter: selectedReciter ?? this.selectedReciter,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  AudioPlayerNotifier()
      : super(AudioPlayerState(
          selectedReciter: QuranAudioService.reciters.first,
        ));

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void setReciter(Reciter reciter) {
    state = state.copyWith(selectedReciter: reciter);
    QuranAudioService.setReciter(reciter.id);
  }

  void setSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed);
    QuranAudioService.setSpeed(speed);
  }

  Future<void> play({required int surahNumber, int startVerse = 1}) async {
    await QuranAudioService.playSurah(
      surahNumber: surahNumber,
      startVerse: startVerse,
    );
  }

  Future<void> pause() async {
    await QuranAudioService.pause();
  }
}

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier();
});

// ═══════════════════════════════════════════════════════════════════════════
// STREAM PROVIDERS (replace StreamBuilder)
// ═══════════════════════════════════════════════════════════════════════════

/// Whether audio is currently playing
final audioPlayingProvider = StreamProvider<bool>((ref) {
  return QuranAudioService.playingStream;
});

/// Current playback position
final audioPositionProvider = StreamProvider<Duration>((ref) {
  return QuranAudioService.positionStream;
});

/// Total duration of current track
final audioDurationProvider = StreamProvider<Duration?>((ref) {
  return QuranAudioService.durationStream;
});
