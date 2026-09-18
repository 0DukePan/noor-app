import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/tafsir_models.dart';
import '../../../../core/services/quran_data_source.dart';
import '../../../../core/services/tafsir_data_source.dart';
import '../../../../core/theme/tafsir_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Tafsir reader page - tafsir_reader_page.dart
/// Extracted from full_tafsir_reader.dart (Phase 1 god-file split); was a
/// `part of` quran_mushaf_page.dart, now a standalone library.

class TafsirReaderPage extends StatefulWidget {
  const TafsirReaderPage({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    super.key,
  });
  final int surahNumber;
  final int ayahNumber;
  final String surahName;

  @override
  State<TafsirReaderPage> createState() => TafsirReaderPageState();
}

class TafsirReaderPageState extends State<TafsirReaderPage> {
  // ── State ──
  SurahTafsir? _surahTafsir;
  bool _isLoading = true;
  TafsirSourceId _currentSource = TafsirSourceId.muyassar;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  double _fontSize = 16;

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
    // Scroll the target ayah into view using its own render context, so the
    // offset is exact regardless of font size / line height (was a hardcoded
    // `(ayahNumber - 1) * 220.0`).
    final context = _ayahKeys[ayahNumber]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
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
              itemBuilder: (_) => TafsirSource.all
                  .map(
                    (s) => PopupMenuItem(
                      value: s.id,
                      child: Row(
                        children: [
                          if (s.id == _currentSource)
                            Icon(Icons.check,
                                size: 18, color: theme.colorScheme.primary,),
                          if (s.id != _currentSource) const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.arabicName)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      body: ColoredBox(
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
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border(
            bottom:
                BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
          ),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: TafsirSource.all.map((source) {
            final isSelected = source.id == _currentSource;
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
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
                selectedColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
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
                selectedColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
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
                icon: Icon(
                  isRtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 20,
                ),
                tooltip: AppLocalizations.of(context).a11yPrevious,
                onPressed: _compareAyah > 1
                    ? () {
                        setState(() => _compareAyah--);
                        _loadCompareData();
                      }
                    : null,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                icon: Icon(
                  isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                ),
                tooltip: AppLocalizations.of(context).a11yNext,
                onPressed: () {
                  setState(() => _compareAyah++);
                  _loadCompareData();
                },
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
            Icon(Icons.menu_book_rounded,
                size: 64, color: theme.colorScheme.outline,),
            const SizedBox(height: 16),
            Text(
              'التفسير غير متوفر',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
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

        return KeyedSubtree(
          key: _ayahKeys[entry.ayah] ??= GlobalKey(),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isTarget
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: isTarget
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4,),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
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
                      WordAnalysisButton(
                          surah: entry.surah, ayah: entry.ayah, theme: theme,),
                      const SizedBox(width: 4),
                      // Phase 6: Tadabbur note
                      GestureDetector(
                        onTap: () => _showTadabburSheet(
                            context, entry.surah, entry.ayah,),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            size: 16,
                            color: theme.colorScheme.tertiary,
                          ),
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
                            color: theme.colorScheme.secondary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.compare_rounded,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
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
                      fontSize: _fontSize,
                      height: 1.9,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                // Phase 6: Inline annotations
                InlineAnnotationsPanel(
                  surah: entry.surah,
                  ayah: entry.ayah,
                  source: _currentSource,
                  theme: theme,
                  onAddNote: () =>
                      _showTadabburSheet(context, entry.surah, entry.ayah),
                ),
              ],
            ),
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
        final accentColor =
            sourceColors[entry.key] ?? theme.colorScheme.primary;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border(right: BorderSide(color: accentColor, width: 4)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Source header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.06),
                  borderRadius:
                      const BorderRadius.only(topLeft: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: accentColor, shape: BoxShape.circle,),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sourceInfo.arabicName,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      sourceInfo.author,
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: theme.colorScheme.outline,),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  entry.value.text,
                  style: GoogleFonts.cairo(
                    fontSize: _fontSize,
                    height: 1.9,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
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
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'حجم الخط',
                style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.bold,),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _fontSize,
                min: 12,
                max: 28,
                divisions: 8,
                label: '${_fontSize.round()}',
                onChanged: (v) {
                  setSheetState(() {});
                  setState(() => _fontSize = v);
                },
              ),
              Text(
                'مثال: بسم الله الرحمن الرحيم',
                style: GoogleFonts.cairo(fontSize: _fontSize),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Phase 6: Tadabbur notes
  void _showTadabburSheet(BuildContext context, int surah, int ayah) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TadabburNoteSheet(
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

class WordAnalysisButton extends StatelessWidget {
  const WordAnalysisButton({
    required this.surah,
    required this.ayah,
    required this.theme,
    super.key,
  });
  final int surah;
  final int ayah;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showWordAnalysis(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.translate_rounded,
          size: 16,
          color: theme.colorScheme.tertiary,
        ),
      ),
    );
  }

  void _showWordAnalysis(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WordAnalysisSheet(surah: surah, ayah: ayah),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WORD ANALYSIS SHEET (Phase 4 - Word-by-Word)
// ═══════════════════════════════════════════════════════════════════════════

class WordAnalysisSheet extends StatefulWidget {
  const WordAnalysisSheet({required this.surah, required this.ayah, super.key});
  final int surah;
  final int ayah;

  @override
  State<WordAnalysisSheet> createState() => WordAnalysisSheetState();
}

class WordAnalysisSheetState extends State<WordAnalysisSheet> {
  int _selectedWordIndex = -1;
  late List<WordData> _words;

  @override
  void initState() {
    super.initState();
    _words = _getFatihaMappings(widget.surah, widget.ayah) ?? const [];
    if (widget.surah != 1) {
      _loadRealWords();
    }
  }

  /// Loads the REAL words of the ayah for non-Fatiha surahs. Morphological
  /// details (root/meaning/i'rab) are only curated for Al-Fatiha; for other
  /// surahs the sheet shows the actual vocabulary instead of fabricating data.
  Future<void> _loadRealWords() async {
    try {
      final verse = await QuranDataSource.getVerse(widget.surah, widget.ayah);
      if (!mounted) return;
      final text = verse?['text'] as String? ?? '';
      final words =
          text.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
      setState(() {
        _words =
            words.map((w) => WordData(w.trim(), '', '', '', '', '')).toList();
      });
    } on Exception catch (e) {
      debugPrint('Failed to load verse words: $e');
    }
  }

  /// Al-Fatiha has hand-curated morphological data; other surahs return null
  /// so the real words are loaded from the Quran text instead.
  List<WordData>? _getFatihaMappings(int surah, int ayah) {
    // Al-Fatiha: full morphological data
    if (surah == 1) {
      if (ayah == 1) {
        return const [
          WordData('بِسْمِ', 'اسم', 'In the name of', 'جار ومجرور', 'bismi',
              'Noun - genitive',),
          WordData('ٱللَّهِ', 'أله', 'Allah', 'لفظ الجلالة مجرور', 'allāh',
              'Proper noun',),
          WordData('ٱلرَّحْمَٰنِ', 'رحم', 'The Most Gracious', 'صفة مجرورة',
              'ar-raḥmān', 'Adjective',),
          WordData('ٱلرَّحِيمِ', 'رحم', 'The Most Merciful', 'صفة مجرورة',
              'ar-raḥīm', 'Adjective',),
        ];
      } else if (ayah == 2) {
        return const [
          WordData('ٱلْحَمْدُ', 'حمد', 'All praise', 'مبتدأ مرفوع', 'al-ḥamdu',
              'Noun - nominative',),
          WordData('لِلَّهِ', 'أله', 'is for Allah', 'جار ومجرور - خبر',
              'lillāhi', 'Preposition + noun',),
          WordData('رَبِّ', 'ربب', 'Lord', 'مضاف إليه مجرور', 'rabbi',
              'Noun - genitive',),
          WordData('ٱلْعَٰلَمِينَ', 'علم', 'of the worlds', 'مضاف إليه مجرور',
              'al-ʿālamīn', 'Noun - genitive plural',),
        ];
      } else if (ayah == 3) {
        return const [
          WordData('ٱلرَّحْمَٰنِ', 'رحم', 'The Most Gracious', 'بدل مجرور',
              'ar-raḥmān', 'Adjective',),
          WordData('ٱلرَّحِيمِ', 'رحم', 'The Most Merciful', 'صفة مجرورة',
              'ar-raḥīm', 'Adjective',),
        ];
      } else if (ayah == 4) {
        return const [
          WordData('مَٰلِكِ', 'ملك', 'Master / Owner', 'بدل مجرور', 'māliki',
              'Active participle',),
          WordData('يَوْمِ', 'يوم', 'of the Day', 'مضاف إليه مجرور', 'yawmi',
              'Noun - genitive',),
          WordData('ٱلدِّينِ', 'دين', 'of Judgment', 'مضاف إليه مجرور',
              'ad-dīni', 'Noun - genitive',),
        ];
      } else if (ayah == 5) {
        return const [
          WordData('إِيَّاكَ', 'إيا', 'You alone', 'مفعول به مقدم', 'iyyāka',
              'Pronoun - accusative',),
          WordData('نَعْبُدُ', 'عبد', 'we worship', 'فعل مضارع مرفوع',
              'naʿbudu', 'Verb - 1st person plural',),
          WordData('وَإِيَّاكَ', 'إيا', 'and You alone', 'مفعول به مقدم',
              'wa-iyyāka', 'Conjunction + pronoun',),
          WordData('نَسْتَعِينُ', 'عون', 'we ask for help', 'فعل مضارع مرفوع',
              'nastaʿīnu', 'Verb - 1st person plural',),
        ];
      } else if (ayah == 6) {
        return const [
          WordData('ٱهْدِنَا', 'هدي', 'Guide us', 'فعل أمر + ضمير', 'ihdinā',
              'Verb - imperative',),
          WordData('ٱلصِّرَٰطَ', 'صرط', 'the path', 'مفعول به منصوب',
              'aṣ-ṣirāṭa', 'Noun - accusative',),
          WordData('ٱلْمُسْتَقِيمَ', 'قوم', 'the straight', 'صفة منصوبة',
              'al-mustaqīma', 'Adjective',),
        ];
      } else if (ayah == 7) {
        return const [
          WordData('صِرَٰطَ', 'صرط', 'The path', 'بدل منصوب', 'ṣirāṭa',
              'Noun - accusative',),
          WordData('ٱلَّذِينَ', 'لذ', 'of those', 'اسم موصول', 'alladhīna',
              'Relative pronoun',),
          WordData('أَنْعَمْتَ', 'نعم', 'You have blessed', 'فعل ماض',
              'anʿamta', 'Verb - 2nd person',),
          WordData('عَلَيْهِمْ', 'على', 'upon them', 'جار ومجرور', 'ʿalayhim',
              'Preposition + pronoun',),
          WordData('غَيْرِ', 'غير', 'not (of)', 'بدل مجرور', 'ghayri',
              'Noun - genitive',),
          WordData('ٱلْمَغْضُوبِ', 'غضب', 'those who earned anger', 'مضاف إليه',
              'al-maghḍūbi', 'Passive participle',),
          WordData('عَلَيْهِمْ', 'على', 'upon them', 'جار ومجرور', 'ʿalayhim',
              'Preposition + pronoun',),
          WordData('وَلَا', 'لا', 'and not', 'حرف عطف + نفي', 'wa-lā',
              'Conjunction + negation',),
          WordData('ٱلضَّآلِّينَ', 'ضلل', 'those who are astray', 'معطوف مجرور',
              'aḍ-ḍāllīn', 'Active participle',),
        ];
      }
    }

    // Not Al-Fatiha: real words are loaded from the Quran text.
    return null;
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Icon(Icons.translate_rounded,
                      size: 20, color: theme.colorScheme.tertiary,),
                  const SizedBox(width: 8),
                  Text(
                    'تحليل الكلمات — سورة ${widget.surah}:${widget.ayah}',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Word chips (tappable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                textDirection: TextDirection.rtl,
                children: List.generate(_words.length, (i) {
                  final word = _words[i];
                  final isSelected = _selectedWordIndex == i;
                  return GestureDetector(
                    onTap: () => setState(
                        () => _selectedWordIndex = isSelected ? -1 : i,),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8,),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        word.arabic,
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
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

  Widget _buildWordDetail(WordData word, ThemeData theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),),
        ),
        child: Column(
          children: [
            Text(
              word.arabic,
              style: GoogleFonts.amiri(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            DetailRow(
                icon: Icons.account_tree_rounded,
                label: 'الجذر',
                value: word.root,
                theme: theme,),
            DetailRow(
                icon: Icons.translate_rounded,
                label: 'المعنى',
                value: word.meaning,
                theme: theme,),
            DetailRow(
                icon: Icons.school_rounded,
                label: 'الإعراب',
                value: word.irab,
                theme: theme,),
            DetailRow(
                icon: Icons.abc_rounded,
                label: 'النطق',
                value: word.transliteration,
                theme: theme,),
            DetailRow(
                icon: Icons.category_rounded,
                label: 'الصيغة',
                value: word.morphology,
                theme: theme,),
          ],
        ),
      ),
    );
  }
}

// ── Data class for word analysis ──
class WordData {
  const WordData(this.arabic, this.root, this.meaning, this.irab,
      this.transliteration, this.morphology,);
  final String arabic;
  final String root;
  final String meaning;
  final String irab;
  final String transliteration;
  final String morphology;
}

// ── Detail row widget ──
class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    super.key,
  });
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon,
              size: 16,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.outline,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'غير متوفر' : value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: value.trim().isEmpty
                    ? theme.colorScheme.outline
                    : theme.colorScheme.onSurface,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 6: INLINE ANNOTATIONS PANEL
// ═══════════════════════════════════════════════════════════════════════════

class InlineAnnotationsPanel extends StatelessWidget {
  const InlineAnnotationsPanel({
    required this.surah,
    required this.ayah,
    required this.source,
    required this.theme,
    required this.onAddNote,
    super.key,
  });
  final int surah;
  final int ayah;
  final TafsirSourceId source;
  final ThemeData theme;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final annotations = TafsirDataSource.getAnnotationsForAyah(
      surah: surah,
      ayah: ayah,
      source: source,
    );

    if (annotations.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.15),
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
              Icon(Icons.edit_note_rounded,
                  size: 16, color: theme.colorScheme.tertiary,),
              const SizedBox(width: 6),
              Text(
                'ملاحظات تدبر',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAddNote,
                child: Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...annotations.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.noteText,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        height: 1.6,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 6: TADABBUR NOTE SHEET
// ═══════════════════════════════════════════════════════════════════════════

class TadabburNoteSheet extends StatefulWidget {
  const TadabburNoteSheet({
    required this.surah,
    required this.ayah,
    required this.source,
    super.key,
  });
  final int surah;
  final int ayah;
  final TafsirSourceId source;

  @override
  State<TadabburNoteSheet> createState() => TadabburNoteSheetState();
}

class TadabburNoteSheetState extends State<TadabburNoteSheet> {
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded,
                    size: 22, color: theme.colorScheme.tertiary,),
                const SizedBox(width: 8),
                Text(
                  'ملاحظات تدبر — سورة ${widget.surah}:${widget.ayah}',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
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
                      color: theme.colorScheme.tertiaryContainer
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            note.noteText,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              height: 1.6,
                              color: theme.colorScheme.onSurface,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteNote(note),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.6),
                          ),
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
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 48,
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد ملاحظات تدبّر بعد',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  Text(
                    'سجّل خواطرك وتأملاتك هنا',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: theme.colorScheme.outline.withValues(alpha: 0.6),
                    ),
                  ),
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
                        horizontal: 16,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
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
                      child: Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: theme.colorScheme.onPrimary,
                      ),
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
