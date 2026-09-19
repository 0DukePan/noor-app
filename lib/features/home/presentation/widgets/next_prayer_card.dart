import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/prayer_time_engine.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/home_provider.dart';

/// Premium Next Prayer Card with gradient, depth, and progress bar
class NextPrayerCard extends ConsumerWidget {

  const NextPrayerCard({super.key, this.prayerTimes});
  final PrayerTimes? prayerTimes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(currentTimeProvider).valueOrNull ?? DateTime.now();
    final nextInfo = _getNextPrayer(now, l10n);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF163E29), const Color(0xFF10281A)]
              : [NoorDesignSystem.primaryGreen, NoorDesignSystem.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: NoorDesignSystem.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.mosque_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    // Wraps inside the chip at large text scales.
                    Flexible(
                      child: Text(
                        l10n.npcBadge,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Prayer name
              Text(
                (nextInfo?['name'] ?? l10n.npcLoading) as String,
                style: GoogleFonts.cairo(
                  fontSize: 34,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              // Wrap, not Row: at large text scales the remaining-time column
              // stacks below the time chip instead of overflowing.
              Wrap(
                spacing: 14,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      (nextInfo?['time'] ?? '--:--') as String,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        color: NoorDesignSystem.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.npcAfter('${nextInfo?['remaining'] ?? '...'}'),
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.npcInshallah,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Time Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (nextInfo?['progress'] as double?) ?? 0.0,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  color: Colors.white,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getNextPrayer(DateTime now, AppLocalizations l10n) {
    if (prayerTimes == null) return null;
    
    final schedule = [
      {'name': 'الفجر', 'time': prayerTimes!.fajr},
      {'name': 'الشروق', 'time': prayerTimes!.sunrise},
      {'name': 'الظهر', 'time': prayerTimes!.dhuhr},
      {'name': 'العصر', 'time': prayerTimes!.asr},
      {'name': 'المغرب', 'time': prayerTimes!.maghrib},
      {'name': 'العشاء', 'time': prayerTimes!.isha},
    ];

    for (var i = 0; i < schedule.length; i++) {
      final time = schedule[i]['time']! as DateTime;
      if (time.isAfter(now)) {
        final previousTime = i > 0 
            ? schedule[i - 1]['time']! as DateTime 
            : (schedule.last['time']! as DateTime).subtract(const Duration(days: 1));
            
        final totalDuration = time.difference(previousTime).inSeconds;
        final elapsed = now.difference(previousTime).inSeconds;
        final progress = (elapsed / totalDuration).clamp(0.0, 1.0);

        final diff = time.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;

        return {
          'name': schedule[i]['name']! as String,
          'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          'remaining': hours > 0
            ? l10n.proHoursMinutes(hours, minutes)
            : l10n.proMinutes(minutes),
          'progress': progress,
        };
      }
    }
    
    return {
      'name': 'الفجر',
      'time': '${prayerTimes!.fajr.hour.toString().padLeft(2, '0')}:${prayerTimes!.fajr.minute.toString().padLeft(2, '0')}',
      'remaining': l10n.npcTomorrow,
      'progress': 0.0,
    };
  }
}
