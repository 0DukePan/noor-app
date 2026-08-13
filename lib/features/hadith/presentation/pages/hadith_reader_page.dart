import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/services/hadith_user_data_service.dart';
import '../../../../core/theme/design_system.dart';
import '../providers/hadith_providers.dart';
import '../widgets/hadith_share_sheet.dart';
import '../widgets/hadith_sharh_sheet.dart';

/// صفحة قراءة الحديث - Immersive Hadith Reader
///
/// Supports two modes:
/// - Bounded: `allHadiths` is the full list (search results, hadith of day).
/// - Paged: pass `bookId` + `chapterId` (+ optionally `startIdInBook`) and
///   the reader loads the chapter lazily from SQLite, so large chapters can
///   be read end-to-end without loading the whole book.
class HadithReaderPage extends ConsumerStatefulWidget {

  const HadithReaderPage({
    required this.hadith, required this.bookTitle, required this.chapterTitle, required this.bookColor, required this.allHadiths, required this.currentIndex,
    this.bookId,
    this.chapterId,
    this.startIdInBook,
    super.key,
  });
  final Hadith hadith;
  final String bookTitle;
  final String chapterTitle;
  final Color bookColor;
  final List<Hadith> allHadiths;
  final int currentIndex;
  final String? bookId;
  final int? chapterId;
  final int? startIdInBook;

  @override
  ConsumerState<HadithReaderPage> createState() => _HadithReaderPageState();
}

class _HadithReaderPageState extends ConsumerState<HadithReaderPage> {
  static const _pageSize = 50;

  late PageController _pageController;
  late int _currentIndex;
  bool _isBookmarked = false;

  final List<Hadith> _hadiths = [];
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;

  bool get _lazyMode => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    _hadiths.addAll(widget.allHadiths);
    _currentIndex = widget.currentIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _updateBookmarkState();
    _saveProgress();
    if (_lazyMode) _loadUntilTarget();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Load pages until the target hadith (by its in-book number) is present.
  Future<void> _loadUntilTarget() async {
    final targetNumber = widget.startIdInBook ?? widget.hadith.idInBook;
    if (_hadiths.any((h) => h.idInBook == targetNumber)) return;
    while (_hasMore && !_isLoading) {
      final before = _hadiths.length;
      await _loadPage();
      if (!mounted || _hadiths.length == before) return;
      final idx = _hadiths.indexWhere((h) => h.idInBook == targetNumber);
      if (idx != -1) {
        setState(() => _currentIndex = idx);
        _pageController.jumpToPage(idx);
        _updateBookmarkState();
        _saveProgress();
        return;
      }
    }
  }

