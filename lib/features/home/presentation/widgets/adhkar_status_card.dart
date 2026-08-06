import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/models/adhkar_models.dart';

class AdhkarStatusCard extends StatelessWidget {
  final DailyAdhkarStats stats;
  final VoidCallback onTap;

  const AdhkarStatusCard({super.key, required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A262C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: stats.isComplete
                  ? NoorDesignSystem.sageGreen.withOpacity(0.3)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: stats.isComplete 
                        ? [const Color(0xFF43A047), const Color(0xFF2E7D32)]
                        : [NoorDesignSystem.primaryGreen.withOpacity(0.12), NoorDesignSystem.primaryLight.withOpacity(0.08)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    stats.isComplete ? '✅' : '📿',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.isComplete ? 'أتممت الورد اليومي' : 'واصل ذكر الله',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : NoorDesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stats.progress,
                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                        color: NoorDesignSystem.primaryGreen,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(stats.progress * 100).toInt()}% مكتمل',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : NoorDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white24 : NoorDesignSystem.textSecondary.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
