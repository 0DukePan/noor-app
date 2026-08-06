import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/tafsir_theme.dart';
import '../../../../core/domain/entities/surah.dart';
import '../../../../core/models/tafsir_models.dart';
import '../../../../core/services/tafsir_data_source.dart';
import '../providers/quran_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MUSHAF THEMES
// ═══════════════════════════════════════════════════════════════════════════

enum MushafTheme {
  madaniCream,   // Classic printed Quran look
  snowWhite,     // Clean modern look
  midnightBlack, // True OLED dark mode
  deepSepia,     // Warm night reading
}

class MushafThemeData {
  final Color backgroundColor;
  final Color textColor;
  final Color verseMarkerColor;
  final Color headerColor;
  final Color headerTextColor;
  final Color borderColor;
  final String label;

  const MushafThemeData({
    required this.backgroundColor,
    required this.textColor,
    required this.verseMarkerColor,
    required this.headerColor,
    required this.headerTextColor,
    required this.borderColor,
    required this.label,
  });

  static const Map<MushafTheme, MushafThemeData> themes = {
    MushafTheme.madaniCream: MushafThemeData(
      backgroundColor: Color(0xFFFDF6E3),
      textColor: Color(0xFF1A1A1A),
      verseMarkerColor: Color(0xFF8B7355),
      headerColor: Color(0xFF2E7D32),
      headerTextColor: Colors.white,
      borderColor: Color(0xFFD4B896),
      label: 'كلاسيكي',
    ),
    MushafTheme.snowWhite: MushafThemeData(
      backgroundColor: Color(0xFFFFFFFE),
      textColor: Color(0xFF212121),
      verseMarkerColor: Color(0xFF1B5E20),
      headerColor: Color(0xFF1B5E20),
      headerTextColor: Colors.white,
      borderColor: Color(0xFFE0E0E0),
      label: 'أبيض',
    ),
    MushafTheme.midnightBlack: MushafThemeData(
      backgroundColor: Color(0xFF0D0D0D),
      textColor: Color(0xFFE8E0D0),
      verseMarkerColor: Color(0xFFF3C623),
      headerColor: Color(0xFF1A1A1A),
      headerTextColor: Color(0xFFE8E0D0),
      borderColor: Color(0xFF2A2A2A),
      label: 'داكن',
    ),
    MushafTheme.deepSepia: MushafThemeData(
      backgroundColor: Color(0xFF2C2416),
      textColor: Color(0xFFD4C5A9),
      verseMarkerColor: Color(0xFFC9A96E),
      headerColor: Color(0xFF3D3222),
      headerTextColor: Color(0xFFD4C5A9),
      borderColor: Color(0xFF4A3D2A),
      label: 'ليلي',
    ),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final mushafThemeProvider = StateProvider<MushafTheme>((ref) => MushafTheme.madaniCream);

/// Whether top/bottom controls overlay is visible
final mushafShowControlsProvider = StateProvider<bool>((ref) => true);

// ═══════════════════════════════════════════════════════════════════════════
// MUSHAF PAGE VIEWER
// ═══════════════════════════════════════════════════════════════════════════

/// صفحة المصحف - Traditional Mushaf Page Viewer
class QuranMushafPage extends ConsumerStatefulWidget {
  final int initialPage;

  const QuranMushafPage({super.key, this.initialPage = 1});

  @override
  ConsumerState<QuranMushafPage> createState() => _QuranMushafPageState();
}

class _QuranMushafPageState extends ConsumerState<QuranMushafPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Pages are 1-indexed but PageView is 0-indexed
    _pageController = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    final current = ref.read(mushafShowControlsProvider);
    ref.read(mushafShowControlsProvider.notifier).state = !current;
    if (!current) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(mushafThemeProvider);
    final themeData = MushafThemeData.themes[currentTheme]!;
    final currentPage = ref.watch(mushafCurrentPageProvider);
    final showControls = ref.watch(mushafShowControlsProvider);

    return Scaffold(
      backgroundColor: themeData.backgroundColor,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main PageView (RTL - swipe right for next page like Arabic books)
            Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 604,
                onPageChanged: (index) {
                  final pageNum = index + 1;
                  ref.read(mushafCurrentPageProvider.notifier).state = pageNum;
                  // Save reading position
                  _saveReadingProgress(pageNum);
                },
                itemBuilder: (context, index) {
                  final pageNum = index + 1;
                  return _MushafPageWidget(
                    pageNumber: pageNum,
                    themeData: themeData,
                  );
                },
              ),
            ),

            // Top controls (App Bar)
            if (showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _MushafTopBar(
                  pageNumber: currentPage,
                  themeData: themeData,
                  onBack: () => Navigator.pop(context),
                  onTheme: () => _showThemeSelector(context, ref),
                ),
              ),

