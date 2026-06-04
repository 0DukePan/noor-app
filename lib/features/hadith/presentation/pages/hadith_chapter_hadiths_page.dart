import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/domain/entities/hadith.dart';
import '../providers/hadith_providers.dart';
import 'hadith_reader_page.dart';

/// صفحة أحاديث باب معين - Hadiths within a specific Chapter
class HadithChapterHadithsPage extends ConsumerWidget {
  final String bookId;
  final String bookTitle;
  final int? chapterId; // null = show all
  final String chapterTitle;
  final Color bookColor;

  const HadithChapterHadithsPage({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.chapterId,
    required this.chapterTitle,
    required this.bookColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(hadithBookProvider(bookId));

    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: Text(
          chapterTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: NoorDesignSystem.creamWhite,
        surfaceTintColor: Colors.transparent,
      ),
      body: bookAsync.when(
        data: (book) {
          final hadiths = chapterId != null
              ? book.hadiths.where((h) => h.chapterId == chapterId).toList()
              : book.hadiths;

          if (hadiths.isEmpty) {
            return const Center(child: Text('لا توجد أحاديث في هذا الباب'));
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: hadiths.length,
            itemBuilder: (context, index) {
              final hadith = hadiths[index];
              return _HadithPreviewCard(
                hadith: hadith,
                index: index + 1,
                bookColor: bookColor,
                bookTitle: bookTitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HadithReaderPage(
                        hadith: hadith,
                        bookTitle: bookTitle,
                        chapterTitle: chapterTitle,
                        bookColor: bookColor,
                        allHadiths: hadiths,
                        currentIndex: index,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('حدث خطأ: $e')),
      ),
    );
  }
}

/// بطاقة معاينة حديث - Hadith preview card in list
class _HadithPreviewCard extends StatelessWidget {
  final Hadith hadith;
  final int index;
  final Color bookColor;
  final String bookTitle;
  final VoidCallback onTap;

  const _HadithPreviewCard({
    required this.hadith,
    required this.index,
    required this.bookColor,
    required this.bookTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanText = hadith.arabic
        .replaceAll(RegExp(r'<[^>]*>'), '')
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
        shadowColor: Colors.black.withOpacity(0.04),
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
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bookColor.withOpacity(0.1),
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
                        size: 14, color: Colors.grey.shade400),
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
