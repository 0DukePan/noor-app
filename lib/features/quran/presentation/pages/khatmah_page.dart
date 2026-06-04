import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/noor_theme.dart';
import '../providers/khatmah_providers.dart';

/// صفحة خطة الختمة - Khatmah Planner Page
class KhatmahPlannerPage extends ConsumerStatefulWidget {
  const KhatmahPlannerPage({super.key});

  @override
  ConsumerState<KhatmahPlannerPage> createState() => _KhatmahPlannerPageState();
}

class _KhatmahPlannerPageState extends ConsumerState<KhatmahPlannerPage> {
  @override
  Widget build(BuildContext context) {
    final khatmah = ref.watch(khatmahProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('خطة الختمة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showCreateKhatmahDialog,
          ),
        ],
      ),
      body: khatmah == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories_rounded, size: 64, color: NoorTheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('لا توجد ختمة نشطة', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showCreateKhatmahDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('بدء ختمة جديدة'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(NoorTheme.spacingMd),
              children: [
                // Active Khatmah Card
                _ActiveKhatmahCard(
                  name: khatmah.name,
                  startDate: khatmah.startDate,
                  targetEndDate: khatmah.targetEndDate,
                  currentSurah: khatmah.currentSurah,
                  currentVerse: khatmah.currentVerse,
                  currentPage: khatmah.currentPage,
                  progressPercentage: khatmah.progressPercentage,
                  onResume: () {
                    HapticFeedback.lightImpact();
                    context.push('/quran/surah/${khatmah.currentSurah}');
                  },
                ),

                const SizedBox(height: NoorTheme.spacingLg),

                // Daily Reading Goal — real data from provider
                ref.watch(todayPagesReadProvider).when(
                  data: (pagesRead) => _DailyGoalCard(
                    pagesPerDay: khatmah.dailyPagesNeeded,
                    pagesReadToday: pagesRead,
                  ),
                  loading: () => _DailyGoalCard(
                    pagesPerDay: khatmah.dailyPagesNeeded,
                    pagesReadToday: 0,
                  ),
                  error: (_, __) => _DailyGoalCard(
                    pagesPerDay: khatmah.dailyPagesNeeded,
                    pagesReadToday: 0,
                  ),
                ),

                const SizedBox(height: NoorTheme.spacingLg),

                // Reading Schedule — algorithmically generated
                Text(
                  'جدول القراءة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: NoorTheme.spacingMd),

                ...ref.watch(khatmahScheduleProvider).map((day) =>
                  _ScheduleCard(
                    day: day.dayLabel,
                    surahs: day.surahRange,
                    pages: day.pageRange,
                    isToday: day.isToday,
                  ),
                ),

                const SizedBox(height: NoorTheme.spacingLg),

                // Past Khatmahs — from Hive history
                Text(
                  'ختماتك السابقة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: NoorTheme.spacingMd),

                ref.watch(completedKhatmahsProvider).when(
                  data: (history) {
                    if (history.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(NoorTheme.spacingLg),
                          child: Text(
                            'لم تُتمم أي ختمة بعد',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: history.map((k) => _PastKhatmahCard(
                        name: k.name,
                        completedDate: k.completedDate,
                        durationDays: k.durationDays,
                      )).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
    );
  }

  void _showCreateKhatmahDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateKhatmahDialog(),
    );
  }
}

class _ActiveKhatmahCard extends StatelessWidget {
  final String name;
  final DateTime startDate;
  final DateTime? targetEndDate;
  final int currentSurah;
  final int currentVerse;
  final int currentPage;
  final double progressPercentage;
  final VoidCallback onResume;

  const _ActiveKhatmahCard({
    required this.name,
    required this.startDate,
    required this.targetEndDate,
    required this.currentSurah,
    required this.currentVerse,
    required this.currentPage,
    required this.progressPercentage,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NoorTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NoorTheme.primary, NoorTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(NoorTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: NoorTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: NoorTheme.spacingSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: NoorTheme.accentGold,
                  borderRadius: BorderRadius.circular(NoorTheme.radiusSm),
                ),
                child: Text(
                  'نشطة',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: NoorTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Spacer(),
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ),
          const SizedBox(height: NoorTheme.spacingLg),

          // Progress Bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progressPercentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: NoorTheme.accentGold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NoorTheme.spacingSm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progressPercentage * 100).toInt()}%',
                style: TextStyle(
                  color: NoorTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'صفحة $currentPage من 604',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),
            ],
          ),

          const SizedBox(height: NoorTheme.spacingLg),

          // Current Position
          Container(
            padding: const EdgeInsets.all(NoorTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bookmark_rounded,
                  color: NoorTheme.accentGold,
                ),
                const SizedBox(width: NoorTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'آخر موضع',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                      ),
                      Text(
                        'سورة ${surahName(currentSurah)} - آية $currentVerse',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onResume,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NoorTheme.accentGold,
                    foregroundColor: NoorTheme.textPrimary,
                  ),
                  child: const Text('متابعة'),
                ),
              ],
            ),
          ),

          if (targetEndDate != null) ...[
            const SizedBox(height: NoorTheme.spacingMd),
            Text(
              'الهدف: ${_formatDate(targetEndDate!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DailyGoalCard extends StatelessWidget {
  final int pagesPerDay;
  final int pagesReadToday;

  const _DailyGoalCard({
    required this.pagesPerDay,
    required this.pagesReadToday,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Guard against division by zero (happens when khatmah is complete)
    final safePagesPerDay = pagesPerDay == 0 ? 1 : pagesPerDay;
    final progress = pagesReadToday / safePagesPerDay;
    
    return Container(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today_rounded,
                color: NoorTheme.primary,
              ),
              const SizedBox(width: NoorTheme.spacingSm),
              Text(
                'هدف اليوم',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: NoorTheme.spacingMd),
          
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: NoorTheme.primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? NoorTheme.hadithSahih : NoorTheme.primary,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: NoorTheme.spacingMd),
              Text(
                '$pagesReadToday / $pagesPerDay صفحة',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: progress >= 1.0 ? NoorTheme.hadithSahih : null,
                    ),
              ),
            ],
          ),

          if (progress >= 1.0)
            Padding(
              padding: const EdgeInsets.only(top: NoorTheme.spacingSm),
              child: Text(
                '🎉 أحسنت! أتممت هدف اليوم',
                style: TextStyle(
                  color: NoorTheme.hadithSahih,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String day;
  final String surahs;
  final String pages;
  final bool isToday;

  const _ScheduleCard({
    required this.day,
    required this.surahs,
    required this.pages,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: NoorTheme.spacingSm),
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: isToday
            ? NoorTheme.primary.withOpacity(0.1)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
        border: isToday
            ? Border.all(color: NoorTheme.primary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70, // ✅ Wider to fit Arabic labels without overflow
            child: Text(
              day,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isToday ? NoorTheme.primary : null,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surahs,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'صفحات $pages',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PastKhatmahCard extends StatelessWidget {
  final String name;
  final DateTime completedDate;
  final int durationDays;

  const _PastKhatmahCard({
    required this.name,
    required this.completedDate,
    required this.durationDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: NoorTheme.spacingSm),
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(NoorTheme.spacingSm),
            decoration: BoxDecoration(
              color: NoorTheme.hadithSahih.withOpacity(0.1),
              borderRadius: BorderRadius.circular(NoorTheme.radiusSm),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: NoorTheme.hadithSahih,
            ),
          ),
          const SizedBox(width: NoorTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'أتممتها في $durationDays يوم',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${completedDate.day}/${completedDate.month}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _CreateKhatmahDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateKhatmahDialog> createState() => _CreateKhatmahDialogState();
}

class _CreateKhatmahDialogState extends ConsumerState<_CreateKhatmahDialog> {
  final _nameController = TextEditingController();
  int _durationDays = 30;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ختمة جديدة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              hintText: 'اسم الختمة (اختياري)',
              hintTextDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: NoorTheme.spacingMd),
          Row(
            children: [
              const Text('المدة:'),
              const Spacer(),
              DropdownButton<int>(
                value: _durationDays,
                items: [7, 14, 21, 30, 60, 90]
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text('$d يوم'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _durationDays = value!);
                },
              ),
            ],
          ),
          const SizedBox(height: NoorTheme.spacingSm),
          Text(
            '≈ ${(604 / _durationDays).ceil()} صفحة يومياً',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  await ref.read(khatmahProvider.notifier).startNew(
                    name: _nameController.text,
                    targetEndDate: DateTime.now().add(Duration(days: _durationDays)),
                  );
                  if (mounted) Navigator.pop(context);
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('ابدأ الختمة'),
        ),
      ],
    );
  }
}
