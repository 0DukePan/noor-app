import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/domain/entities/surah.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/quran_providers.dart';
import 'mushaf_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MUSHAF PAGE CANVAS — one complete fixed page, never a nested scroll (QUR-03)
// ═══════════════════════════════════════════════════════════════════════════

/// A single fixed Mushaf page: header zone, continuous text frame, footer
/// zone. Loading, empty, error, and retry share this frame (QUR-05).
class MushafPageCanvas extends ConsumerWidget {
  const MushafPageCanvas({
    required this.pageNumber,
    required this.themeData,
    this.onAyahAction,
    this.onVerseTap,
    super.key,
  });
  final int pageNumber;
  final MushafThemeData themeData;

  /// Fired when an ayah action starts (lets the reader suppress the
  /// blank-tap control toggle for the sheet-opening tap).
  final VoidCallback? onAyahAction;

  /// Opens the ayah action sheet for the tapped verse.
  final ValueChanged<Verse>? onVerseTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(quranPageProvider(pageNumber));
    final zoom = ref.watch(mushafZoomProvider);

    return versesAsync.when(
      data: (verses) {
        if (verses.isEmpty) {
          return MushafFrame(
            themeData: themeData,
            pageNumber: pageNumber,
            header: MushafPageHeader(
              surahName: '',
              juz: 0,
              pageNumber: pageNumber,
              themeData: themeData,
            ),
            body: Center(
              child: Text(
                AppLocalizations.of(context).mushafEmpty,
                style: TextStyle(color: themeData.textColor),
              ),
            ),
          );
        }

        final firstSurahName = verses.first.surahName ?? '';
        return MushafFrame(
          themeData: themeData,
          pageNumber: pageNumber,
          header: MushafPageHeader(
            surahName: firstSurahName,
            juz: verses.first.juz,
            pageNumber: pageNumber,
            themeData: themeData,
          ),
          body: MushafTextRegion(
            pageNumber: pageNumber,
            verses: verses,
            themeData: themeData,
            baseFontSize: 24 * zoom,
            onVerseTap: (verse) {
              onAyahAction?.call();
              onVerseTap?.call(verse);
            },
          ),
        );
      },
      loading: () => MushafFrame(
        themeData: themeData,
        pageNumber: pageNumber,
        header: MushafPageHeader(
          surahName: '',
          juz: 0,
          pageNumber: pageNumber,
          themeData: themeData,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: themeData.verseMarkerColor,
            strokeWidth: 2,
          ),
        ),
      ),
      // QUR-05: localized error pane with retry + safe diagnostics.
      error: (e, _) => MushafFrame(
        themeData: themeData,
        pageNumber: pageNumber,
        header: MushafPageHeader(
          surahName: '',
          juz: 0,
          pageNumber: pageNumber,
          themeData: themeData,
        ),
        body: MushafErrorPane(
          themeData: themeData,
          pageNumber: pageNumber,
          onRetry: () => ref.refresh(quranPageProvider(pageNumber)),
        ),
      ),
    );
  }
}

/// Same page frame for loading, empty, error, and retry states (QUR-05).
/// Controls never overlap text: header/text/footer zones are reserved.
class MushafFrame extends StatelessWidget {
  const MushafFrame({
    required this.themeData,
    required this.pageNumber,
    required this.header,
    required this.body,
    super.key,
  });
  final MushafThemeData themeData;
  final int pageNumber;
  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 40),
          header,
          const SizedBox(height: 12),
          // Fixed canvas: expanded text frame, no nested scroll.
          Expanded(child: body),
          MushafPageFooter(pageNumber: pageNumber, themeData: themeData),
        ],
      ),
    );
  }
}

