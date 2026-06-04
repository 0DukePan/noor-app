import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../providers/prayer_providers.dart';

/// 🕌 صفحة مواقيت الصلاة — Reactive Prayer Times Page
/// Consumes PrayerTimeEngine via Riverpod. Zero setState. Zero Timer.periodic.
class PrayerPage extends ConsumerWidget {
  const PrayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final prayerAsync = ref.watch(prayerDataProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('مواقيت الصلاة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.go('/tools/prayer/settings'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: prayerAsync.when(
          loading: () => _buildLoading(isDark),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.withOpacity(0.6)),
                const SizedBox(height: 16),
                Text(
                  'تعذر تحميل أوقات الصلاة',
                  style: GoogleFonts.cairo(fontSize: 16, color: isDark ? Colors.white70 : NoorDesignSystem.textSecondary),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(prayerDataProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                ),
              ],
            ),
          ),
          data: (data) => _PrayerContent(data: data),
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms),
          ),
        ],
      ),
    );
  }
}

/// Inner content widget that uses real prayer data
class _PrayerContent extends ConsumerWidget {
  final PrayerPageData data;

  const _PrayerContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch the tick stream to reactively update countdown
    final now = ref.watch(prayerTimeTickProvider).valueOrNull ?? DateTime.now();
    final nextPrayer = _getNextPrayer(now);
    final allPrayers = _buildPrayerList(now);

