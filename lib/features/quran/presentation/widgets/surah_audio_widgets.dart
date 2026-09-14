import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/services.dart';
import '../../../../core/theme/design_system.dart';
import '../providers/quran_providers.dart';

/// Audio widgets for the surah reader - surah_audio_widgets.dart
/// Extracted from surah_page.dart (Phase 1 god-file split).

class AudioPlayerSheet extends StatefulWidget {

  const AudioPlayerSheet({required this.surahNumber, super.key});
  final int surahNumber;

  @override
  State<AudioPlayerSheet> createState() => AudioPlayerSheetState();
}

class AudioPlayerSheetState extends State<AudioPlayerSheet> {
  // Shared with the full player (single engine catalog)
  String _selectedReciter = 'ar.alafasy';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
          final surahAsync = ref.watch(surahProvider(widget.surahNumber));
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return StreamBuilder<bool>(
            stream: QuranAudioService.playingStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Reciter Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                          child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReciter,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                          dropdownColor: theme.colorScheme.surface,
                          items: QuranAudioService.reciters.map((r) =>
                            DropdownMenuItem(value: r.id, child: Text(r.nameArabic)),
                          ).toList(),
                          onChanged: (value) {
                             if (value != null) {
                               setState(() => _selectedReciter = value);
                               // Restart play if playing
                               if (isPlaying && surahAsync.hasValue) {
                                 _playSurah();
                               }
                             }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Open the full player
                    TextButton.icon(
                      onPressed: () => context.push(
                        '/audio-player?surah=${widget.surahNumber}&ayah=1',
                      ),
                      icon: const Icon(Icons.open_in_full_rounded, size: 18),
                      label: Text(
                        'فتح المشغل الكامل',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.stop_rounded),
                          iconSize: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                          onPressed: QuranAudioService.stop,
                        ),
                        const SizedBox(width: 24),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withAlpha(200),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            iconSize: 40,
                            color: Colors.white,
                            onPressed: () {
                              if (surahAsync.isLoading) return;

                              if (isPlaying) {
                                QuranAudioService.pause();
                              } else {
                                if (surahAsync.value != null) {
                                  _playSurah();
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
      },
    );
  }

  void _playSurah() {
    QuranAudioService.setReciter(_selectedReciter);
    QuranAudioService.playSurah(surahNumber: widget.surahNumber);
  }
}

class OptionTile extends StatelessWidget {

  const OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }
}

class MiniAudioPlayer extends ConsumerWidget {

  const MiniAudioPlayer({
    required this.surahNumber,
    required this.isKhushuMode,
    super.key,
  });
  final int surahNumber;
  final bool isKhushuMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<bool>(
      stream: QuranAudioService.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        if (!isPlaying && isKhushuMode) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: isKhushuMode ? -100 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2C33) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: NoorDesignSystem.primaryGreen.withValues(alpha: 0.1),
            ),
            boxShadow: NoorDesignSystem.shadowSmall,
          ),
          child: Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: () {
                  if (isPlaying) {
                    QuranAudioService.pause();
                  } else {
                    QuranAudioService.playSurah(surahNumber: surahNumber);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: NoorDesignSystem.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: NoorDesignSystem.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'سورة $surahNumber',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'تلاوة عذبة',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                onPressed: QuranAudioService.stop,
              ),
            ],
          ),
        );
      },
    );
  }
}
