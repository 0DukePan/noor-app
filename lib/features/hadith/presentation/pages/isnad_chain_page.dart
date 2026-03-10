import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/noor_theme.dart';

/// خريطة الإسناد التفاعلية - Interactive Isnad Chain Visualization
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

class _IsnadChainPageState extends State<IsnadChainPage> {
  String? _selectedNarratorId;

  // Sample isnad chain data
  final List<NarratorNode> _chain = [
    NarratorNode(
      id: '1',
      name: 'الإمام البخاري',
      role: 'المؤلف',
      birthYear: 194,
      deathYear: 256,
      rank: 'ثقة حافظ',
      level: 0,
    ),
    NarratorNode(
      id: '2',
      name: 'عبد الله بن يوسف',
      role: 'الراوي عن مالك',
      birthYear: 0,
      deathYear: 218,
      rank: 'ثقة متقن',
      level: 1,
    ),
    NarratorNode(
      id: '3',
      name: 'الإمام مالك بن أنس',
      role: 'إمام دار الهجرة',
      birthYear: 93,
      deathYear: 179,
      rank: 'إمام ثقة',
      level: 2,
    ),
    NarratorNode(
      id: '4',
      name: 'يحيى بن سعيد الأنصاري',
      role: 'تابعي',
      birthYear: 0,
      deathYear: 143,
      rank: 'ثقة ثبت',
      level: 3,
    ),
    NarratorNode(
      id: '5',
      name: 'محمد بن إبراهيم التيمي',
      role: 'تابعي',
      birthYear: 0,
      deathYear: 120,
      rank: 'ثقة',
      level: 4,
    ),
    NarratorNode(
      id: '6',
      name: 'علقمة بن وقاص الليثي',
      role: 'تابعي',
      birthYear: 0,
      deathYear: 80,
      rank: 'ثقة ثبت',
      level: 5,
    ),
    NarratorNode(
      id: '7',
      name: 'عمر بن الخطاب رضي الله عنه',
      role: 'صحابي',
      birthYear: 0,
      deathYear: 23,
      rank: 'صحابي جليل',
      level: 6,
      isCompanion: true,
    ),
    NarratorNode(
      id: '8',
      name: 'النبي ﷺ',
      role: 'المصدر',
      birthYear: 0,
      deathYear: 11,
      rank: '',
      level: 7,
      isProphet: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: const Text('سلسلة الإسناد'),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Hadith preview
          Container(
            margin: const EdgeInsets.all(NoorTheme.spacingMd),
            padding: const EdgeInsets.all(NoorTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
            ),
            child: Text(
              widget.hadithText,
              style: const TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 16,
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Chain visualization
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NoorTheme.spacingMd),
              child: Column(
                children: [
                  for (int i = 0; i < _chain.length; i++) ...[
                    _buildNarratorCard(_chain[i]),
                    if (i < _chain.length - 1) _buildConnector(),
                  ],
                ],
              ),
            ),
          ),

          // Selected narrator details
          if (_selectedNarratorId != null)
            _buildNarratorDetails(
              _chain.firstWhere((n) => n.id == _selectedNarratorId),
            ),
        ],
      ),
    );
  }

  Widget _buildNarratorCard(NarratorNode narrator) {
    final isSelected = _selectedNarratorId == narrator.id;
    Color cardColor = Colors.white;
    Color borderColor = NoorTheme.primary.withOpacity(0.2);

    if (narrator.isProphet) {
      cardColor = NoorTheme.accentGold.withOpacity(0.1);
      borderColor = NoorTheme.accentGold;
    } else if (narrator.isCompanion) {
      cardColor = NoorTheme.hadithSahih.withOpacity(0.1);
      borderColor = NoorTheme.hadithSahih;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedNarratorId = isSelected ? null : narrator.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(NoorTheme.spacingMd),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
          border: Border.all(
            color: isSelected ? NoorTheme.primary : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: NoorTheme.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Level indicator
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: narrator.isProphet
                      ? [NoorTheme.accentGold, NoorTheme.accentGold.withOpacity(0.7)]
                      : narrator.isCompanion
                          ? [NoorTheme.hadithSahih, NoorTheme.hadithHasan]
                          : [NoorTheme.primary, NoorTheme.primaryDark],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: narrator.isProphet
                    ? const Text('ﷺ', style: TextStyle(color: Colors.white, fontSize: 16))
                    : Text(
                        '${_chain.length - narrator.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: NoorTheme.spacingMd),

            // Name and role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    narrator.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: narrator.isProphet ? 18 : 16,
                      color: narrator.isProphet ? NoorTheme.accentGold : null,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    narrator.role,
                    style: TextStyle(
                      fontSize: 12,
                      color: NoorTheme.textSecondary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),

            // Rank badge
            if (narrator.rank.isNotEmpty && !narrator.isProphet)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: NoorTheme.hadithSahih.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  narrator.rank,
                  style: TextStyle(
                    fontSize: 10,
                    color: NoorTheme.hadithSahih,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(
            width: 2,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NoorTheme.primary.withOpacity(0.5),
                  NoorTheme.primary.withOpacity(0.2),
                ],
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: NoorTheme.primary.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildNarratorDetails(NarratorNode narrator) {
    return Container(
      padding: const EdgeInsets.all(NoorTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(NoorTheme.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: NoorTheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() => _selectedNarratorId = null),
              ),
              const Spacer(),
              Text(
                'بطاقة الراوي',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const Divider(),
          _buildDetailRow('الاسم', narrator.name),
          _buildDetailRow('الطبقة', narrator.role),
          if (narrator.rank.isNotEmpty)
            _buildDetailRow('المرتبة', narrator.rank),
          if (narrator.deathYear > 0)
            _buildDetailRow('سنة الوفاة', '${narrator.deathYear} هـ'),
          const SizedBox(height: NoorTheme.spacingMd),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(color: NoorTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class NarratorNode {
  final String id;
  final String name;
  final String role;
  final int birthYear;
  final int deathYear;
  final String rank;
  final int level;
  final bool isCompanion;
  final bool isProphet;

  NarratorNode({
    required this.id,
    required this.name,
    required this.role,
    required this.birthYear,
    required this.deathYear,
    required this.rank,
    required this.level,
    this.isCompanion = false,
    this.isProphet = false,
  });
}
