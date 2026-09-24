import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/hive_service.dart';
import '../../../../core/theme/noor_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// صفحة الترحيب والتهيئة - Onboarding Page
class OnboardingPage extends StatefulWidget {

  const OnboardingPage({required this.onComplete, super.key});
  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Material icons, not emoji: emoji come from a system font, so the golden
  // test rendered differently on Windows and on the Linux CI image (0.22% of
  // pixels, one glyph). Icon glyphs ship with the framework.
  List<OnboardingStep> _steps(AppLocalizations l10n) => [
    OnboardingStep(
      icon: Icons.nightlight_round,
      title: l10n.ob1Title,
      subtitle: l10n.ob1Subtitle,
      description: l10n.ob1Desc,
      color: NoorTheme.primary,
    ),
    OnboardingStep(
      icon: Icons.menu_book,
      title: l10n.ob2Title,
      subtitle: l10n.ob2Subtitle,
      description: l10n.ob2Desc,
      color: const Color(0xFF2E7D32),
    ),
    OnboardingStep(
      icon: Icons.auto_stories,
      title: l10n.ob3Title,
      subtitle: l10n.ob3Subtitle,
      description: l10n.ob3Desc,
      color: const Color(0xFF5D4037),
    ),
    OnboardingStep(
      icon: Icons.mosque,
      title: l10n.ob4Title,
      subtitle: l10n.ob4Subtitle,
      description: l10n.ob4Desc,
      color: const Color(0xFF1565C0),
    ),
    OnboardingStep(
      icon: Icons.volunteer_activism,
      title: l10n.ob5Title,
      subtitle: l10n.ob5Subtitle,
      description: l10n.ob5Desc,
      color: NoorTheme.accentGold,
      isLast: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final steps = _steps(AppLocalizations.of(context));
    if (_currentPage < steps.length - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    unawaited(HapticFeedback.mediumImpact());
    
    // Save onboarding complete flag (same key the router redirect reads).
    // Fire-and-forget: never block navigation on a disk write.
    unawaited(HiveService.setOnboardingSeen());
    
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _steps(l10n);
    return Scaffold(
      backgroundColor: NoorTheme.bgMushaf,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < steps.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        l10n.obSkip,
                        style: const TextStyle(color: NoorTheme.textSecondary),
                      ),
                    ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return _buildStep(steps[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(steps.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? steps[_currentPage].color
                          : NoorTheme.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: steps[_currentPage].color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    steps[_currentPage].isLast ? l10n.obStart : l10n.obNext,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(step.icon, size: 80, color: step.color),
              );
            },
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: step.color,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            step.subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: NoorTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: NoorTheme.textSecondary,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingStep {

  OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    this.isLast = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final bool isLast;
}

/// Check if onboarding is complete (reads the same flag the router redirects on)
Future<bool> isOnboardingComplete() async {
  return HiveService.isOnboardingSeen;
}
