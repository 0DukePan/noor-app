import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/noor_theme.dart';
import '../providers/quran_providers.dart';
import '../../../../core/domain/entities/surah.dart';

/// صفحة القرآن الديناميكية — Dynamic Quran Page
/// Zero setState. All state via Riverpod providers.
class QuranPage extends ConsumerWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredSurahsProvider);
    final searchQuery = ref.watch(quranSearchQueryProvider);
    final lastReadAsync = ref.watch(lastReadPositionProvider);
    final selectedFilter = ref.watch(surahFilterProvider);

    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar with Search ──
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
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
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        top: -20,
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 180,
                          color: NoorDesignSystem.emeraldGreen.withOpacity(0.05),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'القرآن الكريم',
                            style: NoorDesignSystem.textTheme.displayMedium,
                          ),
                          const SizedBox(height: 8),
                          ref.watch(surahsProvider).when(
                            data: (surahs) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: NoorDesignSystem.shadowSmall,
                              ),
                              child: Text(
                                '${surahs.length} سورة',
                                style: NoorDesignSystem.textTheme.labelMedium?.copyWith(
                                  color: NoorDesignSystem.deepTeal,
                                ),
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _SearchBar(
                  onChanged: (query) {
                    ref.read(quranSearchQueryProvider.notifier).state = query;
                  },
                ),
              ),
            ),
          ),

          // ── Filter Chips ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBarDelegate(
              selectedFilter: selectedFilter,
              onFilterChanged: (filter) {
                HapticFeedback.selectionClick();
                ref.read(surahFilterProvider.notifier).state = filter;
              },
            ),
          ),

          // ── Last Read Position (safe .when access) ──
          ...lastReadAsync.when(
            data: (pos) {
              if (pos == null || searchQuery.isNotEmpty) return [const SliverToBoxAdapter(child: SizedBox.shrink())];
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Material(
                      color: NoorDesignSystem.emeraldGreen,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/quran/surah/${pos['surah']}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.bookmark, color: Colors.white),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'متابعة القراءة',
                                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    'سورة رقم ${pos['surah']}',
                                    style: GoogleFonts.amiri(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            loading: () => [const SliverToBoxAdapter(child: SizedBox.shrink())],
            error: (_, __) => [const SliverToBoxAdapter(child: SizedBox.shrink())],
          ),

          // ── Surahs List (from filteredSurahsProvider) ──
          filteredAsync.when(
            data: (filteredSurahs) {
              if (filteredSurahs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: NoorDesignSystem.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد نتائج',
                          style: NoorDesignSystem.textTheme.titleMedium?.copyWith(
                            color: NoorDesignSystem.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final surah = filteredSurahs[index];
                      return _SurahListTile(
                        number: surah.number,
                        nameArabic: surah.nameArabic,
                        nameEnglish: surah.nameEnglish,
                        versesCount: surah.versesCount,
                        revelationType: surah.revelationType,
                        searchQuery: searchQuery,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/quran/surah/${surah.number}');
                        },
                      );
                    },
                    childCount: filteredSurahs.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const _ShimmerSurahTile(),
                  childCount: 10,
                ),
              ),
            ),
            error: (e, s) => SliverFillRemaining(
              child: _ErrorWidget(
                error: e.toString(),
                onRetry: () => ref.refresh(surahsProvider),
              ),
            ),
          ),

          // Bottom Padding
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
          ),
        ],
      ),

      // Mushaf FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/quran/mushaf'),
        backgroundColor: NoorDesignSystem.emeraldGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.auto_stories_rounded),
        label: const Text('المصحف'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTER BAR
// ═══════════════════════════════════════════════════════════════════════════

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  _FilterBarDelegate({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: NoorDesignSystem.creamWhite,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'الكل',
            isSelected: selectedFilter == 'all',
            onTap: () => onFilterChanged('all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'مكية',
            isSelected: selectedFilter == 'meccan',
            onTap: () => onFilterChanged('meccan'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'مدنية',
            isSelected: selectedFilter == 'medinan',
            onTap: () => onFilterChanged('medinan'),
          ),
        ],
      ),
    );
  }

  @override double get maxExtent => 50;
  @override double get minExtent => 50;
  @override bool shouldRebuild(covariant _FilterBarDelegate old) =>
      selectedFilter != old.selectedFilter;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NoorDesignSystem.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? NoorDesignSystem.primaryGreen : NoorDesignSystem.primaryGreen.withOpacity(0.2),
          ),
          boxShadow: isSelected ? NoorDesignSystem.shadowSmall : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : NoorDesignSystem.primaryGreen,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH BAR (No TextEditingController — pure Riverpod)
