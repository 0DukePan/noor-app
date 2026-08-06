import 'package:flutter/material.dart';
import '../../core/theme/noor_theme.dart';

/// هيكل التحميل - Loading Skeleton Widget
/// Shimmer effect placeholders for loading states
class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 4,
    this.isCircle = false,
  });

  /// Create a text line skeleton
  const LoadingSkeleton.text({
    super.key,
    this.width = 150,
    this.height = 16,
  })  : borderRadius = 4,
        isCircle = false;

  /// Create a circle skeleton (avatar, icon)
  const LoadingSkeleton.circle({
    super.key,
    double size = 48,
  })  : width = size,
        height = size,
        borderRadius = 0,
        isCircle = true;

  /// Create a card skeleton
  const LoadingSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
  })  : borderRadius = 12,
        isCircle = false;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 2, 0),
              colors: [
                NoorTheme.textSecondary.withOpacity(0.1),
                NoorTheme.textSecondary.withOpacity(0.2),
                NoorTheme.textSecondary.withOpacity(0.1),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Surah list loading skeleton
class SurahListSkeleton extends StatelessWidget {
  final int itemCount;

  const SurahListSkeleton({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildSurahItem(),
    );
  }

  Widget _buildSurahItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: NoorTheme.spacingSm),
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      ),
      child: Row(
        children: [
          const LoadingSkeleton.circle(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                LoadingSkeleton.text(width: 120),
                SizedBox(height: 8),
                LoadingSkeleton.text(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hadith list loading skeleton
class HadithListSkeleton extends StatelessWidget {
  final int itemCount;

  const HadithListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildHadithItem(),
    );
  }

  Widget _buildHadithItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: NoorTheme.spacingMd),
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              LoadingSkeleton(width: 60, height: 24, borderRadius: 12),
              LoadingSkeleton.text(width: 100),
            ],
          ),
          const SizedBox(height: 12),
          const LoadingSkeleton(height: 16),
          const SizedBox(height: 6),
          const LoadingSkeleton(height: 16),
          const SizedBox(height: 6),
          const LoadingSkeleton(width: 200, height: 16),
          const SizedBox(height: 12),
          const LoadingSkeleton.text(width: 80, height: 12),
        ],
      ),
    );
  }
}

/// Verse list loading skeleton
class VerseListSkeleton extends StatelessWidget {
  final int itemCount;

  const VerseListSkeleton({super.key, this.itemCount = 7});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildVerseItem(),
    );
  }

  Widget _buildVerseItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: NoorTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              LoadingSkeleton(width: 28, height: 28, borderRadius: 14),
            ],
          ),
          const SizedBox(height: 8),
          const LoadingSkeleton(height: 24),
          const SizedBox(height: 4),
          const LoadingSkeleton(height: 24),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Prayer times loading skeleton
class PrayerTimesSkeleton extends StatelessWidget {
  const PrayerTimesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      child: Column(
        children: [
          // Next prayer card
          const LoadingSkeleton.card(height: 150),
          const SizedBox(height: NoorTheme.spacingMd),
          // Prayer times list
          ...List.generate(5, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  LoadingSkeleton.text(width: 50),
                  LoadingSkeleton.text(width: 60),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
