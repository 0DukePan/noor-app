import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/entities/surah.dart';
import '../../../../core/domain/policies/khushu_policy.dart';
import '../../../../core/services/quran_translation_data_source.dart';
import '../../../../core/services/services.dart';
import '../../../../core/theme/noor_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../hifz/presentation/providers/hifz_providers.dart';
import '../providers/quran_providers.dart';
import '../widgets/surah_audio_widgets.dart';
import '../widgets/surah_verse_widgets.dart';

/// صفحة السورة الديناميكية - Dynamic Surah Reading Page
class SurahPage extends ConsumerStatefulWidget {

  const SurahPage({required this.surahNumber, super.key});
  final int surahNumber;

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _khushuController;
  late Animation<double> _fadeAnimation;
  final KhushuModePolicy _khushuPolicy = const KhushuModePolicy();

  /// الآية قيد التلاوة حالياً (مصدر واحد: QuranAudioEngine).
  int? _playingAyah;

  /// ترجمة السورة الحالية — تُحمَّل عند تفعيل «إظهار الترجمة».
  Map<int, String>? _translations;
  TranslationLanguage _translationsLanguage = TranslationLanguage.arabic;
  StreamSubscription<int>? _ayahSub;

  @override
  void initState() {
    super.initState();
    AnalyticsService.record('surah_opened');
    _khushuController = AnimationController(
      vsync: this,
      duration: _khushuPolicy.getBreathingDelayDuration(),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _khushuController,
      curve: Curves.easeInOut,
    );
    _ayahSub = QuranAudioEngine.currentAyahStream.listen((ayah) {
      if (!mounted) return;
      setState(() => _playingAyah = ayah);
    });
  }

  Future<void> _loadTranslations(TranslationLanguage language) async {
    final translations = await QuranTranslationDataSource.getSurah(
      widget.surahNumber,
      language: language,
    );
    if (!mounted) return;
    setState(() {
      _translations = translations;
      _translationsLanguage = language;
    });
  }

  @override
  void dispose() {
    _ayahSub?.cancel();
    _scrollController.dispose();
    _khushuController.dispose();
    super.dispose();
  }

