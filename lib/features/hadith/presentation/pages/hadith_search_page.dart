import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../domain/entities/hadith_entities.dart';
import '../providers/hadith_providers.dart';

/// صفحة البحث المتقدم - Advanced Search Page
class HadithSearchPage extends ConsumerStatefulWidget {
  const HadithSearchPage({super.key});

  @override
  ConsumerState<HadithSearchPage> createState() => _HadithSearchPageState();
}

class _HadithSearchPageState extends ConsumerState<HadithSearchPage> {
  final _searchController = TextEditingController();
  final _numberController = TextEditingController();

  SearchMode _searchMode = SearchMode.text;
  String? _selectedCollection;
  HadithGrade? _selectedGrade;
  List<Hadith> _results = [];
  bool _isSearching = false;

  final List<String> _collections = [
    'الكل',
    'صحيح البخاري',
    'صحيح مسلم',
    'سنن أبي داود',
    'جامع الترمذي',
    'سنن النسائي',
    'سنن ابن ماجه',
    'موطأ مالك',
    'مسند أحمد',
    'سنن الدارمي',
  ];

  void _performSearch() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    setState(() => _isSearching = true);

    // Simulate search delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Sample results
    setState(() {
      _results = [
        Hadith(
          id: '1',
          textArabic: 'إنما الأعمال بالنيات وإنما لكل امرئ ما نوى',
          textEnglish: 'Actions are judged by intentions',
          narratorChain: 'عن عمر بن الخطاب رضي الله عنه',
          source: 'صحيح البخاري',
          bookName: 'كتاب بدء الوحي',
          chapterName: 'باب كيف كان بدء الوحي',
          hadithNumber: 1,
          grade: HadithGrade.sahih,
        ),
        Hadith(
          id: '2',
          textArabic: 'الدين النصيحة قلنا لمن قال لله ولكتابه ولرسوله ولأئمة المسلمين وعامتهم',
          textEnglish: 'The religion is sincerity',
          narratorChain: 'عن تميم الداري رضي الله عنه',
          source: 'صحيح مسلم',
          bookName: 'كتاب الإيمان',
          chapterName: 'باب بيان أن الدين النصيحة',
          hadithNumber: 55,
          grade: HadithGrade.sahih,
        ),
      ];
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: const Text('البحث المتقدم'),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Options
          Container(
            padding: const EdgeInsets.all(NoorTheme.spacingMd),
            child: Column(
              children: [
                // Search Mode Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                  ),
                  child: Row(
                    children: SearchMode.values.map((mode) {
                      final isSelected = _searchMode == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _searchMode = mode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? NoorTheme.primary : null,
                              borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                            ),
                            child: Text(
                              mode.arabicName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.white : NoorTheme.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: NoorTheme.spacingMd),

                // Search Input
                if (_searchMode == SearchMode.text)
                  TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'ابحث بكلمة أو عبارة...',
                      hintTextDirection: TextDirection.rtl,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _performSearch(),
                  )
                else if (_searchMode == SearchMode.number)
                  TextField(
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'رقم الحديث',
                      prefixIcon: const Icon(Icons.numbers_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  )
                else if (_searchMode == SearchMode.narrator)
                  TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'اسم الراوي...',
                      hintTextDirection: TextDirection.rtl,
                      prefixIcon: const Icon(Icons.person_search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),

                const SizedBox(height: NoorTheme.spacingMd),

                // Filters Row
                Row(
                  children: [
                    // Collection Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCollection ?? 'الكل',
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _collections.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCollection = value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: NoorTheme.spacingSm),
                    // Grade Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                        ),
                        child: DropdownButton<HadithGrade?>(
                          value: _selectedGrade,
                          isExpanded: true,
                          underline: const SizedBox(),
                          hint: const Text('الدرجة'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('الكل')),
                            ...HadithGrade.values.map((g) {
                              return DropdownMenuItem(
                                value: g,
                                child: Text(g.arabicName),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedGrade = value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: NoorTheme.spacingMd),

                // Search Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _performSearch,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('بحث'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 64,
                              color: NoorTheme.textSecondary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ابحث في الكتب التسعة',
                              style: TextStyle(color: NoorTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(NoorTheme.spacingMd),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          return _HadithResultCard(hadith: _results[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

enum SearchMode {
  text,
  number,
  narrator,
}

extension SearchModeExtension on SearchMode {
  String get arabicName {
    switch (this) {
      case SearchMode.text:
        return 'نص';
      case SearchMode.number:
        return 'رقم';
      case SearchMode.narrator:
        return 'راوي';
    }
  }
}

class _HadithResultCard extends StatelessWidget {
  final Hadith hadith;

  const _HadithResultCard({required this.hadith});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: NoorTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Open hadith detail
        },
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(NoorTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Source and Grade
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hadith.grade.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hadith.grade.arabicName,
                      style: TextStyle(
                        fontSize: 11,
                        color: hadith.grade.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${hadith.source} - رقم ${hadith.hadithNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: NoorTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: NoorTheme.spacingSm),

              // Hadith text
              Text(
                hadith.textArabic,
                style: const TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 18,
                  height: 1.8,
                  color: NoorTheme.textArabic,
                ),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: NoorTheme.spacingSm),

              // Narrator
              Text(
                hadith.narratorChain,
                style: TextStyle(
                  fontSize: 13,
                  color: NoorTheme.textSecondary,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension HadithGradeExtension on HadithGrade {
  String get arabicName {
    switch (this) {
      case HadithGrade.sahih:
        return 'صحيح';
      case HadithGrade.hasan:
        return 'حسن';
      case HadithGrade.daif:
        return 'ضعيف';
      case HadithGrade.mawdu:
        return 'موضوع';
      case HadithGrade.sahihLiGhairihi:
        return 'صحيح لغيره';
      case HadithGrade.hasanLiGhairihi:
        return 'حسن لغيره';
      case HadithGrade.unknown:
        return 'غير محدد';
    }
  }

  Color get color {
    switch (this) {
      case HadithGrade.sahih:
      case HadithGrade.sahihLiGhairihi:
        return NoorTheme.hadithSahih;
      case HadithGrade.hasan:
      case HadithGrade.hasanLiGhairihi:
        return NoorTheme.hadithHasan;
      case HadithGrade.daif:
        return NoorTheme.hadithDaif;
      case HadithGrade.mawdu:
        return NoorTheme.hadithMawdu;
      case HadithGrade.unknown:
        return NoorTheme.textSecondary;
    }
  }
}
