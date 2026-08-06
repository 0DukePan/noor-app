import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/hadith_search_engine.dart';
import 'scholar_mode_page.dart';
import 'layered_hadith_page.dart';

/// 📚 صفحة تصفح الأحاديث المتقدمة - Advanced Hadith Browser
/// 
/// Features:
/// - Browse by Book
/// - Browse by Companion
/// - Browse by Topic
/// - Advanced Search
/// - Filters
class AdvancedHadithBrowserPage extends StatefulWidget {
  const AdvancedHadithBrowserPage({super.key});

  @override
  State<AdvancedHadithBrowserPage> createState() => _AdvancedHadithBrowserPageState();
}

class _AdvancedHadithBrowserPageState extends State<AdvancedHadithBrowserPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Search state
  final TextEditingController _searchController = TextEditingController();
  SearchTarget _searchTarget = SearchTarget.all;
  String? _selectedBook;
  String? _selectedCompanion;
  String? _selectedTopic;
  
  // Results
  List<HadithSearchResult> _searchResults = [];
  bool _isSearching = false;
  
  // Indexes
  List<String> _companions = [];
  List<String> _topics = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadIndexes();
  }

  void _loadIndexes() {
    _companions = HadithSearchEngine.getCompanions();
    _topics = HadithSearchEngine.getTopics();
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty && 
        _selectedCompanion == null && 
        _selectedTopic == null) {
      return;
    }
    
    setState(() => _isSearching = true);
    
    final results = await HadithSearchEngine.search(
      _searchController.text,
      target: _searchTarget,
      book: _selectedBook,
      companion: _selectedCompanion,
      topic: _selectedTopic,
    );
    
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'البحث المتقدم',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'بحث'),
                Tab(text: 'الصحابة'),
                Tab(text: 'المواضيع'),
                Tab(text: 'الكتب'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(theme),
          _buildCompanionsTab(theme),
          _buildTopicsTab(theme),
          _buildBooksTab(theme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchTab(ThemeData theme) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.amiri(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'اكتب نصاً للبحث...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Search target selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'نطاق البحث:',
                      style: GoogleFonts.cairo(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: 'الكل',
                      isSelected: _searchTarget == SearchTarget.all,
                      onSelected: () => setState(() => _searchTarget = SearchTarget.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'المتن',
                      isSelected: _searchTarget == SearchTarget.matn,
                      onSelected: () => setState(() => _searchTarget = SearchTarget.matn),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'السند',
                      isSelected: _searchTarget == SearchTarget.sanad,
                      onSelected: () => setState(() => _searchTarget = SearchTarget.sanad),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Filters
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: Icon(Icons.filter_list_rounded, size: 16, color: theme.colorScheme.primary),
                    label: Text(
                      _selectedBook != null ? _getBookName(_selectedBook!) : 'تصفية بالكتب',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _selectedBook != null 
                        ? theme.colorScheme.primaryContainer 
                        : theme.colorScheme.surface,
                    onPressed: _showBookFilter,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  if (_selectedCompanion != null)
                    InputChip(
                      label: Text(_selectedCompanion!, style: GoogleFonts.cairo(fontSize: 12)),
                      onDeleted: () => setState(() => _selectedCompanion = null),
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    ),
                  if (_selectedTopic != null)
                    InputChip(
                      label: Text(_selectedTopic!, style: GoogleFonts.cairo(fontSize: 12)),
                      onDeleted: () => setState(() => _selectedTopic = null),
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Results
        Expanded(
          child: _isSearching
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.manage_search_rounded,
                            size: 80,
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'الموسوعة الحديثية',
                            style: GoogleFonts.amiri(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يمكنك البحث في آلاف الأحاديث النبوية\nمن الكتب التسعة المعتمدة',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _buildResultsList(theme),
        ),
      ],
    );
  }

  Widget _buildResultsList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _HadithResultCard(
          result: result,
          onTap: () => _openScholarMode(result.entry),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPANIONS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCompanionsTab(ThemeData theme) {
    if (_companions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _companions.length,
      itemBuilder: (context, index) {
        final companion = _companions[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(companion),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            setState(() {
              _selectedCompanion = companion;
              _tabController.animateTo(0);
            });
            await _performSearch();
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOPICS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopicsTab(ThemeData theme) {
    final topicIcons = {
      'الصلاة': Icons.access_time,
      'الصيام': Icons.nightlight_round,
      'الزكاة': Icons.attach_money,
      'الحج': Icons.location_city,
      'الأخلاق': Icons.favorite,
      'الإيمان': Icons.star,
      'العلم': Icons.school,
      'الجهاد': Icons.flag,
      'النكاح': Icons.people,
      'البيوع': Icons.shopping_bag,
      'الدعاء': Icons.volunteer_activism,
      'الآداب': Icons.emoji_people,
    };
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final topic = _topics[index];
        return Card(
          child: InkWell(
            onTap: () async {
              setState(() {
                _selectedTopic = topic;
                _tabController.animateTo(0);
              });
              await _performSearch();
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  topicIcons[topic] ?? Icons.bookmark,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  topic,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBooksTab(ThemeData theme) {
    final books = [
      ('bukhari', 'صحيح البخاري', '🟢 أصح كتاب'),
      ('muslim', 'صحيح مسلم', '🟢 ثاني أصح كتاب'),
      ('tirmidhi', 'جامع الترمذي', '📘 السنن'),
      ('abudawud', 'سنن أبي داود', '📘 السنن'),
      ('nasai', 'سنن النسائي', '📘 السنن'),
      ('ibnmajah', 'سنن ابن ماجه', '📘 السنن'),
      ('malik', 'موطأ مالك', '📙 أقدم مصنف'),
      ('ahmad', 'مسند أحمد', '📕 المسانيد'),
      ('darimi', 'سنن الدارمي', '📗 السنن'),
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final (id, name, badge) = books[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text('${index + 1}'),
            ),
            title: Text(name),
            subtitle: Text(badge),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              setState(() {
                _selectedBook = id;
                _tabController.animateTo(0);
              });
              await _performSearch();
            },
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showBookFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('كل الكتب'),
            onTap: () {
              setState(() => _selectedBook = null);
              Navigator.pop(context);
            },
          ),
          ...['bukhari', 'muslim', 'tirmidhi', 'abudawud', 'nasai', 
              'ibnmajah', 'malik', 'ahmad', 'darimi'].map((book) =>
            ListTile(
              title: Text(_getBookName(book)),
              onTap: () {
                setState(() => _selectedBook = book);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openScholarMode(HadithIndexEntry hadith) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LayeredHadithPage(hadith: hadith),
      ),
    );
  }


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
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _HadithResultCard extends StatelessWidget {
  final HadithSearchResult result;
  final VoidCallback onTap;

  const _HadithResultCard({
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hadith = result.entry;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'تطابق ${(result.score * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    
                    // Book and number
                    Row(
                      children: [
                        Text(
                          '${_getBookName(hadith.book)} - ${hadith.number}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.feed_rounded, size: 14, color: theme.colorScheme.primary),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Text
                Text(
                  hadith.text.length > 200
                      ? '${hadith.text.substring(0, 200)}...'
                      : hadith.text,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    height: 1.8,
                    color: theme.colorScheme.onSurface,
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  direction: Axis.horizontal,
                  textDirection: TextDirection.rtl,
                  children: [
                    if (hadith.grade.isNotEmpty)
                      _TagChip(label: hadith.grade, color: theme.colorScheme.tertiary),
                    if (hadith.companion.isNotEmpty)
                      _TagChip(label: hadith.companion, color: theme.colorScheme.secondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getBookName(String book) {
    const names = {
      'bukhari': 'البخاري',
      'muslim': 'مسلم',
      'tirmidhi': 'الترمذي',
      'abudawud': 'أبو داود',
      'nasai': 'النسائي',
      'ibnmajah': 'ابن ماجه',
      'malik': 'مالك',
      'ahmad': 'أحمد',
      'darimi': 'الدارمي',
    };
    return names[book] ?? book;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
