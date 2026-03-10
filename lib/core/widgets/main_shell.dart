import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/design_system.dart';

/// الإطار الرئيسي - Main Shell
/// Premium floating bottom navigation with calm, modern design
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: const _NoorBottomNav(),
    );
  }
}

class _NoorBottomNav extends StatelessWidget {
  const _NoorBottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A262C).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: NoorDesignSystem.emeraldGreen.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isSelected: location == '/',
                  onTap: () => context.go('/'),
                ),
                _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'القرآن',
                  isSelected: location.startsWith('/quran'),
                  onTap: () => context.go('/quran'),
                ),
                _NavItem(
                  icon: Icons.access_time_rounded,
                  label: 'الصلاة',
                  isSelected: location == '/prayer',
                  onTap: () => context.go('/prayer'),
                ),
                _NavItem(
                  icon: Icons.favorite_rounded,
                  label: 'الأذكار',
                  isSelected: location == '/adhkar',
                  onTap: () => context.go('/adhkar'),
                ),
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: 'القبلة',
                  isSelected: location == '/qibla',
                  onTap: () => context.go('/qibla'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSelected ? 16 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      NoorDesignSystem.emeraldGreen.withOpacity(isDark ? 0.25 : 0.12),
                      NoorDesignSystem.deepTeal.withOpacity(isDark ? 0.15 : 0.06),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  widget.icon,
                  size: widget.isSelected ? 24 : 22,
                  color: widget.isSelected
                      ? NoorDesignSystem.emeraldGreen
                      : (isDark ? Colors.white54 : NoorDesignSystem.textSecondary),
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: NoorDesignSystem.emeraldGreen,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
