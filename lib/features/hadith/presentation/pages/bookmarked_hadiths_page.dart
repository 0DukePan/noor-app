import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/services/hadith_user_data_service.dart';
import '../../../../core/theme/design_system.dart';
import 'hadith_reader_page.dart';

/// صفحة المحفوظات - Bookmarked Hadiths Page
class BookmarkedHadithsPage extends StatefulWidget {
  const BookmarkedHadithsPage({super.key});

  @override
  State<BookmarkedHadithsPage> createState() => _BookmarkedHadithsPageState();
}

class _BookmarkedHadithsPageState extends State<BookmarkedHadithsPage> {
  List<Map<String, dynamic>> _bookmarks = [];

  static const Map<String, String> _collectionNames = {
    'bukhari': 'صحيح البخاري',
    'muslim': 'صحيح مسلم',
    'abudawud': 'سنن أبي داود',
    'tirmidhi': 'جامع الترمذي',
    'nasai': 'سنن النسائي',
    'ibnmajah': 'سنن ابن ماجه',
    'malik': 'موطأ مالك',
    'ahmed': 'مسند أحمد',
    'darimi': 'سنن الدارمي',
    'nawawi40': 'الأربعون النووية',
    'qudsi40': 'الأحاديث القدسية',
  };

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarks = HadithUserDataService.getAllBookmarks();
    });
  }

  void _removeBookmark(String collectionId, int hadithId) async {
    HapticFeedback.lightImpact();
    await HadithUserDataService.removeBookmark(collectionId, hadithId);
    _loadBookmarks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إزالة الحديث من المحفوظات', style: GoogleFonts.cairo()),
          backgroundColor: Colors.grey[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: Text(
          'المحفوظات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: NoorDesignSystem.creamWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_bookmarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NoorDesignSystem.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_bookmarks.length}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: NoorDesignSystem.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _bookmarks.isEmpty ? _buildEmptyState() : _buildBookmarksList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 72,
            color: NoorDesignSystem.textSecondary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد أحاديث محفوظة',
            style: GoogleFonts.cairo(
              color: NoorDesignSystem.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على أيقونة الحفظ أثناء قراءة الحديث',
            style: GoogleFonts.cairo(
              color: NoorDesignSystem.textSecondary.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = _bookmarks[index];
        final collectionId = bookmark['collectionId'] as String? ?? '';
        final hadithId = bookmark['hadithId'] as int? ?? 0;
        final arabic = bookmark['arabic'] as String? ?? '';
        final englishText = bookmark['englishText'] as String? ?? '';
        final narrator = bookmark['narrator'] as String? ?? '';
        final idInBook = bookmark['idInBook'] as int? ?? 0;

        final hadith = Hadith(
          id: hadithId,
          idInBook: idInBook,
          arabic: arabic,
          englishText: englishText,
          narratorEnglish: narrator,
          chapterId: 0,
          collectionId: collectionId,
        );

        return Dismissible(
          key: Key('${collectionId}_$hadithId'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          onDismissed: (_) => _removeBookmark(collectionId, hadithId),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: NoorDesignSystem.primaryGreen.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HadithReaderPage(
                        hadith: hadith,
                        bookTitle: _collectionNames[collectionId] ?? collectionId,
                        chapterTitle: '',
                        bookColor: NoorDesignSystem.emeraldGreen,
                        allHadiths: [hadith],
                        currentIndex: 0,
                      ),
                    ),
                  ).then((_) => _loadBookmarks()); // Refresh after coming back
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Header
                      Row(
                        children: [
                          // Collection badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: NoorDesignSystem.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _collectionNames[collectionId] ?? collectionId,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: NoorDesignSystem.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Hadith number
                          Text(
                            'حديث رقم $idInBook',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: NoorDesignSystem.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Remove button
                          GestureDetector(
                            onTap: () => _removeBookmark(collectionId, hadithId),
                            child: Icon(
                              Icons.bookmark_rounded,
                              size: 20,
                              color: NoorDesignSystem.goldAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Arabic text preview
                      Text(
                        arabic.length > 200 ? '${arabic.substring(0, 200)}...' : arabic,
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          height: 1.8,
                          color: NoorDesignSystem.textPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.justify,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (narrator.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          narrator,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: NoorDesignSystem.textSecondary,
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
          ),
        );
      },
    );
  }
}
