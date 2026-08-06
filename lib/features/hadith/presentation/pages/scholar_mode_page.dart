import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hadith_search_engine.dart';
import '../../../../core/services/isnad_parser_service.dart';
import '../../../../core/services/narrator_database_service.dart';
import '../../../../core/services/share_as_image_service.dart';
import '../../../../core/theme/noor_theme.dart';

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

  // Isnad analysis state
  List<NarratorInfo> _isnadChain = [];
  bool _loadingIsnad = true;
  
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
    _loadIsnadChain();
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
    if (!mounted) return;
    setState(() {
      _similarHadiths = similar;
      _loadingSimilar = false;
    });
  }

  Future<void> _loadIsnadChain() async {
    await NarratorDatabaseService.init();
    final chain = IsnadParserService.parseChain(widget.hadith.text);
    if (!mounted) return;
    setState(() {
      _isnadChain = chain;
      _loadingIsnad = false;
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

            // Isnad Analysis Section
            _buildIsnadSection(theme),
            
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

  Widget _buildIsnadSection(ThemeData theme) {
    if (_loadingIsnad) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_isnadChain.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.link_off_rounded, size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              const Text('لم يتم العثور على إسناد في هذا الحديث'),
            ],
          ),
        ),
      );
    }

    // Count narrators by role
    final prophetCount = _isnadChain.where((n) => n.isProphet).length;
    final companionCount = _isnadChain.where((n) => n.isCompanion).length;
    final narratorCount = _isnadChain.where((n) => !n.isProphet && !n.isCompanion).length;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.link_rounded),
        title: const Text('تحليل الإسناد'),
        subtitle: Text('${_isnadChain.length} راوٍ في السلسلة'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Chain stats row
                Row(
                  children: [
                    _buildChainStat('الرواة', '$narratorCount', NoorTheme.primary),
                    const SizedBox(width: 8),
                    _buildChainStat('الصحابة', '$companionCount', NoorTheme.hadithSahih),
                    const SizedBox(width: 8),
                    if (prophetCount > 0)
                      _buildChainStat('النبي ﷺ', '$prophetCount', NoorTheme.accentGold),
                  ],
                ),
                const SizedBox(height: 12),

                // Chain connectivity
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isnadChain.length >= 3
                        ? NoorTheme.hadithSahih.withOpacity(0.08)
                        : NoorTheme.hadithDaif.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isnadChain.length >= 3
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        size: 18,
                        color: _isnadChain.length >= 3
                            ? NoorTheme.hadithSahih
                            : NoorTheme.hadithDaif,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isnadChain.length >= 3
                              ? 'سلسلة متصلة (${_isnadChain.length} حلقات)'
                              : 'سلسلة قصيرة (${_isnadChain.length} حلقات)',
                          style: TextStyle(
                            color: _isnadChain.length >= 3
                                ? NoorTheme.hadithSahih
                                : NoorTheme.hadithDaif,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Narrator chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _isnadChain.map((narrator) {
                    final profile = NarratorDatabaseService.lookupFromNarratorInfo(narrator);
                    final color = _getNarratorColor(narrator.role);

                    return GestureDetector(
                      onTap: () => _showNarratorDetail(narrator, profile),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (profile != null) ...[
                              Icon(Icons.verified_rounded, size: 14, color: color),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              narrator.name,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNarratorColor(String role) {
    if (role.contains('النبي')) return NoorTheme.accentGold;
    if (role.contains('صحابي')) return NoorTheme.hadithSahih;
    return NoorTheme.primary;
  }

  void _showNarratorDetail(NarratorInfo narrator, NarratorProfile? profile) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Name with role badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getNarratorColor(narrator.role).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      narrator.role,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getNarratorColor(narrator.role),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      narrator.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),

              if (narrator.linkWord.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'صيغة التحمل: ${narrator.linkWord}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  textDirection: TextDirection.rtl,
                ),
              ],

              // Profile details if available
              if (profile != null) ...[
                const Divider(height: 24),

                if (profile.rank.isNotEmpty)
                  _buildDetailRow('المرتبة', profile.rank),

                if (profile.rankSource.isNotEmpty)
                  _buildDetailRow('المصدر', profile.rankSource),

                if (profile.deathYear > 0)
                  _buildDetailRow('الوفاة', profile.deathYearDisplay),

                if (profile.birthYear > 0)
                  _buildDetailRow('الولادة', profile.birthYearDisplay),

                if (profile.teachers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('شيوخه', profile.teachers.take(5).join('، ')),
                ],

                if (profile.students.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildDetailRow('تلاميذه', profile.students.take(5).join('، ')),
                ],
              ] else ...[
                const Divider(height: 24),
                Text(
                  'لا تتوفر معلومات إضافية عن هذا الراوي في قاعدة البيانات',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              textDirection: TextDirection.rtl,
            ),
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
