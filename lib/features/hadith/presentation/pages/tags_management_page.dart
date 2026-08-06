import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/theme/noor_theme.dart';

/// الوسوم الشخصية - Personal Tags System
class PersonalTagsService {
  static const _boxName = 'personal_tags';
  static Box<Map>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  static List<PersonalTag> getAllTags() {
    if (_box == null) return [];
    return _box!.values
        .map((m) => PersonalTag.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  static Future<void> addTag(PersonalTag tag) async {
    await _box?.put(tag.id, tag.toJson());
  }

  static Future<void> removeTag(String tagId) async {
    await _box?.delete(tagId);
  }

  static Future<void> addHadithToTag(String tagId, String hadithId) async {
    final tagData = _box?.get(tagId);
    if (tagData != null) {
      final tag = PersonalTag.fromJson(Map<String, dynamic>.from(tagData));
      if (!tag.hadithIds.contains(hadithId)) {
        tag.hadithIds.add(hadithId);
        await _box?.put(tagId, tag.toJson());
      }
    }
  }

  static Future<void> removeHadithFromTag(String tagId, String hadithId) async {
    final tagData = _box?.get(tagId);
    if (tagData != null) {
      final tag = PersonalTag.fromJson(Map<String, dynamic>.from(tagData));
      tag.hadithIds.remove(hadithId);
      await _box?.put(tagId, tag.toJson());
    }
  }

  static List<PersonalTag> getTagsForHadith(String hadithId) {
    return getAllTags().where((t) => t.hadithIds.contains(hadithId)).toList();
  }
}

class PersonalTag {
  final String id;
  String name;
  Color color;
  String icon;
  List<String> hadithIds;
  DateTime createdAt;

  PersonalTag({
    required this.id,
    required this.name,
    required this.color,
    this.icon = '🏷️',
    List<String>? hadithIds,
    DateTime? createdAt,
  })  : hadithIds = hadithIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
        'icon': icon,
        'hadithIds': hadithIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PersonalTag.fromJson(Map<String, dynamic> json) => PersonalTag(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        icon: json['icon'] as String? ?? '🏷️',
        hadithIds: List<String>.from(json['hadithIds'] as List? ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// صفحة إدارة الوسوم - Tags Management Page
class TagsManagementPage extends StatefulWidget {
  const TagsManagementPage({super.key});

  @override
  State<TagsManagementPage> createState() => _TagsManagementPageState();
}

class _TagsManagementPageState extends State<TagsManagementPage> {
  List<PersonalTag> _tags = [];
  final _nameController = TextEditingController();
  Color _selectedColor = NoorTheme.primary;
  String _selectedIcon = '🏷️';

  final List<Color> _colors = [
    NoorTheme.primary,
    NoorTheme.accentGold,
    NoorTheme.hadithSahih,
    NoorTheme.hadithHasan,
    NoorTheme.hadithDaif,
    Colors.purple,
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.pink,
  ];

  final List<String> _icons = [
    '🏷️', '📖', '⭐', '❤️', '🔖', '📝', '🕌', '🤲', '📚', '💡',
    '🎯', '✅', '🔥', '💪', '🌙', '☀️', '🌟', '💎', '🏆', '🎓',
  ];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    await PersonalTagsService.init();
    setState(() {
      _tags = PersonalTagsService.getAllTags();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showCreateTagDialog() {
    _nameController.clear();
    _selectedColor = NoorTheme.primary;
    _selectedIcon = '🏷️';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(NoorTheme.radiusXl),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(NoorTheme.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'إنشاء وسم جديد',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: NoorTheme.spacingLg),

                // Tag name
                TextField(
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'اسم الوسم (مثال: للمراجعة)',
                    hintTextDirection: TextDirection.rtl,
                    prefixIcon: Text(
                      _selectedIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: NoorTheme.spacingMd),

                // Icon selector
                Text('الأيقونة', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _icons.map((icon) {
                    final isSelected = icon == _selectedIcon;
                    return GestureDetector(
                      onTap: () => setModalState(() => _selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedColor.withOpacity(0.2) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: _selectedColor, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: NoorTheme.spacingMd),

                // Color selector
                Text('اللون', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colors.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () => setModalState(() => _selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: NoorTheme.spacingLg),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createTag,
                    child: const Text('إنشاء'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createTag() async {
    if (_nameController.text.isEmpty) return;

    final tag = PersonalTag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      color: _selectedColor,
      icon: _selectedIcon,
    );

    await PersonalTagsService.addTag(tag);
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    _loadTags();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: const Text('وسوماتي'),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
      ),
      body: _tags.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏷️', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد وسومات بعد',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أنشئ وسوماً لتنظيم أحاديثك المفضلة',
                    style: TextStyle(color: NoorTheme.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(NoorTheme.spacingMd),
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: NoorTheme.spacingSm),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                    child: InkWell(
                      onTap: () {
                        // Open tag details
                      },
                      borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
                      child: Padding(
                        padding: const EdgeInsets.all(NoorTheme.spacingMd),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: tag.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  tag.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: NoorTheme.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    tag.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${tag.hadithIds.length} حديث',
                                    style: TextStyle(
                                      color: NoorTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 32,
                              decoration: BoxDecoration(
                                color: tag.color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTagDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('وسم جديد'),
      ),
    );
  }
}
