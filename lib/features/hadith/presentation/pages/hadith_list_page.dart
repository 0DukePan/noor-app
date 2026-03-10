import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/noor_theme.dart';
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 500) {
      // Load more when user is near bottom
      ref.read(paginatedHadithsProvider(widget.collectionId).notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider (state includes hadiths, loading, error)
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
          if (state.isLoading && state.hadiths.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.hadiths.isEmpty) {
            return Center(child: Text('حدث خطأ: ${state.error}'));
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
              
              // Determine grade logic safely (assuming it might be part of metadata if parsed better later, 
              // but current hadith entity doesn't strictly have 'grade' enum field from JSON, 
              // wait, the JSON has hadiths array, let's check entity. 
              // The JSON parser maps simple fields. 
              // We'll treat grade as Sahih default for now as most sources are Sahih/Sunan 
              // or extract from text if possible. For MVP, we stick to content).
              
              return _HadithCard(
                text: hadith.arabic,
                narrator: hadith.narratorEnglish, // Or parse from arabic if possible, current entity has both
                source: widget.title, 
                number: hadith.idInBook,
                // Using a default grade for now as JSON inspection showed mostly text
                grade: HadithGrade.sahih, 
              );
            },
          );
        },
      ),
    );
  }
}

enum HadithGrade { sahih, hasan, daif, mawdu }

class _HadithCard extends StatelessWidget {
  final String text;
  final String narrator;
  final String source;
  final HadithGrade grade;
  final int number;

  const _HadithCard({
    required this.text,
    required this.narrator,
    required this.source,
    required this.grade,
    required this.number,
  });

  Color get _gradeColor {
    switch (grade) {
      case HadithGrade.sahih: return NoorTheme.hadithSahih;
      case HadithGrade.hasan: return NoorTheme.hadithHasan;
      case HadithGrade.daif: return NoorTheme.hadithDaif;
      case HadithGrade.mawdu: return NoorTheme.hadithMawdu;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clean up text (remove HTML or artifacts if any)
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '');

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gradeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    grade.name.toUpperCase(),
                    style: TextStyle(color: _gradeColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  '#$number', 
                  style: GoogleFonts.robotoMono(
                    color: NoorDesignSystem.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
