import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/services/hadith_user_data_service.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/book_card.dart';
import '../hadith_book_names.dart';
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

  /// Launch a quiz over a real hadith deck (the Nawawi 40 collection).
  Future<void> _startQuiz() async {
    try {
      final ds = ref.read(localHadithDataSourceProvider);
      final hadiths = await ds.getHadithsPage(
        bookId: 'nawawi40',
        page: 1,
        limit: 20,
      );
      if (!mounted || hadiths.isEmpty) return;
      context.go('/hadith/quiz', extra: hadiths);
    } on Exception catch (e) {
      debugPrint('Failed to load quiz deck: $e');
    }
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
                      NoorDesignSystem.emeraldGreen.withValues(alpha: 0.1),
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
                    MaterialPageRoute<void>(builder: (_) => const BookmarkedHadithsPage()),
                  ).then((_) => _loadProgress());
                },
              ),
              // Search
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const HadithSearchPage()),
                  );
                },
              ),
              // Quiz
              IconButton(
                icon: const Icon(Icons.quiz_rounded),
                tooltip: 'اختبار الحديث',
                onPressed: _startQuiz,
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
                  final hadithNumber = _lastProgress!['hadithNumber'] as int?;
                  final chapterId = _lastProgress!['chapterId'] as int?;

                  if (!context.mounted) return;
                  // Resume into the same chapter-scoped list, located by the
                  // hadith's in-book number — not by a list index, which
                  // pointed at an unrelated hadith.
                  unawaited(
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => HadithReaderPage(
                          hadith: Hadith(
                            id: 0,
                            idInBook: hadithNumber ?? 0,
                            arabic: '',
                            englishText: '',
                            narratorEnglish: '',
                            chapterId: chapterId ?? 0,
                            collectionId: bookId,
                          ),
                          bookTitle: bookTitle,
                          chapterTitle: '',
                          bookColor: Color(colorValue),
                          allHadiths: const [],
                          currentIndex: 0,
                          bookId: bookId,
                          chapterId: chapterId,
                          startIdInBook: hadithNumber,
                        ),
                      ),
                    ).then((_) => _loadProgress()),
                  );
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
                      MaterialPageRoute<void>(
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
                            MaterialPageRoute<void>(
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

          // ─── Study Tools ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أدوات الدراسة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NoorDesignSystem.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StudyToolTile(
                        icon: Icons.psychology_rounded,
                        label: 'الحفظ بالتكرار',
                        color: NoorDesignSystem.primaryGreen,
                        onTap: () => context.go('/hadith/memorization'),
                      ),
                      _StudyToolTile(
                        icon: Icons.insights_rounded,
                        label: 'الإحصائيات',
                        color: NoorDesignSystem.goldAccent,
                        onTap: () => context.go('/hadith/stats'),
                      ),
                      _StudyToolTile(
                        icon: Icons.label_outline_rounded,
                        label: 'الوسوم',
                        color: NoorDesignSystem.deepTeal,
                        onTap: () => context.go('/hadith/tags'),
                      ),
                      _StudyToolTile(
                        icon: Icons.account_tree_outlined,
                        label: 'شجرة المواضيع',
                        color: const Color(0xFF5D4037),
                        onTap: () => context.go('/hadith/topics'),
                      ),
                      _StudyToolTile(
                        icon: Icons.travel_explore_rounded,
                        label: 'المتصفح المتقدم',
                        color: const Color(0xFF6A1B9A),
                        onTap: () => context.go('/hadith/advanced'),
                      ),
                    ],
                  ),
                ],
              ),
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

  const _ContinueReadingCard({required this.progress, required this.onTap});
  final Map<String, dynamic> progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bookId = progress['bookId'] as String? ?? '';
    final knownName = hadithBookName(bookId);
    final bookTitle = knownName == bookId
        ? (progress['bookTitle'] as String? ?? '')
        : knownName;
    final hadithIndex = progress['hadithIndex'] as int? ?? 0;
    final totalHadiths = progress['totalHadiths'] as int? ?? 1;
    final colorValue = progress['colorValue'] as int? ?? NoorDesignSystem.emeraldGreen.toARGB32();
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
            border: Border.all(color: bookColor.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: bookColor.withValues(alpha: 0.06),
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
                  color: bookColor.withValues(alpha: 0.1),
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
                        backgroundColor: bookColor.withValues(alpha: 0.1),
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

  const _HadithOfTheDayCard({required this.hadith, required this.onTap});
  final Hadith hadith;
  final VoidCallback onTap;

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
                color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
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
                  color: Colors.white.withValues(alpha: 0.06),
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
                            color: Colors.white.withValues(alpha: 0.2),
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

/// Compact tile used in the hadith page "study tools" section.
class _StudyToolTile extends StatelessWidget {

  const _StudyToolTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: (MediaQuery.of(context).size.width - 60) / 2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: NoorDesignSystem.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
