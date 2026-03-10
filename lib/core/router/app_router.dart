import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/quran/presentation/pages/quran_page.dart';
import '../../features/quran/presentation/pages/surah_page.dart';
import '../../features/quran/presentation/pages/khatmah_page.dart';
import '../../features/quran/presentation/pages/tadabbur_page.dart';
import '../../features/hadith/presentation/pages/hadith_page.dart';
import '../../features/hadith/presentation/pages/memorization_page.dart';
import '../../features/hadith/presentation/pages/quiz_page.dart';
import '../../features/hadith/presentation/pages/topic_tree_page.dart';
import '../../features/hadith/presentation/pages/hadith_search_page.dart';
import '../../features/hadith/presentation/pages/learning_statistics_page.dart';
import '../../features/hadith/presentation/pages/tags_management_page.dart';
import '../../features/prayer/presentation/pages/prayer_page.dart';
import '../../features/prayer/presentation/pages/qada_page.dart';
import '../../features/qibla/presentation/pages/qibla_page.dart';
import '../../features/adhkar/presentation/pages/adhkar_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/audio/presentation/pages/audio_player_page.dart';
import '../../features/tafsir/presentation/pages/tafsir_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../widgets/main_shell.dart';

/// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Onboarding route (outside shell)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPage(
          OnboardingPage(onComplete: () => GoRouter.of(context).go('/')),
          state,
        ),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => _buildPage(
              const HomePage(),
              state,
            ),
          ),
          GoRoute(
            path: '/quran',
            name: 'quran',
            pageBuilder: (context, state) => _buildPage(
              const QuranPage(),
              state,
            ),
            routes: [
              GoRoute(
                path: 'surah/:surahNumber',
                name: 'surah',
                pageBuilder: (context, state) {
                  final surahNumber = int.parse(
                    state.pathParameters['surahNumber'] ?? '1',
                  );
                  return _buildPage(
                    SurahPage(surahNumber: surahNumber),
                    state,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'tadabbur/:verseNumber',
                    name: 'tadabbur',
                    pageBuilder: (context, state) {
                      final surahNumber = int.parse(
                        state.pathParameters['surahNumber'] ?? '1',
                      );
                      final verseNumber = int.parse(
                        state.pathParameters['verseNumber'] ?? '1',
                      );
                      return _buildPage(
                        TadabburMihrabPage(
                          surahNumber: surahNumber,
                          verseNumber: verseNumber,
                          verseText: state.extra as String? ?? '',
                        ),
                        state,
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'khatmah',
                name: 'khatmah',
                pageBuilder: (context, state) => _buildPage(
                  const KhatmahPlannerPage(),
                  state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/hadith',
            name: 'hadith',
            pageBuilder: (context, state) => _buildPage(
              const HadithPage(),
              state,
            ),
            routes: [
              GoRoute(
                path: 'memorization',
                name: 'hadith-memorization',
                pageBuilder: (context, state) => _buildPage(
                  const MemorizationPage(),
                  state,
                ),
              ),
              GoRoute(
                path: 'quiz',
                name: 'hadith-quiz',
                pageBuilder: (context, state) => _buildPage(
                  const QuizPage(hadiths: []),
                  state,
                ),
              ),
              GoRoute(
                path: 'topics',
                name: 'hadith-topics',
                pageBuilder: (context, state) => _buildPage(
                  const TopicTreePage(),
                  state,
                ),
              ),
              GoRoute(
                path: 'search',
                name: 'hadith-search',
                pageBuilder: (context, state) => _buildPage(
                  const HadithSearchPage(),
                  state,
                ),
              ),
              GoRoute(
                path: 'stats',
                name: 'hadith-stats',
                pageBuilder: (context, state) => _buildPage(
                  const LearningStatisticsPage(),
                  state,
                ),
              ),
              GoRoute(
                path: 'tags',
                name: 'hadith-tags',
                pageBuilder: (context, state) => _buildPage(
                  const TagsManagementPage(),
                  state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/prayer',
            name: 'prayer',
            pageBuilder: (context, state) => _buildPage(
              const PrayerPage(),
              state,
            ),
            routes: [
              GoRoute(
                path: 'qada',
                name: 'qada',
                pageBuilder: (context, state) => _buildPage(
                  const QadaTrackerPage(),
                  state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/qibla',
            name: 'qibla',
            pageBuilder: (context, state) => _buildPage(
              const QiblaPage(),
              state,
            ),
          ),
          GoRoute(
            path: '/adhkar',
            name: 'adhkar',
            pageBuilder: (context, state) => _buildPage(
              const AdhkarPage(),
              state,
            ),
          ),
          GoRoute(
            path: '/audio',
            name: 'audio',
            pageBuilder: (context, state) => _buildPage(
              const AudioPlayerPage(),
              state,
            ),
          ),
          GoRoute(
            path: '/tafsir',
            name: 'tafsir',
            pageBuilder: (context, state) => _buildPage(
              const TafsirPage(),
              state,
            ),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => _buildPage(
              const SearchPage(),
              state,
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => _buildPage(
              const SettingsPage(),
              state,
            ),
          ),
        ],
      ),
    ],
  );
});

/// Build page with gentle Khushu-style transition
CustomTransitionPage<void> _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Gentle fade transition - Khushu style
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
  );
}

