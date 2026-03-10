import 'package:flutter/material.dart';

import '../../../../core/theme/noor_theme.dart';

/// صفحة خطة الختمة - Khatmah Planner Page
class KhatmahPlannerPage extends StatefulWidget {
  const KhatmahPlannerPage({super.key});

  @override
  State<KhatmahPlannerPage> createState() => _KhatmahPlannerPageState();
}

class _KhatmahPlannerPageState extends State<KhatmahPlannerPage> {
  // Sample data - would come from repository
  final _activeKhatmah = {
    'name': 'ختمة رمضان',
    'startDate': DateTime(2026, 3, 1),
    'targetEndDate': DateTime(2026, 3, 30),
    'currentSurah': 18,
    'currentVerse': 45,
    'currentPage': 299,
    'progressPercentage': 0.48,
  };

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.all(NoorTheme.spacingMd),
        children: [
          // Active Khatmah Card
          _ActiveKhatmahCard(
            name: _activeKhatmah['name'] as String,
            startDate: _activeKhatmah['startDate'] as DateTime,
            targetEndDate: _activeKhatmah['targetEndDate'] as DateTime?,
            currentSurah: _activeKhatmah['currentSurah'] as int,
            currentVerse: _activeKhatmah['currentVerse'] as int,
            currentPage: _activeKhatmah['currentPage'] as int,
            progressPercentage: _activeKhatmah['progressPercentage'] as double,
            onResume: () {
              // Navigate to current reading position
            },
          ),

          const SizedBox(height: NoorTheme.spacingLg),

          // Daily Reading Goal
          _DailyGoalCard(
            pagesPerDay: 20,
            pagesReadToday: 12,
          ),

          const SizedBox(height: NoorTheme.spacingLg),

          // Reading Schedule
          Text(
            'جدول القراءة',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NoorTheme.spacingMd),

          _ScheduleCard(
            day: 'اليوم',
            surahs: 'الكهف - مريم - طه',
            pages: '293 - 312',
            isToday: true,
          ),
          _ScheduleCard(
            day: 'غداً',
            surahs: 'الأنبياء - الحج',
            pages: '312 - 331',
            isToday: false,
          ),
          _ScheduleCard(
            day: 'بعد غد',
            surahs: 'المؤمنون - النور',
            pages: '331 - 350',
            isToday: false,
          ),

          const SizedBox(height: NoorTheme.spacingLg),

          // Past Khatmahs
          Text(
            'ختماتك السابقة',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NoorTheme.spacingMd),

          _PastKhatmahCard(
            name: 'ختمة شهر محرم',
            completedDate: DateTime(2025, 8, 15),
            durationDays: 30,
          ),
          _PastKhatmahCard(
            name: 'ختمة شعبان',
            completedDate: DateTime(2025, 3, 1),
            durationDays: 20,
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
                        'سورة الكهف - آية $currentVerse',
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
    final progress = pagesReadToday / pagesPerDay;
    
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
          Container(
            width: 60,
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

class _CreateKhatmahDialog extends StatefulWidget {
  @override
  State<_CreateKhatmahDialog> createState() => _CreateKhatmahDialogState();
}

class _CreateKhatmahDialogState extends State<_CreateKhatmahDialog> {
  final _nameController = TextEditingController();
  int _durationDays = 30;

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
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            // Create khatmah
            Navigator.pop(context);
          },
          child: const Text('ابدأ الختمة'),
        ),
      ],
    );
  }
}
