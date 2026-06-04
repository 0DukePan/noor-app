import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/data_sources/local_hadith_data_source.dart';
import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/theme/noor_theme.dart';
import '../providers/hadith_providers.dart';
import 'hadith_reader_page.dart';

/// صفحة البحث المتقدم - Advanced Hadith Search (SQLite FTS5)
class HadithSearchPage extends ConsumerStatefulWidget {
  const HadithSearchPage({super.key});

  @override
  ConsumerState<HadithSearchPage> createState() => _HadithSearchPageState();
}

class _HadithSearchPageState extends ConsumerState<HadithSearchPage> {
  final _searchController = TextEditingController();
  _SearchMode _searchMode = _SearchMode.text;
  String? _selectedCollectionId; // null = all books
  List<Hadith> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;

  // Map display name → bookId for the filter
  static const Map<String, String> _collectionMap = {
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
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final dataSource = ref.read(localHadithDataSourceProvider);
      List<Hadith> results;

      switch (_searchMode) {
        case _SearchMode.text:
          results = await dataSource.searchHadiths(query, bookId: _selectedCollectionId);
          break;
        case _SearchMode.narrator:
          results = await dataSource.searchByNarrator(query);
          break;
      }

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: Text('البحث المتقدم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── Search Controls ───
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Mode selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: NoorTheme.primary.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: _SearchMode.values.map((mode) {
                      final isSelected = _searchMode == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _searchMode = mode);
                            _searchController.clear();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? NoorTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  mode.icon,
                                  size: 16,
                                  color: isSelected ? Colors.white : NoorTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  mode.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : NoorTheme.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Search input
                TextField(
                  controller: _searchController,
                  textDirection: _searchMode == _SearchMode.narrator ? TextDirection.ltr : TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: _searchMode.hint,
                    hintTextDirection: TextDirection.rtl,
                    prefixIcon: Icon(_searchMode.icon, color: NoorTheme.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _results.clear();
                                _hasSearched = false;
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) {
                    // Debounce clear button visibility to reduce rebuilds
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                      if (mounted) setState(() {});
                    });
                  },
                  onSubmitted: (_) => _performSearch(),
                ),

                const SizedBox(height: 12),

                // Collection filter (only for text search)
                if (_searchMode == _SearchMode.text) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String?>(
                      value: _selectedCollectionId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: Text('جميع الكتب', style: GoogleFonts.cairo()),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('جميع الكتب', style: GoogleFonts.cairo()),
                        ),
                        ..._collectionMap.entries.map((e) {
                          return DropdownMenuItem<String?>(
                            value: e.key,
                            child: Text(e.value, style: GoogleFonts.cairo(fontSize: 14)),
                          );
                        }),
                      ],
                      onChanged: (value) => setState(() => _selectedCollectionId = value),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Search button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _searchController.text.trim().isNotEmpty ? _performSearch : null,
                    icon: const Icon(Icons.search_rounded),
                    label: Text('بحث', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: NoorTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Results ───
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? _buildEmptyState()
                    : _results.isEmpty
                        ? _buildNoResults()
                        : _buildResultsList(),
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
          Icon(Icons.manage_search_rounded, size: 72, color: NoorTheme.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'ابحث في الكتب التسعة',
            style: GoogleFonts.cairo(color: NoorTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'البحث يشمل النص العربي والإنجليزي',
            style: GoogleFonts.cairo(color: NoorTheme.textSecondary.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: NoorTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'لم يتم العثور على نتائج',
            style: GoogleFonts.cairo(color: NoorTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      children: [
        // Result count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NoorTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_results.length} نتيجة',
                  style: GoogleFonts.cairo(
                    color: NoorTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final hadith = _results[index];
              return _SearchResultCard(
                hadith: hadith,
                collectionName: _collectionMap[hadith.collectionId] ?? hadith.collectionId ?? '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HadithReaderPage(
                        hadith: hadith,
                        bookTitle: _collectionMap[hadith.collectionId] ?? hadith.collectionId ?? '',
                        chapterTitle: '',
                        bookColor: const Color(0xFF1B5E20),
                        allHadiths: _results,
                        currentIndex: index,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SEARCH MODE
// ═══════════════════════════════════════════════════════════════════

enum _SearchMode {
  text,
  narrator;

  String get label {
    switch (this) {
      case _SearchMode.text:
        return 'بحث بالنص';
      case _SearchMode.narrator:
        return 'بحث بالراوي';
    }
  }

  String get hint {
    switch (this) {
      case _SearchMode.text:
        return 'ابحث بكلمة أو عبارة...';
      case _SearchMode.narrator:
        return 'اسم الراوي بالإنجليزية...';
    }
  }

  IconData get icon {
    switch (this) {
      case _SearchMode.text:
        return Icons.search_rounded;
      case _SearchMode.narrator:
        return Icons.person_search_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// RESULT CARD
// ═══════════════════════════════════════════════════════════════════

class _SearchResultCard extends StatelessWidget {
  final Hadith hadith;
  final String collectionName;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.hadith,
    required this.collectionName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: NoorTheme.primary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Header: collection badge + hadith number
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NoorTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        collectionName,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: NoorTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'حديث رقم ${hadith.idInBook}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: NoorTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Arabic text
                Text(
                  hadith.arabic.length > 200
                      ? '${hadith.arabic.substring(0, 200)}...'
                      : hadith.arabic,
                  style: GoogleFonts.amiri(
                    fontSize: 16,
                    height: 1.8,
                    color: NoorTheme.textArabic,
                  ),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Narrator
                if (hadith.narratorEnglish.isNotEmpty)
                  Text(
                    hadith.narratorEnglish,
                    style: TextStyle(
                      fontSize: 12,
                      color: NoorTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
