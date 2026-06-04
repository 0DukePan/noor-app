import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/tafsir_models.dart';
import '../../../../core/services/tafsir_data_source.dart';
import '../../../../core/theme/tafsir_theme.dart';
import '../widgets/tafsir_widgets.dart';

/// 📖 TafsirPage - صفحة التفسير الرئيسية
class TafsirPage extends StatefulWidget {
  final int? initialSurah;
  final int? initialAyah;

  const TafsirPage({
    super.key,
    this.initialSurah,
    this.initialAyah,
  });

  @override
  State<TafsirPage> createState() => _TafsirPageState();
}

class _TafsirPageState extends State<TafsirPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  int _currentSurah = 1;
  TafsirSourceId _currentSource = TafsirSourceId.muyassar;
  SurahTafsir? _surahTafsir;
  bool _isLoading = true;

  final List<String> _surahNames = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف', 'الأنفال',
    'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر', 'النحل',
    'الإسراء', 'الكهف', 'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون', 'النور',
    'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم', 'لقمان', 'السجدة',
    'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
    'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية', 'الأحقاف', 'محمد', 'الفتح',
    'الحجرات', 'ق', 'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن', 'الواقعة',
    'الحديد', 'المجادلة', 'الحشر', 'الممتحنة', 'الصف', 'الجمعة', 'المنافقون', 'التغابن',
    'الطلاق', 'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج', 'نوح', 'الجن',
    'المزمل', 'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
    'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق', 'الأعلى', 'الغاشية',
    'الفجر', 'البلد', 'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين', 'العلق',
    'القدر', 'البينة', 'الزلزلة', 'العاديات', 'القارعة', 'التكاثر', 'العصر', 'الهمزة',
    'الفيل', 'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص',
    'الفلق', 'الناس',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentSurah = widget.initialSurah ?? 1;
    _loadTafsir();
  }

  Future<void> _loadTafsir() async {
    setState(() => _isLoading = true);
    
    final tafsir = await TafsirDataSource.getSurahTafsir(
      surah: _currentSurah,
      source: _currentSource,
    );
    
    if (mounted) {
      setState(() {
        _surahTafsir = tafsir;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التفسير'),
        actions: [
          // Source selector
          PopupMenuButton<TafsirSourceId>(
            icon: const Icon(Icons.menu_book),
            tooltip: 'اختر التفسير',
            onSelected: (source) {
              setState(() => _currentSource = source);
              _loadTafsir();
            },
            itemBuilder: (_) => TafsirSource.all.map((s) => PopupMenuItem(
              value: s.id,
              child: Row(
                children: [
                  if (s.id == _currentSource)
                    Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
                  if (s.id != _currentSource)
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.arabicName)),
                ],
              ),
            )).toList(),
          ),
          
          // Search
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'التفسير', icon: Icon(Icons.book)),
            Tab(text: 'العلامات', icon: Icon(Icons.bookmark)),
            Tab(text: 'السجل', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tafsir
          _buildTafsirTab(theme),
          
          // Tab 2: Bookmarks
          _buildBookmarksTab(theme),
          
          // Tab 3: History
          _buildHistoryTab(theme),
        ],
      ),
    );
  }

  Widget _buildTafsirTab(ThemeData theme) {
    final brightness = theme.brightness;
    return Container(
      color: TafsirTheme.readingBackground(brightness),
      child: Column(
        children: [
          // Surah selector — premium header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TafsirTheme.cardBackground(brightness),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _currentSurah,
                    decoration: InputDecoration(
                      labelText: 'السورة',
                      labelStyle: TafsirTheme.sourceStyle(brightness: brightness),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12,
                      ),
                      filled: true,
                      fillColor: TafsirTheme.readingBackground(brightness),
                    ),
                    items: List.generate(114, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}. ${_surahNames[i]}',
                        style: GoogleFonts.cairo(fontSize: 14)),
                    )),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _currentSurah = value);
                        _loadTafsir();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  TafsirSource.get(_currentSource).arabicName,
                  style: TafsirTheme.sourceStyle(
                    brightness: brightness,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Tafsir content — reading surface
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _surahTafsir == null
                    ? Center(child: Text('لا يوجد تفسير لهذه السورة',
                        style: TafsirTheme.sourceStyle(brightness: brightness)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _surahTafsir!.length,
                        separatorBuilder: (_, __) => const ArabesqueDivider(),
                        itemBuilder: (context, index) {
                          final entry = _surahTafsir!.entries[index];
                          return _TafsirCard(
                            entry: entry,
                            onBookmark: () => setState(() {}),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab(ThemeData theme) {
    final bookmarks = TafsirDataSource.getAllBookmarks();
    
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد علامات محفوظة',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${bookmark.ayah}'),
            ),
            title: Text('سورة ${_surahNames[bookmark.surah - 1]} - الآية ${bookmark.ayah}'),
            subtitle: Text(TafsirSource.get(bookmark.source).arabicName),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await TafsirDataSource.removeBookmark(
                  surah: bookmark.surah,
                  ayah: bookmark.ayah,
                  source: bookmark.source,
                );
                setState(() {});
              },
            ),
            onTap: () {
              setState(() {
                _currentSurah = bookmark.surah;
                _currentSource = bookmark.source;
              });
              _loadTafsir();
              _tabController.animateTo(0);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    final history = TafsirDataSource.getRecentHistory();
    
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد سجل قراءة',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${item.ayah}'),
            ),
            title: Text('سورة ${_surahNames[item.surah - 1]} - الآية ${item.ayah}'),
            subtitle: Text(
              '${TafsirSource.get(item.source).arabicName} • ${_formatDate(item.lastRead)}',
            ),
            trailing: Text('${item.readCount}x'),
            onTap: () {
              setState(() {
                _currentSurah = item.surah;
                _currentSource = item.source;
              });
              _loadTafsir();
              _tabController.animateTo(0);
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _TafsirSearchDelegate(_currentSource),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// بطاقة التفسير — Premium scholar-grade card
class _TafsirCard extends StatelessWidget {
  final TafsirEntry entry;
  final VoidCallback onBookmark;

  const _TafsirCard({
    required this.entry,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final settings = TafsirDataSource.getSettings();
    final isBookmarked = TafsirDataSource.isBookmarked(
      surah: entry.surah,
      ayah: entry.ayah,
      source: entry.source,
    );

    return Container(
      decoration: BoxDecoration(
        color: TafsirTheme.cardBackground(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(brightness == Brightness.light ? 0.03 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header — ayah badge + bookmark
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: TafsirTheme.ayahColor(brightness).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'الآية ${entry.ayah}',
                    style: TafsirTheme.headerStyle(
                      brightness: brightness,
                      fontSize: 13,
                      color: TafsirTheme.ayahColor(brightness),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isBookmarked
                        ? TafsirTheme.ayahColor(brightness)
                        : theme.colorScheme.outline.withOpacity(0.5),
                    size: 22,
                  ),
                  onPressed: () async {
                    if (isBookmarked) {
                      await TafsirDataSource.removeBookmark(
                        surah: entry.surah,
                        ayah: entry.ayah,
                        source: entry.source,
                      );
                    } else {
                      await TafsirDataSource.addBookmark(
                        surah: entry.surah,
                        ayah: entry.ayah,
                        source: entry.source,
                      );
                    }
                    onBookmark();
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Tafsir text — premium reading typography
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SelectableText(
              entry.text,
              style: TafsirTheme.tafsirBodyStyle(
                brightness: brightness,
                fontSize: settings.fontSize,
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 5: THEMATIC TAFSIR & ADVANCED SEARCH ENGINE
// ═══════════════════════════════════════════════════════════════════════════

class _TafsirSearchDelegate extends SearchDelegate<TafsirEntry?> {
  final TafsirSourceId source;
  
  _TafsirSearchDelegate(this.source) : super(
    searchFieldLabel: 'ابحث في التفسير (جذر، كلمة، أو موضوع)...',
    textInputAction: TextInputAction.search,
  );

  // ── Thematic Topics (Mawdu'at) ──
  final List<Map<String, String>> _topics = [
    {'title': 'الصبر', 'icon': '🪴'},
    {'title': 'يوم القيامة', 'icon': '⚖️'},
    {'title': 'الجنة والنار', 'icon': '🔥'},
    {'title': 'قصص الأنبياء', 'icon': '📜'},
    {'title': 'الزكاة والصدقة', 'icon': '💰'},
    {'title': 'بر الوالدين', 'icon': '🤝'},
    {'title': 'الدعاء', 'icon': '🤲'},
    {'title': 'التوبة', 'icon': '💧'},
  ];

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().length < 3) {
      return const Center(child: Text('أدخل 3 حروف على الأقل للبحث بدقة'));
    }

    return FutureBuilder<List<TafsirEntry>>(
      future: TafsirDataSource.search(query: query.trim(), source: source, limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                const Text('لم نعثر على نتائج مطابقة في هذا التفسير'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final entry = results[index];
            return _SearchResultCard(
              entry: entry,
              query: query.trim(),
              onTap: () => close(context, entry),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isNotEmpty) {
      // Live quick search preview
      return buildResults(context);
    }
    
    // Show thematic topics when query is empty
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.category_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'الموضوعات والتصنيفات (Thematic Index)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _topics.map((topic) {
              return ActionChip(
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                avatar: Text(topic['icon']!, style: const TextStyle(fontSize: 14)),
                label: Text(topic['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () {
                  query = topic['title']!;
                  showResults(context);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            'نصائح للبحث:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 8),
          _buildTip(context, 'يمكنك البحث عن جذر الكلمة للحصول على نتائج أشمل.'),
          _buildTip(context, 'البحث يطابق النص ضمن التفسير المختار حالياً فقط.'),
        ],
      ),
    );
  }

  Widget _buildTip(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline))),
        ],
      ),
    );
  }
}

// ── Search Result Card with Highlighting ──
class _SearchResultCard extends StatelessWidget {
  final TafsirEntry entry;
  final String query;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.entry,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Find snippet around query
    final lowerText = entry.text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final idx = lowerText.indexOf(lowerQuery);
    
    String snippet = entry.text;
    if (idx != -1) {
      final start = (idx - 60).clamp(0, entry.text.length);
      final end = (idx + query.length + 80).clamp(0, entry.text.length);
      snippet = (start > 0 ? '...' : '') + entry.text.substring(start, end) + (end < entry.text.length ? '...' : '');
    } else {
      snippet = entry.text.length > 150 ? '${entry.text.substring(0, 150)}...' : entry.text;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'سورة ${entry.surah} • الآية ${entry.ayah}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textDirection: TextDirection.rtl,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                text: _buildHighlightedSpans(snippet, query, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _buildHighlightedSpans(String text, String query, ThemeData theme) {
    if (query.isEmpty) return TextSpan(text: text, style: _normStyle(theme));

    final matches = query.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) return TextSpan(text: text, style: _normStyle(theme));

    final spans = <TextSpan>[];
    int start = 0;
    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: _normStyle(theme)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: _normStyle(theme).copyWith(
          backgroundColor: theme.colorScheme.tertiary.withOpacity(0.2),
          color: theme.colorScheme.tertiary,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: _normStyle(theme)));
    }
    return TextSpan(children: spans);
  }

  TextStyle _normStyle(ThemeData theme) => TextStyle(
    fontFamily: 'Cairo', // or Amiri
    fontSize: 14,
    height: 1.6,
    color: theme.colorScheme.onSurface,
  );
}

