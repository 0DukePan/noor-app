import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/theme/design_system.dart';
import '../providers/hadith_providers.dart';
import 'hadith_reader_page.dart';

/// صفحة أحاديث باب معين - Hadiths within a specific Chapter
///
/// Loads hadiths lazily in pages of `pageSize` instead of loading the whole
/// book into memory (important for large collections).
class HadithChapterHadithsPage extends ConsumerStatefulWidget {

  const HadithChapterHadithsPage({
    required this.bookId, required this.bookTitle, required this.chapterId, required this.chapterTitle, required this.bookColor, super.key,
  });
  final String bookId;
  final String bookTitle;
  final int? chapterId; // null = show all
  final String chapterTitle;
  final Color bookColor;

  @override
  ConsumerState<HadithChapterHadithsPage> createState() =>
      _HadithChapterHadithsPageState();
}

class _HadithChapterHadithsPageState
    extends ConsumerState<HadithChapterHadithsPage> {
  static const _pageSize = 50;

  final _scrollController = ScrollController();
  final List<Hadith> _hadiths = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300 && !_isLoading && _hasMore) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final ds = ref.read(localHadithDataSourceProvider);
      final results = await ds.getHadithsPage(
        bookId: widget.bookId,
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
      debugPrint('Failed to load hadith page: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: Text(
          widget.chapterTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: NoorDesignSystem.creamWhite,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading && _hadiths.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _hadiths.isEmpty
              ? const Center(child: Text('لا توجد أحاديث في هذا الباب'))
              : ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _hadiths.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _hadiths.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final hadith = _hadiths[index];
                    return _HadithPreviewCard(
                      hadith: hadith,
                      index: index + 1,
                      bookColor: widget.bookColor,
                      bookTitle: widget.bookTitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => HadithReaderPage(
                              hadith: hadith,
                              bookTitle: widget.bookTitle,
                              chapterTitle: widget.chapterTitle,
                              bookColor: widget.bookColor,
                              allHadiths: _hadiths,
                              currentIndex: index,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

/// بطاقة معاينة حديث - Hadith preview card in list
class _HadithPreviewCard extends StatelessWidget {

  const _HadithPreviewCard({
    required this.hadith,
    required this.index,
    required this.bookColor,
    required this.bookTitle,
    required this.onTap,
  });
  final Hadith hadith;
  final int index;
  final Color bookColor;
  final String bookTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cleanText = hadith.arabic
        .replaceAll(RegExp('<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final preview =
        cleanText.length > 200 ? '${cleanText.substring(0, 200)}...' : cleanText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4,),
                      decoration: BoxDecoration(
                        color: bookColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${hadith.idInBook}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: bookColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.grey.shade400,),
                  ],
                ),
                const SizedBox(height: 14),

                // Arabic text preview
                Text(
                  preview,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    height: 1.9,
                    color: NoorDesignSystem.textPrimary,
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),

                // Narrator
                if (hadith.narratorEnglish.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    hadith.narratorEnglish,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: NoorDesignSystem.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
