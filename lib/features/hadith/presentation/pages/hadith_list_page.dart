import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../domain/entities/hadith_entities.dart';
import '../providers/hadith_providers.dart';

class HadithListPage extends ConsumerStatefulWidget {
  final String collectionId;
  final String title;

  const HadithListPage({
    super.key,
    required this.collectionId,
    required this.title,
  });

  @override
  ConsumerState<HadithListPage> createState() => _HadithListPageState();
}

class _HadithListPageState extends ConsumerState<HadithListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(paginatedHadithsProvider(widget.collectionId));
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500 &&
        !state.isLoading &&
        state.hasMore) {
      ref.read(paginatedHadithsProvider(widget.collectionId).notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paginatedHadithsProvider(widget.collectionId));

    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: NoorDesignSystem.creamWhite,
      ),
      body: Builder(
        builder: (context) {
          // ✅ Skeleton loading instead of spinner
          if (state.isLoading && state.hadiths.isEmpty) {
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (_, __) => const _ShimmerHadithCard(),
            );
          }

          if (state.error != null && state.hadiths.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: NoorDesignSystem.gradeDaif),
                  const SizedBox(height: 16),
                  Text('حدث خطأ', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(state.error!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(paginatedHadithsProvider(widget.collectionId)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state.hadiths.isEmpty) {
            return const Center(child: Text('لا توجد أحاديث'));
          }

          return ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: state.hadiths.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.hadiths.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final hadith = state.hadiths[index];
              return RepaintBoundary(
                child: _HadithCard(
                  hadithId: hadith.id,
                  text: hadith.textArabic,
                  narrator: hadith.narrator,
                  source: widget.title,
                  number: hadith.hadithNumber ?? (index + 1),
                  grade: hadith.grade,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRADE HELPERS
// ═══════════════════════════════════════════════════════════════════════════

Color _gradeColor(HadithGrade grade) {
  switch (grade) {
    case HadithGrade.sahih:
    case HadithGrade.sahihLiGhairihi:
      return NoorDesignSystem.gradeSahih;
    case HadithGrade.hasan:
    case HadithGrade.hasanLiGhairihi:
      return NoorDesignSystem.gradeHasan;
    case HadithGrade.daif:
      return NoorDesignSystem.gradeDaif;
    case HadithGrade.mawdu:
      return NoorDesignSystem.gradeMawdu;
    case HadithGrade.unknown:
      return NoorDesignSystem.textSecondary;
  }
}

String _gradeLabel(HadithGrade grade) {
  switch (grade) {
    case HadithGrade.sahih:
      return 'صحيح';
    case HadithGrade.sahihLiGhairihi:
      return 'صحيح لغيره';
    case HadithGrade.hasan:
      return 'حسن';
    case HadithGrade.hasanLiGhairihi:
      return 'حسن لغيره';
    case HadithGrade.daif:
      return 'ضعيف';
    case HadithGrade.mawdu:
      return 'موضوع';
    case HadithGrade.unknown:
      return 'غير محدد';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HADITH CARD (with bookmark toggle)
// ═══════════════════════════════════════════════════════════════════════════

class _HadithCard extends ConsumerWidget {
  final String hadithId;
  final String text;
  final String narrator;
  final String source;
  final HadithGrade grade;
  final int number;

  const _HadithCard({
    required this.hadithId,
    required this.text,
    required this.narrator,
    required this.source,
    required this.grade,
    required this.number,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '');
    final color = _gradeColor(grade);
    final label = _gradeLabel(grade);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Grade badge (Arabic label)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.cairo(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '#$number',
                  style: GoogleFonts.robotoMono(
                    color: NoorDesignSystem.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                // ❤️ Bookmark toggle
                _BookmarkButton(hadithId: hadithId),
              ],
            ),
            const SizedBox(height: 16),
            SelectableText(
              cleanText,
              style: GoogleFonts.amiri(
                fontSize: 20,
                height: 1.8,
                color: NoorDesignSystem.textPrimary,
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
            if (narrator.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                narrator,
                style: NoorDesignSystem.textTheme.bodySmall?.copyWith(
                  color: NoorDesignSystem.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOOKMARK BUTTON (uses hadith_providers)
// ═══════════════════════════════════════════════════════════════════════════

class _BookmarkButton extends ConsumerWidget {
  final String hadithId;
  const _BookmarkButton({required this.hadithId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedAsync = ref.watch(bookmarkedHadithIdsProvider);

    return bookmarkedAsync.when(
      data: (bookmarkedIds) {
        final isBookmarked = bookmarkedIds.contains(hadithId);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(localHadithDataSourceProvider).toggleBookmark(hadithId);
            ref.invalidate(bookmarkedHadithIdsProvider);
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(isBookmarked),
              color: isBookmarked ? Colors.red : NoorDesignSystem.textSecondary,
              size: 22,
            ),
          ),
        );
      },
      loading: () => const SizedBox(width: 22, height: 22),
      error: (_, __) => const SizedBox(width: 22, height: 22),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHIMMER SKELETON
// ═══════════════════════════════════════════════════════════════════════════

class _ShimmerHadithCard extends StatelessWidget {
  const _ShimmerHadithCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60, height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 30, height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Text lines
            for (int i = 0; i < 4; i++) ...[
              Container(
                height: 14,
                width: i == 3 ? 180 : double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Container(
              height: 12, width: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
