import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/noor_theme.dart';
import '../providers/hadith_providers.dart';

/// شجرة الموضوعات - Topic Tree Page
class TopicTreePage extends ConsumerStatefulWidget {
  const TopicTreePage({super.key});

  @override
  ConsumerState<TopicTreePage> createState() => _TopicTreePageState();
}

class _TopicTreePageState extends ConsumerState<TopicTreePage> {
  final Set<String> _expandedTopics = {};

  // Sample topic tree structure
  final List<TopicNode> _topics = [
    TopicNode(
      id: 'iman',
      nameArabic: 'الإيمان والعقيدة',
      icon: Icons.auto_awesome,
      children: [
        TopicNode(id: 'tawhid', nameArabic: 'التوحيد', hadithCount: 245),
        TopicNode(id: 'qadr', nameArabic: 'القضاء والقدر', hadithCount: 89),
        TopicNode(id: 'angels', nameArabic: 'الملائكة', hadithCount: 67),
        TopicNode(id: 'books', nameArabic: 'الكتب السماوية', hadithCount: 34),
        TopicNode(id: 'prophets', nameArabic: 'الأنبياء والرسل', hadithCount: 156),
        TopicNode(id: 'akhira', nameArabic: 'اليوم الآخر', hadithCount: 423),
      ],
    ),
    TopicNode(
      id: 'ibadat',
      nameArabic: 'العبادات',
      icon: Icons.mosque,
      children: [
        TopicNode(
          id: 'tahara',
          nameArabic: 'الطهارة',
          hadithCount: 567,
          children: [
            TopicNode(id: 'wudu', nameArabic: 'الوضوء', hadithCount: 234),
            TopicNode(id: 'ghusl', nameArabic: 'الغسل', hadithCount: 89),
            TopicNode(id: 'tayammum', nameArabic: 'التيمم', hadithCount: 45),
          ],
        ),
        TopicNode(
          id: 'salat',
          nameArabic: 'الصلاة',
          hadithCount: 1245,
          children: [
            TopicNode(id: 'fard', nameArabic: 'الفرائض', hadithCount: 456),
            TopicNode(id: 'sunnah', nameArabic: 'السنن والنوافل', hadithCount: 234),
            TopicNode(id: 'jumuah', nameArabic: 'الجمعة', hadithCount: 189),
            TopicNode(id: 'khushu', nameArabic: 'الخشوع', hadithCount: 78),
          ],
        ),
        TopicNode(id: 'zakat', nameArabic: 'الزكاة', hadithCount: 345),
        TopicNode(id: 'sawm', nameArabic: 'الصيام', hadithCount: 456),
        TopicNode(id: 'hajj', nameArabic: 'الحج والعمرة', hadithCount: 567),
      ],
    ),
    TopicNode(
      id: 'muamalat',
      nameArabic: 'المعاملات',
      icon: Icons.handshake,
      children: [
        TopicNode(id: 'buyu', nameArabic: 'البيوع', hadithCount: 345),
        TopicNode(id: 'ijara', nameArabic: 'الإجارة', hadithCount: 67),
        TopicNode(id: 'duyun', nameArabic: 'الديون', hadithCount: 89),
        TopicNode(id: 'waqf', nameArabic: 'الوقف', hadithCount: 45),
      ],
    ),
    TopicNode(
      id: 'akhlaq',
      nameArabic: 'الآداب والأخلاق',
      icon: Icons.favorite,
      children: [
        TopicNode(id: 'birr', nameArabic: 'بر الوالدين', hadithCount: 234),
        TopicNode(id: 'silah', nameArabic: 'صلة الرحم', hadithCount: 156),
        TopicNode(id: 'husnkhuluq', nameArabic: 'حسن الخلق', hadithCount: 345),
        TopicNode(id: 'sidq', nameArabic: 'الصدق', hadithCount: 123),
        TopicNode(id: 'sabr', nameArabic: 'الصبر', hadithCount: 189),
        TopicNode(id: 'shukr', nameArabic: 'الشكر', hadithCount: 98),
      ],
    ),
    TopicNode(
      id: 'adhkar',
      nameArabic: 'الأذكار والأدعية',
      icon: Icons.auto_stories,
      children: [
        TopicNode(id: 'sabah', nameArabic: 'أذكار الصباح', hadithCount: 45),
        TopicNode(id: 'masa', nameArabic: 'أذكار المساء', hadithCount: 45),
        TopicNode(id: 'nawm', nameArabic: 'أذكار النوم', hadithCount: 34),
        TopicNode(id: 'dua', nameArabic: 'الدعاء', hadithCount: 234),
      ],
    ),
    TopicNode(
      id: 'seerah',
      nameArabic: 'السيرة النبوية',
      icon: Icons.history_edu,
      children: [
        TopicNode(id: 'mawlid', nameArabic: 'المولد والنشأة', hadithCount: 89),
        TopicNode(id: 'bitha', nameArabic: 'البعثة', hadithCount: 67),
        TopicNode(id: 'hijra', nameArabic: 'الهجرة', hadithCount: 123),
        TopicNode(id: 'ghazawat', nameArabic: 'الغزوات', hadithCount: 345),
      ],
    ),
  ];

