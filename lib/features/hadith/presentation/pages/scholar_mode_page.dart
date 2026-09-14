import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/services/hadith_search_engine.dart';
import '../../../../core/services/isnad_parser_service.dart';
import '../../../../core/services/narrator_database_service.dart';
import '../../../../core/services/share_as_image_service.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/noor_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../hadith_book_names.dart';
import '../widgets/hadith_share_sheet.dart';
import '../widgets/narrator_profile_body.dart';

/// 🎓 وضع طالب العلم - Scholar Mode for Hadith
/// 
/// Features:
/// - Highlight important words
/// - Copy with takhrij
/// - Save notes on hadith
/// - Compare narrations
/// - Study flashcards
class ScholarModePage extends StatefulWidget {

  const ScholarModePage({required this.hadith, super.key});
  final HadithIndexEntry hadith;

  @override
  State<ScholarModePage> createState() => _ScholarModePageState();
}

class _ScholarModePageState extends State<ScholarModePage> {
  // State
  final bool _showTakhrij = true;
  bool _highlightKeywords = true;
  String _note = '';
  List<HadithSearchResult> _similarHadiths = [];
  bool _loadingSimilar = true;

  // Isnad analysis state
  List<NarratorInfo> _isnadChain = [];
  bool _loadingIsnad = true;
  
