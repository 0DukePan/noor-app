import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/hadith_providers.dart';
import 'hadith_chapter_hadiths_page.dart';

/// صفحة أبواب الكتاب - Hadith Chapters (Books) Browser
/// Collection → **Chapters** → Hadiths
class HadithChaptersPage extends ConsumerWidget {

  const HadithChaptersPage({
    required this.bookId, required this.bookTitle, required this.bookColor, super.key,
  });
  final String bookId;
  final String bookTitle;
  final Color bookColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(hadithBookSummaryProvider(bookId));
    final countsAsync = ref.watch(hadithChapterCountsProvider(bookId));

    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      body: bookAsync.when(
        data: (book) => countsAsync.when(
          data: (counts) => _buildContent(context, book, counts),
          loading: () => _buildLoading(context),
          error: (e, s) => _buildError(context, e),
        ),
        loading: () => _buildLoading(context),
        error: (e, s) => _buildError(context, e),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(null),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context).hchLoading),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).hchError,
                style: GoogleFonts.cairo(fontSize: 16),),
            const SizedBox(height: 8),
            Text(error.toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 12),),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HadithBook book, Map<int, int> chapterCounts) {
    final l10n = AppLocalizations.of(context);
    final chapters = book.chapters;
    final totalHadiths = chapterCounts.values.fold<int>(0, (sum, v) => sum + v);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(book),

        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.menu_book_rounded,
                  label: l10n.hchChapters(chapters.length),
                  color: bookColor,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.format_quote_rounded,
                  label: l10n.topicHadithCount(totalHadiths),
                  color: NoorDesignSystem.goldAccent,
                ),
              ],
            ),
          ),
        ),

        // "View All Hadiths" button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: bookColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => HadithChapterHadithsPage(
                        bookId: bookId,
                        bookTitle: bookTitle,
                        chapterId: null, // null = all hadiths
                        chapterTitle: l10n.hchAllTitle,
                        bookColor: bookColor,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt_rounded, color: bookColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.hchViewAll,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: bookColor,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_back_ios_new_rounded,
                          size: 14, color: bookColor.withValues(alpha: 0.6),),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Section title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              l10n.hchSection,
              style: NoorDesignSystem.textTheme.titleLarge,
            ),
          ),
        ),

        // Chapters list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chapter = chapters[index];
                final count = chapterCounts[chapter.id] ?? 0;
                return _ChapterTile(
                  chapter: chapter,
                  index: index + 1,
                  hadithCount: count,
                  bookColor: bookColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => HadithChapterHadithsPage(
                          bookId: bookId,
                          bookTitle: bookTitle,
                          chapterId: chapter.id,
                          chapterTitle: chapter.topicArabic,
                          bookColor: bookColor,
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: chapters.length,
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(HadithBook? book) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: bookColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bookColor,
                bookColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Text(
                  bookTitle,
                  style: GoogleFonts.amiri(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (book != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    book.metadata.author,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
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

// ─────────────────────────────────────────────────────────
// SUPPORTING WIDGETS
// ─────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {

  const _ChapterTile({
    required this.chapter,
    required this.index,
    required this.hadithCount,
    required this.bookColor,
    required this.onTap,
  });
  final HadithChapter chapter;
  final int index;
  final int hadithCount;
  final Color bookColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Chapter number
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bookColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$index',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: bookColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Chapter title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.topicArabic,
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: NoorDesignSystem.textPrimary,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                      ),
                      if (chapter.topicEnglish.isNotEmpty)
                        Text(
                          chapter.topicEnglish,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: NoorDesignSystem.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Hadith count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$hadithCount',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: bookColor,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).hchHadithUnit,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: NoorDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: Colors.grey.shade400,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