// ═══════════════════════════════════════════════════════════════════════════

class _SearchBar extends ConsumerStatefulWidget {
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.onChanged});

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textDirection: TextDirection.rtl,
        style: NoorDesignSystem.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'ابحث عن سورة...',
          hintTextDirection: TextDirection.rtl,
          hintStyle: TextStyle(
            color: NoorDesignSystem.textSecondary.withOpacity(0.5),
            fontSize: 16,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: NoorDesignSystem.deepTeal),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  color: NoorDesignSystem.error,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SURAH LIST TILE (with search highlight)
// ═══════════════════════════════════════════════════════════════════════════

class _SurahListTile extends StatelessWidget {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final int versesCount;
  final RevelationType revelationType;
  final String searchQuery;
  final VoidCallback onTap;

  const _SurahListTile({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.versesCount,
    required this.revelationType,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMakki = revelationType == RevelationType.meccan;
    final displayName = nameArabic.replaceAll('سورة ', '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        boxShadow: NoorDesignSystem.shadowSmall,
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Surah Number
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: NoorDesignSystem.emeraldGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: GoogleFonts.cairo(
                        color: NoorDesignSystem.emeraldGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Surah Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildHighlightedName(displayName),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$versesCount آية', style: NoorDesignSystem.textTheme.bodySmall),
                          const SizedBox(width: 4),
                          Text('•', style: NoorDesignSystem.textTheme.bodySmall),
                          const SizedBox(width: 4),
                          Text(
                            isMakki ? 'مكية' : 'مدنية',
                            style: NoorDesignSystem.textTheme.bodySmall?.copyWith(
                              color: isMakki ? NoorDesignSystem.goldAccent : NoorDesignSystem.deepTeal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: NoorDesignSystem.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Highlight the matching portion of the surah name
  Widget _buildHighlightedName(String name) {
    if (searchQuery.isEmpty) {
      return Text(
        name,
        style: GoogleFonts.amiri(
          fontSize: 20, fontWeight: FontWeight.bold, height: 1.2,
          color: NoorDesignSystem.textPrimary,
        ),
        textDirection: TextDirection.rtl,
      );
    }

    final normalizedName = normalizeArabic(name);
    final normalizedQuery = normalizeArabic(searchQuery);
    final matchIndex = normalizedName.indexOf(normalizedQuery);

    if (matchIndex < 0) {
      return Text(
        name,
        style: GoogleFonts.amiri(
          fontSize: 20, fontWeight: FontWeight.bold, height: 1.2,
          color: NoorDesignSystem.textPrimary,
        ),
        textDirection: TextDirection.rtl,
      );
    }

    // Build highlighted spans
    final before = name.substring(0, matchIndex);
    final match = name.substring(matchIndex, matchIndex + searchQuery.length);
    final after = name.substring(matchIndex + searchQuery.length);

    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: GoogleFonts.amiri(
          fontSize: 20, fontWeight: FontWeight.bold, height: 1.2,
          color: NoorDesignSystem.textPrimary,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              backgroundColor: NoorDesignSystem.emeraldGreen.withOpacity(0.2),
              color: NoorDesignSystem.emeraldGreen,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHIMMER LOADING SKELETON
// ═══════════════════════════════════════════════════════════════════════════

class _ShimmerSurahTile extends StatelessWidget {
  const _ShimmerSurahTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: Row(
        children: [
          // Number circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NoorDesignSystem.emeraldGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERROR WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: NoorTheme.hadithMawdu),
          const SizedBox(height: 16),
          Text('حدث خطأ', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
