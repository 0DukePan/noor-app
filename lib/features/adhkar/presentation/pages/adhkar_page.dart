import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/adhkar_models.dart';
import '../../../../core/services/adhkar_data_source.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'adhkar_library_page.dart';

/// 📿 Adhkar Page - Modern & Premium Redesign
class AdhkarPage extends StatefulWidget {
  const AdhkarPage({super.key});

  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  // FIX 1: Cache counts from real data source instead of hardcoded values
  final Map<AdhkarType, int> _adhkarCounts = {};
  bool _isLoadingCounts = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final counts = <AdhkarType, int>{};
    for (final type in AdhkarType.values) {
      final collection = await AdhkarDataSource.getCollection(type);
      counts[type] = collection?.count ?? 0;
    }
    if (mounted) {
      setState(() {
        _adhkarCounts.addAll(counts);
        _isLoadingCounts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = AdhkarDataSource.getTodayStats();
    final streak = AdhkarDataSource.getStreak();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-highlight based on time
    final hour = DateTime.now().hour;
    final isMorning = hour >= 4 && hour < 12;
    final isEvening = hour >= 12 && hour < 20;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern AppBar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: Text(
                l10n.adhkarTitle,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : NoorDesignSystem.naskhBlack,
                ),
              ),
            ),
            actions: [
              if (streak > 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 20, top: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          l10n.adhkarStreakDays(streak),
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Today's Progress Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _TodayProgressCard(stats: stats),
            ),
          ),

          // Categories Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                // FIX 2: isHighlighted default changed to false — only morning/evening are highlighted by time
                _ModernCategoryCard(
                  title: l10n.adhkarMorning,
                  subtitle: _getCountLabel(AdhkarType.morning, l10n.adhkarUnitZekr),
                  emoji: '🌅',
                  gradient: LinearGradient(
                    colors: isMorning
                        ? [const Color(0xFFFFD54F), const Color(0xFFFFB300)]
                        : [
                            const Color(0xFFFFD54F).withValues(alpha: 0.5),
                            const Color(0xFFFFB300).withValues(alpha: 0.5),
                          ],
                  ),
                  isHighlighted: isMorning,
                  onTap: () => _openAdhkar(context, AdhkarType.morning),
                ),
                _ModernCategoryCard(
                  title: l10n.adhkarEvening,
                  subtitle: _getCountLabel(AdhkarType.evening, l10n.adhkarUnitZekr),
                  emoji: '🌇',
                  gradient: LinearGradient(
                    colors: isEvening
                        ? [const Color(0xFFFF7043), const Color(0xFFE64A19)]
                        : [
                            const Color(0xFFFF7043).withValues(alpha: 0.5),
                            const Color(0xFFE64A19).withValues(alpha: 0.5),
                          ],
                  ),
                  isHighlighted: isEvening,
                  onTap: () => _openAdhkar(context, AdhkarType.evening),
                ),
                _ModernCategoryCard(
                  title: l10n.adhkarAfterPrayer,
                  subtitle: _getCountLabel(AdhkarType.afterPrayer, l10n.adhkarUnitZekr),
                  emoji: '🕌',
                  gradient: const LinearGradient(
                    colors: [
                      NoorDesignSystem.emeraldGreen,
                      NoorDesignSystem.deepTeal,
                    ],
                  ),
                  // FIX 2: isHighlighted is false by default now
                  onTap: () => _openAdhkar(context, AdhkarType.afterPrayer),
                ),
                _ModernCategoryCard(
                  title: l10n.adhkarSleep,
                  subtitle: _getCountLabel(AdhkarType.sleep, l10n.adhkarUnitZekr),
                  emoji: '🌙',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                  ),
                  onTap: () => _openAdhkar(context, AdhkarType.sleep),
                ),
                _ModernCategoryCard(
                  title: l10n.adhkarWakeup,
                  subtitle: _getCountLabel(AdhkarType.wakeUp, l10n.adhkarUnitZekr),
                  emoji: '☀️',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
                  ),
                  onTap: () => _openAdhkar(context, AdhkarType.wakeUp),
                ),
                _ModernCategoryCard(
                  title: l10n.adhkarQuranic,
                  subtitle: _getCountLabel(AdhkarType.general, l10n.adhkarUnitDua),
                  emoji: '📖',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                  ),
                  onTap: () => _openAdhkar(context, AdhkarType.general),
                ),
                _ModernCategoryCard(
                  title: l10n.adhkarLibrary,
                  subtitle: l10n.adhkarLibrarySub,
                  emoji: '📚',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdhkarLibraryPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // FIX 1: Count comes from real data, shows loading state
  String _getCountLabel(AdhkarType type, String unit) {
    if (_isLoadingCounts) return '...';
    final count = _adhkarCounts[type] ?? 0;
    return '$count $unit';
  }

  void _openAdhkar(BuildContext context, AdhkarType type) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => AdhkarCounterPage(type: type),
          ),
        )
        .then((_) => setState(() {}));
  }
}

