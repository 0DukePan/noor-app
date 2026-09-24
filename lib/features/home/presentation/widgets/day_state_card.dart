import 'package:flutter/material.dart';

import '../../../../core/services/day_state_machine.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// 🕐 Day State Card — shows current Islamic day period from DayStateMachine
class DayStateCard extends StatelessWidget {
  const DayStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: DayStateMachine.completionVersion,
      builder: (context, _, __) => _buildCard(context, l10n),
    );
  }

  Widget _buildCard(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateInfo = DayStateMachine.getCurrentStateInfo();
    final state = stateInfo.state;
    final done = DayStateMachine.todayPrayersCompleted;
    final streak = DayStateMachine.streak;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A262C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
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
              color: NoorDesignSystem.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                _iconFor(state),
                size: 24,
                color: NoorDesignSystem.primaryGreen,
              ),
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
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : NoorDesignSystem.textPrimary,
                  ),
                ),
                if (stateInfo.suggestedAction.isNotEmpty)
                  Text(
                    stateInfo.suggestedAction,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: NoorDesignSystem.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                // Prayer completion progress
                // Wrap, not Row: identical layout when the labels fit, and the
                // streak drops to its own line instead of overflowing at
                // larger text scales (dynamic-type test).
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.dayTasks(done),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: NoorDesignSystem.goldAccent,
                      ),
                    ),
                    if (streak > 0)
                      Text(
                        l10n.dayStreak(streak),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : NoorDesignSystem.textSecondary,
                        ),
                      ),
                  ],
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
                    color: NoorDesignSystem.goldAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stateInfo.suggestedAdhkar,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: NoorDesignSystem.goldAccent,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                stateInfo.formattedTimeToNext,
                style: TextStyle(
                  fontFamily: 'Cairo',
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

/// Material icons, not emoji: an emoji glyph comes from a system font, so the
/// golden test rendered it differently on Windows and on the Linux CI runner.
/// Icons ship with the framework. `Cairo` above is the font bundled in
/// `assets/fonts/` via pubspec, not Google's CDN - google_fonts cannot resolve
/// it offline and throws under test.
IconData _iconFor(DayState state) {
  switch (state) {
    case DayState.unknown:
      return Icons.help_outline;
    case DayState.lateNight:
      return Icons.nights_stay;
    case DayState.lastThird:
      return Icons.dark_mode;
    case DayState.fajr:
      return Icons.wb_twilight;
    case DayState.sunrise:
      return Icons.wb_sunny;
    case DayState.duha:
      return Icons.wb_sunny_outlined;
    case DayState.dhuhr:
      return Icons.light_mode;
    case DayState.asr:
      return Icons.wb_cloudy;
    case DayState.maghrib:
      return Icons.wb_twilight;
    case DayState.isha:
      return Icons.nightlight_round;
    case DayState.sleep:
      return Icons.bedtime;
  }
}
