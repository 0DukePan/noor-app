import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/noor_theme.dart';

/// إحصائيات التعلم - Learning Statistics Page
class LearningStatisticsPage extends StatefulWidget {
  const LearningStatisticsPage({super.key});

  @override
  State<LearningStatisticsPage> createState() => _LearningStatisticsPageState();
}

class _LearningStatisticsPageState extends State<LearningStatisticsPage> {
  // Sample statistics data
  final LearningStats _stats = LearningStats(
    totalHadithsRead: 523,
    totalHadithsMemorized: 47,
    currentStreak: 12,
    longestStreak: 28,
    totalReviewSessions: 156,
    averageSessionMinutes: 15,
    booksProgress: {
      'صحيح البخاري': BookProgress(read: 234, total: 7563),
      'صحيح مسلم': BookProgress(read: 156, total: 3032),
      'سنن أبي داود': BookProgress(read: 89, total: 4590),
      'جامع الترمذي': BookProgress(read: 44, total: 3956),
    },
    weeklyActivity: [3, 5, 2, 8, 4, 6, 7], // Last 7 days
    topicsCompleted: 12,
    quizzesTaken: 23,
    quizAverageScore: 78,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: const Text('إحصائياتي'),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(NoorTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Streak Card
            _buildStreakCard(),
            const SizedBox(height: NoorTheme.spacingMd),

            // Main Stats Grid
            Row(
              children: [
                Expanded(child: _buildStatCard('قرأت', '${_stats.totalHadithsRead}', 'حديث', Icons.menu_book_rounded, NoorTheme.primary)),
                const SizedBox(width: NoorTheme.spacingSm),
                Expanded(child: _buildStatCard('حفظت', '${_stats.totalHadithsMemorized}', 'حديث', Icons.psychology_rounded, NoorTheme.hadithSahih)),
              ],
            ),
            const SizedBox(height: NoorTheme.spacingSm),
            Row(
              children: [
                Expanded(child: _buildStatCard('اختبارات', '${_stats.quizzesTaken}', '${_stats.quizAverageScore}% متوسط', Icons.quiz_rounded, NoorTheme.accentGold)),
                const SizedBox(width: NoorTheme.spacingSm),
                Expanded(child: _buildStatCard('جلسات', '${_stats.totalReviewSessions}', '${_stats.averageSessionMinutes} دقيقة', Icons.timer_rounded, Colors.purple)),
              ],
            ),

            const SizedBox(height: NoorTheme.spacingLg),

            // Weekly Activity
            _buildSectionTitle('نشاط الأسبوع'),
            _buildWeeklyActivityChart(),

            const SizedBox(height: NoorTheme.spacingLg),

            // Books Progress
            _buildSectionTitle('تقدم الكتب'),
            ..._stats.booksProgress.entries.map((e) => _buildBookProgress(e.key, e.value)),

            const SizedBox(height: NoorTheme.spacingLg),

            // Achievements
            _buildSectionTitle('الإنجازات'),
            _buildAchievementsGrid(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NoorTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [NoorTheme.primary, NoorTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(NoorTheme.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'سلسلة الأيام',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${_stats.currentStreak}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🔥', style: TextStyle(fontSize: 36)),
                  ],
                ),
                Text(
                  'أطول سلسلة: ${_stats.longestStreak} يوم',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                title,
                style: TextStyle(
                  color: NoorTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: NoorTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NoorTheme.spacingMd),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildWeeklyActivityChart() {
    final maxActivity = _stats.weeklyActivity.reduce((a, b) => a > b ? a : b);
    final days = ['س', 'ج', 'خ', 'أ', 'ث', 'إ', 'ح'];

    return Container(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final activity = _stats.weeklyActivity[index];
          final height = maxActivity > 0 ? (activity / maxActivity) * 80 : 0.0;
          final isToday = index == 6;

          return Column(
            children: [
              Container(
                width: 28,
                height: 80,
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isToday
                          ? [NoorTheme.primary, NoorTheme.primaryDark]
                          : [
                              NoorTheme.primary.withOpacity(0.3),
                              NoorTheme.primary.withOpacity(0.5),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[index],
                style: TextStyle(
                  color: isToday ? NoorTheme.primary : NoorTheme.textSecondary,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              Text(
                '$activity',
                style: TextStyle(
                  color: NoorTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBookProgress(String bookName, BookProgress progress) {
    final percentage = progress.total > 0 ? (progress.read / progress.total) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: NoorTheme.spacingSm),
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: NoorTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                bookName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: NoorTheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(NoorTheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${progress.read} من ${progress.total}',
            style: TextStyle(
              color: NoorTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid() {
    final achievements = [
      Achievement('🌱', 'البداية', 'قرأ أول حديث', true),
      Achievement('📖', 'قارئ', 'قرأ 100 حديث', true),
      Achievement('🔥', 'مثابر', 'سلسلة 7 أيام', true),
      Achievement('💪', 'متفوق', 'اختبار 100%', true),
      Achievement('📚', 'عالم', 'قرأ 500 حديث', true),
      Achievement('🏆', 'حافظ', 'حفظ 50 حديث', false),
      Achievement('💎', 'خبير', 'أتم كتاباً', false),
      Achievement('👑', 'متميز', 'سلسلة 30 يوم', false),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: achievements.map((a) {
        return Container(
          width: (MediaQuery.of(context).size.width - 48) / 4,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: a.unlocked ? Colors.white : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
          ),
          child: Column(
            children: [
              Text(
                a.emoji,
                style: TextStyle(
                  fontSize: 28,
                  color: a.unlocked ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                a.title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: a.unlocked ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class LearningStats {
  final int totalHadithsRead;
  final int totalHadithsMemorized;
  final int currentStreak;
  final int longestStreak;
  final int totalReviewSessions;
  final int averageSessionMinutes;
  final Map<String, BookProgress> booksProgress;
  final List<int> weeklyActivity;
  final int topicsCompleted;
  final int quizzesTaken;
  final int quizAverageScore;

  LearningStats({
    required this.totalHadithsRead,
    required this.totalHadithsMemorized,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalReviewSessions,
    required this.averageSessionMinutes,
    required this.booksProgress,
    required this.weeklyActivity,
    required this.topicsCompleted,
    required this.quizzesTaken,
    required this.quizAverageScore,
  });
}

class BookProgress {
  final int read;
  final int total;

  BookProgress({required this.read, required this.total});
}

class Achievement {
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;

  Achievement(this.emoji, this.title, this.description, this.unlocked);
}
