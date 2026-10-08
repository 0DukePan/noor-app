import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/entities/surah.dart';
import '../../../../core/services/statistics_service.dart';
import '../../../../core/utils/verse_counts.dart' as vc;
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/quran_providers.dart';
import '../widgets/mushaf/ayah_actions_sheet.dart';
import '../widgets/mushaf/mushaf_canvas.dart';
import '../widgets/mushaf/mushaf_controls.dart';
import '../widgets/mushaf/mushaf_theme.dart';

export '../widgets/mushaf/mushaf_canvas.dart';
export '../widgets/mushaf/mushaf_controls.dart';
export '../widgets/mushaf/mushaf_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MUSHAF READER — fixed continuous page canvas (QUR-03)
//
// Role tree (Phase 2.3):
//
//   QuranMushafPage (route entry; this file — reader state + orchestration)
//     MushafPageView (one horizontal PageView only)
//     MushafPageCanvas (widgets/mushaf/mushaf_canvas.dart — complete page)
//       MushafPageHeader
//       MushafTextRegion (SurahStartBanner + ContinuousVerseBlock)
//       MushafPageFooter
//     MushafControlsOverlay (widgets/mushaf/mushaf_controls.dart)
//     AyahActionsSheet (widgets/mushaf/ayah_actions_sheet.dart)
//
// Theme, zoom, and preference state live in
// widgets/mushaf/mushaf_theme.dart and are re-exported here so existing
// importers keep resolving.
// ═══════════════════════════════════════════════════════════════════════════

/// صفحة المصحف - Traditional Mushaf Page Viewer
class QuranMushafPage extends ConsumerStatefulWidget {
  const QuranMushafPage({super.key, this.initialPage = 1});
  final int initialPage;

  @override
  ConsumerState<QuranMushafPage> createState() => _QuranMushafPageState();
}

class _QuranMushafPageState extends ConsumerState<QuranMushafPage> {
  late final PageController _pageController;
  late final int _normalizedInitial;

  /// Settle-generation: an older async save must never overwrite a later page.
  int _saveGeneration = 0;

  /// Suppresses the blank-tap control toggle immediately after an ayah
  /// action so opening the sheet never also hides the controls (QUR-06).
  DateTime? _lastAyahActionAt;

  /// Slider drag preview (updated live); persistence happens on settle only.
  double? _sliderPreview;

