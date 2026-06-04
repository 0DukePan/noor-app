import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';

/// ⚙️ صفحة الأدوات — Tools Hub
/// Central hub for Prayer Times, Qibla, Tasbih, and Settings
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  'الأدوات',
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            // Tools Grid
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _ToolCard(
                    icon: Icons.access_time_rounded,
                    title: 'مواقيت الصلاة',
                    subtitle: 'الأوقات والتنبيهات',
                    gradient: [
                      NoorDesignSystem.primaryGreen,
                      NoorDesignSystem.primaryLight,
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/tools/prayer');
                    },
                  ),
                  _ToolCard(
                    icon: Icons.explore_rounded,
                    title: 'القبلة',
                    subtitle: 'اتجاه القبلة',
                    gradient: [
                      const Color(0xFF1565C0),
                      const Color(0xFF42A5F5),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/tools/qibla');
                    },
                  ),
                  _ToolCard(
                    icon: Icons.radio_button_checked_rounded,
                    title: 'المسبحة',
                    subtitle: 'عداد التسبيح',
                    gradient: [
                      NoorDesignSystem.goldMuted,
                      NoorDesignSystem.goldAccent,
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/tools/tasbih');
                    },
                  ),
                  _ToolCard(
                    icon: Icons.search_rounded,
                    title: 'البحث',
                    subtitle: 'البحث في القرآن والحديث',
                    gradient: [
                      const Color(0xFF6A1B9A),
                      const Color(0xFF9C27B0),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/tools/search');
                    },
                  ),
                  _ToolCard(
                    icon: Icons.person_rounded,
                    title: 'ملفي الشخصي',
                    subtitle: 'الإحصائيات والتقدم',
                    gradient: [
                      const Color(0xFFBF360C),
                      const Color(0xFFFF7043),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/tools/profile');
                    },
                  ),
                  _ToolCard(
                    icon: Icons.settings_rounded,
                    title: 'الإعدادات',
                    subtitle: 'المظهر واللغة',
                    gradient: [
                      isDark ? const Color(0xFF37474F) : const Color(0xFF546E7A),
                      isDark ? const Color(0xFF455A64) : const Color(0xFF78909C),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/tools/settings');
                    },
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
              ),
            ),

            // Bottom spacing for nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