/// Footer announces "Page N of 604" semantically (QUR-03).
class MushafPageFooter extends StatelessWidget {
  const MushafPageFooter({
    required this.pageNumber,
    required this.themeData,
    super.key,
  });
  final int pageNumber;
  final MushafThemeData themeData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        label: AppLocalizations.of(context).mushafPageIndicator(pageNumber),
        excludeSemantics: false,
        child: Text(
          '$pageNumber',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: themeData.verseMarkerColor.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Localized error pane with retry + non-sensitive diagnostic ID (QUR-05).
/// Never shows raw exceptions.
class MushafErrorPane extends StatelessWidget {
  const MushafErrorPane({
    required this.themeData,
    required this.pageNumber,
    required this.onRetry,
    super.key,
  });
  final MushafThemeData themeData;
  final int pageNumber;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: themeData.verseMarkerColor,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.mushafError(''),
              style: TextStyle(color: themeData.textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.mushafDiagnosticId('p$pageNumber'),
              style: TextStyle(
                color: themeData.textColor.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const Key('mushafRetryButton'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.mushafRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal header zone (QUR-03): surah context + juz context, no injected
/// basmala, no modern card chrome inside the text frame.
class MushafPageHeader extends StatelessWidget {
  const MushafPageHeader({
    required this.surahName,
    required this.juz,
    required this.pageNumber,
    required this.themeData,
    super.key,
  });
  final String surahName;
  final int juz;
  final int pageNumber;
  final MushafThemeData themeData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      header: true,
      label: l10n.mushafPageSemantics(pageNumber, surahName, juz),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              surahName,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: themeData.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              juz > 0 ? l10n.mushafJuz(juz) : '',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: themeData.textColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Continuous Arabic text region (QUR-03): one semantic RTL text region per
/// surah segment, pinch zoom/pan with reset — never a nested vertical
/// scroll. A new surah starts with a metadata ornament only (QUR-02): the
/// renderer never injects Qur'an text such as a hard-coded basmala.
class MushafTextRegion extends StatelessWidget {
  const MushafTextRegion({
    required this.pageNumber,
    required this.verses,
    required this.themeData,
    required this.baseFontSize,
    this.onVerseTap,
    super.key,
  });
  final int pageNumber;
  final List<Verse> verses;
  final MushafThemeData themeData;
  final double baseFontSize;
  final ValueChanged<Verse>? onVerseTap;

  /// Detect which verses start a new surah on this page.
  static Set<int> detectSurahStarts(List<Verse> verses) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surahStarts = detectSurahStarts(verses);
    final children = <Widget>[];

    var i = 0;
    while (i < verses.length) {
      if (surahStarts.contains(i)) {
        final verse = verses[i];
        children.add(
          SurahStartBanner(
            surahName:
                verse.surahName ??
                AppLocalizations.of(context).surahFallback(verse.surahNumber),
            themeData: themeData,
          ),
        );
      }

      // Collect all consecutive verses from the same surah segment.
      final segmentStart = i;
      final currentSurah = verses[i].surahNumber;
      while (i < verses.length &&
          verses[i].surahNumber == currentSurah &&
          !(i != segmentStart && surahStarts.contains(i))) {
        i++;
      }

      final segmentVerses = verses.sublist(segmentStart, i);
      children.add(
        ContinuousVerseBlock(
          verses: segmentVerses,
          themeData: themeData,
          baseFontSize: baseFontSize,
          onVerseTap: onVerseTap,
        ),
      );
    }

    final firstName =
        verses.first.surahName ?? l10n.surahFallback(verses.first.surahNumber);
    return Semantics(
      container: true,
      readOnly: true,
      label: l10n.mushafPageSemantics(pageNumber, firstName, verses.first.juz),
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 2.5,
        panEnabled: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Surah heading ornament (QUR-02): metadata only. Never carries Qur'an
/// text — in particular never a hard-coded basmala.
class SurahStartBanner extends StatelessWidget {
  const SurahStartBanner({
    required this.surahName,
    required this.themeData,
    super.key,
  });
  final String surahName;
  final MushafThemeData themeData;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: false,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: themeData.borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: themeData.headerColor.withValues(alpha: 0.06),
        ),
        child: Semantics(
          header: true,
          label: surahName,
          child: Text(
            surahName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ).copyWith(color: themeData.textColor),
          ),
        ),
      ),
    );
  }
}

/// One tappable continuous verse segment with an explicitly managed
/// recognizer lifecycle (QUR-06).
class ContinuousVerseBlock extends StatefulWidget {
  const ContinuousVerseBlock({
    required this.verses,
    required this.themeData,
    this.baseFontSize = 24,
    this.onVerseTap,
    super.key,
  });
  final List<Verse> verses;
  final MushafThemeData themeData;
  final double baseFontSize;
  final ValueChanged<Verse>? onVerseTap;

  @override
  State<ContinuousVerseBlock> createState() => _ContinuousVerseBlockState();
}

class _ContinuousVerseBlockState extends State<ContinuousVerseBlock> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _buildRecognizers();
  }

  @override
  void didUpdateWidget(covariant ContinuousVerseBlock oldWidget) {
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
      // Verse text (tappable). The bundled Amiri font is used directly —
      // never fetched at runtime. No semanticsLabel here: it would replace
      // the verse words in TextSpan.toPlainText and break text search,
      // selection, and copy. Per-ayah identity is exposed through the tap
      // recognizer (link node) and the page/ayah semantic labels instead.
      spans.add(
        TextSpan(
          text: verse.textUthmani,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: widget.baseFontSize,
            height: 2.2,
            color: widget.themeData.textColor,
            fontWeight: FontWeight.w500,
          ),
          recognizer: _recognizers[idx],
        ),
      );

      // End-of-ayah marker inline in the natural text flow (QUR-03),
      // joined to its ayah by a word-joiner so it cannot begin an
      // unrelated line. Empty semantics: ornaments are never read as prose.
      spans.add(
        TextSpan(
          text:
              '\u00A0\u2060\uFD3F${toArabicNumeral(verse.numberInSurah)}\uFD3E ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            color: widget.themeData.verseMarkerColor,
            fontWeight: FontWeight.bold,
          ),
          recognizer: _recognizers[idx],
          semanticsLabel: '',
        ),
      );
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
}

/// Safe Arabic-numeral conversion: non-digit input can never throw.
String toArabicNumeral(int number) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final clamped = number < 0 ? 0 : number;
  return clamped.toString().split('').map((d) {
    final parsed = int.tryParse(d);
    if (parsed == null) return d;
    return arabicDigits[parsed];
  }).join();
}
