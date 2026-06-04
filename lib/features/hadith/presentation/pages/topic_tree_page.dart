import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/hadith_search_engine.dart';
import '../../../../core/theme/noor_theme.dart';

/// شجرة الموضوعات - Topic Tree Page
/// Dynamically loads topics and counts from HadithSearchEngine.
class TopicTreePage extends ConsumerStatefulWidget {
  const TopicTreePage({super.key});

  @override
  ConsumerState<TopicTreePage> createState() => _TopicTreePageState();
}

class _TopicTreePageState extends ConsumerState<TopicTreePage> {
  List<_TopicItem> _topics = [];
  bool _loading = true;

  // Mapping of known topic keywords to icons for visual polish
  static const Map<String, IconData> _topicIcons = {
    'الصلاة': Icons.access_time_rounded,
    'الصيام': Icons.nightlight_round,
    'الزكاة': Icons.volunteer_activism,
    'الحج': Icons.location_city_rounded,
    'الأخلاق': Icons.favorite_rounded,
    'الإيمان': Icons.auto_awesome,
    'العلم': Icons.school_rounded,
    'الجهاد': Icons.flag_rounded,
    'النكاح': Icons.people_rounded,
    'البيوع': Icons.shopping_bag_rounded,
    'الدعاء': Icons.volunteer_activism,
    'الآداب': Icons.emoji_people_rounded,
    'الطهارة': Icons.water_drop_rounded,
    'الجنائز': Icons.nightlight_round,
    'السيرة': Icons.history_edu_rounded,
    'الأذكار': Icons.auto_stories_rounded,
    'الأطعمة': Icons.restaurant_rounded,
    'اللباس': Icons.checkroom_rounded,
    'الطب': Icons.local_hospital_rounded,
    'الفتن': Icons.warning_rounded,
    'القيامة': Icons.hourglass_bottom_rounded,
    'الجنة': Icons.park_rounded,
    'النار': Icons.local_fire_department_rounded,
    'التوبة': Icons.refresh_rounded,
    'الدعوة': Icons.campaign_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  void _loadTopics() {
    final topicCounts = HadithSearchEngine.getTopicCounts();

    // Sort topics by hadith count descending
    final sorted = topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _topics = sorted.map((e) {
        // Pick an icon if we have a match, otherwise use a bookmark icon
        IconData icon = Icons.bookmark_rounded;
        for (final entry in _topicIcons.entries) {
          if (e.key.contains(entry.key)) {
            icon = entry.value;
            break;
          }
        }
        return _TopicItem(
          name: e.key,
          hadithCount: e.value,
          icon: icon,
        );
      }).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: const Text('التصنيف الموضوعي'),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _topics.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(NoorTheme.spacingMd),
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    return _buildTopicCard(_topics[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.topic_rounded, size: 64, color: NoorTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'لا توجد مواضيع بعد',
            style: TextStyle(color: NoorTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'يتم بناء الفهرس عند أول تحميل للأحاديث',
            style: TextStyle(color: NoorTheme.textSecondary.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(_TopicItem topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: NoorTheme.spacingSm),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
        elevation: 1,
        child: InkWell(
          onTap: () => _openTopic(topic),
          borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(NoorTheme.spacingMd),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [NoorTheme.primary, NoorTheme.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(topic.icon, color: Colors.white, size: 22),
                ),

                const SizedBox(width: NoorTheme.spacingMd),

                // Title and count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        topic.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      Text(
                        '${topic.hadithCount} حديث',
                        style: TextStyle(
                          fontSize: 12,
                          color: NoorTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: NoorTheme.textSecondary.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTopic(_TopicItem topic) {
    HapticFeedback.mediumImpact();
    // Navigate to hadiths filtered by topic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جارٍ تحميل أحاديث ${topic.name}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _TopicItem {
  final String name;
  final int hadithCount;
  final IconData icon;

  const _TopicItem({
    required this.name,
    required this.hadithCount,
    required this.icon,
  });
}