    return SafeArea(
      child: Column(
        children: [
          // Next Prayer Countdown
          const SizedBox(height: 20),
          _NextPrayerCountdown(
            nextPrayer: nextPrayer,
            now: now,
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 30),

          // Timeline List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                children: [
                  _LocationCard(
                    cityName: data.cityName,
                    countryName: data.countryName,
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 32),
                  ...allPrayers.asMap().entries.map((entry) {
                    final i = entry.key;
                    final prayer = entry.value;
                    return _TimelinePrayerRow(
                      name: prayer['name'] as String,
                      time: prayer['timeStr'] as String,
                      meridiem: prayer['meridiem'] as String,
                      icon: prayer['icon'] as IconData,
                      status: prayer['status'] as PrayerStatus,
                      isFirst: i == 0,
                      isLast: i == allPrayers.length - 1,
                      isSunrise: prayer['isSunrise'] as bool? ?? false,
                    ).animate().fadeIn(
                      delay: Duration(milliseconds: 150 + i * 80),
                      duration: 400.ms,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getNextPrayer(DateTime now) {
    final prayers = _buildPrayerList(now);
    for (final p in prayers) {
      if (p['status'] == PrayerStatus.next) return p;
    }
    return null;
  }

  List<Map<String, dynamic>> _buildPrayerList(DateTime now) {
    final pt = data.prayerTimes;
    final prayers = <Map<String, dynamic>>[
      {'name': 'الفجر', 'dt': pt.fajr, 'icon': Icons.nights_stay_rounded, 'isSunrise': false},
      {'name': 'الشروق', 'dt': pt.sunrise, 'icon': Icons.wb_twilight_rounded, 'isSunrise': true},
      {'name': 'الظهر', 'dt': pt.dhuhr, 'icon': Icons.wb_sunny_rounded, 'isSunrise': false},
      {'name': 'العصر', 'dt': pt.asr, 'icon': Icons.wb_sunny_outlined, 'isSunrise': false},
      {'name': 'المغرب', 'dt': pt.maghrib, 'icon': Icons.wb_twilight_rounded, 'isSunrise': false},
      {'name': 'العشاء', 'dt': pt.isha, 'icon': Icons.dark_mode_rounded, 'isSunrise': false},
    ];

    bool foundNext = false;
    return prayers.map((p) {
      final dt = p['dt'] as DateTime;
      PrayerStatus status;
      if (!foundNext && dt.isAfter(now)) {
        status = PrayerStatus.next;
        foundNext = true;
      } else if (dt.isBefore(now)) {
        status = PrayerStatus.passed;
      } else {
        status = PrayerStatus.upcoming;
      }

      final hour = dt.hour;
      final minute = dt.minute;
      final isAM = hour < 12;
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return {
        ...p,
        'status': status,
        'timeStr': '${_toArabicNum(displayHour.toString().padLeft(2, '0'))}:${_toArabicNum(minute.toString().padLeft(2, '0'))}',
        'meridiem': isAM ? 'ص' : 'م',
      };
    }).toList();
  }

  String _toArabicNum(String input) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = input;
    for (int i = 0; i < en.length; i++) {
      result = result.replaceAll(en[i], ar[i]);
    }
    return result;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

enum PrayerStatus { passed, next, upcoming }

class _NextPrayerCountdown extends StatelessWidget {
  final Map<String, dynamic>? nextPrayer;
  final DateTime now;

  const _NextPrayerCountdown({required this.nextPrayer, required this.now});

  @override
  Widget build(BuildContext context) {
    if (nextPrayer == null) {
      return Text(
        'انتهت صلوات اليوم',
        style: GoogleFonts.cairo(fontSize: 16, color: NoorDesignSystem.primaryGreen, fontWeight: FontWeight.w600),
      );
    }

    final dt = nextPrayer!['dt'] as DateTime;
    final diff = dt.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    // Haptic when very close
    if (hours == 0 && minutes == 0 && seconds < 10) {
      HapticFeedback.lightImpact();
    }

    return Column(
      children: [
        Text(
          'الصلاة القادمة: ${nextPrayer!['name']}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: NoorDesignSystem.primaryGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: GoogleFonts.outfit(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: NoorDesignSystem.textPrimary,
            height: 1,
          ),
        ),
        Text(
          'متبقي حتى الأذان',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: NoorDesignSystem.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TimelinePrayerRow extends StatelessWidget {
  final String name;
  final String time;
  final String meridiem;
  final IconData icon;
  final PrayerStatus status;
  final bool isSunrise;
  final bool isFirst;
  final bool isLast;

  const _TimelinePrayerRow({
    required this.name,
    required this.time,
    required this.meridiem,
    required this.icon,
    required this.status,
    this.isSunrise = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNext = status == PrayerStatus.next;
    final isPassed = status == PrayerStatus.passed;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Column
          SizedBox(
            width: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    fontSize: isNext ? 24 : 18,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                    color: isNext
                        ? NoorDesignSystem.primaryGreen
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  meridiem,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: NoorDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Timeline Line & Dot
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isLast)
                  Positioned(
                    top: 24,
                    bottom: -24,
                    width: 2,
                    child: Container(
                      color: isPassed
                          ? theme.colorScheme.primary.withOpacity(0.3)
                          : theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                Container(
                  width: isNext ? 16 : 12,
                  height: isNext ? 16 : 12,
                  decoration: BoxDecoration(
                    color: isNext
                        ? NoorDesignSystem.goldAccent
                        : isPassed
                            ? NoorDesignSystem.primaryGreen.withOpacity(0.5)
                            : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isNext
                          ? NoorDesignSystem.goldAccent
                          : isPassed
                              ? Colors.transparent
                              : theme.colorScheme.outline.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: isNext
                        ? [
                            BoxShadow(
                              color: NoorDesignSystem.goldAccent.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isNext
                      ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isNext
                      ? Border.all(color: theme.colorScheme.primary.withOpacity(0.2))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isNext
                          ? NoorDesignSystem.primaryGreen
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        fontSize: isNext ? 18 : 16,
                        fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                        color: isNext
                            ? NoorDesignSystem.primaryGreen
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (!isSunrise)
                      IconButton(
                        icon: Icon(
                          isPassed
                              ? Icons.notifications_off_outlined
                              : Icons.notifications_active_rounded,
                          size: 18,
                          color: isPassed
                              ? theme.colorScheme.outline
                              : theme.colorScheme.tertiary,
                        ),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String cityName;
  final String countryName;

  const _LocationCard({required this.cityName, required this.countryName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = countryName.isNotEmpty ? '$cityName، $countryName' : cityName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: NoorDesignSystem.primaryGreen,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              displayText,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
