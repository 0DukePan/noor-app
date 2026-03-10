import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hadith_search_engine.dart';
import '../../../../core/services/share_as_image_service.dart';

/// 🎓 وضع طالب العلم - Scholar Mode for Hadith
/// 
/// Features:
/// - Highlight important words
/// - Copy with takhrij
/// - Save notes on hadith
/// - Compare narrations
/// - Study flashcards
class ScholarModePage extends StatefulWidget {
  final HadithIndexEntry hadith;

  const ScholarModePage({super.key, required this.hadith});

  @override
  State<ScholarModePage> createState() => _ScholarModePageState();
}

class _ScholarModePageState extends State<ScholarModePage> {
  // State
  bool _showTakhrij = true;
  bool _highlightKeywords = true;
  String _note = '';
  List<HadithSearchResult> _similarHadiths = [];
  bool _loadingSimilar = true;
  
  // Highlight colors
  final Map<String, Color> _highlightColors = {
    'قال': Colors.blue.withOpacity(0.3),
    'النبي': Colors.green.withOpacity(0.3),
    'صلى الله عليه وسلم': Colors.amber.withOpacity(0.3),
    'رضي الله عنه': Colors.purple.withOpacity(0.3),
    'عن': Colors.orange.withOpacity(0.3),
  };

  @override
  void initState() {
    super.initState();
    _loadNote();
    _loadSimilarHadiths();
  }

  Future<void> _loadNote() async {
    final box = await Hive.openBox('hadith_notes');
    setState(() {
      _note = box.get(widget.hadith.id, defaultValue: '');
    });
  }

  Future<void> _saveNote(String note) async {
    final box = await Hive.openBox('hadith_notes');
    await box.put(widget.hadith.id, note);
    setState(() => _note = note);
  }