  Future<void> _toggleKhushuMode() async {
    final settings = ref.read(readingSettingsProvider);
    final isKhushu = settings.isKhushuMode;

    if (!isKhushu) {
      await HapticFeedback.lightImpact();
      unawaited(_khushuController.forward());
    } else {
      unawaited(_khushuController.reverse());
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

    // Load translations once when the toggle is on; reload on language change.
    final wantsLanguage = settings.translationLanguage;
    if (settings.showTranslation &&
        (_translations == null || _translationsLanguage != wantsLanguage)) {
      _loadTranslations(wantsLanguage);
    }

    // Determine background color based on mode
    final backgroundColor = settings.isKhushuMode
        ? (isDark ? Colors.black : const Color(0xFFFDFCF9))
        : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
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
                    Text(AppLocalizations.of(context).surahLoadError, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.refresh(surahProvider(widget.surahNumber)),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(AppLocalizations.of(context).commonRetry),
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
                      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      centerTitle: true,
                      title: Text(
                        surahAsync.value?.nameArabic ?? AppLocalizations.of(context).surahFallback(widget.surahNumber),
                        style: GoogleFonts.amiri(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      leading: BackButton(color: theme.colorScheme.onSurface),
                      actions: [
                        IconButton(
                          icon: Icon(Icons.self_improvement_rounded, color: theme.colorScheme.primary),
                          tooltip: AppLocalizations.of(context).surahKhushuTooltip,
                          onPressed: _toggleKhushuMode,
                        ),
                        IconButton(
                          icon: Icon(Icons.graphic_eq_rounded, color: theme.colorScheme.onSurfaceVariant),
                          tooltip: AppLocalizations.of(context).surahListenTooltip,
                          onPressed: () => _showAudioPlayer(context),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (value) {
                            switch (value) {
                              case 'tafsir':
                                context.push('/tafsir?surah=${widget.surahNumber}');
                              case 'settings':
                                _showReadingAppearanceSheet();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'tafsir',
                              child: Row(children: [const Icon(Icons.menu_book_rounded, size: 20), const SizedBox(width: 12), Text(AppLocalizations.of(context).quranTafsir)]),
                            ),
                            PopupMenuItem(
                              value: 'settings',
                              child: Row(children: [const Icon(Icons.text_fields_rounded, size: 20), const SizedBox(width: 12), Text(AppLocalizations.of(context).surahAppearance)]),
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
                      child: BismillahHeader(surahNumber: widget.surahNumber),
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
                            child: DynamicVerseCard(
                              verse: verse,
                              isKhushuMode: settings.isKhushuMode,
                              isSelected: selectedVerseIndex == index,
                              isPlaying:
                                  _playingAyah == verse.numberInSurah,
                              translation: settings.showTranslation
                                  ? (_translations?[verse.numberInSurah])
                                  : null,
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
                child: DynamicTafsirPanel(
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
              child: MiniAudioPlayer(
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
                          backgroundColor.withValues(alpha: 0),
                          backgroundColor.withValues(alpha: 0.1),
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AudioPlayerSheet(surahNumber: widget.surahNumber),
    );
  }

  void _showReadingAppearanceSheet() {
    final settings = ref.read(readingSettingsProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).surahAppearance,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).settingsFontSize,
                      style: GoogleFonts.cairo(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${settings.fontSize.round()}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.fontSize,
                  min: 16,
                  max: 34,
                  divisions: 9,
                  label: settings.fontSize.round().toString(),
                  onChanged: (v) {
                    ref
                        .read(readingSettingsProvider.notifier)
                        .setFontSize(v);
                    setSheetState(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppLocalizations.of(context).surahShowTranslation,
                    style: GoogleFonts.cairo(fontSize: 14),
                  ),
                  value: settings.showTranslation,
                  onChanged: (v) {
                    ref
                        .read(readingSettingsProvider.notifier)
                        .toggleTranslation();
                    setSheetState(() {});
                  },
                ),
                if (settings.showTranslation)
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context).surahTrLang,
                        style: GoogleFonts.cairo(fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: Text('العربية', style: GoogleFonts.cairo(fontSize: 12)),
                        selected: settings.translationLanguage ==
                            TranslationLanguage.arabic,
                        onSelected: (_) {
                          ref
                              .read(readingSettingsProvider.notifier)
                              .setTranslationLanguage(TranslationLanguage.arabic);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('English', style: GoogleFonts.cairo(fontSize: 12)),
                        selected: settings.translationLanguage ==
                            TranslationLanguage.english,
                        onSelected: (_) {
                          ref
                              .read(readingSettingsProvider.notifier)
                              .setTranslationLanguage(TranslationLanguage.english);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVerseOptions(BuildContext context, Verse verse) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
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
                color: NoorTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            OptionTile(
              icon: Icons.menu_book_rounded,
              title: AppLocalizations.of(context).verseTafsir,
              onTap: () {
                Navigator.pop(context);
                ref.read(surahSelectedVerseProvider(widget.surahNumber).notifier).state = verse.numberInSurah - 1;
              },
            ),
            OptionTile(
              icon: Icons.auto_stories_rounded,
              title: AppLocalizations.of(context).verseAddHifz,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final l10n = AppLocalizations.of(context);
                Navigator.pop(context);
                await ref.read(hifzProvider.notifier).addAyah(
                      surah: widget.surahNumber,
                      ayah: verse.numberInSurah,
                      arabicText: verse.textUthmani,
                    );
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.verseHifzAdded)),
                );
              },
            ),
            OptionTile(
              icon: Icons.bookmark_outline_rounded,
              title: AppLocalizations.of(context).verseAddBookmark,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final l10n = AppLocalizations.of(context);
                Navigator.pop(context);
                // quran_uthmani.json has no page field; map it via quran_pages.
                final page = await ref
                        .read(localQuranDataSourceProvider)
                        .getPageForAyah(widget.surahNumber, verse.numberInSurah) ??
                    0;
                await ref.read(quranRepositoryProvider).saveReadingProgress(
                      surahNumber: widget.surahNumber,
                      verseNumber: verse.numberInSurah,
                      page: page,
                    );
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.verseBookmarkSaved)),
                );
              },
            ),
            OptionTile(
              icon: Icons.share_rounded,
              title: AppLocalizations.of(context).verseShare,
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                final l10n = AppLocalizations.of(context);
                Navigator.pop(context);
                final shareText = l10n.verseShareTemplate(verse.textUthmani, widget.surahNumber, verse.numberInSurah);
                Clipboard.setData(ClipboardData(text: shareText));
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.verseShareCopied)),
                );
              },
            ),
            OptionTile(
              icon: Icons.play_arrow_rounded,
              title: AppLocalizations.of(context).versePlayAudio,
              onTap: () {
                Navigator.pop(context);
                QuranAudioService.playSurah(surahNumber: widget.surahNumber);
              },
            ),
            OptionTile(
              icon: Icons.copy_rounded,
              title: AppLocalizations.of(context).verseCopy,
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: verse.textUthmani));
                messenger.showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).verseCopied)),
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
