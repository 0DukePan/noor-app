import 'package:flutter/material.dart';
import '../../../../core/models/tafsir_models.dart';
import '../../../../core/services/tafsir_data_source.dart';
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
    return Column(
      children: [
        // Surah selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _currentSurah,
                  decoration: InputDecoration(
                    labelText: 'السورة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: List.generate(114, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1}. ${_surahNames[i]}'),
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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        
        // Tafsir content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _surahTafsir == null
                  ? const Center(child: Text('لا يوجد تفسير لهذه السورة'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _surahTafsir!.length,
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

/// بطاقة التفسير
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
    final settings = TafsirDataSource.getSettings();
    final isBookmarked = TafsirDataSource.isBookmarked(
      surah: entry.surah,
      ayah: entry.ayah,
      source: entry.source,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'الآية ${entry.ayah}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? theme.colorScheme.primary : null,
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
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Tafsir text
            SelectableText(
              entry.text,
              style: TextStyle(
                fontSize: settings.fontSize,
                height: 1.8,
                fontFamily: 'Amiri',
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}

/// البحث في التفسير
class _TafsirSearchDelegate extends SearchDelegate<TafsirEntry?> {
  final TafsirSourceId source;
  
  _TafsirSearchDelegate(this.source) : super(
    searchFieldLabel: 'ابحث في التفسير...',
    textInputAction: TextInputAction.search,
  );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 3) {
      return const Center(
        child: Text('أدخل 3 حروف على الأقل للبحث'),
      );
    }

    return FutureBuilder<List<TafsirEntry>>(
      future: TafsirDataSource.search(query: query, source: source),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final results = snapshot.data ?? [];
        
        if (results.isEmpty) {
          return const Center(child: Text('لا توجد نتائج'));
        }
        
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final entry = results[index];
            return ListTile(
              title: Text('سورة ${entry.surah} - الآية ${entry.ayah}'),
              subtitle: Text(
                entry.text.length > 100
                    ? '${entry.text.substring(0, 100)}...'
                    : entry.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => close(context, entry),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
