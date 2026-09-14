import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// ⚙️ صفحة الأدوات — Tools Hub
/// Central hub for Prayer Times, Qibla, Tasbih, and Settings
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  l10n.toolsTitle,
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
                    title: l10n.toolsPrayer,
                    subtitle: l10n.toolsPrayerSub,
                    gradient: const [
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
                    title: l10n.toolsQibla,
                    subtitle: l10n.toolsQiblaSub,
                    gradient: const [
                      Color(0xFF1565C0),
                      Color(0xFF42A5F5),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/tools/qibla');
                    },
                  ),
                  _ToolCard(
                    icon: Icons.radio_button_checked_rounded,
                    title: l10n.toolsTasbih,
                    subtitle: l10n.toolsTasbihSub,
                    gradient: const [
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
                    title: l10n.toolsSearch,
                    subtitle: l10n.toolsSearchSub,
                    gradient: const [
                      Color(0xFF6A1B9A),
                      Color(0xFF9C27B0),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/tools/search');
                    },
                  ),
                  _ToolCard(
                    icon: Icons.auto_stories_rounded,
                    title: l10n.toolsHifz,
                    subtitle: l10n.toolsHifzSub,
                    gradient: const [
                      Color(0xFF00695C),
                      Color(0xFF26A69A),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/quran/hifz');
                    },
                  ),
                  _ToolCard(
                    icon: Icons.person_rounded,
                    title: l10n.toolsProfile,
                    subtitle: l10n.toolsProfileSub,
                    gradient: const [
                      Color(0xFFBF360C),
                      Color(0xFFFF7043),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/tools/profile');
                    },
                  ),
                  _ToolCard(
                    icon: Icons.settings_rounded,
                    title: l10n.settingsTitle,
                    subtitle: l10n.toolsSettingsSub,
                    gradient: [
                      if (isDark) const Color(0xFF37474F) else const Color(0xFF546E7A),
                      if (isDark) const Color(0xFF455A64) else const Color(0xFF78909C),
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

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              color: gradient.first.withValues(alpha: 0.25),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
                      color: Colors.white.withValues(alpha: 0.8),
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