  void _toggleExpand(String topicId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_expandedTopics.contains(topicId)) {
        _expandedTopics.remove(topicId);
      } else {
        _expandedTopics.add(topicId);
      }
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
      body: ListView.builder(
        padding: const EdgeInsets.all(NoorTheme.spacingMd),
        itemCount: _topics.length,
        itemBuilder: (context, index) {
          return _buildTopicCard(_topics[index], 0);
        },
      ),
    );
  }

  Widget _buildTopicCard(TopicNode topic, int depth) {
    final isExpanded = _expandedTopics.contains(topic.id);
    final hasChildren = topic.children.isNotEmpty;
    final isRoot = depth == 0;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(
            right: depth * 16.0,
            bottom: NoorTheme.spacingSm,
          ),
          child: Material(
            color: isRoot
                ? Colors.white
                : NoorTheme.primary.withOpacity(0.02),
            borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
            elevation: isRoot ? 1 : 0,
            child: InkWell(
              onTap: () {
                if (hasChildren) {
                  _toggleExpand(topic.id);
                } else {
                  _openTopic(topic);
                }
              },
              borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(NoorTheme.spacingMd),
                child: Row(
                  children: [
                    // Icon
                    if (isRoot && topic.icon != null)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              NoorTheme.primary,
                              NoorTheme.primaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          topic.icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      )
                    else if (!isRoot)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: NoorTheme.primary.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),

                    SizedBox(width: isRoot ? NoorTheme.spacingMd : NoorTheme.spacingSm),

                    // Title and count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            topic.nameArabic,
                            style: TextStyle(
                              fontSize: isRoot ? 16 : 14,
                              fontWeight: isRoot ? FontWeight.bold : FontWeight.w500,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          if (topic.hadithCount > 0)
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

                    // Expand/chevron icon
                    if (hasChildren)
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: isExpanded ? 0.25 : 0,
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: NoorTheme.textSecondary,
                        ),
                      )
                    else
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
        ),

        // Children
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: topic.children.map((child) {
              return _buildTopicCard(child, depth + 1);
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _openTopic(TopicNode topic) {
    HapticFeedback.mediumImpact();
    // Navigate to hadiths filtered by topic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جارٍ تحميل أحاديث ${topic.nameArabic}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class TopicNode {
  final String id;
  final String nameArabic;
  final IconData? icon;
  final List<TopicNode> children;
  final int hadithCount;

  TopicNode({
    required this.id,
    required this.nameArabic,
    this.icon,
    this.children = const [],
    this.hadithCount = 0,
  });
}
