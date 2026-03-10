import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/book_card.dart';
import '../providers/hadith_providers.dart';
import '../../../../core/domain/entities/hadith.dart'; // Ensure this path is correct
import 'hadith_list_page.dart';
import 'hadith_search_page.dart';

/// صفحة مكتبة الحديث - Hadith Library
class HadithPage extends ConsumerStatefulWidget {
  const HadithPage({super.key});

  @override
  ConsumerState<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends ConsumerState<HadithPage> {
  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(hadithCollectionsProvider);

    return Scaffold(
      backgroundColor: NoorDesignSystem.creamWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 160,
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
                      const SizedBox(height: 8),
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
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HadithSearchPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Featured / 40 Nawawi Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [NoorDesignSystem.emeraldGreen, NoorDesignSystem.deepTeal],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: NoorDesignSystem.shadowMedium,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'حديث اليوم',
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'إنما الأعمال بالنيات',
                            style: GoogleFonts.amiri(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HadithListPage(
                                    collectionId: 'nawawi40',
                                    title: 'الأربعون النووية',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                            label: const Text('اقرأ الحديث'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: NoorDesignSystem.emeraldGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.format_quote_rounded,
                      size: 100,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'الكتب والمجاميع',
                style: NoorDesignSystem.textTheme.titleLarge,
              ),
            ),
          ),

          // Books Grid
          collectionsAsync.when(
            data: (collections) {
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65, // Tall cards like books
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = collections[index];
                      // Filter out Nawawi if it's already featured, or keep it.
                      // The repository returns all.
                      
                      return BookCard(
                        title: book.titleArabic,
                        subtitle: 'كتاب', // Type placeholder
                        count: book.hadithsCount,
                        color: _getBookColor(book.id),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HadithListPage(
                                collectionId: book.id,
                                title: book.titleArabic,
                              ),
                            ),
                          );
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
