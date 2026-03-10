import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../../../core/algorithms/fsrs_algorithm.dart';
import '../providers/hadith_providers.dart';

/// صفحة الحفظ بالتكرار المتباعد - Spaced Repetition Memorization Page
class MemorizationPage extends ConsumerStatefulWidget {
  const MemorizationPage({super.key});

  @override
  ConsumerState<MemorizationPage> createState() => _MemorizationPageState();
}

class _MemorizationPageState extends ConsumerState<MemorizationPage>
    with SingleTickerProviderStateMixin {
  bool _showAnswer = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    HapticFeedback.lightImpact();
    if (_showAnswer) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showAnswer = !_showAnswer);
  }

  void _reviewCard(Rating rating) {
    HapticFeedback.mediumImpact();
    ref.read(memorizationProvider.notifier).reviewCard(rating.index + 1);
    setState(() => _showAnswer = false);
    _flipController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memorizationProvider);

    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      appBar: AppBar(
        title: const Text('حفظ الأحاديث'),
        backgroundColor: NoorTheme.bgMushaf,
        elevation: 0,
        actions: [
          // Streak display
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: NoorTheme.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(state.streak.streakEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  '${state.streak.currentStreak}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: NoorTheme.accentGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: state.currentCard == null
          ? _buildEmptyState()
          : Column(
              children: [
                // Progress Header
                _buildProgressHeader(state),

                // Flashcard
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(NoorTheme.spacingLg),
                    child: GestureDetector(
                      onTap: _toggleCard,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final isBack = _flipAnimation.value > 0.5;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_flipAnimation.value * 3.14159),
                            child: isBack
                                ? Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(3.14159),
                                    child: _buildCardBack(),
                                  )
                                : _buildCardFront(),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Rating Buttons (only when answer shown)
                if (_showAnswer) _buildRatingButtons(state),

                const SizedBox(height: NoorTheme.spacingXl),
              ],
            ),
    );
  }

  Widget _buildProgressHeader(MemorizationState state) {
    return Container(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCard(
            icon: Icons.pending_actions_rounded,
            label: 'متبقي اليوم',
            value: '${state.dueCards.length}',
            color: NoorTheme.primary,
          ),
          _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'راجعت اليوم',
            value: '${state.todayReviewed}',
            color: NoorTheme.hadithSahih,
          ),
          _StatCard(
            icon: Icons.bookmark_rounded,
            label: 'إجمالي الحفظ',
            value: '${state.totalMemorized}',
            color: NoorTheme.accentGold,
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NoorTheme.spacingXl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NoorTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: NoorTheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 48,
            color: NoorTheme.accentGold.withOpacity(0.5),
          ),
          const SizedBox(height: NoorTheme.spacingLg),
          const Text(
            'تذكّر الحديث...',
            style: TextStyle(
              fontSize: 18,
              color: NoorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: NoorTheme.spacingXl),
          // Show partial hadith as hint
          Text(
            'قال رسول الله ﷺ: "...',
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 22,
              color: NoorTheme.textArabic,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const Spacer(),
          Text(
            'اضغط لإظهار الإجابة',
            style: TextStyle(
              color: NoorTheme.textSecondary.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NoorTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NoorTheme.primary.withOpacity(0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(NoorTheme.radiusLg),
        border: Border.all(color: NoorTheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: NoorTheme.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Full hadith text
            Text(
              'قال رسول الله ﷺ: "إنما الأعمال بالنيات وإنما لكل امرئ ما نوى"',
              style: const TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 24,
                height: 2.0,
                color: NoorTheme.textArabic,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: NoorTheme.spacingLg),
            // Source
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: NoorTheme.spacingMd,
                vertical: NoorTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: NoorTheme.hadithSahih.withOpacity(0.1),
                borderRadius: BorderRadius.circular(NoorTheme.radiusSm),
              ),
              child: Text(
                'صحيح البخاري - كتاب بدء الوحي',
                style: TextStyle(
                  color: NoorTheme.hadithSahih,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButtons(MemorizationState state) {
    final intervals = ref.read(memorizationProvider.notifier).getIntervalPreviews();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: NoorTheme.spacingMd),
      child: Row(
        children: Rating.values.map((rating) {
          final intervalText = intervals[rating.index + 1] ?? '1 يوم';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _RatingButton(
                rating: rating,
                intervalText: intervalText,
                onTap: () => _reviewCard(rating),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🎉',
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: NoorTheme.spacingLg),
          Text(
            'أحسنت! أنهيت مراجعة اليوم',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: NoorTheme.spacingSm),
          Text(
            'عد غداً لمواصلة الحفظ',
            style: TextStyle(color: NoorTheme.textSecondary),
          ),
          const SizedBox(height: NoorTheme.spacingXl),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('العودة'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NoorTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: NoorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final Rating rating;
  final String intervalText;
  final VoidCallback onTap;

  const _RatingButton({
    required this.rating,
    required this.intervalText,
    required this.onTap,
  });

  Color get _color {
    switch (rating) {
      case Rating.again:
        return NoorTheme.hadithMawdu;
      case Rating.hard:
        return NoorTheme.hadithDaif;
      case Rating.good:
        return NoorTheme.hadithHasan;
      case Rating.easy:
        return NoorTheme.hadithSahih;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NoorTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: NoorTheme.spacingMd),
          child: Column(
            children: [
              Text(rating.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                rating.arabicName,
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                intervalText,
                style: TextStyle(
                  color: NoorTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