/// Modern Progress Card
class _TodayProgressCard extends StatelessWidget {

  const _TodayProgressCard({required this.stats});
  final DailyAdhkarStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stats.isComplete
              ? [const Color(0xFF4CAF50), const Color(0xFF388E3C)]
              : [NoorDesignSystem.emeraldGreen, NoorDesignSystem.deepTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (stats.isComplete
                    ? Colors.green
                    : NoorDesignSystem.emeraldGreen)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child: Text(
                      stats.isComplete ? '✅' : '📿',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.isComplete
                          ? l10n.adhkarTodayDone
                          : l10n.adhkarToday,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getProgressText(context),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: stats.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 16),

          // Status chips
          Wrap(
            spacing: 8,
            children: [
              _StatusChip(
                label: l10n.adhkarChipMorning,
                isComplete: stats.morningCompleted,
              ),
              _StatusChip(
                label: l10n.adhkarChipEvening,
                isComplete: stats.eveningCompleted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getProgressText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (stats.isComplete) return l10n.adhkarBlessed;

    final remaining = <String>[];
    if (!stats.morningCompleted) remaining.add(l10n.adhkarChipMorning);
    if (!stats.eveningCompleted) remaining.add(l10n.adhkarChipEvening);

    if (remaining.isEmpty) return l10n.adhkarAllDone;
    return l10n.adhkarRemainingJoined(remaining.join(' و '));
  }
}

class _StatusChip extends StatelessWidget {

  const _StatusChip({
    required this.label,
    required this.isComplete,
  });
  final String label;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isComplete ? Colors.white : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isComplete ? Colors.green[700] : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: isComplete ? Colors.green[700] : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern Category Card
class _ModernCategoryCard extends StatelessWidget {

  const _ModernCategoryCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.onTap, this.isHighlighted = false, // ? was: true (wrong)
  });
  final String title;
  final String subtitle;
  final String emoji;
  final Gradient gradient;

  // FIX 2: Default changed from true ? false so non-time-based cards are NOT highlighted
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            border: isHighlighted
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 2,)
                : null,
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 36),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADHKAR COUNTER PAGE
// ---------------------------------------------------------------------------

class AdhkarCounterPage extends StatefulWidget {

  const AdhkarCounterPage({required this.type, super.key});
  final AdhkarType type;

