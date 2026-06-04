import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/services/services.dart';
import '../../../../core/domain/policies/khushu_policy.dart';
import '../providers/quran_providers.dart';
import '../../../../core/domain/entities/surah.dart';

/// صفحة السورة الديناميكية - Dynamic Surah Reading Page
class SurahPage extends ConsumerStatefulWidget {
  final int surahNumber;

  const SurahPage({super.key, required this.surahNumber});

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _khushuController;
  late Animation<double> _fadeAnimation;
  final KhushuModePolicy _khushuPolicy = const KhushuModePolicy();

  @override
  void initState() {
    super.initState();
    _khushuController = AnimationController(
      vsync: this,
      duration: _khushuPolicy.getBreathingDelayDuration(),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _khushuController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _khushuController.dispose();
    super.dispose();
  }

  Future<void> _toggleKhushuMode() async {
    final settings = ref.read(readingSettingsProvider);
    final isKhushu = settings.isKhushuMode;

    if (!isKhushu) {
      await HapticFeedback.lightImpact();
      _khushuController.forward();
    } else {
      _khushuController.reverse();
    }
    ref.read(readingSettingsProvider.notifier).toggleKhushuMode();
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahProvider(widget.surahNumber));
    final settings = ref.watch(readingSettingsProvider);
    final selectedVerseIndex = ref.watch(surahSelectedVerseProvider(widget.surahNumber));
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine background color based on mode
    final backgroundColor = settings.isKhushuMode 
        ? (isDark ? Colors.black : const Color(0xFFFDFCF9))
        : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: null,
      body: GestureDetector(
        onTap: settings.isKhushuMode ? _toggleKhushuMode : null,
        child: Stack(
          children: [
            // Texture Pattern
            if (!isDark && !settings.isKhushuMode)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.03,
                  child: Image.asset(
                    'assets/images/pattern.png',
                    repeat: ImageRepeat.repeat,
                    errorBuilder: (_,__,___) => const SizedBox(),
                  ),
                ),
              ),

            // Main Content
            if (surahAsync.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (surahAsync.hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('حدث خطأ في تحميل السورة', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.refresh(surahProvider(widget.surahNumber)),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            else if (surahAsync.value != null)
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  if (!settings.isKhushuMode)
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.9),
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      centerTitle: true,
                      title: Text(
                        surahAsync.value?.nameArabic ?? 'سورة ${widget.surahNumber}',
                        style: GoogleFonts.amiri(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      leading: BackButton(color: theme.colorScheme.onSurface),
                      actions: [
                        IconButton(
                          icon: Icon(Icons.self_improvement_rounded, color: theme.colorScheme.primary),
                          tooltip: 'وضع الخشوع',
                          onPressed: _toggleKhushuMode,
                        ),
                        IconButton(
                          icon: Icon(Icons.graphic_eq_rounded, color: theme.colorScheme.onSurfaceVariant),
                          tooltip: 'استماع',
                          onPressed: () => _showAudioPlayer(context),
                        ),
                        PopupMenuButton(
                          icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'tafsir',
                              child: Row(children: [Icon(Icons.menu_book_rounded, size: 20), SizedBox(width: 12), Text('التفسير')]),
                            ),
                            const PopupMenuItem(
                              value: 'settings',
                              child: Row(children: [Icon(Icons.text_fields_rounded, size: 20), SizedBox(width: 12), Text('مظهر القراءة')]),
                            ),
                          ],
                        ),
                      ],
                    ),

                  if (!settings.isKhushuMode)
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  if (widget.surahNumber != 9)
                  SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: settings.isKhushuMode ? 0.0 : 1.0,
                      child: _BismillahHeader(surahNumber: widget.surahNumber),
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: settings.isKhushuMode ? 24 : 16,
                      vertical: 20,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final verse = surahAsync.value!.verses[index];
                          return RepaintBoundary(
                            child: _DynamicVerseCard(
                              verse: verse,
                              isKhushuMode: settings.isKhushuMode,
                              isSelected: selectedVerseIndex == index,
                              onTap: () {
                                if (!settings.isKhushuMode) {
                                  HapticFeedback.selectionClick();
                                  ref.read(surahSelectedVerseProvider(widget.surahNumber).notifier).state = index;
                                }
                              },
                              onLongPress: () => _showVerseOptions(context, verse),
                            ),
                          );
                        },
                        childCount: surahAsync.value!.verses.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 150),
                  ),
                ],
              ),

            // Tafsir Panel
            if (selectedVerseIndex != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _DynamicTafsirPanel(
                  surahNumber: widget.surahNumber,
                  verseNumber: selectedVerseIndex + 1,
                  onClose: () => ref.read(surahSelectedVerseProvider(widget.surahNumber).notifier).state = null,
                ),
              ),

            // Audio Mini Player
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: _MiniAudioPlayer(
                surahNumber: widget.surahNumber,
                isKhushuMode: settings.isKhushuMode,
              ),
            ),

            // Khushu Overlay
            if (settings.isKhushuMode)
              IgnorePointer(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          backgroundColor.withOpacity(0.0),
                          backgroundColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAudioPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AudioPlayerSheet(surahNumber: widget.surahNumber),
    );
  }

  void _showVerseOptions(BuildContext context, Verse verse) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(NoorTheme.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NoorTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _OptionTile(
              icon: Icons.menu_book_rounded,
              title: 'تفسير الآية',
              onTap: () {
                Navigator.pop(context);
                ref.read(surahSelectedVerseProvider(widget.surahNumber).notifier).state = verse.numberInSurah - 1;
              },
            ),
            _OptionTile(
              icon: Icons.bookmark_outline_rounded,
              title: 'إضافة علامة',
              onTap: () {
                Navigator.pop(context);
                ref.read(quranRepositoryProvider).saveReadingProgress(
                  surahNumber: widget.surahNumber,
                  verseNumber: verse.numberInSurah,
                  page: verse.page,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ العلامة')),
                );
              },
            ),
            _OptionTile(
              icon: Icons.share_rounded,
              title: 'مشاركة',
              onTap: () {
                Navigator.pop(context);
                final shareText = '${verse.textUthmani}\n\n— القرآن الكريم (سورة ${widget.surahNumber}، آية ${verse.numberInSurah})';
                Clipboard.setData(ClipboardData(text: shareText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ الآية للمشاركة')),
                );
              },
            ),
            _OptionTile(
              icon: Icons.play_arrow_rounded,
              title: 'تشغيل الصوت',
              onTap: () {
                Navigator.pop(context);
                QuranAudioService.playSurah(surahNumber: widget.surahNumber);
              },
            ),
            _OptionTile(
              icon: Icons.copy_rounded,
              title: 'نسخ الآية',
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: verse.textUthmani));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ الآية')),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _BismillahHeader extends StatelessWidget {
  final int surahNumber;

  const _BismillahHeader({required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.horizontal_rule_rounded, 
            color: theme.colorScheme.primary.withOpacity(0.3),
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: GoogleFonts.amiri(
              fontSize: 26,
              color: theme.colorScheme.onSurface,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

class _DynamicVerseCard extends StatelessWidget {
  final Verse verse;
  final bool isKhushuMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DynamicVerseCard({
    required this.verse,
    required this.isKhushuMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: isKhushuMode ? 40 : 16),
        padding: EdgeInsets.all(isKhushuMode ? 24 : 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
              : null,
        ),
        child: Column(
          children: [
            Text(
              verse.textUthmani,
              style: GoogleFonts.amiri(
                fontSize: isKhushuMode ? 32 : 26,
                height: 2.2, // Generous line height for Arabic
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface,
                fontWeight: isKhushuMode ? FontWeight.normal : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: isKhushuMode ? null : BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '﴿${verse.numberInSurah}﴾',
                style: GoogleFonts.cairo(
                  fontSize: isKhushuMode ? 18 : 14,
                  color: isKhushuMode ? const Color(0xFFF3C623) : theme.colorScheme.primary, // Local gold accent
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicTafsirPanel extends ConsumerWidget {
  final int surahNumber;
  final int verseNumber;
  final VoidCallback onClose;

  const _DynamicTafsirPanel({
    required this.surahNumber,
    required this.verseNumber,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tafsirAsync = ref.watch(tafsirProvider((surahId: surahNumber, verseId: verseNumber)));
    final selectedBookId = ref.watch(selectedTafsirBookProvider);
    final availableBooks = ref.watch(availableTafsirBooksProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Selector
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBookId,
                          isDense: true,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                          items: availableBooks.map((book) {
                            return DropdownMenuItem(
                              value: book.id,
                              child: Text(book.nameArabic),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              ref.read(selectedTafsirBookProvider.notifier).state = id;
                            }
                          },
                        ),
                      ),
                      Text(
                        'الآية $verseNumber',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tafsirAsync.isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  else if (tafsirAsync.hasError)
                     const Center(child: Text('غير متوفر'))
                  else if (tafsirAsync.value != null)
                     Text(
                      tafsirAsync.value!.text,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        height: 1.8,
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                      ),
                      textDirection: TextDirection.rtl,
                    )
                  else 
                    const Center(child: Text('لا يوجد تفسير لهذا الكتاب')),
                    
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioPlayerSheet extends StatefulWidget {
  final int surahNumber;

  const _AudioPlayerSheet({required this.surahNumber});

  @override
  State<_AudioPlayerSheet> createState() => _AudioPlayerSheetState();
}

class _AudioPlayerSheetState extends State<_AudioPlayerSheet> {
  // QuranAudioService is static
  String _selectedReciter = 'Abdul_Basit_Mujawwad_128kbps';
  
  // Mapping for UI display
  final Map<String, String> _reciters = {
    'Abdul_Basit_Mujawwad_128kbps': 'عبد الباسط عبد الصمد (مجود)',
    'Alafasy_128kbps': 'مشاري العفاسي',
    'MaherAlMuaiqly_128kbps': 'ماهر المعيقلي',
    'Husary_128kbps': 'محمود خليل الحصري',
  };
  
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
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
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
                          items: _reciters.entries.map((e) => 
                            DropdownMenuItem(value: e.key, child: Text(e.value))
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

                    const SizedBox(height: 32),
                    
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.stop_rounded),
                          iconSize: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                          onPressed: () => QuranAudioService.stop(),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary, 
                                theme.colorScheme.primary.withAlpha(200)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
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
            }
          );
      }
    );
  }

  void _playSurah() {
    QuranAudioService.setReciter(_selectedReciter);
    QuranAudioService.playSurah(surahNumber: widget.surahNumber);
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

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

class _MiniAudioPlayer extends ConsumerWidget {
  final int surahNumber;
  final bool isKhushuMode;

  const _MiniAudioPlayer({
    required this.surahNumber,
    required this.isKhushuMode,
  });

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
              color: NoorDesignSystem.primaryGreen.withOpacity(0.1),
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
                    color: NoorDesignSystem.primaryGreen.withOpacity(0.1),
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
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                onPressed: () => QuranAudioService.stop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

