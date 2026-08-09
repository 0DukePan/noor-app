import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/services/isnad_parser_service.dart';
import '../../../../core/services/narrator_database_service.dart';

/// Shared narrator profile content used by the isnad chain, isnad graph, and
/// scholar-mode panels/sheets (was copy-pasted in three places).
class NarratorProfileBody extends StatelessWidget {
  final NarratorInfo narrator;
  final NarratorProfile? profile;
  final Color accentColor;

  const NarratorProfileBody({
    super.key,
    required this.narrator,
    this.profile,
    this.accentColor = NoorDesignSystem.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Name with role badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                narrator.role,
                style: TextStyle(
                  fontSize: 11,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                narrator.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),

        if (narrator.linkWord.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'صيغة التحمل: ${narrator.linkWord}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textDirection: TextDirection.rtl,
          ),
        ],

        if (profile != null) ...[
          const Divider(height: 24),
          if (profile!.rank.isNotEmpty) _row('المرتبة', profile!.rank),
          if (profile!.rankSource.isNotEmpty) _row('المصدر', profile!.rankSource),
          if (profile!.deathYear > 0) _row('الوفاة', profile!.deathYearDisplay),
          if (profile!.birthYear > 0) _row('الولادة', profile!.birthYearDisplay),
          if (profile!.tadlis.isNotEmpty) _row('التدليس', profile!.tadlis),
          if (profile!.ikhtilat.isNotEmpty) _row('الاختلاط', profile!.ikhtilat),
          if (profile!.verdictSource.isNotEmpty)
            _row('مصدر الحكم', profile!.verdictSource),
          if (profile!.teachers.isNotEmpty)
            _row('شيوخه', profile!.teachers.take(5).join('، ')),
          if (profile!.students.isNotEmpty)
            _row('تلاميذه', profile!.students.take(5).join('، ')),
        ] else ...[
          const Divider(height: 24),
          Text(
            'لا تتوفر معلومات إضافية عن هذا الراوي في قاعدة البيانات',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            textDirection: TextDirection.rtl,
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}
