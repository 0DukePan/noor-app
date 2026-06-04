import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/services/day_state_machine.dart';

/// 🕐 Day State Card — shows current Islamic day period from DayStateMachine
class DayStateCard extends StatelessWidget {
  const DayStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateInfo = DayStateMachine.getCurrentStateInfo();
    final state = stateInfo.state;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A262C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
        ),
        boxShadow: NoorDesignSystem.shadowSmall,
      ),
      child: Row(
        children: [
          // State icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: NoorDesignSystem.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(state.icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),

          // State info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.arabicName,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : NoorDesignSystem.textPrimary,
                  ),
                ),
                if (stateInfo.suggestedAction.isNotEmpty)
                  Text(
                    stateInfo.suggestedAction,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: NoorDesignSystem.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Time to next state
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (stateInfo.suggestedAdhkar.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: NoorDesignSystem.goldAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stateInfo.suggestedAdhkar,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: NoorDesignSystem.goldAccent,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                stateInfo.formattedTimeToNext,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : NoorDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
