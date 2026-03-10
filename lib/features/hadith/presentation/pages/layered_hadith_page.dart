import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/hadith_search_engine.dart';
import '../../../../core/services/share_as_image_service.dart';
import 'scholar_mode_page.dart';

/// 📜 طبقات الحديث - Layered Hadith View
/// 
/// Features:
/// - Tab System: النص | السند | الحكم | التخريج
/// - Rich formatting for each layer
/// - Easy navigation between layers
/// - Copy/Share each layer separately
class LayeredHadithPage extends StatefulWidget {
  final HadithIndexEntry hadith;

  const LayeredHadithPage({super.key, required this.hadith});

  @override
  State<LayeredHadithPage> createState() => _LayeredHadithPageState();
}

class _LayeredHadithPageState extends State<LayeredHadithPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<HadithSearchResult> _similarHadiths = [];
  List<HadithSearchResult> _otherNarrations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRelatedHadiths();
  }

  Future<void> _loadRelatedHadiths() async {
    // Load similar hadiths
    final similar = await HadithSearchEngine.getSimilar(widget.hadith);
    
    // Load other narrations (same text, different chain)
    final otherNarrations = await HadithSearchEngine.search(
      widget.hadith.text.length > 50 
          ? widget.hadith.text.substring(0, 50) 
          : widget.hadith.text,
      target: SearchTarget.matn,
      limit: 10,
    );
    
    setState(() {
      _similarHadiths = similar;
      _otherNarrations = otherNarrations
          .where((r) => r.entry.id != widget.hadith.id)
          .toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getBookName(widget.hadith.book)} - ${widget.hadith.number}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.school),
            onPressed: () => _openScholarMode(context),
            tooltip: 'وضع طالب العلم',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _share(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.article), text: 'المتن'),
            Tab(icon: Icon(Icons.link), text: 'السند'),
            Tab(icon: Icon(Icons.gavel), text: 'الحكم'),
            Tab(icon: Icon(Icons.library_books), text: 'التخريج'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatnTab(theme),
          _buildSanadTab(theme),
          _buildHukmTab(theme),
          _buildTakhrijTab(theme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: المتن (Text)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMatnTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main text
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Bismillah decoration
                  const Text(
                    '﷽',
                    style: TextStyle(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                  
                  const Divider(height: 32),
                  
                  // Hadith text
                  SelectableText(
                    widget.hadith.text,
                    style: GoogleFonts.amiri(
                      fontSize: 24,
                      height: 2.2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                icon: const Icon(Icons.copy),
                onPressed: () => _copyText(widget.hadith.text),
                tooltip: 'نسخ المتن',
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.image),
                onPressed: () => _shareAsImage(context),
                tooltip: 'مشاركة كصورة',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Keywords
          if (widget.hadith.topics.isNotEmpty) ...[
            Text(
              'المواضيع',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.hadith.topics.map((topic) =>
                Chip(
                  label: Text(topic),
                  avatar: const Icon(Icons.tag, size: 16),
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: السند (Chain of Narration)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSanadTab(ThemeData theme) {
    // Parse the sanad into individual narrators
    final narrators = _parseSanad(widget.hadith.narrator);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual chain
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'سلسلة الرواة',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Chain visualization
                  ...narrators.asMap().entries.map((entry) {
                    final index = entry.key;
                    final narrator = entry.value;
                    final isLast = index == narrators.length - 1;
                    
                    return Column(
                      children: [
                        _NarratorCard(
                          name: narrator,
                          level: index,
                          isCompanion: index == narrators.length - 1,
                        ),
                        if (!isLast)
                          Container(
                            height: 30,
                            width: 2,
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Full sanad text
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.format_quote),
                      const SizedBox(width: 8),
                      Text(
                        'السند الكامل',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    widget.hadith.narrator,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      fontStyle: FontStyle.italic,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
          
          // Companion info
          if (widget.hadith.companion.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(widget.hadith.companion),
                subtitle: const Text('الصحابي رضي الله عنه'),
                trailing: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchByCompanion(widget.hadith.companion),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _parseSanad(String sanad) {
    // Split by common patterns
    final patterns = ['عن', 'حدثنا', 'أخبرنا', 'قال'];
    
    List<String> narrators = [];
    String current = sanad;
    
    for (final pattern in patterns) {
      if (current.contains(pattern)) {
        final parts = current.split(pattern);
        for (final part in parts) {
          final cleaned = part.trim();
          if (cleaned.isNotEmpty && cleaned.length > 3) {
            narrators.add(cleaned);
          }
        }
        break;
      }
    }
    
    // If no pattern found, return the full sanad
    if (narrators.isEmpty) {
      narrators = [sanad];
    }
    
    return narrators;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: الحكم (Ruling/Grade)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHukmTab(ThemeData theme) {
    final grade = widget.hadith.grade;
    final gradeInfo = _getGradeInfo(grade);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main grade card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Grade badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: gradeInfo.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: gradeInfo.color,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          gradeInfo.icon,
                          color: gradeInfo.color,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          grade.isEmpty ? 'غير محكوم عليه' : grade,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: gradeInfo.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Explanation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      gradeInfo.explanation,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Other narrations with different grades
          if (_otherNarrations.isNotEmpty) ...[
            Text(
              'روايات أخرى',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_otherNarrations.take(5).map((result) => Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getGradeColor(result.entry.grade).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.entry.grade.isEmpty ? '?' : result.entry.grade,
                    style: TextStyle(
                      color: _getGradeColor(result.entry.grade),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  _getBookName(result.entry.book),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('الحديث ${result.entry.number}'),
                onTap: () => _openHadith(result.entry),
              ),
            ))),
          ],
          
          const SizedBox(height: 24),
          
          // Grade legend
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 8),
                      Text(
                        'دليل الأحكام',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGradeLegendRow('صحيح', Colors.green, '✓ يحتج به'),
                  _buildGradeLegendRow('حسن', Colors.lightGreen, '✓ يحتج به'),
                  _buildGradeLegendRow('ضعيف', Colors.orange, '⚠ لا يحتج به'),
                  _buildGradeLegendRow('موضوع', Colors.red, '✗ مكذوب'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeLegendRow(String grade, Color color, String meaning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              grade,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(meaning),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: التخريج (Documentation)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTakhrijTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main source
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getBookName(widget.hadith.book),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الباب ${widget.hadith.chapter}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'الحديث رقم ${widget.hadith.number}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Similar narrations in other books
          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else ...[
            Text(
              'الحديث في كتب أخرى',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_similarHadiths.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'لم يُوجد في كتب أخرى',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...(_similarHadiths
                  .where((r) => r.entry.book != widget.hadith.book)
                  .take(5)
                  .map((result) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(result.entry.book[0].toUpperCase()),
                      ),
                      title: Text(_getBookName(result.entry.book)),
                      subtitle: Text('الحديث ${result.entry.number}'),
                      trailing: Text(
                        '${(result.score * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _openHadith(result.entry),
                    ),
                  ))),
          ],
          
          const SizedBox(height: 24),
          
          // Copy takhrij
          FilledButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('نسخ التخريج الكامل'),
            onPressed: _copyFullTakhrij,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم النسخ ✓')),
    );
  }

  void _copyFullTakhrij() {
    final takhrij = '''
📚 ${_getBookName(widget.hadith.book)}
📖 الباب ${widget.hadith.chapter}
🔢 الحديث ${widget.hadith.number}
${widget.hadith.grade.isNotEmpty ? '⚖️ الحكم: ${widget.hadith.grade}' : ''}
${widget.hadith.companion.isNotEmpty ? '👤 الصحابي: ${widget.hadith.companion}' : ''}

${widget.hadith.text}
''';
    
    _copyText(takhrij);
  }

  Future<void> _shareAsImage(BuildContext context) async {
    await ShareAsImageService.shareHadith(
      context: context,
      hadithText: widget.hadith.text,
      source: _getBookName(widget.hadith.book),
      narrator: widget.hadith.companion,
      grade: widget.hadith.grade.isEmpty ? null : widget.hadith.grade,
    );
  }

  void _share(BuildContext context) {
    _copyFullTakhrij();
  }

  void _openScholarMode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScholarModePage(hadith: widget.hadith),
      ),
    );
  }

  void _openHadith(HadithIndexEntry hadith) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LayeredHadithPage(hadith: hadith),
      ),
    );
  }

  void _searchByCompanion(String companion) {
    // Navigate back to search with companion filter
    Navigator.pop(context);
    // This would typically use a navigation callback
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

  Color _getGradeColor(String grade) {
    if (grade.contains('صحيح')) return Colors.green;
    if (grade.contains('حسن')) return Colors.lightGreen;
    if (grade.contains('ضعيف')) return Colors.orange;
    if (grade.contains('موضوع')) return Colors.red;
    return Colors.grey;
  }

  _GradeInfo _getGradeInfo(String grade) {
    if (grade.contains('صحيح')) {
      return _GradeInfo(
        color: Colors.green,
        icon: Icons.verified,
        explanation: 'حديث صحيح يحتج به، اتصل سنده بنقل العدل الضابط عن مثله إلى منتهاه من غير شذوذ ولا علة.',
      );
    }
    if (grade.contains('حسن')) {
      return _GradeInfo(
        color: Colors.lightGreen,
        icon: Icons.check_circle,
        explanation: 'حديث حسن يحتج به، وهو ما اتصل سنده بنقل العدل خفيف الضبط من غير شذوذ ولا علة.',
      );
    }
    if (grade.contains('ضعيف')) {
      return _GradeInfo(
        color: Colors.orange,
        icon: Icons.warning,
        explanation: 'حديث ضعيف لا يحتج به، فقد شرطًا من شروط الصحة.',
      );
    }
    if (grade.contains('موضوع')) {
      return _GradeInfo(
        color: Colors.red,
        icon: Icons.cancel,
        explanation: 'حديث موضوع مكذوب على النبي ﷺ، لا تجوز روايته إلا مع بيان وضعه.',
      );
    }
    return _GradeInfo(
      color: Colors.grey,
      icon: Icons.help_outline,
      explanation: 'لم يُحكم على هذا الحديث، يحتاج إلى مراجعة أهل الحديث.',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _GradeInfo {
  final Color color;
  final IconData icon;
  final String explanation;

  const _GradeInfo({
    required this.color,
    required this.icon,
    required this.explanation,
  });
}

class _NarratorCard extends StatelessWidget {
  final String name;
  final int level;
  final bool isCompanion;

  const _NarratorCard({
    required this.name,
    required this.level,
    required this.isCompanion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCompanion
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isCompanion
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isCompanion
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            child: Icon(
              isCompanion ? Icons.star : Icons.person,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompanion
                        ? theme.colorScheme.onPrimaryContainer
                        : null,
                  ),
                ),
                if (isCompanion)
                  Text(
                    'صحابي',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
