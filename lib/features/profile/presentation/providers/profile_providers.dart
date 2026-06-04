import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/statistics_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE STATS DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

class ProfileStats {
  final ReadingStats todayReading;
  final ReadingStats totalReading;
  final ListeningStats listening;
  final AdhkarDayStatus adhkarStatus;
  final KhatmahProgress khatmah;
  final WeeklySummary weekly;
  final int adhkarStreak;
  final int completedKhatmah;

  const ProfileStats({
    required this.todayReading,
    required this.totalReading,
    required this.listening,
    required this.adhkarStatus,
    required this.khatmah,
    required this.weekly,
    required this.adhkarStreak,
    required this.completedKhatmah,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER — single reactive source for all profile stats
// ═══════════════════════════════════════════════════════════════════════════

final profileStatsProvider = Provider<ProfileStats>((ref) {
  return ProfileStats(
    todayReading: StatisticsService.getTodayReadingStats(),
    totalReading: StatisticsService.getTotalReadingStats(),
    listening: StatisticsService.getListeningStats(),
    adhkarStatus: StatisticsService.getTodayAdhkarStatus(),
    khatmah: StatisticsService.getKhatmahProgress(),
    weekly: StatisticsService.getWeeklySummary(),
    adhkarStreak: StatisticsService.getAdhkarStreak(),
    completedKhatmah: StatisticsService.getCompletedKhatmahCount(),
  );
});