  Future<void> _loadPage() async {
    if (_isLoading || !_hasMore || widget.bookId == null) return;
    setState(() => _isLoading = true);
    try {
      final ds = ref.read(localHadithDataSourceProvider);
      final results = await ds.getHadithsPage(
        bookId: widget.bookId!,
        page: _page,
        limit: _pageSize,
        chapterId: widget.chapterId,
      );
      if (!mounted) return;
      setState(() {
        _hadiths.addAll(results);
        _hasMore = results.length == _pageSize;
        _page++;
        _isLoading = false;
      });
    } on Exception catch (e) {
      debugPrint('Failed to load reader page: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateBookmarkState() {
    if (_hadiths.isEmpty) return;
    setState(() {
      _isBookmarked = HadithUserDataService.isBookmarked(
        _currentHadith.collectionId,
        _currentHadith.id,
      );
    });
  }

  void _saveProgress() {
    if (_hadiths.isEmpty) return;
    HadithUserDataService.saveReadingProgress(
      bookId: _currentHadith.collectionId ?? widget.bookId ?? widget.bookTitle,
      bookTitle: widget.bookTitle,
      colorValue: widget.bookColor.toARGB32(),
      hadithIndex: _currentIndex,
      totalHadiths: _hadiths.length,
      chapterId: _currentHadith.chapterId,
      hadithNumber: _currentHadith.idInBook,
    );
  }

  Future<void> _toggleBookmark() async {
    unawaited(HapticFeedback.mediumImpact());
    final nowBookmarked = await HadithUserDataService.toggleBookmark(_currentHadith);
    if (!mounted) return;
    setState(() => _isBookmarked = nowBookmarked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowBookmarked ? 'تمت إضافة الحديث للمحفوظات' : 'تمت إزالة الحديث من المحفوظات',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: nowBookmarked ? NoorDesignSystem.primaryGreen : Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Hadith get _currentHadith => _hadiths[_currentIndex];

  void _copyHadith() {
    final text =
        '${_currentHadith.arabic}\n\n${_currentHadith.narratorEnglish}\n\n— ${widget.bookTitle} #${_currentHadith.idInBook}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ الحديث', style: GoogleFonts.cairo()),
        backgroundColor: NoorDesignSystem.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareHadith() {
    HadithShareSheet.show(
      context,
      hadith: _currentHadith,
      bookTitle: widget.bookTitle,
      bookColor: widget.bookColor,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    HapticFeedback.selectionClick();
    _updateBookmarkState();
    _saveProgress();
    // Preload the next page before the reader runs out.
    if (_lazyMode && index >= _hadiths.length - 3 && !_isLoading && _hasMore) {
      _loadPage();
    }
  }

  Future<void> _goPrevious() async {
    if (_currentIndex > 0) {
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _goNext() async {
    if (_currentIndex < _hadiths.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_hasMore) {
      await _loadPage();
      if (mounted && _currentIndex < _hadiths.length - 1) {
        await _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: NoorDesignSystem.textPrimary,
        title: Text(
          '${widget.bookTitle} — #${_currentHadith.idInBook}',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          // Sharh button (prominent)
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, size: 22),
            onPressed: () => HadithSharhSheet.show(
              context,
              hadith: _currentHadith,
              bookTitle: widget.bookTitle,
              bookColor: widget.bookColor,
            ),
            tooltip: 'شرح',
          ),
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 22,
              color: _isBookmarked ? NoorDesignSystem.goldAccent : null,
            ),
            onPressed: _toggleBookmark,
            tooltip: 'حفظ',
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: _copyHadith,
            tooltip: 'نسخ',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: _shareHadith,
            tooltip: 'مشاركة',
          ),
        ],
      ),
      body: _hadiths.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              itemCount: _hadiths.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final hadith = _hadiths[index];
                return _HadithReaderContent(
                  hadith: hadith,
                  bookTitle: widget.bookTitle,
                  chapterTitle: widget.chapterTitle,
                  bookColor: widget.bookColor,
                  index: index + 1,
                  total: _hadiths.length,
                );
              },
            ),
      // Bottom navigation
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        total: _hadiths.length,
        bookColor: widget.bookColor,
        onPrevious: _currentIndex > 0 ? _goPrevious : null,
        onNext: _currentIndex < _hadiths.length - 1 || _hasMore
            ? _goNext
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// HADITH READER CONTENT
// ─────────────────────────────────────────────────────────

class _HadithReaderContent extends StatelessWidget {

  const _HadithReaderContent({
    required this.hadith,
    required this.bookTitle,
    required this.chapterTitle,
    required this.bookColor,
    required this.index,
    required this.total,
  });
  final Hadith hadith;
  final String bookTitle;
  final String chapterTitle;
  final Color bookColor;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cleanArabic = hadith.arabic
        .replaceAll(RegExp('<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metadata card
          _MetadataCard(
            bookTitle: bookTitle,
            chapterTitle: chapterTitle,
            hadithNumber: hadith.idInBook,
            narrator: hadith.narratorEnglish,
            bookColor: bookColor,
          ),

          const SizedBox(height: 24),

          // ─── Bismillah ornament ───
          Center(
            child: Text(
              '﷽',
              style: GoogleFonts.amiri(
                fontSize: 28,
                color: NoorDesignSystem.goldAccent,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── Arabic Matn (the hadith text) ───
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: bookColor.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: bookColor.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SelectableText(
              cleanArabic,
              style: GoogleFonts.amiri(
                fontSize: 22,
                height: 2,
                color: NoorDesignSystem.textPrimary,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
          ),

          // ─── English Translation ───
          if (hadith.englishText.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.translate_rounded,
                          size: 16, color: NoorDesignSystem.textSecondary,),
                      const SizedBox(width: 6),
                      Text(
                        'Translation',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: NoorDesignSystem.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    hadith.englishText.trim(),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.7,
                      color: NoorDesignSystem.textPrimary.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Page indicator
          Center(
            child: Text(
              '$index / $total',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: NoorDesignSystem.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// METADATA CARD
// ─────────────────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {

  const _MetadataCard({
    required this.bookTitle,
    required this.chapterTitle,
    required this.hadithNumber,
    required this.narrator,
    required this.bookColor,
  });
  final String bookTitle;
  final String chapterTitle;
  final int hadithNumber;
  final String narrator;
  final Color bookColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bookColor.withValues(alpha: 0.08),
            bookColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bookColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          // Book & Hadith number
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 18, color: bookColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bookTitle,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: bookColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bookColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'حديث #$hadithNumber',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: bookColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Chapter
          if (chapterTitle.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.bookmark_border_rounded,
                    size: 16, color: NoorDesignSystem.textSecondary,),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chapterTitle,
                    style: GoogleFonts.amiri(
                      fontSize: 14,
                      color: NoorDesignSystem.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),

          // Narrator
          if (narrator.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 16, color: NoorDesignSystem.textSecondary,),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    narrator,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: NoorDesignSystem.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// BOTTOM NAVIGATION
// ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {

  const _BottomNav({
    required this.currentIndex,
    required this.total,
    required this.bookColor,
    this.onPrevious,
    this.onNext,
  });
  final int currentIndex;
  final int total;
  final Color bookColor;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous
          _NavButton(
            icon: Icons.arrow_back_ios_rounded,
            label: 'السابق',
            onTap: onPrevious,
            color: bookColor,
          ),

          // Progress
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${currentIndex + 1} / $total',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: bookColor,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? (currentIndex + 1) / total : 0,
                    backgroundColor: bookColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(bookColor),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),

          // Next
          _NavButton(
            icon: Icons.arrow_forward_ios_rounded,
            label: 'التالي',
            onTap: onNext,
            color: bookColor,
            isForward: true,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isForward = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool isForward;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isForward) Icon(icon, size: 16, color: color),
            if (!isForward) const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (isForward) const SizedBox(width: 4),
            if (isForward) Icon(icon, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
