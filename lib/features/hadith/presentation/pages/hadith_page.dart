import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/book_card.dart';
import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/services/hadith_user_data_service.dart';
import '../../../../core/data/data_sources/local_hadith_data_source.dart';
import '../providers/hadith_providers.dart';
import 'bookmarked_hadiths_page.dart';
import 'hadith_chapters_page.dart';
import 'hadith_reader_page.dart';
import 'hadith_search_page.dart';

// Daily random hadith provider
final hadithOfTheDayProvider = FutureProvider<Hadith?>((ref) async {
  final ds = ref.watch(localHadithDataSourceProvider);
  return ds.getRandomHadith();
});

/// صفحة مكتبة الحديث - Hadith Library Dashboard
class HadithPage extends ConsumerStatefulWidget {
  const HadithPage({super.key});

  @override
  ConsumerState<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends ConsumerState<HadithPage> {
  Map<String, dynamic>? _lastProgress;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() {
    setState(() {
      _lastProgress = HadithUserDataService.getLastReadingProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(hadithCollectionsProvider);
    final dailyHadith = ref.watch(hadithOfTheDayProvider);

    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── App Bar ───
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: NoorDesignSystem.creamWhite,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      NoorDesignSystem.emeraldGreen.withOpacity(0.1),
                      NoorDesignSystem.creamWhite,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'جوامع الكلم',
                        style: NoorDesignSystem.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مكتبة السنة النبوية الشريفة',
                        style: NoorDesignSystem.textTheme.titleMedium?.copyWith(
                          color: NoorDesignSystem.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // Bookmarks
              IconButton(
                icon: const Icon(Icons.bookmark_rounded),
                tooltip: 'المحفوظات',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookmarkedHadithsPage()),
                  ).then((_) => _loadProgress());
                },
              ),
              // Search
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HadithSearchPage()),
                  );
                },
              ),
            ],
          ),

          // ─── Continue Reading ───
          if (_lastProgress != null)
            SliverToBoxAdapter(
              child: _ContinueReadingCard(
                progress: _lastProgress!,
                onTap: () async {
                  final bookId = _lastProgress!['bookId'] as String;
                  final bookTitle = _lastProgress!['bookTitle'] as String;
                  final colorValue = _lastProgress!['colorValue'] as int;
                  final hadithIndex = _lastProgress!['hadithIndex'] as int;

                  // Load the book's hadiths to open the reader
                  try {
                    final ds = ref.read(localHadithDataSourceProvider);
                    final book = await ds.loadBook(bookId);
                    if (mounted && book.hadiths.isNotEmpty) {
                      final safeIndex = hadithIndex.clamp(0, book.hadiths.length - 1);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HadithReaderPage(
                            hadith: book.hadiths[safeIndex],
                            bookTitle: bookTitle,
                            chapterTitle: '',
                            bookColor: Color(colorValue),
                            allHadiths: book.hadiths,
                            currentIndex: safeIndex,
                          ),
                        ),
                      ).then((_) => _loadProgress());
                    }
                  } catch (e) {
                    // Silently handle errors
                  }
                },
              ),
            ),

          // ─── Hadith of the Day ───
          SliverToBoxAdapter(
            child: dailyHadith.when(
              data: (hadith) {
                if (hadith == null) return const SizedBox.shrink();
                return _HadithOfTheDayCard(
                  hadith: hadith,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HadithReaderPage(
                          hadith: hadith,
                          bookTitle: hadith.collectionId ?? '',
                          chapterTitle: '',
                          bookColor: NoorDesignSystem.emeraldGreen,
                          allHadiths: [hadith],
                          currentIndex: 0,
                        ),
                      ),
                    ).then((_) => _loadProgress());
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ─── Section Header: Books ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الكتب والمجاميع', style: NoorDesignSystem.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'اختر كتاباً لتصفح الأحاديث',
                    style: NoorDesignSystem.textTheme.labelMedium?.copyWith(
                      color: NoorDesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Books Grid ───
          collectionsAsync.when(
            data: (collections) {
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = collections[index];
                      return BookCard(
                        title: book.titleArabic,
                        subtitle: 'مجموعة أحاديث',
                        count: book.hadithsCount,
                        color: _getBookColor(book.id),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HadithChaptersPage(
                                bookId: book.id,
                                bookTitle: book.titleArabic,
                                bookColor: _getBookColor(book.id),
                              ),
                            ),
                          ).then((_) => _loadProgress());
                        },
                      );
                    },
                    childCount: collections.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => SliverFillRemaining(
              child: Center(child: Text('حدث خطأ: $e')),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Color _getBookColor(String id) {
    if (id.contains('bukhari')) return NoorDesignSystem.bukhariColor;
    if (id.contains('muslim')) return NoorDesignSystem.muslimColor;
    if (id.contains('abudawud')) return NoorDesignSystem.abuDawudColor;
    if (id.contains('tirmidhi')) return NoorDesignSystem.tirmidhiColor;
    if (id.contains('nasai')) return NoorDesignSystem.nasaiColor;
    if (id.contains('ibnmajah')) return NoorDesignSystem.ibnMajahColor;
    if (id.contains('malik')) return NoorDesignSystem.malikColor;
    if (id.contains('darimi')) return NoorDesignSystem.darimiColor;
    return NoorDesignSystem.emeraldGreen;
  }
}

// ═══════════════════════════════════════════════════════════════════
// CONTINUE READING CARD
// ═══════════════════════════════════════════════════════════════════

class _ContinueReadingCard extends StatelessWidget {
  final Map<String, dynamic> progress;
  final VoidCallback onTap;

  const _ContinueReadingCard({required this.progress, required this.onTap});

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
  };

  @override
  Widget build(BuildContext context) {
    final bookId = progress['bookId'] as String? ?? '';
    final bookTitle = _collectionNames[bookId] ?? progress['bookTitle'] as String? ?? '';
    final hadithIndex = progress['hadithIndex'] as int? ?? 0;
    final totalHadiths = progress['totalHadiths'] as int? ?? 1;
    final colorValue = progress['colorValue'] as int? ?? NoorDesignSystem.emeraldGreen.value;
    final bookColor = Color(colorValue);

    final progressRatio = totalHadiths > 0 ? (hadithIndex + 1) / totalHadiths : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bookColor.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: bookColor.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bookColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_rounded, color: bookColor, size: 24),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مواصلة القراءة',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: NoorDesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$bookTitle  •  حديث ${hadithIndex + 1} / $totalHadiths',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: NoorDesignSystem.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        backgroundColor: bookColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(bookColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: bookColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HADITH OF THE DAY CARD
// ═══════════════════════════════════════════════════════════════════

class _HadithOfTheDayCard extends StatelessWidget {
  final Hadith hadith;
  final VoidCallback onTap;

  const _HadithOfTheDayCard({required this.hadith, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF388E3C),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative pattern
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 100,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wb_sunny_rounded, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                'حديث اليوم',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Arabic text preview
                    Text(
                      hadith.arabic.length > 150
                          ? '${hadith.arabic.substring(0, 150)}...'
                          : hadith.arabic,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        height: 1.8,
                        color: Colors.white,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.justify,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Read more
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'اقرأ المزيد',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white70),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
