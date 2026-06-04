import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/services/hadith_user_data_service.dart';
import '../../../../core/theme/noor_theme.dart';

/// إحصائيات التعلم - Learning Statistics Page
/// Loads real user data from Hive (bookmarks, notes, quiz scores, memorization).
class LearningStatisticsPage extends StatefulWidget {
  const LearningStatisticsPage({super.key});

  @override
  State<LearningStatisticsPage> createState() => _LearningStatisticsPageState();
}

class _LearningStatisticsPageState extends State<LearningStatisticsPage> {
  bool _loading = true;
  late _RealStats _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // --- Bookmarks ---
    final bookmarks = HadithUserDataService.getAllBookmarks();
    final totalBookmarked = bookmarks.length;

    // --- Notes ---
    int totalNotes = 0;
    try {
      final notesBox = await Hive.openBox('hadith_notes');
      totalNotes = notesBox.length;
    } catch (_) {}

    // --- Quiz history ---
    int quizzesTaken = 0;
    int quizTotalScore = 0;
    int quizTotalQuestions = 0;
    try {
      final quizBox = await Hive.openBox('quiz_history');
      for (final key in quizBox.keys) {
        final entry = quizBox.get(key);
        if (entry is Map) {
          quizzesTaken++;
          quizTotalScore += (entry['score'] as int?) ?? 0;
          quizTotalQuestions += (entry['total'] as int?) ?? 0;
        }
      }
    } catch (_) {}
    final quizAverage = quizTotalQuestions > 0
        ? ((quizTotalScore / quizTotalQuestions) * 100).round()
        : 0;

    // --- Memorization intervals ---
    int totalMemorized = 0;
    try {
      final memBox = await Hive.openBox('memorization_intervals');
      totalMemorized = memBox.length;
    } catch (_) {}

    // --- Reading streak (from progress box) ---
    int currentStreak = 0;
    int longestStreak = 0;
    try {
      final streakBox = await Hive.openBox('reading_streak');
      currentStreak = streakBox.get('current', defaultValue: 0) as int;
      longestStreak = streakBox.get('longest', defaultValue: 0) as int;
    } catch (_) {}

    // --- Weekly activity (last 7 days read counts) ---
    List<int> weeklyActivity = List.filled(7, 0);
    try {
      final activityBox = await Hive.openBox('daily_activity');
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: 6 - i));
        final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        weeklyActivity[i] = (activityBox.get(key, defaultValue: 0) as int);
      }
    } catch (_) {}

    // --- Books progress (bookmarks per book) ---
    final Map<String, _BookProg> booksProgress = {};
    for (final bm in bookmarks) {
      final coll = bm['collectionId'] as String? ?? '';
      if (coll.isNotEmpty) {
        booksProgress.putIfAbsent(coll, () => _BookProg(read: 0, total: 0));
        booksProgress[coll] = _BookProg(
          read: booksProgress[coll]!.read + 1,
          total: booksProgress[coll]!.total,
        );
      }
    }

    setState(() {
      _stats = _RealStats(
        totalBookmarked: totalBookmarked,
        totalNotes: totalNotes,
        totalMemorized: totalMemorized,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        quizzesTaken: quizzesTaken,
        quizAverageScore: quizAverage,
        weeklyActivity: weeklyActivity,
        booksProgress: booksProgress,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: const Text('إحصائياتي'),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      Expanded(child: _buildStatCard('محفوظات', '${_stats.totalBookmarked}', 'حديث', Icons.bookmark_rounded, NoorTheme.primary)),
                      const SizedBox(width: NoorTheme.spacingSm),
                      Expanded(child: _buildStatCard('ملاحظات', '${_stats.totalNotes}', 'ملاحظة', Icons.note_rounded, NoorTheme.hadithSahih)),
                    ],
                  ),
                  const SizedBox(height: NoorTheme.spacingSm),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('اختبارات', '${_stats.quizzesTaken}', '${_stats.quizAverageScore}% متوسط', Icons.quiz_rounded, NoorTheme.accentGold)),
                      const SizedBox(width: NoorTheme.spacingSm),
                      Expanded(child: _buildStatCard('حفظ', '${_stats.totalMemorized}', 'بطاقة', Icons.psychology_rounded, Colors.purple)),
                    ],
                  ),

                  const SizedBox(height: NoorTheme.spacingLg),

                  // Weekly Activity
                  _buildSectionTitle('نشاط الأسبوع'),
                  _buildWeeklyActivityChart(),

                  const SizedBox(height: NoorTheme.spacingLg),

                  // Books bookmarked
                  if (_stats.booksProgress.isNotEmpty) ...[
                    _buildSectionTitle('المحفوظات حسب الكتب'),
                    ..._stats.booksProgress.entries.map(
                      (e) => _buildBookProgress(_getBookName(e.key), e.value),
                    ),
                  ],

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
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                style: TextStyle(color: NoorTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            subtitle,
            style: TextStyle(color: NoorTheme.textSecondary, fontSize: 11),
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
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWeeklyActivityChart() {
    final maxActivity = _stats.weeklyActivity.fold<int>(0, (a, b) => a > b ? a : b);
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
                          : [NoorTheme.primary.withOpacity(0.3), NoorTheme.primary.withOpacity(0.5)],
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
                style: TextStyle(color: NoorTheme.textSecondary, fontSize: 10),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBookProgress(String bookName, _BookProg progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: NoorTheme.spacingSm),
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: NoorTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${progress.read}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: NoorTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              bookName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textDirection: TextDirection.rtl,
            ),
          ),
          Text(
            '${progress.read} محفوظ',
            style: TextStyle(color: NoorTheme.textSecondary, fontSize: 12),
          ),
        ],
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
      'nawawi40': 'الأربعون النووية',
      'qudsi40': 'الأحاديث القدسية',
    };
    return names[book] ?? book;
  }
}

class _RealStats {
  final int totalBookmarked;
  final int totalNotes;
  final int totalMemorized;
  final int currentStreak;
  final int longestStreak;
  final int quizzesTaken;
  final int quizAverageScore;
  final List<int> weeklyActivity;
  final Map<String, _BookProg> booksProgress;

  const _RealStats({
    required this.totalBookmarked,
    required this.totalNotes,
    required this.totalMemorized,
    required this.currentStreak,
    required this.longestStreak,
    required this.quizzesTaken,
    required this.quizAverageScore,
    required this.weeklyActivity,
    required this.booksProgress,
  });
}

class _BookProg {
  final int read;
  final int total;

  const _BookProg({required this.read, required this.total});
}
