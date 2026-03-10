import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../domain/entities/hadith_entities.dart';

/// مقارنة الروايات المتعددة - Multi-Narration Comparison Page
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

  // Sample narrations from different books
  final List<HadithNarration> _narrations = [
    HadithNarration(
      source: 'صحيح البخاري',
      hadithNumber: 1,
      narrator: 'عمر بن الخطاب رضي الله عنه',
      text: 'إنما الأعمال بالنيات وإنما لكل امرئ ما نوى فمن كانت هجرته إلى الله ورسوله فهجرته إلى الله ورسوله ومن كانت هجرته لدنيا يصيبها أو امرأة ينكحها فهجرته إلى ما هاجر إليه',
      grade: HadithGrade.sahih,
      differences: ['إنما الأعمال بالنيات'],
    ),
    HadithNarration(
      source: 'صحيح مسلم',
      hadithNumber: 1907,
      narrator: 'عمر بن الخطاب رضي الله عنه',
      text: 'إنما الأعمال بالنية وإنما لكل امرئ ما نوى فمن كانت هجرته إلى الله ورسوله فهجرته إلى الله ورسوله ومن كانت هجرته لدنيا يصيبها أو امرأة يتزوجها فهجرته إلى ما هاجر إليه',
      grade: HadithGrade.sahih,
      differences: ['بالنية', 'يتزوجها'],
    ),
    HadithNarration(
      source: 'سنن أبي داود',
      hadithNumber: 2201,
      narrator: 'عمر بن الخطاب رضي الله عنه',
      text: 'الأعمال بالنية وإنما لكل امرئ ما نوى فمن كانت هجرته إلى الله ورسوله فهجرته إلى الله ورسوله ومن كانت هجرته لدنيا يصيبها أو امرأة ينكحها فهجرته إلى ما هاجر إليه',
      grade: HadithGrade.sahih,
      differences: ['الأعمال بالنية'],
    ),
    HadithNarration(
      source: 'جامع الترمذي',
      hadithNumber: 1647,
      narrator: 'عمر بن الخطاب رضي الله عنه',
      text: 'إنما الأعمال بالنيات وإنما لكل امرئ ما نوى فمن كانت هجرته إلى الله ورسوله فهجرته إلى الله ورسوله ومن كانت هجرته لدنيا يصيبها أو امرأة ينكحها فهجرته إلى ما هاجر إليه',
      grade: HadithGrade.sahih,
      differences: [],
    ),
  ];

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
      body: Column(
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

  Widget _buildNarrationCard(HadithNarration narration) {
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
                        color: NoorTheme.hadithSahih.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: NoorTheme.hadithSahih,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'صحيح',
                            style: TextStyle(
                              color: NoorTheme.hadithSahih,
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

  Widget _buildHighlightedText(HadithNarration narration) {
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
}

class HadithNarration {
  final String source;
  final int hadithNumber;
  final String narrator;
  final String text;
  final HadithGrade grade;
  final List<String> differences;

  HadithNarration({
    required this.source,
    required this.hadithNumber,
    required this.narrator,
    required this.text,
    required this.grade,
    this.differences = const [],
  });
}
