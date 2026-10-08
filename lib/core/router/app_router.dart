import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/entities/hadith.dart';
import '../../core/router/route_decoder.dart';
import '../../core/router/route_recovery_page.dart';
import '../../features/adhkar/presentation/pages/adhkar_page.dart';
import '../../features/audio/presentation/pages/audio_player_page.dart';
import '../../features/hadith/presentation/pages/advanced_hadith_browser_page.dart';
import '../../features/hadith/presentation/pages/hadith_page.dart';
import '../../features/hadith/presentation/pages/hadith_search_page.dart';
import '../../features/hadith/presentation/pages/learning_statistics_page.dart';
import '../../features/hadith/presentation/pages/memorization_page.dart';
import '../../features/hadith/presentation/pages/quiz_page.dart';
import '../../features/hadith/presentation/pages/tags_management_page.dart';
import '../../features/hadith/presentation/pages/topic_tree_page.dart';
import '../../features/hifz/presentation/pages/hifz_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/prayer/presentation/pages/prayer_page.dart';
import '../../features/prayer/presentation/pages/prayer_settings_page.dart';
import '../../features/prayer/presentation/pages/qada_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/qibla/presentation/pages/qibla_page.dart';
import '../../features/quran/domain/entities/quran_location.dart';
import '../../features/quran/presentation/pages/khatmah_page.dart';
import '../../features/quran/presentation/pages/quran_mushaf_page.dart';
import '../../features/quran/presentation/pages/quran_page.dart';
import '../../features/quran/presentation/pages/surah_page.dart';
import '../../features/quran/presentation/pages/tadabbur_page.dart';
import '../../features/quran/presentation/providers/quran_providers.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/settings/presentation/pages/notifications_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/storage_settings_page.dart';
import '../../features/tafsir/presentation/pages/tafsir_page.dart';
import '../../features/tools/presentation/pages/tasbih_page.dart';
import '../../features/tools/presentation/pages/tools_page.dart';
import '../services/hive_service.dart';
import '../widgets/main_shell.dart';

/// Deep link preserved across the first-run onboarding gate (QUR-04).
///
/// A fresh install opened from a notification or deep link lands on
/// onboarding; without this, completing onboarding always drops the user at
/// '/' and the original target is silently lost. The redirect stashes the
/// target, and [consumePendingDeepLink] hands it to onboarding completion
/// exactly once. In-memory on purpose: it only matters within one boot.
String? _pendingDeepLink;

/// Takes the stashed onboarding-gate target, if any.
String? consumePendingDeepLink() {
  final target = _pendingDeepLink;
  _pendingDeepLink = null;
  return target;
}

/// Stashes a cold-boot deep target (web boots evaluate the gate against
/// '/' before the browser deep URL is parsed — proven by e2e boot logs.
/// Call once from main() where Uri.base is already correct).
void stashInitialDeepLink(Uri uri) {
  if (uri.path == '/' || uri.path == '/onboarding') return;
  _pendingDeepLink =
      uri.path + (uri.hasQuery ? '?${uri.query}' : '');
}

/// Pure onboarding-gate decision (unit-tested): returns '/onboarding' when
/// the gate parks the location, else null. Parking a non-trivial target
/// stashes it for [consumePendingDeepLink]; '/' and '/onboarding' stash
/// nothing so plain onboarding still lands on home.
String? onboardingGateRedirect({
  required bool onboardingSeen,
  required Uri uri,
}) {
  if (onboardingSeen || uri.path == '/onboarding') return null;
  final target = uri.toString();
  if (target != '/' && target != '/onboarding') {
    _pendingDeepLink = target;
  }
  return '/onboarding';
}

/// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  // NOTE: no `initialLocation` on purpose, so nothing shadows the
  // platform's default location (browser URL on web, deep link on mobile).
  return GoRouter(
    redirect: (context, state) => onboardingGateRedirect(
      onboardingSeen: HiveService.isOnboardingSeen,
      uri: state.uri,
    ),
    routes: [
      // Onboarding route (outside shell)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPage(
          OnboardingPage(
            onComplete: () {
              HiveService.setOnboardingSeen();
              GoRouter.of(context).go(consumePendingDeepLink() ?? '/');
            },
          ),
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
            pageBuilder: (context, state) =>
                _buildPage(const HomePage(), state),
          ),
          GoRoute(
            path: '/quran',
            name: 'quran',
            pageBuilder: (context, state) =>
                _buildPage(const QuranPage(), state),
            routes: [
              GoRoute(
                path: 'surah/:surahNumber',
                name: 'surah',
                pageBuilder: (context, state) {
                  // NAV-01: typed, range-aware decoding. Malformed values
                  // reach a localized recovery screen, never an exception.
                  final decoded = decodeSurahRoute(
                    surahRaw: state.pathParameters['surahNumber'],
                    ayahRaw: state.uri.queryParameters['ayah'],
                  );
                  if (decoded is RouteFailure) {
                    return _buildPage(
                      RouteRecoveryPage(failure: decoded, safeRoute: '/quran'),
                      state,
                    );
                  }
                  final location = (decoded as DecodedQuranLocation).location;
                  return _buildPage(
                    SurahPage(
                      surahNumber: location.surah,
                      initialAyah: location.ayah == 1 ? null : location.ayah,
                    ),
                    state,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'tadabbur/:verseNumber',
                    name: 'tadabbur',
                    pageBuilder: (context, state) {
                      final decoded = decodeTadabburRoute(
                        surahRaw: state.pathParameters['surahNumber'],
                        verseRaw: state.pathParameters['verseNumber'],
                      );
                      if (decoded is RouteFailure) {
                        return _buildPage(
                          RouteRecoveryPage(
                            failure: decoded,
                            safeRoute: '/quran',
                          ),
                          state,
                        );
                      }
                      final location =
                          (decoded as DecodedQuranLocation).location;
                      return _buildPage(
                        TadabburMihrabPage(
                          surahNumber: location.surah,
                          verseNumber: location.ayah,
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
                pageBuilder: (context, state) =>
                    _buildPage(const KhatmahPlannerPage(), state),
              ),
              GoRoute(
                path: 'mushaf',
                name: 'mushaf',
                pageBuilder: (context, state) {
                  // QUR-04: validate/clamp 1..604 before PageController sees
                  // the value; invalid input can never crash paging.
                  final decoded = decodeMushafPage(
                    state.uri.queryParameters['page'],
                  );
                  // Phase 3.1: route-scoped reader state. Each Mushaf route
                  // push gets a fresh provider scope seeded with its decoded
                  // page, so pushes, back navigation, and deep links can
                  // never leak current-page state into each other. The reader
                  // still reads one source of truth below this scope.
                  return _buildPage(
                    ProviderScope(
                      overrides: [
                        mushafCurrentPageProvider.overrideWith(
                          (ref) => decoded.page,
                        ),
                      ],
                      child: QuranMushafPage(initialPage: decoded.page),
                    ),
                    state,
                  );
                },
              ),
              GoRoute(
                path: 'hifz',
                name: 'hifz',
                pageBuilder: (context, state) =>
                    _buildPage(const HifzPage(), state),
              ),
            ],
          ),
          GoRoute(
            path: '/hadith',
            name: 'hadith',
            pageBuilder: (context, state) =>
                _buildPage(const HadithPage(), state),
            routes: [
              GoRoute(
                path: 'memorization',
                name: 'hadith-memorization',
                pageBuilder: (context, state) =>
                    _buildPage(const MemorizationPage(), state),
              ),
              GoRoute(
                path: 'quiz',
                name: 'hadith-quiz',
                pageBuilder: (context, state) {
                  final hadiths =
                      (state.extra as List?)?.cast<Hadith>() ??
                      const <Hadith>[];
                  return _buildPage(QuizPage(hadiths: hadiths), state);
                },
              ),
              GoRoute(
                path: 'advanced',
                name: 'hadith-advanced',
                pageBuilder: (context, state) =>
                    _buildPage(const AdvancedHadithBrowserPage(), state),
              ),
              GoRoute(
                path: 'topics',
                name: 'hadith-topics',
                pageBuilder: (context, state) =>
                    _buildPage(const TopicTreePage(), state),
              ),
              GoRoute(
                path: 'search',
                name: 'hadith-search',
                pageBuilder: (context, state) =>
                    _buildPage(const HadithSearchPage(), state),
              ),
              GoRoute(
                path: 'stats',
                name: 'hadith-stats',
                pageBuilder: (context, state) =>
                    _buildPage(const LearningStatisticsPage(), state),
              ),
              GoRoute(
                path: 'tags',
                name: 'hadith-tags',
                pageBuilder: (context, state) =>
                    _buildPage(const TagsManagementPage(), state),
              ),
            ],
          ),
          GoRoute(
            path: '/adhkar',
            name: 'adhkar',
            pageBuilder: (context, state) =>
                _buildPage(const AdhkarPage(), state),
          ),
          GoRoute(
            path: '/tafsir',
            name: 'tafsir',
            pageBuilder: (context, state) {
              final surahRaw = state.uri.queryParameters['surah'];
              final ayahRaw = state.uri.queryParameters['ayah'];
              // No location: open the Tafsir home. Malformed location:
              // recovery screen. Valid location: exact ayah (TAF-03).
              if ((surahRaw == null || surahRaw.trim().isEmpty) &&
                  (ayahRaw == null || ayahRaw.trim().isEmpty)) {
                return _buildPage(const TafsirPage(), state);
              }
              final decoded = decodeTafsirRoute(
                surahRaw: surahRaw,
                ayahRaw: ayahRaw,
              );
              if (decoded is RouteFailure) {
                return _buildPage(
                  RouteRecoveryPage(failure: decoded, safeRoute: '/tafsir'),
                  state,
                );
              }
              final location = (decoded as DecodedQuranLocation).location;
              return _buildPage(
                TafsirPage(
                  initialSurah: location.surah,
                  initialAyah: location.ayah,
                  location: TafsirLocation.validated(
                    surah: location.surah,
                    ayah: location.ayah,
                    source: state.uri.queryParameters['source'] ?? 'muyassar',
                    returnRoute:
                        '/quran/surah/${location.surah}'
                        '?ayah=${location.ayah}',
                  ),
                ),
                state,
              );
            },
          ),
          GoRoute(
            path: '/audio-player',
            name: 'audio-player',
            pageBuilder: (context, state) {
              final decoded = decodeSurahRoute(
                surahRaw: state.uri.queryParameters['surah'] ?? '1',
                ayahRaw: state.uri.queryParameters['ayah'],
              );
              if (decoded is RouteFailure) {
                return _buildPage(
                  RouteRecoveryPage(failure: decoded, safeRoute: '/quran'),
                  state,
                );
              }
              final location = (decoded as DecodedQuranLocation).location;
              return _buildPage(
                AudioPlayerPage(
                  initialSurah: location.surah,
                  initialAyah: location.ayah,
                ),
                state,
              );
            },
          ),
          GoRoute(
            path: '/tools',
            name: 'tools',
            pageBuilder: (context, state) =>
                _buildPage(const ToolsPage(), state),
            routes: [
              GoRoute(
                path: 'prayer',
                name: 'prayer',
                pageBuilder: (context, state) =>
                    _buildPage(const PrayerPage(), state),
                routes: [
                  GoRoute(
                    path: 'qada',
                    name: 'qada',
                    pageBuilder: (context, state) =>
                        _buildPage(const QadaTrackerPage(), state),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: 'prayer-settings',
                    pageBuilder: (context, state) =>
                        _buildPage(const PrayerSettingsPage(), state),
                  ),
                ],
              ),
              GoRoute(
                path: 'qibla',
                name: 'qibla',
                pageBuilder: (context, state) =>
                    _buildPage(const QiblaPage(), state),
              ),
              GoRoute(
                path: 'tasbih',
                name: 'tasbih',
                pageBuilder: (context, state) =>
                    _buildPage(const TasbihPage(), state),
              ),
              GoRoute(
                path: 'search',
                name: 'search',
                pageBuilder: (context, state) =>
                    _buildPage(const SearchPage(), state),
              ),
              GoRoute(
                path: 'profile',
                name: 'profile',
                pageBuilder: (context, state) =>
                    _buildPage(const ProfilePage(), state),
              ),
              GoRoute(
                path: 'settings',
                name: 'settings',
                pageBuilder: (context, state) =>
                    _buildPage(const SettingsPage(), state),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    name: 'notifications-settings',
                    pageBuilder: (context, state) =>
                        _buildPage(const NotificationsSettingsPage(), state),
                  ),
                  GoRoute(
                    path: 'storage',
                    name: 'storage-settings',
                    pageBuilder: (context, state) =>
                        _buildPage(const StorageSettingsPage(), state),
                  ),
                ],
              ),
            ],
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
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Gentle fade transition - Khushu style
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
