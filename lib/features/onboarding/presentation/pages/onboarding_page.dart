import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/theme/noor_theme.dart';
import '../../../../core/services/hive_service.dart';

/// صفحة الترحيب والتهيئة - Onboarding Page
class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      icon: '🌙',
      title: 'أهلاً بك في نور',
      subtitle: 'بيئة عبادة رقمية شاملة',
      description: 'تلاوة القرآن، حفظ الأحاديث، مواقيت الصلاة، والأذكار في مكان واحد',
      color: NoorTheme.primary,
    ),
    OnboardingStep(
      icon: '📖',
      title: 'القرآن الكريم',
      subtitle: 'تلاوة وتدبر',
      description: 'قراءة بالخط العثماني، تفسير، أسباب النزول، وصوت أكثر من 9 قراء',
      color: const Color(0xFF2E7D32),
    ),
    OnboardingStep(
      icon: '📚',
      title: 'الأحاديث النبوية',
      subtitle: 'الكتب التسعة',
      description: 'بحث متقدم، شجرة موضوعية، تخريج، وحفظ بالتكرار المتباعد',
      color: const Color(0xFF5D4037),
    ),
    OnboardingStep(
      icon: '🕌',
      title: 'مواقيت الصلاة',
      subtitle: 'دقيقة وذكية',
      description: 'تنبيهات الصلاة، وضع صامت تلقائي، واتجاه القبلة',
      color: const Color(0xFF1565C0),
    ),
    OnboardingStep(
      icon: '🤲',
      title: 'هل أنت مستعد؟',
      subtitle: 'ابدأ رحلتك الروحية',
      description: 'نسأل الله أن يجعل هذا التطبيق نافعاً لك في دينك ودنياك',
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
    if (_currentPage < _steps.length - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    
    // Save onboarding complete flag using the HiveService
    await HiveService.saveSetting('onboarding_complete', true);
    
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
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
                  if (_currentPage < _steps.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'تخطي',
                        style: TextStyle(color: NoorTheme.textSecondary),
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
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildStep(_steps[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? _steps[_currentPage].color
                          : NoorTheme.textSecondary.withOpacity(0.3),
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
                    backgroundColor: _steps[_currentPage].color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _steps[_currentPage].isLast ? 'ابدأ الآن' : 'التالي',
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
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Text(
                  step.icon,
                  style: const TextStyle(fontSize: 80),
                ),
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
  final String icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final bool isLast;

  OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    this.isLast = false,
  });
}

/// Check if onboarding is complete
Future<bool> isOnboardingComplete() async {
  return HiveService.getSetting<bool>('onboarding_complete', defaultValue: false) ?? false;
}
