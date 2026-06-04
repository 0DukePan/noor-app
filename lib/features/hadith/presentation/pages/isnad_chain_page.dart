import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/services/isnad_parser_service.dart';
import '../../../../core/services/narrator_database_service.dart';
import 'isnad_graph_page.dart';

/// 🔗 خريطة الإسناد التفاعلية - Interactive Isnad Chain Visualization
///
/// Professional timeline visualization with:
/// - Real narrator parsing from hadith text
/// - ListView.builder for performance
/// - ValueNotifier for efficient rebuilds
/// - Narrator biography from database lookup
/// - Animated connectors with link-word labels
class IsnadChainPage extends StatefulWidget {
  final String hadithId;
  final String hadithText;

  const IsnadChainPage({
    super.key,
    required this.hadithId,
    required this.hadithText,
  });

  @override
  State<IsnadChainPage> createState() => _IsnadChainPageState();
}

class _IsnadChainPageState extends State<IsnadChainPage>
    with SingleTickerProviderStateMixin {
  // Parsed chain from real hadith text
  List<NarratorInfo> _chain = [];
  bool _isLoading = true;

  // Use ValueNotifier instead of setState for selection
  final ValueNotifier<String?> _selectedNarrator = ValueNotifier(null);

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _loadChain();
  }

  Future<void> _loadChain() async {
    // Ensure narrator database is initialized
    await NarratorDatabaseService.init();

    // Parse the isnad chain from the hadith text
    final parsed = IsnadParserService.parseChain(widget.hadithText);

    if (mounted) {
      setState(() {
        _chain = parsed;
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _selectedNarrator.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? NoorDesignSystem.bgDark : const Color(0xFFFAF8F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'سلسلة الإسناد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Graph view toggle
          IconButton(
            icon: const Icon(Icons.account_tree_rounded, size: 22),
            tooltip: 'عرض الرسم البياني',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IsnadGraphPage(
                    hadithText: widget.hadithText,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _chain.isEmpty
              ? _buildEmptyState()
              : _buildChainView(isDark),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: NoorDesignSystem.primaryGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحليل سلسلة الإسناد...',
            style: GoogleFonts.cairo(
              color: NoorDesignSystem.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off_rounded,
              size: 64,
              color: NoorDesignSystem.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'لم يتم العثور على إسناد',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NoorDesignSystem.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لا يحتوي نص الحديث على سلسلة إسناد قابلة للتحليل',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: NoorDesignSystem.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChainView(bool isDark) {
    return Column(
      children: [
        // Hadith preview
        _buildHadithPreview(isDark),

        // Chain count badge
        _buildChainCountBadge(),

        // Chain visualization — ListView.builder for performance
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _chain.length * 2 - 1, // narrators + connectors
              itemBuilder: (context, index) {
                if (index.isEven) {
                  // Narrator card
                  final narratorIdx = index ~/ 2;
                  return _NarratorCard(
                    narrator: _chain[narratorIdx],
                    index: narratorIdx,
                    total: _chain.length,
                    selectedNotifier: _selectedNarrator,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _selectedNarrator.value =
                          _selectedNarrator.value == _chain[narratorIdx].normalizedName
                              ? null
                              : _chain[narratorIdx].normalizedName;
                    },
                  );
                } else {
                  // Connector between narrators
                  final nextIdx = (index + 1) ~/ 2;
                  return _IsnadConnector(
                    linkWord: nextIdx < _chain.length
                        ? _chain[nextIdx].linkWord
                        : 'عن',
                  );
                }
              },
            ),
          ),
        ),

        // Selected narrator detail panel
        ValueListenableBuilder<String?>(
          valueListenable: _selectedNarrator,
          builder: (context, selectedName, _) {
            if (selectedName == null) return const SizedBox.shrink();
            final narrator = _chain.firstWhere(
              (n) => n.normalizedName == selectedName,
              orElse: () => _chain.first,
            );
            return _NarratorDetailPanel(
              narrator: narrator,
              onClose: () => _selectedNarrator.value = null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildHadithPreview(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NoorDesignSystem.primaryGreen.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        widget.hadithText,
        style: GoogleFonts.amiri(
          fontSize: 15,
          height: 1.8,
          color: isDark ? NoorDesignSystem.textPrimaryDark : NoorDesignSystem.textPrimary,
        ),
        textDirection: TextDirection.rtl,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildChainCountBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [NoorDesignSystem.primaryGreen, NoorDesignSystem.deepTeal],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '${_chain.length} رواة في السلسلة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

// ═══════════════════════════════════════════════════════════════════════════
// NARRATOR CARD
// ═══════════════════════════════════════════════════════════════════════════

class _NarratorCard extends StatelessWidget {
  final NarratorInfo narrator;
  final int index;
  final int total;
  final ValueNotifier<String?> selectedNotifier;
  final VoidCallback onTap;

  const _NarratorCard({
    required this.narrator,
    required this.index,
    required this.total,
    required this.selectedNotifier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = NarratorDatabaseService.lookupFromNarratorInfo(narrator);

    return ValueListenableBuilder<String?>(
      valueListenable: selectedNotifier,
      builder: (context, selectedName, _) {
        final isSelected = selectedName == narrator.normalizedName;

        // Determine colors based on narrator type
        Color accentColor;
        Color bgColor;
        IconData icon;

        if (narrator.isProphet) {
          accentColor = NoorDesignSystem.goldAccent;
          bgColor = NoorDesignSystem.goldAccent.withOpacity(0.08);
          icon = Icons.star_rounded;
        } else if (narrator.isCompanion) {
          accentColor = NoorDesignSystem.gradeSahih;
          bgColor = NoorDesignSystem.gradeSahih.withOpacity(0.06);
          icon = Icons.shield_rounded;
        } else {
          accentColor = NoorDesignSystem.primaryGreen;
          bgColor = isDark
              ? NoorDesignSystem.surfaceElevatedDark
              : Colors.white;
          icon = Icons.person_rounded;
        }

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : accentColor.withOpacity(0.15),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Level indicator circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: narrator.isProphet
                          ? [NoorDesignSystem.goldAccent, const Color(0xFFD4A537)]
                          : narrator.isCompanion
                              ? [NoorDesignSystem.gradeSahih, NoorDesignSystem.gradeHasan]
                              : [NoorDesignSystem.primaryGreen, NoorDesignSystem.deepTeal],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: narrator.isProphet
                        ? Text('ﷺ', style: GoogleFonts.amiri(
                            color: Colors.white, fontSize: 18))
                        : Text(
                            '${total - index}',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name and role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        narrator.name,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: narrator.isProphet ? 18 : 16,
                          color: narrator.isProphet
                              ? NoorDesignSystem.goldAccent
                              : isDark
                                  ? NoorDesignSystem.textPrimaryDark
                                  : NoorDesignSystem.textPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(icon, size: 12, color: accentColor.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            narrator.role,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: NoorDesignSystem.textSecondary,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rank badge from database
                if (profile != null && profile.rank.isNotEmpty && !narrator.isProphet)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: NoorDesignSystem.gradeSahih.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: NoorDesignSystem.gradeSahih.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      profile.rank.length > 15
                          ? profile.rank.substring(0, 15)
                          : profile.rank,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: NoorDesignSystem.gradeSahih,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ISNAD CONNECTOR
// ═══════════════════════════════════════════════════════════════════════════

class _IsnadConnector extends StatelessWidget {
  final String linkWord;

  const _IsnadConnector({required this.linkWord});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left dotted line
          Container(
            width: 30,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  NoorDesignSystem.primaryGreen.withOpacity(0.0),
                  NoorDesignSystem.primaryGreen.withOpacity(0.3),
                ],
              ),
            ),
          ),

          // Link word badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: NoorDesignSystem.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NoorDesignSystem.primaryGreen.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 12,
                  color: NoorDesignSystem.primaryGreen.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  linkWord,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NoorDesignSystem.primaryGreen,
                  ),
                ),
              ],
            ),
          ),

          // Right dotted line
          Container(
            width: 30,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  NoorDesignSystem.primaryGreen.withOpacity(0.3),
                  NoorDesignSystem.primaryGreen.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NARRATOR DETAIL PANEL
// ═══════════════════════════════════════════════════════════════════════════

class _NarratorDetailPanel extends StatelessWidget {
  final NarratorInfo narrator;
  final VoidCallback onClose;

  const _NarratorDetailPanel({
    required this.narrator,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = NarratorDatabaseService.lookupFromNarratorInfo(narrator);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceElevatedDark : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClose,
              ),
              const Spacer(),
              Text(
                'بطاقة الراوي',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NoorDesignSystem.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.person_rounded,
                  color: NoorDesignSystem.primaryGreen, size: 20),
            ],
          ),
          const Divider(height: 20),

          // Name
          _DetailRow(label: 'الاسم', value: narrator.name),

          // Role
          _DetailRow(label: 'الطبقة', value: narrator.role),

          // From database
          if (profile != null) ...[
            if (profile.rank.isNotEmpty)
              _DetailRow(label: 'المرتبة', value: profile.rank),
            if (profile.rankSource.isNotEmpty)
              _DetailRow(label: 'المصدر', value: profile.rankSource),
            if (profile.deathYear > 0)
              _DetailRow(label: 'سنة الوفاة', value: profile.deathYearDisplay),
            if (profile.birthYear > 0)
              _DetailRow(label: 'سنة الولادة', value: profile.birthYearDisplay),

            // Teachers
            if (profile.teachers.isNotEmpty)
              _DetailRow(
                label: 'شيوخه',
                value: profile.teachers.join(' ، '),
              ),

            // Students
            if (profile.students.isNotEmpty)
              _DetailRow(
                label: 'تلاميذه',
                value: profile.students.join(' ، '),
              ),
          ] else ...[
            // Minimal info if not in database
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا تتوفر معلومات إضافية عن هذا الراوي في قاعدة البيانات',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: NoorDesignSystem.textSecondary.withOpacity(0.6),
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                color: NoorDesignSystem.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
