import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/theme/noor_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../hadith_book_names.dart';
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
    unawaited(HapticFeedback.lightImpact());
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
        case _SearchMode.narrator:
          results = await dataSource.searchByNarrator(query);
      }

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } on Exception {
      setState(() {
        _results = [];
        _isSearching = false;
      });
    }
  }

  String _modeLabel(_SearchMode mode) {
    switch (mode) {
      case _SearchMode.text:
        return AppLocalizations.of(context).hsearchByText;
      case _SearchMode.narrator:
        return AppLocalizations.of(context).hsearchByNarrator;
    }
  }

  String _modeHint(_SearchMode mode) {
    switch (mode) {
      case _SearchMode.text:
        return AppLocalizations.of(context).hsearchTextHint;
      case _SearchMode.narrator:
        return AppLocalizations.of(context).hsearchNarratorHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: Text(l10n.hsearchTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                        color: NoorTheme.primary.withValues(alpha: 0.06),
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
                                  _modeLabel(mode),
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
                    hintText: _modeHint(_searchMode),
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
                      hint: Text(l10n.hsearchAllBooks, style: GoogleFonts.cairo()),
                      items: [
                        DropdownMenuItem<String?>(
                          child: Text(l10n.hsearchAllBooks, style: GoogleFonts.cairo()),
                        ),
                        ...kHadithBookNames.entries
                            .where((e) => e.key != 'ahmad') // skip alias
                            .map((e) {
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
                    label: Text(l10n.hsearchButton, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_search_rounded, size: 72, color: NoorTheme.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            l10n.hsearchEmpty,
            style: GoogleFonts.cairo(color: NoorTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.hsearchEmptySub,
            style: GoogleFonts.cairo(color: NoorTheme.textSecondary.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: NoorTheme.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            l10n.hsearchNoResults,
            style: GoogleFonts.cairo(color: NoorTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    final l10n = AppLocalizations.of(context);
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
                  color: NoorTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.hsearchCount(_results.length),
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
                collectionName: hadithBookName(hadith.collectionId ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => HadithReaderPage(
                        hadith: hadith,
                        bookTitle: hadithBookName(hadith.collectionId ?? ''),
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

  const _SearchResultCard({
    required this.hadith,
    required this.collectionName,
    required this.onTap,
  });
  final Hadith hadith;
  final String collectionName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: NoorTheme.primary.withValues(alpha: 0.04),
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
                        color: NoorTheme.primary.withValues(alpha: 0.1),
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
                      AppLocalizations.of(context).hsearchHadithNumber(hadith.idInBook),
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
                    style: const TextStyle(
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
