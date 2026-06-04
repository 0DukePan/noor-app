import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_system.dart';

class FavoritesSection extends StatelessWidget {
  const FavoritesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _FavoriteItemCard(
          title: 'سورة الملك',
          subtitle: 'القرآن الكريم',
          icon: Icons.auto_stories_rounded,
          color: NoorDesignSystem.primaryGreen,
          onTap: () => context.go('/quran/surah/67'),
        ),
        _FavoriteItemCard(
          title: 'أذكار الصباح',
          subtitle: 'الأذكار',
          icon: Icons.wb_sunny_rounded,
          color: NoorDesignSystem.morningColor,
          onTap: () => context.go('/adhkar'),
        ),
        _FavoriteItemCard(
          title: 'سورة يس',
          subtitle: 'القرآن الكريم',
          icon: Icons.auto_stories_rounded,
          color: NoorDesignSystem.primaryGreen,
          onTap: () => context.go('/quran/surah/36'),
        ),
      ],
    );
  }
}

class _FavoriteItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FavoriteItemCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(NoorDesignSystem.radiusMedium),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
          ),
          boxShadow: NoorDesignSystem.shadowSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
