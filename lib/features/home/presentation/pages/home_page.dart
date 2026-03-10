import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/services/prayer_time_engine.dart';
import '../../../../core/services/hadith_data_source.dart';
import '../../../../core/services/adhkar_data_source.dart';
import '../../../../core/models/adhkar_models.dart';

/// 📱 الصفحة الرئيسية - Premium Home Dashboard
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PrayerTimes? _prayerTimes;
  Map<String, dynamic>? _hadithOfDay;
  DailyAdhkarStats? _adhkarStats;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final times = PrayerTimeEngine.calculate(
      latitude: 21.4225,
      longitude: 39.8262,
      date: DateTime.now(),
      method: CalculationMethod.ummAlQura,
    );
    
    final hadith = await HadithDataSource.getRandomHadith();
    final stats = AdhkarDataSource.getTodayStats();
    
    if (mounted) {
      setState(() {
        _prayerTimes = times;
        _hadithOfDay = hadith;
        _adhkarStats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F171A) : NoorDesignSystem.creamWhite,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: NoorDesignSystem.emeraldGreen,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Gradient AppBar
            SliverAppBar(
              expandedHeight: 60,
              floating: true,
              snap: true,
              backgroundColor: isDark ? const Color(0xFF0F171A) : NoorDesignSystem.creamWhite,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          NoorDesignSystem.emeraldGreen,
                          NoorDesignSystem.deepTeal,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: NoorDesignSystem.emeraldGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'نور',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : NoorDesignSystem.naskhBlack,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  color: isDark ? Colors.white70 : NoorDesignSystem.textSecondary,
                  onPressed: () => context.go('/search'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  color: isDark ? Colors.white70 : NoorDesignSystem.textSecondary,
                  onPressed: () => context.go('/settings'),
                ),
              ],
            ),

            // Greeting Section with gradient
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.cairo(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : NoorDesignSystem.naskhBlack,
                        height: 1.3,
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, 
                          color: NoorDesignSystem.emeraldGreen.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(
                          _getHijriDate(),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : NoorDesignSystem.textSecondary,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Next Prayer - Premium Glass Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _NextPrayerCard(prayerTimes: _prayerTimes)
                    .animate().fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.15),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Quick Actions - Modern Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الوصول السريع',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : NoorDesignSystem.naskhBlack,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _QuickActionsGrid(),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Adhkar Status
            if (_adhkarStats != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أذكار اليوم',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : NoorDesignSystem.naskhBlack,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AdhkarStatusCard(
                        stats: _adhkarStats!,
                        onTap: () => context.go('/adhkar'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              ),
              
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Hadith of Day - Premium card
            if (_hadithOfDay != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نور النبوة',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : NoorDesignSystem.naskhBlack,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HadithOfDayCard(hadith: _hadithOfDay!),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'قيام الليل 🌙';
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 17) return 'طاب يومك 🌤️';
    return 'مساء النور 🌆';
  }

  String _getHijriDate() {
    // Simple placeholder - would integrate with hijri date library
    final now = DateTime.now();
    final months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

/// Premium Next Prayer Card with gradient and depth
class _NextPrayerCard extends StatelessWidget {
  final PrayerTimes? prayerTimes;

  const _NextPrayerCard({this.prayerTimes});

  @override
  Widget build(BuildContext context) {
    final next = _getNextPrayer();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B5E20), const Color(0xFF004D40)]
              : [NoorDesignSystem.emeraldGreen, NoorDesignSystem.deepTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: NoorDesignSystem.emeraldGreen.withOpacity(isDark ? 0.2 : 0.35),
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
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'الصلاة القادمة',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Prayer name
              Text(
                next?['name'] ?? 'جاري التحميل...',
                style: GoogleFonts.cairo(
                  fontSize: 34,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              // Time + remaining
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      next?['time'] ?? '--:--',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        color: NoorDesignSystem.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بعد ${next?['remaining'] ?? '...'}',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'إن شاء الله',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, String>? _getNextPrayer() {
    if (prayerTimes == null) return null;
    final now = DateTime.now();
    final prayers = [
      {'name': 'الفجر', 'time': prayerTimes!.fajr},
      {'name': 'الشروق', 'time': prayerTimes!.sunrise},
      {'name': 'الظهر', 'time': prayerTimes!.dhuhr},
      {'name': 'العصر', 'time': prayerTimes!.asr},
      {'name': 'المغرب', 'time': prayerTimes!.maghrib},
      {'name': 'العشاء', 'time': prayerTimes!.isha},
    ];

    for (final prayer in prayers) {
      final time = prayer['time'] as DateTime;
      if (time.isAfter(now)) {
        final diff = time.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        return {
          'name': prayer['name'] as String,
          'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          'remaining': hours > 0 ? '$hours ساعة و $minutes د' : '$minutes دقيقة',
        };
      }
    }
    return {
      'name': 'الفجر',
      'time': '${prayerTimes!.fajr.hour.toString().padLeft(2, '0')}:${prayerTimes!.fajr.minute.toString().padLeft(2, '0')}',
      'remaining': 'غداً',
    };
  }
}

/// Quick Actions Grid with gradient icon backgrounds
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _QuickActionItem(
          icon: Icons.menu_book_rounded,
          label: 'القرآن',
          gradient: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          onTap: () => context.go('/quran'),
          delay: 0,
        ),
        _QuickActionItem(
          icon: Icons.fingerprint_rounded,
          label: 'الأذكار',
          gradient: const [Color(0xFF43A047), Color(0xFF2E7D32)],
          onTap: () => context.go('/adhkar'),
          delay: 80,
        ),
        _QuickActionItem(
          icon: Icons.format_quote_rounded,
          label: 'الحديث',
          gradient: const [Color(0xFF00897B), Color(0xFF00695C)],
          onTap: () => context.go('/hadith'),
          delay: 160,
        ),
        _QuickActionItem(
          icon: Icons.explore_rounded,
          label: 'القبلة',
          gradient: const [Color(0xFFD4AF37), Color(0xFFB8960C)],
          onTap: () => context.go('/qibla'),
          delay: 240,
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int delay;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? gradient.map((c) => c.withOpacity(0.3)).toList()
                      : [Colors.white, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: isDark ? null : Border.all(
                  color: gradient[0].withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(isDark ? 0.15 : 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: gradient[0], size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark ? Colors.white70 : NoorDesignSystem.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 500 + delay), duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
}

class _AdhkarStatusCard extends StatelessWidget {
  final DailyAdhkarStats stats;
  final VoidCallback onTap;

  const _AdhkarStatusCard({required this.stats, required this.onTap});

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
                        : [NoorDesignSystem.emeraldGreen.withOpacity(0.12), NoorDesignSystem.deepTeal.withOpacity(0.08)],
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
                        color: isDark ? Colors.white : NoorDesignSystem.naskhBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stats.progress,
                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                        color: NoorDesignSystem.emeraldGreen,
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

class _HadithOfDayCard extends StatelessWidget {
  final Map<String, dynamic> hadith;

  const _HadithOfDayCard({required this.hadith});

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
          color: NoorDesignSystem.emeraldGreen.withOpacity(isDark ? 0.15 : 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
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
                  color: NoorDesignSystem.emeraldGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.format_quote_rounded,
                  color: NoorDesignSystem.emeraldGreen.withOpacity(0.6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'حديث اليوم',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: NoorDesignSystem.emeraldGreen,
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
              color: isDark ? Colors.white.withOpacity(0.9) : NoorDesignSystem.naskhBlack,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
