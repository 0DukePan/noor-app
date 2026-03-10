import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../../../core/theme/noor_theme.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  // Timer for countdown update
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
            onPressed: () => _showPrayerSettings(context),
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
        child: SafeArea(
          child: Column(
            children: [
              // Next Prayer Countdown
              const SizedBox(height: 20),
              _NextPrayerCountdown(),
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
                      _LocationCard(),
                      const SizedBox(height: 32),
                      
                      _TimelinePrayerRow(
                        name: 'الفجر',
                        time: '٠٥:٣٠',
                        meridiem: 'ص',
                        icon: Icons.nights_stay_rounded,
                        status: PrayerStatus.passed,
                        isFirst: true,
                      ),
                      _TimelinePrayerRow(
                        name: 'الشروق',
                        time: '٠٦:٥٥',
                        meridiem: 'ص',
                        icon: Icons.wb_twilight_rounded,
                        status: PrayerStatus.passed,
                        isSunrise: true,
                      ),
                      _TimelinePrayerRow(
                        name: 'الظهر',
                        time: '١٢:١٥',
                        meridiem: 'م',
                        icon: Icons.wb_sunny_rounded,
                        status: PrayerStatus.passed,
                      ),
                      _TimelinePrayerRow(
                        name: 'العصر',
                        time: '٠٣:٤٥',
                        meridiem: 'م',
                        icon: Icons.wb_sunny_outlined,
                        status: PrayerStatus.next,
                      ),
                      _TimelinePrayerRow(
                        name: 'المغرب',
                        time: '٠٦:٢٠',
                        meridiem: 'م',
                        icon: Icons.wb_twilight_rounded,
                        status: PrayerStatus.upcoming,
                      ),
                      _TimelinePrayerRow(
                        name: 'العشاء',
                        time: '٠٧:٥٠',
                        meridiem: 'م',
                        icon: Icons.dark_mode_rounded,
                        status: PrayerStatus.upcoming,
                        isLast: true,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Qibla Quick Access
                      _QiblaQuickAccess(
                        onTap: () => context.push('/qibla'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrayerSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('إعدادات الصلاة', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text('طريقة الحساب', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: Text('أم القرى', style: GoogleFonts.cairo()), selected: true, onSelected: (_) {}),
                ChoiceChip(label: Text('رابطة العالم الإسلامي', style: GoogleFonts.cairo()), selected: false, onSelected: (_) {}),
                ChoiceChip(label: Text('ISNA', style: GoogleFonts.cairo()), selected: false, onSelected: (_) {}),
              ],
            ),
            const SizedBox(height: 20),
            Text('الإشعارات', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
            SwitchListTile(
              title: Text('أذان قبل الصلاة', style: GoogleFonts.cairo()),
              value: true, onChanged: (v) {}, contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text('تذكير بعد الأذان', style: GoogleFonts.cairo()),
              value: false, onChanged: (v) {}, contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

enum PrayerStatus { passed, next, upcoming }

class _NextPrayerCountdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          'الصلاة القادمة: العصر',
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '02:15:30',
          style: GoogleFonts.outfit(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            height: 1,
          ),
        ),
        Text(
          'متبقي حتى الأذان',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: theme.colorScheme.secondary,
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
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  meridiem,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: theme.colorScheme.secondary,
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
                        ? theme.colorScheme.primary 
                        : isPassed 
                            ? theme.colorScheme.primary.withOpacity(0.5)
                            : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isNext 
                          ? theme.colorScheme.primary 
                          : isPassed 
                              ? Colors.transparent
                              : theme.colorScheme.outline.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: isNext ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
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
                          ? theme.colorScheme.primary 
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
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (!isSunrise)
                      IconButton(
                        icon: Icon(
                          isPassed ? Icons.notifications_off_outlined : Icons.notifications_active_rounded,
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: theme.colorScheme.secondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'الرياض، المملكة العربية السعودية',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.colorScheme.outline,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _QiblaQuickAccess extends StatelessWidget {
  final VoidCallback onTap;

  const _QiblaQuickAccess({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -20,
              bottom: -20,
              child: Icon(
                Icons.explore_rounded,
                size: 100,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اتجاه القبلة',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تحديد الاتجاه بدقة عالية',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
