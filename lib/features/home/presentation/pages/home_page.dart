import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/design_system.dart';

import '../providers/home_provider.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/day_state_card.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/adhkar_status_card.dart';
import '../widgets/hadith_of_day_card.dart';
import '../widgets/smart_suggestion_box.dart';
import '../widgets/favorites_section.dart';
import 'package:hijri/hijri_calendar.dart';
import 'dart:async';

/// 📱 الصفحة الرئيسية - Premium Home Dashboard
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    ref.invalidate(homeDataProvider);
    ref.invalidate(smartGreetingProvider);
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeState = ref.watch(homeDataProvider);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F171A) : NoorDesignSystem.creamWhite,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: NoorDesignSystem.emeraldGreen,
        child: homeState.when(
          data: (data) => _buildContent(context, data, isDark),
          loading: () => _buildLoading(isDark),
          error: (error, stack) => _buildError(context, error, isDark),
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 120),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildShimmerBox(isDark, 120),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildShimmerBox(isDark, 200),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildShimmerBox(isDark, 150),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(height: 16),
          Text(
            'تعذر جلب البيانات',
            style: GoogleFonts.cairo(fontSize: 18, color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(homeDataProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: NoorDesignSystem.primaryGreen,
              foregroundColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeData data, bool isDark) {
    final greeting = ref.watch(smartGreetingProvider);
    final suggestion = ref.watch(smartSuggestionProvider);
    
    return CustomScrollView(
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
                      greeting,
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
                          data.cityName,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : NoorDesignSystem.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(width: 4, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
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

            SliverList.list(
              children: [
                // Day State Card (contains smart suggestion internally or optionally here)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DayStateCard(),
                      const SizedBox(height: 12),
                      const SmartSuggestionBox(),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 500.ms),

                const SizedBox(height: 16),

                // Next Prayer - Premium Glass Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: NextPrayerCard(prayerTimes: data.prayerTimes)
                      .animate().fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.15),
                ),
                
                const SizedBox(height: 28),

                // Continue Reading - Interactive Progress Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'متابعة القراءة',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : NoorDesignSystem.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ContinueReadingCard(lastRead: data.lastRead),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                
                const SizedBox(height: 28),

                // Favorites - Horizontal Scroll
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المفضلة',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : NoorDesignSystem.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {}, // TODO: Navigate to all favorites
                            style: TextButton.styleFrom(
                              foregroundColor: NoorDesignSystem.primaryGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                            ),
                            child: Text(
                              'عرض الكل',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: const FavoritesSection(),
                    ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                  ],
                ),
                
                const SizedBox(height: 28),

                // Adhkar Status
                Padding(
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
                      AdhkarStatusCard(
                        stats: data.adhkarStats,
                        onTap: () => context.go('/adhkar'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
                  
                const SizedBox(height: 28),

                // Hadith of Day - Premium card
                Padding(
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
                      if (data.hadithOfDay != null)
                        HadithOfDayCard(hadith: data.hadithOfDay!),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 500.ms),

                const SizedBox(height: 120),
              ],
            ),
          ],
        );
  }

  Widget _buildShimmerBox(bool isDark, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.black12,
        borderRadius: BorderRadius.circular(20),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 1500.ms, color: isDark ? Colors.white24 : Colors.white60);
  }

  String _getHijriDate() {
    HijriCalendar.setLocal('ar');
    final today = HijriCalendar.now();
    return today.toFormat("dd MMMM yyyy");
  }
}