  Future<void> _loadSimilarHadiths() async {
    final similar = await HadithSearchEngine.getSimilar(widget.hadith);
    setState(() {
      _similarHadiths = similar;
      _loadingSimilar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('وضع طالب العلم'),
        actions: [
          IconButton(
            icon: Icon(_highlightKeywords ? Icons.highlight : Icons.highlight_off),
            onPressed: () => setState(() => _highlightKeywords = !_highlightKeywords),
            tooltip: 'تظليل الكلمات المهمة',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareWithTakhrij,
            tooltip: 'مشاركة مع التخريج',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hadith Card
            _buildHadithCard(theme),
            
            const SizedBox(height: 16),
            
            // Takhrij Section
            if (_showTakhrij) _buildTakhrijSection(theme),
            
            const SizedBox(height: 16),
            
            // Notes Section
            _buildNotesSection(theme),
            
            const SizedBox(height: 16),
            
            // Similar Hadiths
            _buildSimilarSection(theme),
            
            const SizedBox(height: 16),
            
            // Quick Actions
            _buildActionsSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHadithCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Grade badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getGradeColor(widget.hadith.grade).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.hadith.grade.isEmpty ? 'غير محكوم' : widget.hadith.grade,
                style: TextStyle(
                  color: _getGradeColor(widget.hadith.grade),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Narrator (Sanad)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.hadith.narrator,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Matn (Text)
            _highlightKeywords
                ? _buildHighlightedText(widget.hadith.text, theme)
                : Text(
                    widget.hadith.text,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 2.0,
                      fontFamily: 'Amiri',
                    ),
                    textDirection: TextDirection.rtl,
                  ),
            
            const SizedBox(height: 16),
            
            // Reference
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الحديث رقم ${widget.hadith.number}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  _getBookName(widget.hadith.book),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, ThemeData theme) {
    final spans = <TextSpan>[];
    var currentIndex = 0;
    
    // Find and highlight keywords
    final sortedKeywords = _highlightColors.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    while (currentIndex < text.length) {
      bool found = false;
      
      for (final keyword in sortedKeywords) {
        if (text.substring(currentIndex).startsWith(keyword)) {
          spans.add(TextSpan(
            text: keyword,
            style: TextStyle(
              fontSize: 22,
              height: 2.0,
              fontFamily: 'Amiri',
              backgroundColor: _highlightColors[keyword],
            ),
          ));
          currentIndex += keyword.length;
          found = true;
          break;
        }
      }
      
      if (!found) {
        // Find next keyword or end
        var nextKeywordIndex = text.length;
        for (final keyword in sortedKeywords) {
          final idx = text.indexOf(keyword, currentIndex);
          if (idx != -1 && idx < nextKeywordIndex) {
            nextKeywordIndex = idx;
          }
        }
        
        spans.add(TextSpan(
          text: text.substring(currentIndex, nextKeywordIndex),
          style: const TextStyle(
            fontSize: 22,
            height: 2.0,
            fontFamily: 'Amiri',
          ),
        ));
        currentIndex = nextKeywordIndex;
      }
    }
    
    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: TextStyle(color: theme.colorScheme.onSurface),
        children: spans,
      ),
    );
  }

  Widget _buildTakhrijSection(ThemeData theme) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.library_books),
        title: const Text('التخريج'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTakhrijRow('الكتاب', _getBookName(widget.hadith.book)),
                _buildTakhrijRow('الباب', 'الباب ${widget.hadith.chapter}'),
                _buildTakhrijRow('رقم الحديث', widget.hadith.number.toString()),
                if (widget.hadith.companion.isNotEmpty)
                  _buildTakhrijRow('الصحابي', widget.hadith.companion),
                if (widget.hadith.topics.isNotEmpty)
                  _buildTakhrijRow('المواضيع', widget.hadith.topics.join(', ')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakhrijRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.note),
        title: const Text('ملاحظاتي'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'أضف ملاحظاتك على هذا الحديث...',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: _note),
                  onChanged: _saveNote,
                ),
                const SizedBox(height: 8),
                Text(
                  'تُحفظ الملاحظات تلقائيًا',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarSection(ThemeData theme) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.compare_arrows),
        title: const Text('أحاديث مشابهة'),
        children: [
          if (_loadingSimilar)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_similarHadiths.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('لا توجد أحاديث مشابهة'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _similarHadiths.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final result = _similarHadiths[index];
                return ListTile(
                  title: Text(
                    result.entry.text.length > 100
                        ? '${result.entry.text.substring(0, 100)}...'
                        : result.entry.text,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: Text(
                    '${_getBookName(result.entry.book)} - ${result.entry.number}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Text(
                    '${(result.score * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScholarModePage(hadith: result.entry),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.copy, size: 18),
          label: const Text('نسخ مع التخريج'),
          onPressed: _copyWithTakhrij,
        ),
        ActionChip(
          avatar: const Icon(Icons.image, size: 18),
          label: const Text('مشاركة كصورة'),
          onPressed: () => _shareAsImage(context),
        ),
        ActionChip(
          avatar: const Icon(Icons.bookmark_border, size: 18),
          label: const Text('حفظ للمراجعة'),
          onPressed: _addToReview,
        ),
      ],
    );
  }

  void _copyWithTakhrij() {
    final takhrij = '''
${widget.hadith.text}

📚 ${_getBookName(widget.hadith.book)}
📖 الباب ${widget.hadith.chapter} - الحديث ${widget.hadith.number}
${widget.hadith.grade.isNotEmpty ? '✓ ${widget.hadith.grade}' : ''}
${widget.hadith.companion.isNotEmpty ? '👤 ${widget.hadith.companion}' : ''}

— تطبيق نور الإسلامي
''';
    
    Clipboard.setData(ClipboardData(text: takhrij));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم النسخ مع التخريج ✓')),
    );
  }

  void _shareWithTakhrij() {
    _copyWithTakhrij();
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

  Future<void> _addToReview() async {
    final box = await Hive.openBox('hadith_review');
    final list = box.get('review_list', defaultValue: <String>[]) as List;
    if (!list.contains(widget.hadith.id)) {
      list.add(widget.hadith.id);
      await box.put('review_list', list);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت الإضافة للمراجعة ✓')),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.contains('صحيح')) return Colors.green;
    if (grade.contains('حسن')) return Colors.lightGreen;
    if (grade.contains('ضعيف')) return Colors.orange;
    return Colors.grey;
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
