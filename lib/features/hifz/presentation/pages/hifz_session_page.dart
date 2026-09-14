import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/algorithms/fsrs_algorithm.dart';
import '../../../../core/services/quran_audio_engine.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/hifz_ayah_card.dart';
import '../providers/hifz_providers.dart';

/// جلسة حفظ: استماع متكرر للآية ثم تقييم FSRS.
///
/// لكل آية: تُشغَّل [HifzAyahCard.repeatCount] مرات، ثم تُعرض أزرار التقييم
/// (لم أتذكر/صعب/جيد/سهل) لتحديث الجدولة.
class HifzSessionPage extends ConsumerStatefulWidget {

  const HifzSessionPage({required this.cards, super.key});
  final List<HifzAyahCard> cards;

  @override
  ConsumerState<HifzSessionPage> createState() => _HifzSessionPageState();
}

class _HifzSessionPageState extends ConsumerState<HifzSessionPage> {
  late final List<HifzAyahCard> _queue;
  int _index = 0;
  int _repeatsLeft = 0;
  bool _playing = false;
  StreamSubscription<PlayState>? _playStateSub;

  HifzAyahCard get _current => _queue[_index];

  @override
  void initState() {
    super.initState();
    _queue = List.of(widget.cards);
    _playStateSub = QuranAudioEngine.playStateStream.listen(_onPlayState);
    if (_queue.isNotEmpty) {
      _startRepeat();
    }
  }

  @override
  void dispose() {
    _playStateSub?.cancel();
    unawaited(QuranAudioEngine.stop());
    super.dispose();
  }

  void _onPlayState(PlayState state) {
    if (!state.isCompleted || !mounted) return;
    if (_repeatsLeft > 1) {
      _repeatsLeft--;
      unawaited(_play());
    } else {
      setState(() => _playing = false);
    }
  }

  Future<void> _startRepeat() async {
    _repeatsLeft = _current.repeatCount;
    await _play();
  }

  Future<void> _play() async {
    setState(() => _playing = true);
    await QuranAudioEngine.playAyah(
      surah: _current.surah,
      ayah: _current.ayah,
    );
  }

  Future<void> _rate(Rating rating) async {
    final reviewed = _current;
    await ref.read(hifzProvider.notifier).reviewAyah(reviewed.id, rating);
    if (!mounted) return;

    if (rating == Rating.again && _index + 1 < _queue.length) {
      // Move the failed card to the end of the queue for another pass.
      final failed = _queue.removeAt(_index);
      _queue.add(failed);
      setState(() {});
      await _startRepeat();
      return;
    }

    if (_index + 1 < _queue.length) {
      setState(() => _index++);
      await _startRepeat();
      return;
    }

    _showSessionComplete();
  }

  void _showSessionComplete() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.hsessionDoneTitle, style: GoogleFonts.cairo()),
        content: Text(
          l10n.hsessionDoneBody,
          style: GoogleFonts.cairo(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.hsessionFinish, style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final card = _current;
    final intervals = card.previewIntervals();

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: Text(
          l10n.hsessionCounter(_index + 1, _queue.length),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Ayah reference + listen counter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.hsessionCardRef(card.surah, card.ayah),
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Ayah text
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    card.arabicText,
                    style: GoogleFonts.amiri(
                      fontSize: 30,
                      height: 2.2,
                      color: theme.colorScheme.onSurface,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Repeat controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  iconSize: 32,
                  onPressed: () async {
                    if (_playing) {
                      await QuranAudioEngine.pause();
                      setState(() => _playing = false);
                    } else {
                      await _play();
                    }
                  },
                ),
                const SizedBox(width: 16),
                IconButton.outlined(
                  icon: const Icon(Icons.replay_rounded),
                  onPressed: _startRepeat,
                ),
                const SizedBox(width: 16),
                Text(
                  l10n.hsessionRepeatCount(card.repeatCount),
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // FSRS rating buttons
            Text(
              l10n.hsessionRatePrompt,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: Rating.values.map((rating) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _RatingButton(
                      rating: rating,
                      intervalDays: intervals[rating] ?? 1,
                      onTap: () => _rate(rating),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {

  const _RatingButton({
    required this.rating,
    required this.intervalDays,
    required this.onTap,
  });
  final Rating rating;
  final int intervalDays;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              rating.emoji,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              rating.arabicName,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              l10n.hsessionIntervalDays(intervalDays),
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