            // Bottom controls (Page indicator + quick jump)
            if (showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _MushafBottomBar(
                  currentPage: currentPage,
                  themeData: themeData,
                  onJump: (page) {
                    _pageController.jumpToPage(page - 1);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _saveReadingProgress(int page) async {
    try {
      final box = Hive.box('quranProgress');
      await box.put('lastPage', page);
    } catch (_) {}
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(mushafThemeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: MushafThemeData.themes[currentTheme]!.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: MushafThemeData.themes[currentTheme]!.borderColor,
          ),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MushafThemeData.themes[currentTheme]!.textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'مظهر القراءة',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MushafThemeData.themes[currentTheme]!.textColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MushafTheme.values.map((theme) {
                final data = MushafThemeData.themes[theme]!;
                final isSelected = theme == currentTheme;
                return GestureDetector(
                  onTap: () {
                    ref.read(mushafThemeProvider.notifier).state = theme;
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: data.backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? data.headerColor : data.borderColor,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: data.headerColor.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ] : null,
                        ),
                        child: isSelected
                            ? Icon(Icons.check_rounded, color: data.textColor, size: 24)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.label,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: MushafThemeData.themes[currentTheme]!.textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SINGLE MUSHAF PAGE (Continuous RichText)
// ═══════════════════════════════════════════════════════════════════════════

class _MushafPageWidget extends ConsumerWidget {
  final int pageNumber;
  final MushafThemeData themeData;

  const _MushafPageWidget({
    required this.pageNumber,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(quranPageProvider(pageNumber));

    return versesAsync.when(
      data: (verses) {
        if (verses.isEmpty) {
          return Center(
            child: Text('صفحة فارغة', style: TextStyle(color: themeData.textColor)),
          );
        }

        // Build text spans for continuous flow
        final surahStartsOnPage = _detectSurahStarts(verses);
        final juz = verses.first.juz;
        final firstSurahName = verses.first.surahName ?? '';

        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Page header
              _PageHeader(
                surahName: firstSurahName,
                juz: juz,
                pageNumber: pageNumber,
                themeData: themeData,
              ),
              const SizedBox(height: 12),

              // Continuous text body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildContinuousText(context, verses, surahStartsOnPage),
                  ),
                ),
              ),

              // Page number footer
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$pageNumber',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: themeData.verseMarkerColor.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: themeData.verseMarkerColor,
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => Center(
        child: Text('خطأ: $e', style: TextStyle(color: themeData.textColor)),
      ),
    );
  }

  /// Detect which verses start a new surah on this page
  Set<int> _detectSurahStarts(List<Verse> verses) {
    final starts = <int>{};
    int? lastSurah;
    for (var i = 0; i < verses.length; i++) {
      if (lastSurah != null && verses[i].surahNumber != lastSurah) {
        starts.add(i);
      }
      if (i == 0 && verses[i].numberInSurah == 1) {
        starts.add(0);
      }
      lastSurah = verses[i].surahNumber;
    }
    return starts;
  }

  Widget _buildContinuousText(BuildContext context, List<Verse> verses, Set<int> surahStarts) {
    final children = <Widget>[];

    int i = 0;
    while (i < verses.length) {
      // Check if a new surah starts here
      if (surahStarts.contains(i)) {
        final verse = verses[i];
        // Add Surah header (Bismillah card)
        children.add(_SurahStartBanner(
          surahName: verse.surahName ?? 'سورة ${verse.surahNumber}',
          surahNumber: verse.surahNumber,
          themeData: themeData,
        ));
      }

      // Collect all consecutive verses from the same surah segment
      final segmentStart = i;
      final currentSurah = verses[i].surahNumber;
      while (i < verses.length && verses[i].surahNumber == currentSurah &&
             !(i != segmentStart && surahStarts.contains(i))) {
        i++;
      }

      // Build RichText for this segment
      final segmentVerses = verses.sublist(segmentStart, i);
      children.add(_ContinuousVerseBlock(
        verses: segmentVerses,
        themeData: themeData,
        onVerseTap: (verse) => _showAyahActions(context, verse, themeData),
      ));
    }

    return Column(children: children);
  }

  /// Show Ayah Actions bottom sheet with Tafsir preview
  static void _showAyahActions(BuildContext context, Verse verse, MushafThemeData themeData) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AyahActionSheet(
        verse: verse,
        themeData: themeData,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _PageHeader extends StatelessWidget {
  final String surahName;
  final int juz;
  final int pageNumber;
  final MushafThemeData themeData;

  const _PageHeader({
    required this.surahName,
    required this.juz,
    required this.pageNumber,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: themeData.headerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'الجزء $juz',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: themeData.headerTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            surahName,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: themeData.headerTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahStartBanner extends StatelessWidget {
  final String surahName;
  final int surahNumber;
  final MushafThemeData themeData;

  const _SurahStartBanner({
    required this.surahName,
    required this.surahNumber,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: themeData.borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: themeData.headerColor.withOpacity(0.06),
      ),
      child: Column(
        children: [
          Text(
            surahName,
            style: GoogleFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeData.textColor,
            ),
          ),
          if (surahNumber != 1 && surahNumber != 9)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  color: themeData.textColor.withOpacity(0.8),
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContinuousVerseBlock extends StatefulWidget {
  final List<Verse> verses;
  final MushafThemeData themeData;
  final ValueChanged<Verse>? onVerseTap;

  const _ContinuousVerseBlock({
    required this.verses,
    required this.themeData,
    this.onVerseTap,
  });

  @override
  State<_ContinuousVerseBlock> createState() => _ContinuousVerseBlockState();
}

class _ContinuousVerseBlockState extends State<_ContinuousVerseBlock> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _buildRecognizers();
  }

  @override
  void didUpdateWidget(covariant _ContinuousVerseBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verses != widget.verses) {
      _disposeRecognizers();
      _buildRecognizers();
    }
  }

  void _buildRecognizers() {
    for (final verse in widget.verses) {
      final rec = TapGestureRecognizer()
        ..onTap = () => widget.onVerseTap?.call(verse);
      _recognizers.add(rec);
    }
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];

    for (var idx = 0; idx < widget.verses.length; idx++) {
      final verse = widget.verses[idx];
      // Verse text (tappable)
      spans.add(TextSpan(
        text: verse.textUthmani,
        style: GoogleFonts.amiri(
          fontSize: 24,
          height: 2.2,
          color: widget.themeData.textColor,
          fontWeight: FontWeight.w500,
        ),
        recognizer: _recognizers[idx],
      ));

      // Verse number marker ﴿١﴾ (also tappable)
      spans.add(TextSpan(
        text: ' \uFD3F${_toArabicNumeral(verse.numberInSurah)}\uFD3E ',
        style: GoogleFonts.amiri(
          fontSize: 16,
          color: widget.themeData.verseMarkerColor,
          fontWeight: FontWeight.bold,
        ),
        recognizer: _recognizers[idx],
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  String _toArabicNumeral(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════

class _MushafTopBar extends StatelessWidget {
  final int pageNumber;
  final MushafThemeData themeData;
  final VoidCallback onBack;
  final VoidCallback onTheme;

  const _MushafTopBar({
    required this.pageNumber,
    required this.themeData,
    required this.onBack,
    required this.onTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 4, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            themeData.backgroundColor,
            themeData.backgroundColor.withOpacity(0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: themeData.textColor),
            onPressed: onBack,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.palette_rounded, color: themeData.textColor),
            tooltip: 'المظهر',
            onPressed: onTheme,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM BAR
// ═══════════════════════════════════════════════════════════════════════════

class _MushafBottomBar extends StatelessWidget {
  final int currentPage;
  final MushafThemeData themeData;
  final ValueChanged<int> onJump;

  const _MushafBottomBar({
    required this.currentPage,
    required this.themeData,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            themeData.backgroundColor,
            themeData.backgroundColor.withOpacity(0.0),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page slider
          Directionality(
            textDirection: TextDirection.ltr,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: themeData.headerColor,
                inactiveTrackColor: themeData.borderColor,
                thumbColor: themeData.headerColor,
                overlayColor: themeData.headerColor.withOpacity(0.2),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: currentPage.toDouble(),
                min: 1,
                max: 604,
                onChanged: (v) => onJump(v.round()),
              ),
            ),
          ),
          Text(
            'صفحة $currentPage / 604',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: themeData.textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AYAH ACTION SHEET (Tap-to-Tafsir)
// ═══════════════════════════════════════════════════════════════════════════

class _AyahActionSheet extends StatefulWidget {
  final Verse verse;
  final MushafThemeData themeData;

  const _AyahActionSheet({
    required this.verse,
    required this.themeData,
  });

  @override
  State<_AyahActionSheet> createState() => _AyahActionSheetState();
}

class _AyahActionSheetState extends State<_AyahActionSheet> {
  TafsirEntry? _tafsirEntry;
  bool _loadingTafsir = true;
  bool _tafsirExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadTafsir();
  }

  Future<void> _loadTafsir() async {
    final entry = await TafsirDataSource.getAyahTafsir(
      surah: widget.verse.surahNumber,
      ayah: widget.verse.numberInSurah,
      source: TafsirSourceId.muyassar,
    );
    if (mounted) {
      setState(() {
        _tafsirEntry = entry;
        _loadingTafsir = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final td = widget.themeData;
    final verse = widget.verse;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: td.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: td.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: td.textColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Surah + Ayah label
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: td.headerColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${verse.surahName ?? 'سورة ${verse.surahNumber}'} ﴿${verse.numberInSurah}﴾',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: td.headerColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ayah text in large Uthmani script
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: td.headerColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: td.borderColor.withOpacity(0.5)),
              ),
              child: Text(
                verse.textUthmani,
                style: GoogleFonts.amiri(
                  fontSize: 26,
                  height: 2.0,
                  color: td.textColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 20),

            // Quick action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.copy_rounded,
                  label: 'نسخ',
                  color: td.headerColor,
                  bgColor: td.headerColor.withOpacity(0.1),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: verse.textUthmani));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('تم نسخ الآية'),
                        backgroundColor: td.headerColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
                _ActionButton(
                  icon: Icons.bookmark_add_rounded,
                  label: 'حفظ',
                  color: const Color(0xFFE8A838),
                  bgColor: const Color(0xFFE8A838).withOpacity(0.1),
                  onTap: () async {
                    await TafsirDataSource.addBookmark(
                      surah: verse.surahNumber,
                      ayah: verse.numberInSurah,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('تم حفظ العلامة 🔖'),
                          backgroundColor: const Color(0xFFE8A838),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                ),
                _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'مشاركة',
                  color: const Color(0xFF5C6BC0),
                  bgColor: const Color(0xFF5C6BC0).withOpacity(0.1),
                  onTap: () {
                    final shareText = '${verse.textUthmani}\n\n'
                        '— ${verse.surahName ?? 'سورة ${verse.surahNumber}'} ﴿${verse.numberInSurah}﴾';
                    Clipboard.setData(ClipboardData(text: shareText));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('تم النسخ للمشاركة'),
                        backgroundColor: const Color(0xFF5C6BC0),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Tafsir Preview ──
            Container(
              decoration: BoxDecoration(
                color: td.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: td.borderColor),
              ),
              child: Column(
                children: [
                  // Tafsir header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: td.headerColor.withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 18, color: td.headerColor),
                        const SizedBox(width: 8),
                        Text(
                          'التفسير الميسر',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: td.headerColor,
                          ),
                        ),
                        const Spacer(),
                        if (_tafsirEntry != null)
                          GestureDetector(
                            onTap: () => setState(() => _tafsirExpanded = !_tafsirExpanded),
                            child: Icon(
                              _tafsirExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: td.headerColor,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Tafsir body
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _loadingTafsir
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: td.verseMarkerColor,
                                ),
                              ),
                            ),
                          )
                        : _tafsirEntry == null
                            ? Text(
                                'التفسير غير متوفر حالياً',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: td.textColor.withOpacity(0.5),
                                ),
                                textAlign: TextAlign.center,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _tafsirExpanded
                                        ? _tafsirEntry!.text
                                        : _truncate(_tafsirEntry!.text, 200),
                                    style: GoogleFonts.cairo(
                                      fontSize: 15,
                                      height: 1.9,
                                      color: td.textColor.withOpacity(0.85),
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  if (!_tafsirExpanded && _tafsirEntry!.text.length > 200) ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => setState(() => _tafsirExpanded = true),
                                      child: Text(
                                        'اقرأ المزيد ←',
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          color: td.headerColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Open full Tafsir page button
            Material(
              color: td.headerColor,
              borderRadius: BorderRadius.circular(14),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to the dedicated TafsirPage for this surah+ayah
                  Navigator.of(context).push(
                    FadeThroughPageRoute(
                      page: _FullTafsirReaderPage(
                        surahNumber: verse.surahNumber,
                        ayahNumber: verse.numberInSurah,
                        surahName: verse.surahName ?? '',
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'فتح التفسير الكامل',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTION BUTTON (circular icon + label)
// ═══════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FULL TAFSIR READER PAGE (Phase 2-4: Reader + Comparative + Word Analysis)
// ═══════════════════════════════════════════════════════════════════════════

class _FullTafsirReaderPage extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;

  const _FullTafsirReaderPage({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
  });

  @override
  State<_FullTafsirReaderPage> createState() => _FullTafsirReaderPageState();
}

class _FullTafsirReaderPageState extends State<_FullTafsirReaderPage> {
  // ── State ──
  SurahTafsir? _surahTafsir;
  bool _isLoading = true;
  TafsirSourceId _currentSource = TafsirSourceId.muyassar;
  final ScrollController _scrollController = ScrollController();
  double _fontSize = 16.0;

  // ── Phase 3: Comparative Mode ──
  bool _comparativeMode = false;
  final Set<TafsirSourceId> _compareSources = {
    TafsirSourceId.muyassar,
    TafsirSourceId.saadi,
  };
  Map<TafsirSourceId, TafsirEntry>? _compareData;
  int _compareAyah = 1;

  @override
  void initState() {
    super.initState();
    _compareAyah = widget.ayahNumber;
    _loadTafsir();
  }

  Future<void> _loadTafsir() async {
    setState(() => _isLoading = true);
    final tafsir = await TafsirDataSource.getSurahTafsir(
      surah: widget.surahNumber,
      source: _currentSource,
    );
    if (!mounted) return;
    setState(() {
      _surahTafsir = tafsir;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAyah(widget.ayahNumber);
    });
  }

  Future<void> _loadCompareData() async {
    final data = await TafsirDataSource.getCompareTafsir(
      surah: widget.surahNumber,
      ayah: _compareAyah,
      sources: _compareSources.toList(),
    );
    if (!mounted) return;
    setState(() => _compareData = data);
  }

  void _scrollToAyah(int ayahNumber) {
    final offset = (ayahNumber - 1) * 220.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تفسير ${widget.surahName.isNotEmpty ? widget.surahName : 'سورة ${widget.surahNumber}'}',
        ),
        elevation: 0,
        actions: [
          // Font size
          IconButton(
            icon: const Icon(Icons.text_fields_rounded),
            tooltip: 'حجم الخط',
            onPressed: () => _showFontSizeSheet(context),
          ),
          // Comparative mode toggle
          IconButton(
            icon: Icon(
              _comparativeMode ? Icons.compare_rounded : Icons.compare_outlined,
              color: _comparativeMode ? theme.colorScheme.primary : null,
            ),
            tooltip: 'وضع المقارنة',
            onPressed: () {
              setState(() {
                _comparativeMode = !_comparativeMode;
                if (_comparativeMode) {
                  _loadCompareData();
                }
              });
            },
          ),
          // Source switcher (single mode)
          if (!_comparativeMode)
            PopupMenuButton<TafsirSourceId>(
              icon: const Icon(Icons.menu_book_rounded),
              tooltip: 'اختر التفسير',
              onSelected: (source) {
                setState(() => _currentSource = source);
                _loadTafsir();
              },
              itemBuilder: (_) => TafsirSource.all.map((s) => PopupMenuItem(
                value: s.id,
                child: Row(
                  children: [
                    if (s.id == _currentSource)
                      Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
                    if (s.id != _currentSource)
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.arabicName)),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
      body: Container(
        color: TafsirTheme.readingBackground(theme.brightness),
        child: Column(
          children: [
            // ── Source chip bar (Phase 3) ──
            _buildSourceChipBar(theme),

            // ── Body ──
            Expanded(
              child: _comparativeMode
                  ? _buildComparativeView(theme)
                  : _buildSingleView(theme),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SOURCE CHIP BAR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSourceChipBar(ThemeData theme) {
    if (!_comparativeMode) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          border: Border(
            bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
          ),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: TafsirSource.all.map((source) {
            final isSelected = source.id == _currentSource;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(
                  source.arabicName,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _currentSource = source.id);
                  _loadTafsir();
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    // Compare mode: multi-select chips + ayah selector
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            children: TafsirSource.all.map((source) {
              final isSelected = _compareSources.contains(source.id);
              return FilterChip(
                label: Text(
                  source.arabicName,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _compareSources.add(source.id);
                    } else if (_compareSources.length > 1) {
                      _compareSources.remove(source.id);
                    }
                  });
                  _loadCompareData();
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.15),
                checkmarkColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: _compareAyah > 1
                    ? () {
                        setState(() => _compareAyah--);
                        _loadCompareData();
                      }
                    : null,
                visualDensity: VisualDensity.compact,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'الآية $_compareAyah',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: () {
                  setState(() => _compareAyah++);
                  _loadCompareData();
                },
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SINGLE VIEW (with Phase 4 word analysis buttons)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSingleView(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_surahTafsir == null || _surahTafsir!.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('التفسير غير متوفر',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _surahTafsir!.entries.length,
      separatorBuilder: (_, __) => const ArabesqueDividerCompact(),
      itemBuilder: (context, index) {
        final entry = _surahTafsir!.entries[index];
        final isTarget = entry.ayah == widget.ayahNumber;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isTarget
                ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                : theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: isTarget
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'الآية ${entry.ayah}',
                        style: TafsirTheme.headerStyle(
                          brightness: theme.brightness,
                          fontSize: 13,
                          color: TafsirTheme.ayahColor(theme.brightness),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Phase 4: Word analysis
                    _WordAnalysisButton(surah: entry.surah, ayah: entry.ayah, theme: theme),
                    const SizedBox(width: 4),
                    // Phase 6: Tadabbur note
                    GestureDetector(
                      onTap: () => _showTadabburSheet(context, entry.surah, entry.ayah),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit_note_rounded, size: 16,
                          color: theme.colorScheme.tertiary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Quick compare
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _comparativeMode = true;
                          _compareAyah = entry.ayah;
                        });
                        _loadCompareData();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.compare_rounded, size: 16,
                          color: theme.colorScheme.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              // Tafsir text
              Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  entry.text,
                  style: GoogleFonts.cairo(
                    fontSize: _fontSize, height: 1.9,
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              // Phase 6: Inline annotations
              _InlineAnnotationsPanel(
                surah: entry.surah,
                ayah: entry.ayah,
                source: _currentSource,
                theme: theme,
                onAddNote: () => _showTadabburSheet(context, entry.surah, entry.ayah),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPARATIVE VIEW (Phase 3)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildComparativeView(ThemeData theme) {
    if (_compareData == null || _compareData!.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final sources = _compareData!.entries.toList();
    const sourceColors = <TafsirSourceId, Color>{
      TafsirSourceId.muyassar: Color(0xFF2E7D32),
      TafsirSourceId.ibnKathir: Color(0xFF1565C0),
      TafsirSourceId.saadi: Color(0xFF6A1B9A),
      TafsirSourceId.tabari: Color(0xFFBF360C),
    };

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final entry = sources[index];
        final sourceInfo = TafsirSource.get(entry.key);
        final accentColor = sourceColors[entry.key] ?? theme.colorScheme.primary;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border(right: BorderSide(color: accentColor, width: 4)),
            boxShadow: [
              BoxShadow(color: accentColor.withOpacity(0.05), blurRadius: 8,
                offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Source header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.06),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(sourceInfo.arabicName,
                      style: GoogleFonts.cairo(
                        fontSize: 14, fontWeight: FontWeight.bold, color: accentColor)),
                    const Spacer(),
                    Text(sourceInfo.author,
                      style: GoogleFonts.cairo(fontSize: 11, color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  entry.value.text,
                  style: GoogleFonts.cairo(
                    fontSize: _fontSize, height: 1.9,
                    color: theme.colorScheme.onSurface.withOpacity(0.85)),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFontSizeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('حجم الخط',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Slider(
                value: _fontSize, min: 12, max: 28, divisions: 8,
                label: '${_fontSize.round()}',
                onChanged: (v) { setSheetState(() {}); setState(() => _fontSize = v); },
              ),
              Text('مثال: بسم الله الرحمن الرحيم',
                style: GoogleFonts.cairo(fontSize: _fontSize),
                textDirection: TextDirection.rtl),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Phase 6: Tadabbur notes
  void _showTadabburSheet(BuildContext context, int surah, int ayah) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TadabburNoteSheet(
        surah: surah,
        ayah: ayah,
        source: _currentSource,
      ),
    ).then((_) => setState(() {})); // Refresh inline annotations
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WORD ANALYSIS BUTTON (Phase 4)
// ═══════════════════════════════════════════════════════════════════════════

class _WordAnalysisButton extends StatelessWidget {
  final int surah;
  final int ayah;
  final ThemeData theme;

  const _WordAnalysisButton({
    required this.surah,
    required this.ayah,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showWordAnalysis(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.translate_rounded, size: 16,
          color: theme.colorScheme.tertiary),
      ),
    );
  }

  void _showWordAnalysis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WordAnalysisSheet(surah: surah, ayah: ayah),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WORD ANALYSIS SHEET (Phase 4 - Word-by-Word)
// ═══════════════════════════════════════════════════════════════════════════

class _WordAnalysisSheet extends StatefulWidget {
  final int surah;
  final int ayah;

  const _WordAnalysisSheet({required this.surah, required this.ayah});

  @override
  State<_WordAnalysisSheet> createState() => _WordAnalysisSheetState();
}

class _WordAnalysisSheetState extends State<_WordAnalysisSheet> {
  int _selectedWordIndex = -1;
  late List<_WordData> _words;

  @override
  void initState() {
    super.initState();
    _words = _getWordMappings(widget.surah, widget.ayah);
  }

  List<_WordData> _getWordMappings(int surah, int ayah) {
    // Al-Fatiha: full morphological data for demonstration
    if (surah == 1) {
      if (ayah == 1) {
        return const [
          _WordData('بِسْمِ', 'اسم', 'In the name of', 'جار ومجرور', 'bismi', 'Noun - genitive'),
          _WordData('ٱللَّهِ', 'أله', 'Allah', 'لفظ الجلالة مجرور', 'allāh', 'Proper noun'),
          _WordData('ٱلرَّحْمَٰنِ', 'رحم', 'The Most Gracious', 'صفة مجرورة', 'ar-raḥmān', 'Adjective'),
          _WordData('ٱلرَّحِيمِ', 'رحم', 'The Most Merciful', 'صفة مجرورة', 'ar-raḥīm', 'Adjective'),
        ];
      } else if (ayah == 2) {
        return const [
          _WordData('ٱلْحَمْدُ', 'حمد', 'All praise', 'مبتدأ مرفوع', 'al-ḥamdu', 'Noun - nominative'),
          _WordData('لِلَّهِ', 'أله', 'is for Allah', 'جار ومجرور - خبر', 'lillāhi', 'Preposition + noun'),
          _WordData('رَبِّ', 'ربب', 'Lord', 'مضاف إليه مجرور', 'rabbi', 'Noun - genitive'),
          _WordData('ٱلْعَٰلَمِينَ', 'علم', 'of the worlds', 'مضاف إليه مجرور', 'al-ʿālamīn', 'Noun - genitive plural'),
        ];
      } else if (ayah == 3) {
        return const [
          _WordData('ٱلرَّحْمَٰنِ', 'رحم', 'The Most Gracious', 'بدل مجرور', 'ar-raḥmān', 'Adjective'),
          _WordData('ٱلرَّحِيمِ', 'رحم', 'The Most Merciful', 'صفة مجرورة', 'ar-raḥīm', 'Adjective'),
        ];
      } else if (ayah == 4) {
        return const [
          _WordData('مَٰلِكِ', 'ملك', 'Master / Owner', 'بدل مجرور', 'māliki', 'Active participle'),
          _WordData('يَوْمِ', 'يوم', 'of the Day', 'مضاف إليه مجرور', 'yawmi', 'Noun - genitive'),
          _WordData('ٱلدِّينِ', 'دين', 'of Judgment', 'مضاف إليه مجرور', 'ad-dīni', 'Noun - genitive'),
        ];
      } else if (ayah == 5) {
        return const [
          _WordData('إِيَّاكَ', 'إيا', 'You alone', 'مفعول به مقدم', 'iyyāka', 'Pronoun - accusative'),
          _WordData('نَعْبُدُ', 'عبد', 'we worship', 'فعل مضارع مرفوع', 'naʿbudu', 'Verb - 1st person plural'),
          _WordData('وَإِيَّاكَ', 'إيا', 'and You alone', 'مفعول به مقدم', 'wa-iyyāka', 'Conjunction + pronoun'),
          _WordData('نَسْتَعِينُ', 'عون', 'we ask for help', 'فعل مضارع مرفوع', 'nastaʿīnu', 'Verb - 1st person plural'),
        ];
      } else if (ayah == 6) {
        return const [
          _WordData('ٱهْدِنَا', 'هدي', 'Guide us', 'فعل أمر + ضمير', 'ihdinā', 'Verb - imperative'),
          _WordData('ٱلصِّرَٰطَ', 'صرط', 'the path', 'مفعول به منصوب', 'aṣ-ṣirāṭa', 'Noun - accusative'),
          _WordData('ٱلْمُسْتَقِيمَ', 'قوم', 'the straight', 'صفة منصوبة', 'al-mustaqīma', 'Adjective'),
        ];
      } else if (ayah == 7) {
        return const [
          _WordData('صِرَٰطَ', 'صرط', 'The path', 'بدل منصوب', 'ṣirāṭa', 'Noun - accusative'),
          _WordData('ٱلَّذِينَ', 'لذ', 'of those', 'اسم موصول', 'alladhīna', 'Relative pronoun'),
          _WordData('أَنْعَمْتَ', 'نعم', 'You have blessed', 'فعل ماض', 'anʿamta', 'Verb - 2nd person'),
          _WordData('عَلَيْهِمْ', 'على', 'upon them', 'جار ومجرور', 'ʿalayhim', 'Preposition + pronoun'),
          _WordData('غَيْرِ', 'غير', 'not (of)', 'بدل مجرور', 'ghayri', 'Noun - genitive'),
          _WordData('ٱلْمَغْضُوبِ', 'غضب', 'those who earned anger', 'مضاف إليه', 'al-maghḍūbi', 'Passive participle'),
          _WordData('عَلَيْهِمْ', 'على', 'upon them', 'جار ومجرور', 'ʿalayhim', 'Preposition + pronoun'),
          _WordData('وَلَا', 'لا', 'and not', 'حرف عطف + نفي', 'wa-lā', 'Conjunction + negation'),
          _WordData('ٱلضَّآلِّينَ', 'ضلل', 'those who are astray', 'معطوف مجرور', 'aḍ-ḍāllīn', 'Active participle'),
        ];
      }
    }

    // Generic fallback for other surahs
    return List.generate(
      (ayah % 4) + 3,
      (i) => _WordData(
        'كلمة ${i + 1}', '---', 'Word ${i + 1}',
        'تحليل صرفي', 'kalima ${i + 1}', 'Morphological form',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16,
            offset: const Offset(0, -4)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Icon(Icons.translate_rounded, size: 20, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Text('تحليل الكلمات — سورة ${widget.surah}:${widget.ayah}',
                    style: GoogleFonts.cairo(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
                ],
              ),
            ),
            const Divider(height: 1),

            // Word chips (tappable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                textDirection: TextDirection.rtl,
                children: List.generate(_words.length, (i) {
                  final word = _words[i];
                  final isSelected = _selectedWordIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedWordIndex = isSelected ? -1 : i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.2)),
                      ),
                      child: Text(word.arabic,
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                    ),
                  );
                }),
              ),
            ),

            // Detail card
            if (_selectedWordIndex >= 0 && _selectedWordIndex < _words.length)
              _buildWordDetail(_words[_selectedWordIndex], theme),

            SizedBox(height: bottomPad + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWordDetail(_WordData word, ThemeData theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(word.arabic,
              style: GoogleFonts.amiri(
                fontSize: 36, fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary, height: 1.4)),
            const SizedBox(height: 12),
            _DetailRow(icon: Icons.account_tree_rounded, label: 'الجذر', value: word.root, theme: theme),
            _DetailRow(icon: Icons.translate_rounded, label: 'المعنى', value: word.meaning, theme: theme),
            _DetailRow(icon: Icons.school_rounded, label: 'الإعراب', value: word.irab, theme: theme),
            _DetailRow(icon: Icons.abc_rounded, label: 'النطق', value: word.transliteration, theme: theme),
            _DetailRow(icon: Icons.category_rounded, label: 'الصيغة', value: word.morphology, theme: theme),
          ],
        ),
      ),
    );
  }
}

// ── Data class for word analysis ──
class _WordData {
  final String arabic;
  final String root;
  final String meaning;
  final String irab;
  final String transliteration;
  final String morphology;

  const _WordData(this.arabic, this.root, this.meaning, this.irab, this.transliteration, this.morphology);
}

// ── Detail row widget ──
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.icon, required this.label,
    required this.value, required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary.withOpacity(0.7)),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(label,
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold,
                color: theme.colorScheme.outline),
              textDirection: TextDirection.rtl),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
              style: GoogleFonts.cairo(fontSize: 14, color: theme.colorScheme.onSurface),
              textDirection: TextDirection.rtl),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 6: INLINE ANNOTATIONS PANEL
// ═══════════════════════════════════════════════════════════════════════════

class _InlineAnnotationsPanel extends StatelessWidget {
  final int surah;
  final int ayah;
  final TafsirSourceId source;
  final ThemeData theme;
  final VoidCallback onAddNote;

  const _InlineAnnotationsPanel({
    required this.surah,
    required this.ayah,
    required this.source,
    required this.theme,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final annotations = TafsirDataSource.getAnnotationsForAyah(
      surah: surah, ayah: ayah, source: source,
    );

    if (annotations.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          right: BorderSide(color: theme.colorScheme.tertiary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 6),
              Text('ملاحظات تدبر',
                style: GoogleFonts.cairo(
                  fontSize: 12, fontWeight: FontWeight.bold,
                  color: theme.colorScheme.tertiary)),
              const Spacer(),
              GestureDetector(
                onTap: onAddNote,
                child: Icon(Icons.add_circle_outline, size: 16,
                  color: theme.colorScheme.tertiary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...annotations.map((note) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.circle, size: 6,
                  color: theme.colorScheme.tertiary.withOpacity(0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(note.noteText,
                    style: GoogleFonts.cairo(
                      fontSize: 13, height: 1.6,
                      color: theme.colorScheme.onSurface.withOpacity(0.75)),
                    textDirection: TextDirection.rtl),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 6: TADABBUR NOTE SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _TadabburNoteSheet extends StatefulWidget {
  final int surah;
  final int ayah;
  final TafsirSourceId source;

  const _TadabburNoteSheet({
    required this.surah,
    required this.ayah,
    required this.source,
  });

  @override
  State<_TadabburNoteSheet> createState() => _TadabburNoteSheetState();
}

class _TadabburNoteSheetState extends State<_TadabburNoteSheet> {
  final _controller = TextEditingController();
  late List<TafsirAnnotation> _notes;

  @override
  void initState() {
    super.initState();
    _notes = TafsirDataSource.getAnnotationsForAyah(
      surah: widget.surah,
      ayah: widget.ayah,
      source: widget.source,
    );
  }

  Future<void> _addNote() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final annotation = TafsirAnnotation(
      id: now.millisecondsSinceEpoch.toString(),
      surah: widget.surah,
      ayah: widget.ayah,
      source: widget.source,
      noteText: text,
      createdAt: now,
      updatedAt: now,
    );

    await TafsirDataSource.addAnnotation(annotation);
    _controller.clear();
    setState(() {
      _notes = TafsirDataSource.getAnnotationsForAyah(
        surah: widget.surah,
        ayah: widget.ayah,
        source: widget.source,
      );
    });
  }

  Future<void> _deleteNote(TafsirAnnotation note) async {
    await TafsirDataSource.removeAnnotation(note.key);
    setState(() {
      _notes = TafsirDataSource.getAnnotationsForAyah(
        surah: widget.surah,
        ayah: widget.ayah,
        source: widget.source,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16,
            offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 22, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text('ملاحظات تدبر — سورة ${widget.surah}:${widget.ayah}',
                  style: GoogleFonts.cairo(
                    fontSize: 15, fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Existing notes
          if (_notes.isNotEmpty)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(note.noteText,
                            style: GoogleFonts.cairo(
                              fontSize: 14, height: 1.6,
                              color: theme.colorScheme.onSurface),
                            textDirection: TextDirection.rtl),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteNote(note),
                          child: Icon(Icons.delete_outline, size: 18,
                            color: theme.colorScheme.error.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          if (_notes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 48,
                    color: theme.colorScheme.outline.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text('لا توجد ملاحظات تدبّر بعد',
                    style: GoogleFonts.cairo(
                      fontSize: 14, color: theme.colorScheme.outline)),
                  Text('سجّل خواطرك وتأملاتك هنا',
                    style: GoogleFonts.cairo(
                      fontSize: 12, color: theme.colorScheme.outline.withOpacity(0.6))),
                ],
              ),
            ),

          const Divider(height: 1),

          // Input row
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'أضف تدبّرك هنا...',
                      hintTextDirection: TextDirection.rtl,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.cairo(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _addNote,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.send_rounded, size: 20,
                        color: theme.colorScheme.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