  @override
  State<AdhkarCounterPage> createState() => _AdhkarCounterPageState();
}

class _AdhkarCounterPageState extends State<AdhkarCounterPage>
    with SingleTickerProviderStateMixin {
  AdhkarCollection? _collection;
  AdhkarProgress _progress = const AdhkarProgress(type: AdhkarType.morning);
  AdhkarDisplaySettings _settings = const AdhkarDisplaySettings();

  late AnimationController _pulseController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    // FIX 3: All data fetched consistently as async
    final collection = await AdhkarDataSource.getCollection(widget.type);
    final progress = AdhkarDataSource.getProgress(widget.type);
    final settings = AdhkarDataSource.getSettings();

    if (mounted) {
      setState(() {
        _collection = collection;
        _progress = progress;
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Zekr? get _currentZekr {
    if (_collection == null) return null;
    if (_progress.currentIndex >= _collection!.count) return null;
    return _collection!.adhkar[_progress.currentIndex];
  }

  bool _isTapping = false;

  Future<void> _onTap() async {
    if (_collection == null || _progress.isCompleted) return;
    // Guard against rapid double-taps losing counts (the saved progress is
    // read before the async write completes).
    if (_isTapping) return;
    _isTapping = true;
    try {
      if (_settings.vibrateOnComplete) {
        unawaited(HapticFeedback.lightImpact());
      }

      unawaited(_pulseController.forward().then((_) => _pulseController.reverse()));

      final currentZekr = _currentZekr;
      if (currentZekr == null) return;

      if (_progress.currentCount + 1 >= currentZekr.repeat) {
        if (_settings.vibrateOnComplete) {
          unawaited(HapticFeedback.mediumImpact());
        }

        if (_progress.currentIndex + 1 >= _collection!.count) {
          await AdhkarDataSource.completeAdhkar(widget.type);
          AnalyticsService.record('adhkar_completed');
          if (!mounted) return;
          setState(() {
            _progress = _progress.complete();
          });
          _showCompletionDialog();
        } else {
          final newProgress = await AdhkarDataSource.nextZekr(widget.type);
          if (!mounted) return;
          setState(() => _progress = newProgress);
        }
      } else {
        final newProgress = await AdhkarDataSource.incrementCount(widget.type);
        if (!mounted) return;
        setState(() => _progress = newProgress);
      }
    } finally {
      _isTapping = false;
    }
  }

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Text('🎉', style: TextStyle(fontSize: 48)),
        title: Text(l10n.quizPassed),
        content: Text(l10n.adhkarCongratsBody(widget.type.arabicName)),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.adhkarDone),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.type.arabicName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_collection == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.type.arabicName)),
        body: Center(child: Text(l10n.adhkarNoAdhkar)),
      );
    }

    final currentZekr = _currentZekr;
    final totalProgress = _collection!.count == 0
        ? 0.0
        : _progress.currentIndex / _collection!.count;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.arabicName,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 20),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_progress.currentIndex + 1}/${_collection!.count}',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
            child: LinearProgressIndicator(
              value: totalProgress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              minHeight: 6,
            ),
          ),
        ),
      ),
      body: _progress.isCompleted
          ? _buildCompletedView(theme)
          : _buildCounterView(theme, currentZekr),
    );
  }

  Widget _buildCompletedView(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Text('✅', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.adhkarCongratsBody(widget.type.arabicName),
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface, // FIX 4: was onBackground (deprecated)
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.adhkarBlessAccept,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: Transform.flip(flipX: true, child: const Icon(Icons.arrow_back_rounded)),
            label: Text(l10n.adhkarBackToList,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterView(ThemeData theme, Zekr? currentZekr) {
    final l10n = AppLocalizations.of(context);
    if (currentZekr == null) return const SizedBox();

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _progress.currentCount / currentZekr.repeat,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            minHeight: 6,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          currentZekr.text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: _settings.fontSize + 12,
                            height: 2,
                            color: theme.colorScheme.onSurface, // FIX 4: was onBackground (deprecated)
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Animate(
                          key: ValueKey(_progress.currentCount),
                          effects: [
                            ScaleEffect(
                                duration: 200.ms,
                                curve: Curves.easeOutBack,),
                          ],
                          child: Text(
                            '${_progress.currentCount}',
                            style: GoogleFonts.cairo(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              height: 1,
                            ),
                          ),
                        ),
                        Text(
                          l10n.adhkarOfTotal(currentZekr.repeat),
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.tasbihHint,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (currentZekr.bless != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 16, color: theme.colorScheme.primary,),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentZekr.bless!,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
