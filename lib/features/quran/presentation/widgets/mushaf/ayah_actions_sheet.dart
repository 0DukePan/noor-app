import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/data/data_sources/tafsir_database.dart';
import '../../../../../core/domain/entities/surah.dart';
import '../../../../../core/models/tafsir_models.dart';
import '../../../../../core/services/tafsir_data_source.dart';
import '../../../../../core/theme/tafsir_theme.dart';
import '../../../../../core/widgets/tafsir_state_view.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../pages/tafsir_reader_page.dart';
import 'mushaf_controls.dart';
import 'mushaf_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AYAH ACTION SHEET (Tap-to-Tafsir)
// ═══════════════════════════════════════════════════════════════════════════

/// Bottom sheet for one tapped ayah: large Uthmani text, copy/save/share
/// actions, Tafsir preview with truthful availability, and a full-reader
/// entry point. Adds no visible cards to the Mushaf page itself.
class AyahActionsSheet extends StatefulWidget {
  const AyahActionsSheet({
    required this.verse,
    required this.themeData,
    super.key,
  });
  final Verse verse;
  final MushafThemeData themeData;

  @override
  State<AyahActionsSheet> createState() => _AyahActionsSheetState();
}

class _AyahActionsSheetState extends State<AyahActionsSheet> {
  TafsirEntry? _tafsirEntry;
  bool _loadingTafsir = true;
  bool _tafsirExpanded = false;

  /// True when the lookup itself failed (copy/open/storage). Distinct from
  /// "no row for this ayah" (TAF-01): failures get retry, gaps get truth.
  bool _tafsirFailed = false;

  @override
  void initState() {
    super.initState();
    _loadTafsir();
  }

  Future<void> _loadTafsir() async {
    if (mounted) {
      setState(() {
        _loadingTafsir = true;
        _tafsirFailed = false;
      });
    }
    try {
      final entry = await TafsirDataSource.getAyahTafsir(
        surah: widget.verse.surahNumber,
        ayah: widget.verse.numberInSurah,
      );
      if (mounted) {
        setState(() {
          _tafsirEntry = entry;
          _loadingTafsir = false;
          _tafsirFailed = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _tafsirEntry = null;
          _loadingTafsir = false;
          _tafsirFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            color: Colors.black.withValues(alpha: 0.3),
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
                  color: td.textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Surah + Ayah label
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: td.headerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Semantics(
                  header: true,
                  label: l10n.mushafAyahLabel(
                    verse.surahName ?? l10n.surahFallback(verse.surahNumber),
                    verse.numberInSurah,
                  ),
                  child: Text(
                    l10n.mushafAyahLabel(
                      verse.surahName ?? l10n.surahFallback(verse.surahNumber),
                      verse.numberInSurah,
                    ),
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: td.headerColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ayah text in large Uthmani script
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: td.headerColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: td.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                verse.textUthmani,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 26,
                  height: 2,
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
                MushafActionButton(
                  icon: Icons.copy_rounded,
                  label: l10n.mushafCopy,
                  color: td.headerColor,
                  bgColor: td.headerColor.withValues(alpha: 0.1),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: verse.textUthmani));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.verseCopied),
                        backgroundColor: td.headerColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
                MushafActionButton(
                  icon: Icons.bookmark_add_rounded,
                  label: l10n.mushafSave,
                  color: const Color(0xFFE8A838),
                  bgColor: const Color(0xFFE8A838).withValues(alpha: 0.1),
                  onTap: () async {
                    await TafsirDataSource.addBookmark(
                      surah: verse.surahNumber,
                      ayah: verse.numberInSurah,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.mushafSaved),
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
                MushafActionButton(
                  icon: Icons.share_rounded,
                  label: l10n.verseShare,
                  color: const Color(0xFF5C6BC0),
                  bgColor: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                  onTap: () {
                    final shareText = l10n.mushafShareTemplate(
                      verse.textUthmani,
                      verse.surahName ?? l10n.surahFallback(verse.surahNumber),
                      verse.numberInSurah,
                    );
                    Clipboard.setData(ClipboardData(text: shareText));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.mushafShareCopied),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: td.headerColor.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: td.headerColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.mushafTafsirTitle,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: td.headerColor,
                          ),
                        ),
                        const Spacer(),
                        if (_tafsirEntry != null)
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton(
                              tooltip: l10n.mushafReadMore,
                              onPressed: () => setState(
                                () => _tafsirExpanded = !_tafsirExpanded,
                              ),
                              icon: Icon(
                                _tafsirExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: td.headerColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Tafsir body — one shared view contract (TAF-02).
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TafsirStateView(
                      state: _viewState(),
                      contentBuilder: (entry) => _excerptColumn(context, entry),
                      onRetry: _loadTafsir,
                      emptyText: l10n.mushafTafsirMissing,
                      failureText: l10n.tafsirStateStorageFailure,
                      retryText: l10n.tafsirRetry,
                      textColor: td.textColor,
                      accentColor: td.verseMarkerColor,
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
                    FadeThroughPageRoute<void>(
                      page: TafsirReaderPage(
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
                      const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.mushafOpenFull,
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

  /// Maps the lookup outcome onto the shared view contract (TAF-02):
  /// explicit failure, empty-corpus storage failure, missing row, or content.
  TafsirViewState _viewState() {
    if (_loadingTafsir) return const TafsirViewLoading();
    if (_tafsirFailed) {
      return const TafsirViewFailure(TafsirAvailability.storageFailure);
    }
    if (TafsirDatabase.isServingEmptyFallback) {
      return const TafsirViewFailure(TafsirAvailability.storageFailure);
    }
    final entry = _tafsirEntry;
    if (entry == null) {
      return const TafsirViewEmpty(TafsirAvailability.rowMissing);
    }
    return TafsirViewContent(entry);
  }

  /// Excerpt content for [TafsirViewContent]: truncated prose with an
  /// explicit expand action (never a bare GestureDetector). Invoked only
  /// when an entry is present.
  Widget _excerptColumn(BuildContext context, TafsirEntry entry) {
    final l10n = AppLocalizations.of(context);
    final td = widget.themeData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _tafsirExpanded ? entry.text : _truncate(entry.text, 200),
          style: GoogleFonts.cairo(
            fontSize: 15,
            height: 1.9,
            color: td.textColor.withValues(alpha: 0.85),
          ),
          textDirection: TextDirection.rtl,
        ),
        if (!_tafsirExpanded && entry.text.length > 200) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => setState(() => _tafsirExpanded = true),
              child: Text(
                l10n.mushafReadMore,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: td.headerColor,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