  // Highlight colors
  final Map<String, Color> _highlightColors = {
    'قال': Colors.blue.withValues(alpha: 0.3),
    'النبي': Colors.green.withValues(alpha: 0.3),
    'صلى الله عليه وسلم': Colors.amber.withValues(alpha: 0.3),
    'رضي الله عنه': Colors.purple.withValues(alpha: 0.3),
    'عن': Colors.orange.withValues(alpha: 0.3),
  };

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: _note);
    _loadNote();
    _loadSimilarHadiths();
    _loadIsnadChain();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  late final TextEditingController _noteController;

  Future<void> _loadNote() async {
    final box = await Hive.openBox<dynamic>('hadith_notes');
    if (!mounted) return;
    setState(() {
      _note = (box.get(_noteKey, defaultValue: '') ?? '') as String;
      _noteController.text = _note;
    });
  }

  Future<void> _saveNote(String note) async {
    final box = await Hive.openBox<dynamic>('hadith_notes');
    await box.put(_noteKey, note);
    setState(() => _note = note);
  }

  /// Canonical note key shared with the sharh sheet — book + in-book number.
  String get _noteKey => 'note_${widget.hadith.book}_${widget.hadith.number}';

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
        title: Text(AppLocalizations.of(context).schTitle),
        actions: [
          IconButton(
            icon: Icon(_highlightKeywords ? Icons.highlight : Icons.highlight_off),
            onPressed: () => setState(() => _highlightKeywords = !_highlightKeywords),
            tooltip: AppLocalizations.of(context).schHighlightTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareWithTakhrij,
            tooltip: AppLocalizations.of(context).schShareTooltip,
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
                color: _getGradeColor(widget.hadith.grade).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.hadith.grade.isEmpty ? AppLocalizations.of(context).schUngraded : widget.hadith.grade,
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
            if (_highlightKeywords) _buildHighlightedText(widget.hadith.text, theme) else Text(
                    widget.hadith.text,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 2,
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
                  AppLocalizations.of(context).schHadithNumber(widget.hadith.number),
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
      var found = false;
      
      for (final keyword in sortedKeywords) {
        if (text.substring(currentIndex).startsWith(keyword)) {
          spans.add(TextSpan(
            text: keyword,
            style: TextStyle(
              fontSize: 22,
              height: 2,
              fontFamily: 'Amiri',
              backgroundColor: _highlightColors[keyword],
            ),
          ),);
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
            height: 2,
            fontFamily: 'Amiri',
          ),
        ),);
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
        title: Text(AppLocalizations.of(context).schTakhrij),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTakhrijRow(AppLocalizations.of(context).schBook, _getBookName(widget.hadith.book)),
                _buildTakhrijRow(AppLocalizations.of(context).schChapter, AppLocalizations.of(context).schChapterValue(widget.hadith.chapter)),
                _buildTakhrijRow(AppLocalizations.of(context).schNumber, widget.hadith.number.toString()),
                if (widget.hadith.companion.isNotEmpty)
                  _buildTakhrijRow(AppLocalizations.of(context).schCompanion, widget.hadith.companion),
                if (widget.hadith.topics.isNotEmpty)
                  _buildTakhrijRow(AppLocalizations.of(context).schTopics, widget.hadith.topics.join(', ')),
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
        title: Text(AppLocalizations.of(context).schNotes),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).schNotesHint,
                    border: const OutlineInputBorder(),
                  ),
                  controller: _noteController,
                  onChanged: _saveNote,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).schNotesSaved,
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
        title: Text(AppLocalizations.of(context).sharhSimilar),
        children: [
          if (_loadingSimilar)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_similarHadiths.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(AppLocalizations.of(context).schNoSimilar),
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
                      MaterialPageRoute<void>(
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
              Text(AppLocalizations.of(context).schNoIsnad),
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
        title: Text(AppLocalizations.of(context).schIsnadAnalysis),
        subtitle: Text(AppLocalizations.of(context).schChainCount(_isnadChain.length)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Chain stats row
                Row(
                  children: [
                    _buildChainStat(AppLocalizations.of(context).schStatNarrators, '$narratorCount', NoorTheme.primary),
                    const SizedBox(width: 8),
                    _buildChainStat(AppLocalizations.of(context).schStatCompanions, '$companionCount', NoorTheme.hadithSahih),
                    const SizedBox(width: 8),
                    if (prophetCount > 0)
                      _buildChainStat(AppLocalizations.of(context).schStatProphet, '$prophetCount', NoorTheme.accentGold),
                  ],
                ),
                const SizedBox(height: 12),

                // Chain connectivity
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isnadChain.length >= 3
                        ? NoorTheme.hadithSahih.withValues(alpha: 0.08)
                        : NoorTheme.hadithDaif.withValues(alpha: 0.08),
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
                              ? AppLocalizations.of(context).schChainConnected(_isnadChain.length)
                              : AppLocalizations.of(context).schChainShort(_isnadChain.length),
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
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
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
          color: color.withValues(alpha: 0.1),
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
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
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
    showModalBottomSheet<void>(
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

              // Profile details (shared widget)
              NarratorProfileBody(
                narrator: narrator,
                profile: profile,
                accentColor: _getNarratorColor(narrator.role),
              ),
            ],
          ),
        ),
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
          label: Text(AppLocalizations.of(context).schCopyTakhrij),
          onPressed: _copyWithTakhrij,
        ),
        ActionChip(
          avatar: const Icon(Icons.image, size: 18),
          label: Text(AppLocalizations.of(context).hshareTitle),
          onPressed: () => _shareAsImage(context),
        ),
        ActionChip(
          avatar: const Icon(Icons.bookmark_border, size: 18),
          label: Text(AppLocalizations.of(context).schSaveReview),
          onPressed: _addToReview,
        ),
      ],
    );
  }

  void _copyWithTakhrij() {
    final l10n = AppLocalizations.of(context);
    final takhrij = '''
${widget.hadith.text}

${l10n.schTakhrijBook(_getBookName(widget.hadith.book))}
${l10n.schTakhrijChapter(widget.hadith.chapter, widget.hadith.number)}
${widget.hadith.grade.isNotEmpty ? l10n.schTakhrijGrade(widget.hadith.grade) : ''}
${widget.hadith.companion.isNotEmpty ? l10n.schTakhrijCompanion(widget.hadith.companion) : ''}

${l10n.schTakhrijApp}
''';
    
    Clipboard.setData(ClipboardData(text: takhrij));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.schCopiedTakhrij)),
    );
  }

  void _shareWithTakhrij() {
    HadithShareSheet.show(
      context,
      hadith: Hadith(
        id: widget.hadith.number,
        idInBook: widget.hadith.number,
        arabic: widget.hadith.text,
        englishText: '',
        narratorEnglish: widget.hadith.narrator,
        chapterId: widget.hadith.chapter,
        collectionId: widget.hadith.book,
      ),
      bookTitle: _getBookName(widget.hadith.book),
      bookColor: NoorDesignSystem.emeraldGreen,
    );
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
    final box = await Hive.openBox<dynamic>('hadith_review');
    final list = box.get('review_list', defaultValue: <String>[]) as List;
    if (!list.contains(widget.hadith.id)) {
      list.add(widget.hadith.id);
      await box.put('review_list', list);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).schAddedReview)),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.contains('صحيح')) return Colors.green;
    if (grade.contains('حسن')) return Colors.lightGreen;
    if (grade.contains('ضعيف')) return Colors.orange;
    return Colors.grey;
  }

  String _getBookName(String book) => hadithBookName(book);
}
