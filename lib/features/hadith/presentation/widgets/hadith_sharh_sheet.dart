import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/data/data_sources/hadith_database.dart';
import '../../../../core/domain/entities/hadith.dart';
import '../../../../core/services/hadith_search_engine.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../hadith_book_names.dart';
import '../pages/isnad_chain_page.dart';
import '../pages/isnad_graph_page.dart';
import '../pages/narration_comparison_page.dart';
import '../pages/tags_management_page.dart';

/// 📖 شرح الحديث — Scholarly Explanation Bottom Sheet
/// Stage 7: Provides contextual explanation, grade analysis, benefits, and user notes
class HadithSharhSheet extends StatefulWidget {

  const HadithSharhSheet({
    required this.hadith, required this.bookTitle, required this.bookColor, super.key,
  });
  final Hadith hadith;
  final String bookTitle;
  final Color bookColor;

  /// Show the sheet from anywhere
  static Future<void> show(
    BuildContext context, {
    required Hadith hadith,
    required String bookTitle,
    required Color bookColor,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HadithSharhSheet(
        hadith: hadith,
        bookTitle: bookTitle,
        bookColor: bookColor,
      ),
    );
  }

  @override
  State<HadithSharhSheet> createState() => _HadithSharhSheetState();
}

class _HadithSharhSheetState extends State<HadithSharhSheet> {
  final _noteController = TextEditingController();
  List<HadithSearchResult> _similarHadiths = [];
  bool _loadingSimilar = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
    _loadSimilarHadiths();
  }

  Future<void> _loadNote() async {
    try {
      final box = await Hive.openBox<dynamic>('hadith_notes');
      final note = box.get(_noteKey, defaultValue: '') as String;
      setState(() {
        _noteController.text = note;
      });
    } on Exception catch (_) {}
  }

  Future<void> _saveNote(String note) async {
    try {
      final box = await Hive.openBox<dynamic>('hadith_notes');
      await box.put(_noteKey, note);
    } on Exception catch (_) {}
  }

  /// Canonical note key shared with Scholar Mode — book + in-book number.
  String get _noteKey =>
      'note_${widget.hadith.collectionId}_${widget.hadith.idInBook}';

  Future<void> _loadSimilarHadiths() async {
    try {
      // Search for similar hadiths using keywords from this hadith
      final words = widget.hadith.arabic.split(' ');
      if (words.length >= 3) {
        final searchTerms = words.sublist(0, 3).join(' ');
        final results = await HadithSearchEngine.search(searchTerms, limit: 5);
        if (mounted) {
          setState(() {
            // Exclude this exact hadith (same book + in-book number); the
            // entry id format differs from the entity id, so matching on
            // number is the reliable comparison.
            _similarHadiths = results
                .where((r) =>
                    !(r.entry.book == widget.hadith.collectionId &&
                        r.entry.number == widget.hadith.idInBook),)
                .take(3)
                .toList();
            _loadingSimilar = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingSimilar = false);
      }
    } on Exception catch (_) {
      if (mounted) setState(() => _loadingSimilar = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? NoorDesignSystem.surfaceDark : const Color(0xFFFAF8F5);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.bookColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.menu_book_rounded, color: widget.bookColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.sharhTitle(widget.hadith.idInBook),
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. Hadith Text (Preview)
                    _buildSection(
                      icon: Icons.format_quote_rounded,
                      title: l10n.sharhMatn,
                      color: widget.bookColor,
                      child: Text(
                        widget.hadith.arabic,
                        style: GoogleFonts.amiri(fontSize: 18, height: 2),
                        textDirection: TextDirection.rtl,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Source & Grade
                    _buildSection(
                      icon: Icons.verified_rounded,
                      title: l10n.sharhTakhrij,
                      color: NoorDesignSystem.primaryGreen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(label: l10n.sharhBook, value: widget.bookTitle),
                          _InfoRow(label: l10n.sharhNumber, value: '#${widget.hadith.idInBook}'),
                          if (widget.hadith.narratorEnglish.isNotEmpty)
                            _InfoRow(label: l10n.sharhNarrator, value: widget.hadith.narratorEnglish),
                          _InfoRow(
                            label: l10n.sharhSource,
                            value: _getCollectionFullName(widget.hadith.collectionId ?? ''),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Benefits / Key Points
                    _buildSection(
                      icon: Icons.lightbulb_rounded,
                      title: l10n.sharhBenefits,
                      color: NoorDesignSystem.goldAccent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _extractBenefits().map((benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💎 ', style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: GoogleFonts.cairo(fontSize: 14, height: 1.6),
                                ),
                              ),
                            ],
                          ),
                        ),).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. User Notes
                    _buildSection(
                      icon: Icons.edit_note_rounded,
                      title: l10n.sharhNotes,
                      color: Colors.orange,
                      child: Column(
                        children: [
                          TextField(
                            controller: _noteController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: l10n.sharhNotesHint,
                              hintStyle: GoogleFonts.cairo(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: NoorDesignSystem.primaryGreen),
                              ),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                            style: GoogleFonts.cairo(fontSize: 14),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: () {
                                _saveNote(_noteController.text);
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.sharhNoteSaved, style: GoogleFonts.cairo()),
                                    backgroundColor: NoorDesignSystem.primaryGreen,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.save_rounded, size: 16),
                              label: Text(l10n.tadSave, style: GoogleFonts.cairo()),
                              style: FilledButton.styleFrom(
                                backgroundColor: NoorDesignSystem.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Similar Hadiths
                    if (_similarHadiths.isNotEmpty || _loadingSimilar)
                      _buildSection(
                        icon: Icons.compare_arrows_rounded,
                        title: l10n.sharhSimilar,
                        color: Colors.blue,
                        child: _loadingSimilar
                            ? const Center(child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),)
                            : Column(
                                children: _similarHadiths.map((h) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h.entry.text,
                                        style: GoogleFonts.amiri(fontSize: 14, height: 1.8),
                                        textDirection: TextDirection.rtl,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${h.entry.book} - #${h.entry.number}',
                                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),).toList(),
                              ),
                      ),
                    const SizedBox(height: 16),

                    // 6. Study Tools (Isnad & Cross-References)
                      _buildSection(
                        icon: Icons.school_rounded,
                        title: l10n.sharhTools,
                      color: Colors.deepPurple,
                      child: Column(
                        children: [
                          // Isnad Chain
                          _StudyToolButton(
                            icon: Icons.account_tree_rounded,
                            label: l10n.sharhIsnadMap,
                            subtitle: l10n.sharhIsnadMapSub,
                            color: Colors.deepPurple,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute<void>(
                                builder: (_) => IsnadChainPage(
                                  hadithId: widget.hadith.id.toString(),
                                  hadithText: widget.hadith.arabic,
                                ),
                              ),);
                            },
                          ),
                          const SizedBox(height: 8),
                          // Isnad Graph
                          _StudyToolButton(
                            icon: Icons.hub_rounded,
                            label: l10n.igTitle,
                            subtitle: l10n.sharhIsnadGraphSub,
                            color: Colors.indigo,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute<void>(
                                builder: (_) => IsnadGraphPage(
                                  hadithText: widget.hadith.arabic,
                                  hadithSource: widget.bookTitle,
                                ),
                              ),);
                            },
                          ),
                          // Cross-References
                          _StudyToolButton(
                            icon: Icons.compare_arrows_rounded,
                            label: l10n.sharhCompare,
                            subtitle: l10n.sharhCompareSub,
                            color: Colors.teal,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute<void>(
                                builder: (_) => NarrationComparisonPage(
                                  hadithKeyword: widget.hadith.arabic.split(' ').take(4).join(' '),
                                ),
                              ),);
                            },
                          ),
                          // Add to a personal tag
                          _StudyToolButton(
                            icon: Icons.label_outline_rounded,
                            label: l10n.sharhAddTag,
                            subtitle: l10n.sharhAddTagSub,
                            color: Colors.brown,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute<void>(
                                builder: (_) => TagsManagementPage(
                                  hadithId: widget.hadith.id.toString(),
                                ),
                              ),);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Extract contextual benefits from the hadith text
  List<String> _extractBenefits() {
    // The corpus is fully vocalized, so keywords are matched against the
    // de-diacritized text.
    final text = HadithDatabase.normalizeForSearch(widget.hadith.arabic);
    final benefits = <String>[];

    // Common hadith themes to extract benefits for
    if (text.contains('صلاة') || text.contains('صلى')) {
      benefits.add('يدل الحديث على أهمية الصلاة وفضلها');
    }
    if (text.contains('ذكر') || text.contains('سبحان')) {
      benefits.add('فيه الحث على ذكر الله تعالى والمداومة عليه');
    }
    if (text.contains('صبر') || text.contains('ابتلاء')) {
      benefits.add('فيه بيان فضل الصبر على البلاء وعظم أجره');
    }
    if (text.contains('صدق') || text.contains('كذب')) {
      benefits.add('فيه التحذير من الكذب والحث على الصدق');
    }
    if (text.contains('رحم') || text.contains('إحسان')) {
      benefits.add('فيه الحث على الرحمة والإحسان إلى الخلق');
    }
    if (text.contains('علم') || text.contains('تعلم')) {
      benefits.add('فيه فضل طلب العلم والحث عليه');
    }
    if (text.contains('توبة') || text.contains('استغفار')) {
      benefits.add('فيه بيان سعة رحمة الله وقبوله للتوبة');
    }
    if (text.contains('صيام') || text.contains('صام')) {
      benefits.add('فيه فضل الصيام وعظم ثوابه عند الله');
    }
    if (text.contains('قرآن') || text.contains('كتاب الله')) {
      benefits.add('فيه الحث على تلاوة القرآن والعمل به');
    }
    if (text.contains('جنة') || text.contains('نار')) {
      benefits.add('فيه تذكير بالآخرة والترغيب في الجنة والتحذير من النار');
    }

    // Always add general benefit
    if (benefits.isEmpty) {
      benefits.add('فيه من الفوائد التربوية والإيمانية ما ينبغي التأمل فيه');
    }
    benefits.add('ينبغي حفظ هذا الحديث والعمل بمقتضاه');

    return benefits;
  }

  String _getCollectionFullName(String id) {
    final name = hadithBookName(id);
    return name == id ? widget.bookTitle : name;
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: GoogleFonts.cairo(
              fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600,
            ),),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StudyToolButton extends StatelessWidget {

  const _StudyToolButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.cairo(
                      fontSize: 14, fontWeight: FontWeight.bold, color: color,
                    ),),
                    Text(subtitle, style: GoogleFonts.cairo(
                      fontSize: 11, color: Colors.grey,
                    ),),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
