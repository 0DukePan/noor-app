import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/adhkar_models.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';

class AdhkarStatusCard extends StatelessWidget {

  const AdhkarStatusCard({required this.stats, required this.onTap, super.key});
  final DailyAdhkarStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  ? NoorDesignSystem.sageGreen.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                        : [NoorDesignSystem.primaryGreen.withValues(alpha: 0.12), NoorDesignSystem.primaryLight.withValues(alpha: 0.08)],
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
                      stats.isComplete ? l10n.adhkarCardDone : l10n.adhkarCardTodo,
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
                      l10n.adhkarCardPct((stats.progress * 100).toInt()),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : NoorDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: isDark ? Colors.white24 : NoorDesignSystem.textSecondary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
