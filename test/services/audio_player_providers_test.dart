import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_app/features/quran/presentation/providers/audio_player_providers.dart';

/// Tests for the audio-player UI state.
///
/// Only the pure state logic is exercised here: everything that touches the
/// just_audio engine (play/pause/setReciter/setSpeed, the three stream
/// providers) needs a real platform channel and stays plugin-bound.
/// Constructing the notifier reads the engine's static reciter catalog, which
/// is a compile-time const map and safe without a device.
void main() {
  test('initial state selects the first reciter, collapsed, 1x speed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(audioPlayerProvider);
    expect(state.isExpanded, isFalse);
    expect(state.playbackSpeed, 1.0);
    expect(state.selectedReciter.id, isNotEmpty);
  });

  test('toggleExpanded flips the expanded flag', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(audioPlayerProvider.notifier).toggleExpanded();
    expect(container.read(audioPlayerProvider).isExpanded, isTrue);
    container.read(audioPlayerProvider.notifier).toggleExpanded();
    expect(container.read(audioPlayerProvider).isExpanded, isFalse);
  });

  test('copyWith preserves untouched fields', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(audioPlayerProvider);
    final changed = initial.copyWith(isExpanded: true, playbackSpeed: 1.5);
    expect(changed.isExpanded, isTrue);
    expect(changed.playbackSpeed, 1.5);
    expect(changed.selectedReciter, initial.selectedReciter);
  });
}