  @override
  void initState() {
    super.initState();
    // QUR-04: validate/clamp route input 1..604 BEFORE PageController sees it,
    // and initialize one source of truth before first paint.
    _normalizedInitial = vc.clampPage(widget.initialPage);
    _pageController = PageController(initialPage: _normalizedInitial - 1);
    // Sync the route-scoped state source before first frame.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(mushafCurrentPageProvider.notifier).state = _normalizedInitial;
      _restorePreferences();
    });
  }

  /// Only restore persisted prefs when the user has saved ones (QUR-07):
  /// a missing record keeps constructor/test defaults instead of clobbering
  /// provider overrides.
  Future<void> _restorePreferences() async {
    final stored = await MushafPreferenceStore.readStored();
    if (stored == null || !mounted) return;
    final prefs = MushafPreferences.fromStored(stored);
    ref.read(mushafThemeProvider.notifier).state = prefs.theme;
    ref.read(mushafZoomProvider.notifier).state = prefs.zoom;
    ref.read(mushafShowControlsProvider.notifier).state = prefs.showControls;
  }

  Future<void> _persistPreferences({int? lastPage}) async {
    await MushafPreferenceStore.writeStored(
      MushafPreferences(
        theme: ref.read(mushafThemeProvider),
        zoom: ref.read(mushafZoomProvider),
        showControls: ref.read(mushafShowControlsProvider),
        lastPage: lastPage ?? ref.read(mushafCurrentPageProvider),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    // An ayah tap that just opened the sheet must not toggle controls.
    final lastAyah = _lastAyahActionAt;
    if (lastAyah != null &&
        DateTime.now().difference(lastAyah).inMilliseconds < 350) {
      return;
    }
    final current = ref.read(mushafShowControlsProvider);
    ref.read(mushafShowControlsProvider.notifier).state = !current;
    if (!current) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    _persistPreferences();
  }

  void _markAyahAction() {
    _lastAyahActionAt = DateTime.now();
  }

  void _showAyahActions(Verse verse, MushafThemeData themeData) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AyahActionsSheet(verse: verse, themeData: themeData),
    );
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
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            MushafPageView(
              controller: _pageController,
              themeData: themeData,
              onPageSettled: (pageNum) {
                ref.read(mushafCurrentPageProvider.notifier).state = pageNum;
                setState(() => _sliderPreview = null);
                // Save reading position only after page settle.
                _saveReadingProgress(pageNum);
                _persistPreferences(lastPage: pageNum);
              },
              onAyahAction: _markAyahAction,
              onVerseTap: (verse) => _showAyahActions(verse, themeData),
            ),

            // Chrome auto-hides as one unit; the canvas reserves its zones.
            MushafControlsOverlay(
              visible: showControls,
              currentPage: (_sliderPreview ?? currentPage.toDouble())
                  .round()
                  .clamp(1, vc.kTotalPages),
              themeData: themeData,
              onBack: () => Navigator.pop(context),
              onTheme: () => _showThemeSelector(context, ref),
              onPreview: (page) =>
                  setState(() => _sliderPreview = page.toDouble()),
              onSettle: (page) {
                final target = vc.clampPage(page);
                setState(() => _sliderPreview = null);
                _pageController.jumpToPage(target - 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReadingProgress(int page) async {
    final generation = ++_saveGeneration;
    try {
      final verses = await ref.read(quranPageProvider(page).future);
      // Drop obsolete writes: an older save cannot overwrite a later page.
      if (generation != _saveGeneration || !mounted) return;
      if (verses.isEmpty) return;
      final first = verses.first;
      final surah = first.surahNumber;
      final ayah = first.numberInSurah;

      // Statistics/home card reads the app_statistics box.
      await StatisticsService.recordVerseRead(surah, ayah);
      if (generation != _saveGeneration || !mounted) return;
      // Quran page "continue reading" reads the reading_progress box.
      await ref
          .read(quranRepositoryProvider)
          .saveReadingProgress(
            surahNumber: surah,
            verseNumber: ayah,
            page: page,
          );
    } on Exception catch (_) {
      // Progress is best-effort; never block paging on a write failure.
    }
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(mushafThemeProvider);

    showModalBottomSheet<void>(
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
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MushafThemeData.themes[currentTheme]!.textColor
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).surahAppearance,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MushafThemeData.themes[currentTheme]!.textColor,
              ),
            ),
            const SizedBox(height: 20),
            // Wrap so five skins (incl. high-contrast) fit narrow screens.
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8,
              runSpacing: 12,
              children: MushafTheme.values.map((theme) {
                final data = MushafThemeData.themes[theme]!;
                final isSelected = theme == currentTheme;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: data.localizedLabel(context),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(mushafThemeProvider.notifier).state = theme;
                      _persistPreferences();
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
                              color: isSelected
                                  ? data.headerColor
                                  : data.borderColor,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: data.headerColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: data.textColor,
                                  size: 24,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.localizedLabel(context),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color:
                                MushafThemeData.themes[currentTheme]!.textColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Approved discrete zoom levels + reset (QUR-03).
            MushafZoomControls(
              themeData: MushafThemeData.themes[currentTheme]!,
            ),
          ],
        ),
      ),
    );
  }
}

/// One horizontal PageView only (QUR-03): each child is a complete fixed
/// page canvas, never a scroll view nested inside another. Arabic locale
/// page direction is fixed RTL and covered by widget tests.
class MushafPageView extends StatelessWidget {
  const MushafPageView({
    required this.controller,
    required this.themeData,
    required this.onPageSettled,
    this.onAyahAction,
    this.onVerseTap,
    super.key,
  });
  final PageController controller;
  final MushafThemeData themeData;

  /// Fired once per settled page (persistence happens here, not on drag).
  final ValueChanged<int> onPageSettled;
  final VoidCallback? onAyahAction;
  final ValueChanged<Verse>? onVerseTap;

  @override
  Widget build(BuildContext context) {
    // RTL swipe turns pages like an Arabic book.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PageView.builder(
        controller: controller,
        itemCount: vc.kTotalPages,
        onPageChanged: (index) => onPageSettled(index + 1),
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          return MushafPageCanvas(
            pageNumber: pageNum,
            themeData: themeData,
            onAyahAction: onAyahAction,
            onVerseTap: onVerseTap,
          );
        },
      ),
    );
  }
}
