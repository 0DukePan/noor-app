import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/noor_theme.dart';
import '../providers/quran_providers.dart';
import '../../../../core/domain/entities/surah.dart';

/// صفحة القرآن الديناميكية - Dynamic Quran Page
class QuranPage extends ConsumerStatefulWidget {
  const QuranPage({super.key});

  @override
  ConsumerState<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends ConsumerState<QuranPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsProvider);
    final searchQuery = ref.watch(quranSearchQueryProvider);
    final lastReadAsync = ref.watch(lastReadPositionProvider);

    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with Search
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
                          surahsAsync.when(
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
                            error: (_,__) => const SizedBox.shrink(),
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
                  controller: _searchController,
                  onChanged: (query) {
                    ref.read(quranSearchQueryProvider.notifier).state = query;
                  },
                ),
              ),
            ),
          ),

          // Last Read Position (if available)
          if (lastReadAsync.value != null && searchQuery.isEmpty)
             SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                 child: Material(
                   color: NoorDesignSystem.emeraldGreen,
                   borderRadius: BorderRadius.circular(16),
                   elevation: 4,
                   child: InkWell(
                     borderRadius: BorderRadius.circular(16),
                     onTap: () {
                       final pos = lastReadAsync.value!;
                       // Navigate to specific verse logic or just surah
                       // For now just surah, ideally we scroll to verse
                       if (context.mounted) {
                          context.push('/quran/surah/${pos['surah']}');
                       }
                     },
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
                                 style: GoogleFonts.cairo(
                                   color: Colors.white70, 
                                   fontSize: 12,
                                 ),
                               ),
                               Text(
                                 'سورة رقم ${lastReadAsync.value!['surah']}',
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

          // Surahs List
          surahsAsync.when(
            data: (allSurahs) {
              final filteredSurahs = searchQuery.isEmpty 
                  ? allSurahs 
                  : allSurahs.where((horizontalSurah) => 
                      horizontalSurah.nameArabic.contains(searchQuery) || 
                      horizontalSurah.nameEnglish.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      horizontalSurah.number.toString() == searchQuery
                    ).toList();

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
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // Ensure we use the correct path format expected by router
                          context.push('/quran/surah/${surah.number}');
                        },
                      );
                    },
                    childCount: filteredSurahs.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => SliverFillRemaining(
              child: _ErrorWidget(
                error: e.toString(),
                onRetry: () => ref.refresh(surahsProvider),
              ),
            ),
          ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),

      // Quick Access FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickJumpDialog(context),
        backgroundColor: NoorDesignSystem.emeraldGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.flash_on_rounded),
        label: const Text('انتقال سريع'),
      ),
    );
  }

  void _showQuickJumpDialog(BuildContext context) {
    final jumpController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: NoorDesignSystem.creamWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(NoorDesignSystem.radiusXLarge),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NoorDesignSystem.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'انتقال سريع',
                style: NoorDesignSystem.textTheme.titleLarge,
              ),
              const SizedBox(height: NoorDesignSystem.spacingM),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: jumpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'رقم السورة (1-114)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NoorDesignSystem.spacingM),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final number = int.tryParse(jumpController.text);
                    if (number != null && number >= 1 && number <= 114) {
                      Navigator.pop(context);
                      context.push('/quran/surah/$number');
                    }
                  },
                  child: const Text('انتقال'),
                ),
              ),
              const SizedBox(height: NoorDesignSystem.spacingM),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        style: NoorDesignSystem.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'ابحث عن سورة...',
          hintTextDirection: TextDirection.rtl,
          hintStyle: TextStyle(
            color: NoorDesignSystem.textSecondary.withOpacity(0.5),
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: NoorDesignSystem.deepTeal,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  color: NoorDesignSystem.error,
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _SurahListTile extends StatelessWidget {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final int versesCount;
  final RevelationType revelationType;
  final VoidCallback onTap;

  const _SurahListTile({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.versesCount,
    required this.revelationType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMakki = revelationType == RevelationType.meccan;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
        boxShadow: NoorDesignSystem.shadowSmall,
        border: Border.all(
          color: Colors.black.withOpacity(0.03),
        ),
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
                      Text(
                        nameArabic.replaceAll('سورة ', ''),
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: NoorDesignSystem.textPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$versesCount آية',
                            style: NoorDesignSystem.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '•',
                            style: NoorDesignSystem.textTheme.bodySmall,
                          ),
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
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: NoorDesignSystem.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: NoorTheme.hadithMawdu,
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
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
