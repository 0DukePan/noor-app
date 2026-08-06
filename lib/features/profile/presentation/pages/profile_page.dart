import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/services/statistics_service.dart';
import '../providers/profile_providers.dart';

/// 📊 صفحة الملف الشخصي — User Profile Dashboard
/// Wires StatisticsService into a premium reading analytics UI
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? NoorDesignSystem.bgDark : NoorDesignSystem.bgLight,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(profileStatsProvider),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Premium App Bar ──
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: NoorDesignSystem.primaryGreen,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                title: Text(
                  'ملفي الشخصي',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        NoorDesignSystem.primaryGreen,
                        NoorDesignSystem.primaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative pattern
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 160,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -10,
                        child: Icon(
                          Icons.mosque_rounded,
                          size: 120,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Today's Stats Grid ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  '📊 إحصائيات اليوم',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _StatCard(
                    icon: Icons.menu_book_rounded,
                    title: 'آيات مقروءة',
                    value: '${stats.todayReading.versesRead}',
                    subtitle: 'اليوم',
                    gradient: [NoorDesignSystem.primaryGreen, NoorDesignSystem.primaryLight],
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.timer_outlined,
                    title: 'وقت القراءة',
                    value: stats.todayReading.formattedTime,
                    subtitle: 'اليوم',
                    gradient: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.headphones_rounded,
                    title: 'الاستماع',
                    value: '${stats.listening.todayVerses}',
                    subtitle: 'آيات اليوم',
                    gradient: [const Color(0xFF6A1B9A), const Color(0xFF9C27B0)],
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    title: 'سلسلة الأذكار',
                    value: '${stats.adhkarStreak}',
                    subtitle: stats.adhkarStreak == 1 ? 'يوم' : 'أيام',
                    gradient: [const Color(0xFFE65100), const Color(0xFFFF9800)],
                    isDark: isDark,
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
              ),
            ),

            // ── Adhkar Status ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  '🤲 أذكار اليوم',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: NoorDesignSystem.shadowSmall,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _AdhkarCheckItem(
                        icon: Icons.wb_sunny_rounded,
                        label: 'أذكار الصباح',
                        isComplete: stats.adhkarStatus.morningComplete,
                        color: NoorDesignSystem.morningColor,
                      ),
                      const SizedBox(width: 24),
                      _AdhkarCheckItem(
                        icon: Icons.nightlight_rounded,
                        label: 'أذكار المساء',
                        isComplete: stats.adhkarStatus.eveningComplete,
                        color: NoorDesignSystem.eveningColor,
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text(
                            '${stats.adhkarStatus.afterPrayerCount}',
                            style: GoogleFonts.cairo(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: NoorDesignSystem.prayerColor,
                            ),
                          ),
                          Text(
                            'بعد الصلاة',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Khatmah Progress ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  '📖 تقدم الختمة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: NoorDesignSystem.shadowSmall,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Circular progress
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: stats.khatmah.percentage / 100,
                              strokeWidth: 8,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : NoorDesignSystem.primaryContainer,
                              valueColor: const AlwaysStoppedAnimation(
                                NoorDesignSystem.primaryGreen,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Text(
                                stats.khatmah.formattedPercentage,
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: NoorDesignSystem.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'السورة ${stats.khatmah.surah} — الآية ${stats.khatmah.ayah}',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ stats.completedKhatmah} ختمات مكتملة',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  await StatisticsService.startNewKhatmah();
                                  ref.invalidate(profileStatsProvider);
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: Text('بدء ختمة جديدة',
                                  style: GoogleFonts.cairo(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: NoorDesignSystem.primaryGreen,
                                  side: const BorderSide(
                                    color: NoorDesignSystem.primaryGreen,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Weekly Summary ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  '📈 ملخص الأسبوع',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: NoorDesignSystem.shadowSmall,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _WeeklyRow(
                        icon: Icons.menu_book_rounded,
                        label: 'آيات مقروءة',
                        value: '${stats.weekly.versesRead}',
                        color: NoorDesignSystem.primaryGreen,
                      ),
                      const Divider(height: 24),
                      _WeeklyRow(
                        icon: Icons.timer_outlined,
                        label: 'وقت القراءة',
                        value: _formatDuration(stats.weekly.readingTime),
                        color: const Color(0xFF1565C0),
                      ),
                      const Divider(height: 24),
                      _WeeklyRow(
                        icon: Icons.headphones_rounded,
                        label: 'وقت الاستماع',
                        value: _formatDuration(stats.weekly.listeningTime),
                        color: const Color(0xFF6A1B9A),
                      ),
                      const Divider(height: 24),
                      _WeeklyRow(
                        icon: Icons.check_circle_rounded,
                        label: 'أيام أذكار كاملة',
                        value: '${stats.weekly.completeAdhkarDays}/7',
                        color: NoorDesignSystem.morningColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Total Stats ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  '🏆 الإحصائيات الكلية',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1A3A2A), const Color(0xFF1A2A35)]
                          : [
                              NoorDesignSystem.primaryGreen.withOpacity(0.08),
                              const Color(0xFF1565C0).withOpacity(0.08),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: NoorDesignSystem.primaryGreen.withOpacity(0.15),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TotalStatBubble(
                        value: '${stats.totalReading.versesRead}',
                        label: 'آية',
                        icon: Icons.menu_book_rounded,
                        color: NoorDesignSystem.primaryGreen,
                      ),
                      _TotalStatBubble(
                        value: stats.totalReading.formattedTime,
                        label: 'قراءة',
                        icon: Icons.timer_outlined,
                        color: const Color(0xFF1565C0),
                      ),
                      _TotalStatBubble(
                        value: '${stats.completedKhatmah}',
                        label: 'ختمات',
                        icon: Icons.auto_stories_rounded,
                        color: NoorDesignSystem.goldAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds} ثانية';
    if (d.inHours < 1) return '${d.inMinutes} دقيقة';
    return '${d.inHours} س ${d.inMinutes % 60} د';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAT CARD
// ═══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final List<Color> gradient;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.gradient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? NoorDesignSystem.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? NoorDesignSystem.textSecondaryDark
                        : NoorDesignSystem.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: gradient.first,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: isDark
                      ? NoorDesignSystem.textSecondaryDark
                      : NoorDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADHKAR CHECK ITEM
// ═══════════════════════════════════════════════════════════════════════════

class _AdhkarCheckItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isComplete;
  final Color color;

  const _AdhkarCheckItem({
    required this.icon,
    required this.label,
    required this.isComplete,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isComplete ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isComplete ? Icons.check_rounded : icon,
            color: isComplete ? color : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isComplete ? color : Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WEEKLY ROW
// ═══════════════════════════════════════════════════════════════════════════

class _WeeklyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _WeeklyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOTAL STAT BUBBLE
// ═══════════════════════════════════════════════════════════════════════════

class _TotalStatBubble extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _TotalStatBubble({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
