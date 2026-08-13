import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';

class HadithOfDayCard extends StatelessWidget {

  const HadithOfDayCard({required this.hadith, super.key});
  final Map<String, dynamic> hadith;

  @override
  Widget build(BuildContext context) {
    final text = hadith['arabic'] ?? hadith['hadith_text'] ?? hadith['text'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A262C), const Color(0xFF1E2C33)]
              : [Colors.white, const Color(0xFFF8FFF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NoorDesignSystem.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NoorDesignSystem.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.format_quote_rounded,
                  color: NoorDesignSystem.primaryGreen.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'حديث اليوم',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: NoorDesignSystem.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            text.toString(),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.amiri(
              fontSize: 18,
              height: 1.9,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : NoorDesignSystem.textPrimary,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
