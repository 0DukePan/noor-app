import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../../../core/services/quran_audio_service.dart';

/// مشغل صوت القرآن - Quran Audio Player Widget
class QuranAudioPlayerWidget extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? currentVerse;
  final Function(int verse)? onVerseChanged;

  const QuranAudioPlayerWidget({
    super.key,
    required this.surahNumber,
    required this.surahName,
    this.currentVerse,
    this.onVerseChanged,
  });

  @override
  State<QuranAudioPlayerWidget> createState() => _QuranAudioPlayerWidgetState();
}

class _QuranAudioPlayerWidgetState extends State<QuranAudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isExpanded = false;
  Reciter _selectedReciter = QuranAudioService.reciters.first;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    QuranAudioService.init();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  Future<void> _play() async {
    HapticFeedback.lightImpact();
    await QuranAudioService.playSurah(
      surahNumber: widget.surahNumber,
      startVerse: widget.currentVerse ?? 1,
    );
    setState(() {});
  }

  Future<void> _pause() async {
    HapticFeedback.lightImpact();
    await QuranAudioService.pause();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: NoorTheme.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Player
          _buildMainPlayer(),

          // Expanded Controls
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _isExpanded ? _buildExpandedControls() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPlayer() {
    return StreamBuilder<bool>(
      stream: QuranAudioService.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;

        return Padding(
          padding: const EdgeInsets.all(NoorTheme.spacingMd),
          child: Column(
            children: [
              // Title and expand button
              Row(
                children: [
                  IconButton(
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.menu_close,
                      progress: _animController,
                    ),
                    onPressed: _toggleExpand,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.surahName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _selectedReciter.nameArabic,
                          style: TextStyle(
                            fontSize: 12,
                            color: NoorTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: NoorTheme.spacingSm),

              // Progress Slider
              StreamBuilder<Duration>(
                stream: QuranAudioService.positionStream,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;

                  return StreamBuilder<Duration?>(
                    stream: QuranAudioService.durationStream,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;
                      final progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0;

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: NoorTheme.primary,
                              inactiveTrackColor: NoorTheme.primary.withOpacity(0.2),
                              thumbColor: NoorTheme.primary,
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: (value) {
                                if (duration.inMilliseconds > 0) {
                                  QuranAudioService.seek(
                                    Duration(
                                      milliseconds:
                                          (value * duration.inMilliseconds).toInt(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: NoorTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: NoorTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: NoorTheme.spacingSm),

              // Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: 32,
                    onPressed: QuranAudioService.previousVerse,
                  ),

                  // Rewind 10s
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded),
                    onPressed: () {
                      final newPos = QuranAudioService.position -
                          const Duration(seconds: 10);
                      QuranAudioService.seek(
                        newPos.isNegative ? Duration.zero : newPos,
                      );
                    },
                  ),

                  // Play/Pause
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [NoorTheme.primary, NoorTheme.primaryDark],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: NoorTheme.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      iconSize: 32,
                      color: Colors.white,
                      onPressed: isPlaying ? _pause : _play,
                    ),
                  ),

                  // Forward 10s
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded),
                    onPressed: () {
                      final newPos = QuranAudioService.position +
                          const Duration(seconds: 10);
                      QuranAudioService.seek(newPos);
                    },
                  ),

                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 32,
                    onPressed: QuranAudioService.nextVerse,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandedControls() {
    return Container(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: NoorTheme.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(NoorTheme.radiusLg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Reciter Selection
          Text(
            'القارئ',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: QuranAudioService.reciters.length,
              itemBuilder: (context, index) {
                final reciter = QuranAudioService.reciters[index];
                final isSelected = reciter.id == _selectedReciter.id;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedReciter = reciter);
                    QuranAudioService.setReciter(reciter.id);
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? NoorTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: NoorTheme.primary.withOpacity(0.3),
                            ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: isSelected ? Colors.white : NoorTheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reciter.nameArabic.split(' ').last,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white : null,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: NoorTheme.spacingMd),

          // Playback Speed
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [0.75, 1.0, 1.25, 1.5].map((speed) {
                    final isSelected = _playbackSpeed == speed;
                    return ChoiceChip(
                      label: Text('${speed}x'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _playbackSpeed = speed);
                          QuranAudioService.setSpeed(speed);
                        }
                      },
                      selectedColor: NoorTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              Text(
                'السرعة',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: NoorTheme.spacingMd),

          // Loop Mode
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildLoopButton(LoopMode.off, 'بدون', Icons.repeat),
                    const SizedBox(width: 8),
                    _buildLoopButton(LoopMode.one, 'آية', Icons.repeat_one_rounded),
                    const SizedBox(width: 8),
                    _buildLoopButton(LoopMode.all, 'سورة', Icons.repeat_rounded),
                  ],
                ),
              ),
              Text(
                'التكرار',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoopButton(LoopMode mode, String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () => QuranAudioService.setLoopMode(mode),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Mini player for bottom bar
class QuranMiniPlayer extends StatelessWidget {
  final VoidCallback onTap;

  const QuranMiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: QuranAudioService.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;

        if (!isPlaying && QuranAudioService.currentSurah == 1) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: NoorTheme.spacingMd),
            padding: const EdgeInsets.all(NoorTheme.spacingSm),
            decoration: BoxDecoration(
              color: NoorTheme.primary,
              borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  onPressed: isPlaying
                      ? QuranAudioService.pause
                      : QuranAudioService.resume,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'سورة ${QuranAudioService.currentSurah}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'آية ${QuranAudioService.currentVerse}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}
