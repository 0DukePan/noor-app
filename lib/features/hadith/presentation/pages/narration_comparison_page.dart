import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/hadith_search_engine.dart';
import '../../../../core/theme/noor_theme.dart';

/// مقارنة الروايات المتعددة - Multi-Narration Comparison Page
/// Uses HadithSearchEngine to find real narrations matching the keyword.
class NarrationComparisonPage extends StatefulWidget {
  final String hadithKeyword;

  const NarrationComparisonPage({
    super.key,
    required this.hadithKeyword,
  });

  @override
  State<NarrationComparisonPage> createState() => _NarrationComparisonPageState();
}

class _NarrationComparisonPageState extends State<NarrationComparisonPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _showDiff = true;
  bool _loading = true;
  List<_ComparisonNarration> _narrations = [];

  @override
  void initState() {
    super.initState();
    _loadNarrations();
  }

  Future<void> _loadNarrations() async {
    // Search across all books for hadiths matching the keyword (by matn)
    final results = await HadithSearchEngine.search(
      widget.hadithKeyword,
      target: SearchTarget.matn,
      limit: 20,
    );

    if (!mounted) return;

    // Convert search results into comparison narrations
    final narrations = results.map((r) {
      return _ComparisonNarration(
        source: _getBookName(r.entry.book),
        hadithNumber: r.entry.number,
        narrator: r.entry.narrator,
        text: r.entry.text,
        grade: r.entry.grade,
        score: r.score,
      );
    }).toList();

    // Compute textual differences relative to the first (highest-score) narration
    if (narrations.length > 1) {
      final baseWords = narrations.first.text.split(' ').toSet();
      for (var i = 1; i < narrations.length; i++) {
        final words = narrations[i].text.split(' ');
        final diffs = <String>[];
        for (final w in words) {
          if (!baseWords.contains(w) && w.length > 2) {
            diffs.add(w);
          }
        }
        narrations[i] = narrations[i].copyWith(differences: diffs);
      }
    }

    setState(() {
      _narrations = narrations;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: const Text('مقارنة الروايات'),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
        actions: [
          // Toggle diff highlighting
          IconButton(
            icon: Icon(
              _showDiff ? Icons.highlight : Icons.highlight_off,
              color: _showDiff ? NoorTheme.primary : NoorTheme.textSecondary,
            ),
            tooltip: 'إظهار الفروقات',
            onPressed: () => setState(() => _showDiff = !_showDiff),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _narrations.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Sources tabs
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: NoorTheme.spacingMd),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _narrations.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _currentIndex;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? NoorTheme.primary : Colors.white,
                                borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                                border: Border.all(
                                  color: isSelected ? NoorTheme.primary : NoorTheme.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _narrations[index].source,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : NoorTheme.primary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Narrations pages
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _currentIndex = index),
                        itemCount: _narrations.length,
                        itemBuilder: (context, index) {
                          return _buildNarrationCard(_narrations[index]);
                        },
                      ),
                    ),

                    // Side-by-side comparison button
                    Padding(
                      padding: const EdgeInsets.all(NoorTheme.spacingMd),
                      child: ElevatedButton.icon(
                        onPressed: _showSideBySideComparison,
                        icon: const Icon(Icons.compare_arrows_rounded),
                        label: const Text('عرض جنباً إلى جنب'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: NoorTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'لم يتم العثور على روايات مطابقة',
            style: TextStyle(color: NoorTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'حاول بكلمة مفتاحية مختلفة',
            style: TextStyle(color: NoorTheme.textSecondary.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrationCard(_ComparisonNarration narration) {
    final gradeColor = _getGradeColor(narration.grade);
    final gradeLabel = narration.grade.isNotEmpty ? narration.grade : 'غير محكوم';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      child: Column(
        children: [
          // Source header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(NoorTheme.spacingMd),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [NoorTheme.primary, NoorTheme.primaryDark],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(NoorTheme.radiusLg),
              ),
            ),
            child: Column(
              children: [
                Text(
                  narration.source,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'حديث رقم ${narration.hadithNumber}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Hadith text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(NoorTheme.spacingLg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(NoorTheme.radiusLg),
              ),
              boxShadow: [
                BoxShadow(
                  color: NoorTheme.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Narrator
                Text(
                  narration.narrator,
                  style: TextStyle(
                    color: NoorTheme.textSecondary,
                    fontSize: 14,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: NoorTheme.spacingMd),

                // Hadith text with diff highlighting
                _buildHighlightedText(narration),

                const SizedBox(height: NoorTheme.spacingMd),

                // Grade badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 16, color: gradeColor),
                          const SizedBox(width: 4),
                          Text(
                            gradeLabel,
                            style: TextStyle(
                              color: gradeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (narration.differences.isNotEmpty && _showDiff)
                      Text(
                        '${narration.differences.length} اختلاف',
                        style: TextStyle(
                          color: NoorTheme.accentGold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(_ComparisonNarration narration) {
    if (!_showDiff || narration.differences.isEmpty) {
      return Text(
        narration.text,
        style: const TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: 22,
          height: 2.0,
          color: NoorTheme.textArabic,
        ),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      );
    }

    // Build highlighted text with differences
    return RichText(
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: 22,
          height: 2.0,
          color: NoorTheme.textArabic,
        ),
        children: _buildHighlightedSpans(narration.text, narration.differences),
      ),
    );
  }

  List<TextSpan> _buildHighlightedSpans(String text, List<String> diffs) {
    final spans = <TextSpan>[];
    String remaining = text;

    for (final diff in diffs) {
      final index = remaining.indexOf(diff);
      if (index >= 0) {
        if (index > 0) {
          spans.add(TextSpan(text: remaining.substring(0, index)));
        }
        spans.add(TextSpan(
          text: diff,
          style: TextStyle(
            backgroundColor: NoorTheme.accentGold.withOpacity(0.3),
            color: NoorTheme.textArabic,
          ),
        ));
        remaining = remaining.substring(index + diff.length);
      }
    }

    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining));
    }

    return spans;
  }

  void _showSideBySideComparison() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(NoorTheme.radiusXl),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NoorTheme.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(NoorTheme.spacingMd),
                  child: Text(
                    'مقارنة جنباً إلى جنب',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(NoorTheme.spacingMd),
                    itemCount: _narrations.length,
                    itemBuilder: (context, index) {
                      final narration = _narrations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: NoorTheme.spacingMd),
                        padding: const EdgeInsets.all(NoorTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                          border: Border.all(
                            color: NoorTheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NoorTheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${narration.hadithNumber}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  narration.source,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              narration.text,
                              style: const TextStyle(
                                fontFamily: 'AmiriQuran',
                                fontSize: 16,
                                height: 1.8,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _getBookName(String book) {
    const names = {
      'bukhari': 'صحيح البخاري',
      'muslim': 'صحيح مسلم',
      'tirmidhi': 'جامع الترمذي',
      'abudawud': 'سنن أبي داود',
      'nasai': 'سنن النسائي',
      'ibnmajah': 'سنن ابن ماجه',
      'malik': 'موطأ مالك',
      'ahmad': 'مسند أحمد',
      'darimi': 'سنن الدارمي',
    };
    return names[book] ?? book;
  }

  Color _getGradeColor(String grade) {
    if (grade.contains('صحيح')) return NoorTheme.hadithSahih;
    if (grade.contains('حسن')) return NoorTheme.hadithHasan;
    if (grade.contains('ضعيف')) return NoorTheme.hadithDaif;
    if (grade.contains('موضوع')) return NoorTheme.hadithMawdu;
    return Colors.grey;
  }
}

/// Internal model for comparison narrations, built from search results.
class _ComparisonNarration {
  final String source;
  final int hadithNumber;
  final String narrator;
  final String text;
  final String grade;
  final double score;
  final List<String> differences;

  const _ComparisonNarration({
    required this.source,
    required this.hadithNumber,
    required this.narrator,
    required this.text,
    required this.grade,
    this.score = 0,
    this.differences = const [],
  });

  _ComparisonNarration copyWith({List<String>? differences}) {
    return _ComparisonNarration(
      source: source,
      hadithNumber: hadithNumber,
      narrator: narrator,
      text: text,
      grade: grade,
      score: score,
      differences: differences ?? this.differences,
    );
  }
}
