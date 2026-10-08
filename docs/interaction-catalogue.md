# Interaction catalogue (INT-01)

Living release artefact. Every reachable callback, gesture, menu item, dialog choice, selector, and permission prompt gets one stable row. The release gate is catalogue coverage: no reachable action without an owner, precondition, observable outcome, and current regression or device evidence.

Generated inventory: 533 callback declarations across `166` files under `lib/` (`dart run tool/gen_interaction_catalogue.dart`). Rows marked `unverified` are an honest test gap, not a pass.

## Critical contracts (reviewed, with evidence)

| ID | Location | Trigger + preconditions | Intended outcome | Feedback | Persistence | Evidence |
|---|---|---|---|---|---|---|
| NAV-01-surah | lib/core/router/app_router.dart surah/:surahNumber | open /quran/surah/:n(+?ayah=); any string incl. malformed | validated SurahPage(surah, initialAyah?) or localized recovery screen | recovery title/body/value + safe back button; never a red screen | none | test/unit/route_decoder_test.dart; device-pending for deep links |
| NAV-01-tadabbur | lib/core/router/app_router.dart tadabbur/:verseNumber | open nested tadabbur path; malformed surah/verse | validated TadabburMihrabPage or recovery screen | same recovery contract | none | test/unit/route_decoder_test.dart |
| QUR-04-mushaf-link | lib/core/router/app_router.dart mushaf?page= | page=1/604/0/negative/huge/malformed/missing | clamped QuranMushafPage before PageController sees it | slider/page indicator agree from first paint | last page persisted on settle only | test/unit/route_decoder_test.dart; test/widget/quran_mushaf_page_test.dart |
| QUR-05-page-error | lib/features/quran/presentation/pages/quran_mushaf_page.dart _MushafErrorPane | missing/corrupt page asset | localized pane, diagnostic ID, retry; no raw exception | retry button (Key mushafRetryButton); snackbar-free inline | none | test/widget/quran_mushaf_page_test.dart (retry recovers) |
| QUR-06-ayah-action | lib/features/quran/presentation/pages/quran_mushaf_page.dart _ContinuousVerseBlock | tap/long-press correct ayah region; blank-tap toggles controls | AyahActionsSheet for that (surah, ayah); controls untouched | haptic + sheet; 350ms toggle suppression after ayah tap | none | code contract; device TalkBack/VoiceOver pass pending (QA-01) |
| QUR-07-prefs | lib/features/quran/presentation/pages/quran_mushaf_page.dart MushafPreferences | change theme/zoom/controls; relaunch; corrupt stored values | approved values persist; corrupt values safely default (v1) | theme/zoom controls localized; 48dp targets | versioned settings-box record; best-effort, never blocks reading | test/unit/mushaf_preferences_test.dart; device relaunch pending |
| QUR-09-continue | home ContinueReadingCard, QuranPage last-position, search result, Khatmah resume | saved non-first ayah location; tap card/result/resume | study reader opens SAME surah+ayah with highlight; Back returns to results where applicable | visible context matches the card/query | reads shared reading_progress record; no overwrite | test/widget/surah_initial_ayah_test.dart; entry wiring code-reviewed; device pending |
| QUR-12-bookmark | lib/features/quran/data/repositories/quran_repository_impl.dart | add same ayah twice; remove; relaunch | one bookmark stored then removed; last-reading unchanged | verseBookmarkSaved snackbar on study page | idempotent bookmarks box rows; migration-safe tryFromMap pattern reused | test/data/quran_bookmarks_test.dart |
| AUD-01-verse-play | SurahPage verse options; QuranAudioService.playVerse | select non-first ayah, tap play | engine receives exact (surah, ayah); pending/playing/error UI accurate | playback error stream + localized error + one safe retry | resume position per (surah, ayah) | code contract; engine unit part in test/services/audio_boundary_test.dart; device audio pending |
| AUD-02-boundary | lib/core/services/quran_audio_engine.dart nextAyahIdentity/_onAyahComplete | completion on each surah final ayah under every repeat/queue mode | stop or valid same-surah restart; never an out-of-range pair or mislabeled recording | end-of-surah/Quran state; no request for invalid identity | none beyond resume marker | test/services/audio_boundary_test.dart (all 114 surahs x modes) |
| AUD-03-failure | lib/core/services/quran_audio_engine.dart PlaybackFailure | offline, invalid URL, player error | typed failure emitted (never log-only); coherent stopped state; one safe retry | localized audioError* strings + audioRetry | none | test/services/audio_boundary_test.dart (typing); offline/player-error device pass pending |
| TAF-01-availability | lib/core/data/data_sources/tafsir_database.dart; mushaf ayah sheet | missing asset, checksum mismatch, copy/storage failure, corrupt DB, failed open | distinct typed states with truthful localized UI + safe retry; never generic “no Tafsir” | tafsirState* strings; retry re-runs verified init | re-copy only after checksum verification | test/unit/mushaf_preferences_test.dart (resolver); DB-failure device pass pending |
| TAF-03-exact-entry | lib/features/tafsir/presentation/pages/tafsir_page.dart; TafsirReaderPage | open from Mushaf/Surah/search/bookmark/history/deep link at non-first ayah | full reader/preview identifies, scrolls to, highlights exact surah+ayah+source; Back restores origin | highlighted card border + ayah badge | history only on explicit read (TAF-05) | code contract; automated scroll test pending; device pending |
| TAF-04-compare-bound | lib/features/quran/presentation/pages/tafsir_reader_page.dart compare mode | forward/back at first/final ayah every surah; partial source set | navigation stays in valid range; per-source available/absent rows; never spins forever | disabled end action with end-label; partial rows informative | none | code contract (verse-count bound + distinct states); widget test pending |
| APP-04-hive-owner | lib/main.dart; lib/core/services/hive_service.dart | cold start; init failure; existing store | exactly one Hive.initFlutter owner (HiveService.initialize) | startup proceeds; failures logged non-fatally | existing boxes opened, never wiped | code contract; cold-start timing device pending |

<!-- INVENTORY:BEGIN (generated — do not hand-edit) -->

| Inventory ID | File | Line | Enclosing | Callback | Source | Status |
|---|---|---|---|---|---|---|
| INT-001 | core/router/route_recovery_page.dart | 47 | RouteRecoveryPage | onPressed | `onPressed: () =>` | unverified |
| INT-002 | core/services/silent_ui_controller.dart | 263 | _GentleNotificationWidgetState | onTap | `onTap: _dismiss,` | unverified |
| INT-003 | core/services/silent_ui_controller.dart | 352 | _ReadingModeWrapperState | onTap | `onTap: () => _controller.recordInteraction(),` | unverified |
| INT-004 | core/services/smart_notification_engine.dart | 62 | SmartNotificationEngine | onTap | `onDidReceiveNotificationResponse: _onNotificationTap,` | unverified |
| INT-005 | core/services/smart_notification_engine.dart | 473 | SmartNotificationEngine | onTap | `static void _onNotificationTap(NotificationResponse response) {` | unverified |
| INT-006 | core/widgets/book_card.dart | 8 | BookCard | onTap | `required this.title, required this.subtitle, required this.count, required this.color, req…` | unverified |
| INT-007 | core/widgets/book_card.dart | 14 | BookCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-008 | core/widgets/book_card.dart | 35 | BookCard | onTap | `onTap: onTap,` | unverified |
| INT-009 | core/widgets/book_card.dart | 35 | BookCard | onTap | `onTap: onTap,` | unverified |
| INT-010 | core/widgets/category_card.dart | 8 | CategoryCard | onTap | `required this.title, required this.color, required this.onTap, super.key,` | unverified |
| INT-011 | core/widgets/category_card.dart | 19 | CategoryCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-012 | core/widgets/category_card.dart | 47 | CategoryCard | onTap | `onTap: onTap,` | unverified |
| INT-013 | core/widgets/category_card.dart | 47 | CategoryCard | onTap | `onTap: onTap,` | unverified |
| INT-014 | core/widgets/main_shell.dart | 67 | _NoorBottomNav | onTap | `onTap: () => context.go('/'),` | unverified |
| INT-015 | core/widgets/main_shell.dart | 73 | _NoorBottomNav | onTap | `onTap: () => context.go('/quran'),` | unverified |
| INT-016 | core/widgets/main_shell.dart | 79 | _NoorBottomNav | onTap | `onTap: () => context.go('/hadith'),` | unverified |
| INT-017 | core/widgets/main_shell.dart | 85 | _NoorBottomNav | onTap | `onTap: () => context.go('/adhkar'),` | unverified |
| INT-018 | core/widgets/main_shell.dart | 91 | _NoorBottomNav | onTap | `onTap: () => context.go('/tools'),` | unverified |
| INT-019 | core/widgets/main_shell.dart | 108 | _NavItem | onTap | `required this.onTap,` | unverified |
| INT-020 | core/widgets/main_shell.dart | 113 | _NavItem | onTap | `final VoidCallback onTap;` | unverified |
| INT-021 | core/widgets/main_shell.dart | 149 | _NavItemState | onTap | `onTap: widget.onTap,` | unverified |
| INT-022 | core/widgets/main_shell.dart | 149 | _NavItemState | onTap | `onTap: widget.onTap,` | unverified |
| INT-023 | core/widgets/main_shell.dart | 157 | _NavItemState | onTap | `widget.onTap();` | unverified |
| INT-024 | features/adhkar/presentation/pages/adhkar_library_page.dart | 95 | _AdhkarLibraryPageState | onTap | `onTap: () => Navigator.of(context).push(` | unverified |
| INT-025 | features/adhkar/presentation/pages/adhkar_library_page.dart | 215 | _CategoryItemsPageState | onTap | `onTap: () {` | unverified |
| INT-026 | features/adhkar/presentation/pages/adhkar_page.dart | 145 | _AdhkarPageState | onTap | `onTap: () => _openAdhkar(context, AdhkarType.morning),` | unverified |
| INT-027 | features/adhkar/presentation/pages/adhkar_page.dart | 160 | _AdhkarPageState | onTap | `onTap: () => _openAdhkar(context, AdhkarType.evening),` | unverified |
| INT-028 | features/adhkar/presentation/pages/adhkar_page.dart | 173 | _AdhkarPageState | onTap | `onTap: () => _openAdhkar(context, AdhkarType.afterPrayer),` | unverified |
| INT-029 | features/adhkar/presentation/pages/adhkar_page.dart | 182 | _AdhkarPageState | onTap | `onTap: () => _openAdhkar(context, AdhkarType.sleep),` | unverified |
| INT-030 | features/adhkar/presentation/pages/adhkar_page.dart | 191 | _AdhkarPageState | onTap | `onTap: () => _openAdhkar(context, AdhkarType.wakeUp),` | unverified |
| INT-031 | features/adhkar/presentation/pages/adhkar_page.dart | 200 | _AdhkarPageState | onTap | `onTap: () => _openAdhkar(context, AdhkarType.general),` | unverified |
| INT-032 | features/adhkar/presentation/pages/adhkar_page.dart | 209 | _AdhkarPageState | onTap | `onTap: () => Navigator.of(context).push(` | unverified |
| INT-033 | features/adhkar/presentation/pages/adhkar_page.dart | 417 | _ModernCategoryCard | onTap | `required this.onTap, this.isHighlighted = false, // ? was: true (wrong)` | unverified |
| INT-034 | features/adhkar/presentation/pages/adhkar_page.dart | 426 | _ModernCategoryCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-035 | features/adhkar/presentation/pages/adhkar_page.dart | 433 | _ModernCategoryCard | onTap | `onTap: onTap,` | unverified |
| INT-036 | features/adhkar/presentation/pages/adhkar_page.dart | 433 | _ModernCategoryCard | onTap | `onTap: onTap,` | unverified |
| INT-037 | features/adhkar/presentation/pages/adhkar_page.dart | 557 | _AdhkarCounterPageState | onTap | `Future<void> _onTap() async {` | unverified |
| INT-038 | features/adhkar/presentation/pages/adhkar_page.dart | 611 | _AdhkarCounterPageState | onPressed | `onPressed: () {` | unverified |
| INT-039 | features/adhkar/presentation/pages/adhkar_page.dart | 731 | _AdhkarCounterPageState | onPressed | `onPressed: () => Navigator.of(context).pop(),` | unverified |
| INT-040 | features/adhkar/presentation/pages/adhkar_page.dart | 750 | _AdhkarCounterPageState | onTap | `onTap: _onTap,` | unverified |
| INT-041 | features/adhkar/presentation/pages/adhkar_page.dart | 750 | _AdhkarCounterPageState | onTap | `onTap: _onTap,` | unverified |
| INT-042 | features/audio/presentation/pages/audio_player_page.dart | 82 | _AudioPlayerPageState | onPressed | `onPressed: () => Navigator.pop(context, false),` | unverified |
| INT-043 | features/audio/presentation/pages/audio_player_page.dart | 86 | _AudioPlayerPageState | onPressed | `onPressed: () => Navigator.pop(context, true),` | unverified |
| INT-044 | features/audio/presentation/pages/audio_player_page.dart | 161 | _AudioPlayerPageState | onPressed | `onPressed: _showSurahSelector,` | unverified |
| INT-045 | features/audio/presentation/pages/audio_player_page.dart | 166 | _AudioPlayerPageState | onPressed | `onPressed: _showReciterSelector,` | unverified |
| INT-046 | features/audio/presentation/pages/audio_player_page.dart | 175 | _AudioPlayerPageState | onTap | `onTap: _showReciterSelector,` | unverified |
| INT-047 | features/audio/presentation/pages/audio_player_page.dart | 211 | _AudioPlayerPageState | onTap | `onTap: () => _playFromAyah(verseNumber),` | unverified |
| INT-048 | features/audio/presentation/pages/audio_player_page.dart | 232 | _AudioPlayerPageState | onChanged | `onChanged: (value) {` | unverified |
| INT-049 | features/audio/presentation/pages/audio_player_page.dart | 289 | _AudioPlayerPageState | onChanged | `onChanged: (value) {` | unverified |
| INT-050 | features/audio/presentation/pages/audio_player_page.dart | 334 | _AudioPlayerPageState | onPressed | `onPressed: () {` | unverified |
| INT-051 | features/audio/presentation/pages/audio_player_page.dart | 342 | _AudioPlayerPageState | onPressed | `onPressed: () {` | unverified |
| INT-052 | features/audio/presentation/pages/audio_player_page.dart | 369 | _AudioPlayerPageState | onPressed | `onPressed: () {` | unverified |
| INT-053 | features/audio/presentation/pages/audio_player_page.dart | 383 | _AudioPlayerPageState | onPressed | `onPressed: () {` | unverified |
| INT-054 | features/audio/presentation/pages/audio_player_page.dart | 397 | _AudioPlayerPageState | onPressed | `onPressed: _cycleRepeatMode,` | unverified |
| INT-055 | features/audio/presentation/pages/audio_player_page.dart | 496 | _AudioPlayerPageState | onTap | `onTap: () async {` | unverified |
| INT-056 | features/audio/presentation/pages/audio_player_page.dart | 545 | _AudioPlayerPageState | onTap | `onTap: () {` | unverified |
| INT-057 | features/audio/presentation/pages/audio_player_page.dart | 579 | _ReciterBar | onTap | `required this.onTap,` | unverified |
| INT-058 | features/audio/presentation/pages/audio_player_page.dart | 582 | _ReciterBar | onTap | `final VoidCallback onTap;` | unverified |
| INT-059 | features/audio/presentation/pages/audio_player_page.dart | 589 | _ReciterBar | onTap | `onTap: onTap,` | unverified |
| INT-060 | features/audio/presentation/pages/audio_player_page.dart | 589 | _ReciterBar | onTap | `onTap: onTap,` | unverified |
| INT-061 | features/audio/presentation/pages/audio_player_page.dart | 620 | _VerseCard | onTap | `required this.verseNumber, required this.text, required this.isPlaying, required this.isCu…` | unverified |
| INT-062 | features/audio/presentation/pages/audio_player_page.dart | 626 | _VerseCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-063 | features/audio/presentation/pages/audio_player_page.dart | 633 | _VerseCard | onTap | `onTap: onTap,` | unverified |
| INT-064 | features/audio/presentation/pages/audio_player_page.dart | 633 | _VerseCard | onTap | `onTap: onTap,` | unverified |
| INT-065 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 201 | _AdvancedHadithBrowserPageState | onPressed | `onPressed: () {` | unverified |
| INT-066 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 211 | _AdvancedHadithBrowserPageState | onSubmitted | `onSubmitted: (_) => _performSearch(),` | unverified |
| INT-067 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 234 | _AdvancedHadithBrowserPageState | onSelected | `onSelected: () => setState(() => _searchTarget = SearchTarget.all),` | unverified |
| INT-068 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 240 | _AdvancedHadithBrowserPageState | onSelected | `onSelected: () => setState(() => _searchTarget = SearchTarget.matn),` | unverified |
| INT-069 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 246 | _AdvancedHadithBrowserPageState | onSelected | `onSelected: () => setState(() => _searchTarget = SearchTarget.sanad),` | unverified |
| INT-070 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 268 | _AdvancedHadithBrowserPageState | onPressed | `onPressed: _showBookFilter,` | unverified |
| INT-071 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 282 | _AdvancedHadithBrowserPageState | onDeleted | `onDeleted: () => setState(() => _selectedGrades = {}),` | unverified |
| INT-072 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 292 | _AdvancedHadithBrowserPageState | onDeleted | `onDeleted: () => setState(() {` | unverified |
| INT-073 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 302 | _AdvancedHadithBrowserPageState | onDeleted | `onDeleted: () => setState(() => _selectedCompanion = null),` | unverified |
| INT-074 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 309 | _AdvancedHadithBrowserPageState | onDeleted | `onDeleted: () => setState(() => _selectedTopic = null),` | unverified |
| INT-075 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 338 | _AdvancedHadithBrowserPageState | onSelected | `onSelected: () => setState(() => _searchMode = mode),` | unverified |
| INT-076 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 371 | _AdvancedHadithBrowserPageState | onPressed | `onPressed: () {` | unverified |
| INT-077 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 385 | _AdvancedHadithBrowserPageState | onChanged | `onChanged: (_) => setState(() {}),` | unverified |
| INT-078 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 386 | _AdvancedHadithBrowserPageState | onSubmitted | `onSubmitted: (_) => _performSearch(),` | unverified |
| INT-079 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 410 | _AdvancedHadithBrowserPageState | onSubmitted | `onSubmitted: (_) => _performSearch(),` | unverified |
| INT-080 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 411 | _AdvancedHadithBrowserPageState | onChanged | `onChanged: (value) =>` | unverified |
| INT-081 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 436 | _AdvancedHadithBrowserPageState | onSubmitted | `onSubmitted: (_) => _performSearch(),` | unverified |
| INT-082 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 437 | _AdvancedHadithBrowserPageState | onChanged | `onChanged: (value) =>` | unverified |
| INT-083 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 468 | _AdvancedHadithBrowserPageState | onSelected | `onSelected: (selected) => setState(() {` | unverified |
| INT-084 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 589 | _AdvancedHadithBrowserPageState | onTap | `onTap: () => _openScholarMode(result.entry),` | unverified |
| INT-085 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 616 | _AdvancedHadithBrowserPageState | onTap | `onTap: () async {` | unverified |
| INT-086 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 660 | _AdvancedHadithBrowserPageState | onTap | `onTap: () async {` | unverified |
| INT-087 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 723 | _AdvancedHadithBrowserPageState | onTap | `onTap: () async {` | unverified |
| INT-088 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 749 | _AdvancedHadithBrowserPageState | onTap | `onTap: () {` | unverified |
| INT-089 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 758 | _AdvancedHadithBrowserPageState | onTap | `onTap: () {` | unverified |
| INT-090 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 814 | _HadithResultCard | onTap | `required this.onTap,` | unverified |
| INT-091 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 817 | _HadithResultCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-092 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 841 | _HadithResultCard | onTap | `onTap: onTap,` | unverified |
| INT-093 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 841 | _HadithResultCard | onTap | `onTap: onTap,` | unverified |
| INT-094 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 949 | _FilterChip | onSelected | `required this.onSelected,` | unverified |
| INT-095 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 953 | _FilterChip | onSelected | `final VoidCallback onSelected;` | unverified |
| INT-096 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 959 | _FilterChip | onTap | `onTap: onSelected,` | unverified |
| INT-097 | features/hadith/presentation/pages/advanced_hadith_browser_page.dart | 959 | _FilterChip | onSelected | `onTap: onSelected,` | unverified |
| INT-098 | features/hadith/presentation/pages/bookmarked_hadiths_page.dart | 182 | _BookmarkedHadithsPageState | onTap | `onTap: () {` | unverified |
| INT-099 | features/hadith/presentation/pages/bookmarked_hadiths_page.dart | 233 | _BookmarkedHadithsPageState | onTap | `onTap: () => _removeBookmark(collectionId, hadithId),` | unverified |
| INT-100 | features/hadith/presentation/pages/hadith_chapter_hadiths_page.dart | 125 | _HadithChapterHadithsPageState | onTap | `onTap: () {` | unverified |
| INT-101 | features/hadith/presentation/pages/hadith_chapter_hadiths_page.dart | 160 | _HadithPreviewCard | onTap | `required this.onTap,` | unverified |
| INT-102 | features/hadith/presentation/pages/hadith_chapter_hadiths_page.dart | 166 | _HadithPreviewCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-103 | features/hadith/presentation/pages/hadith_chapter_hadiths_page.dart | 186 | _HadithPreviewCard | onTap | `onTap: onTap,` | unverified |
| INT-104 | features/hadith/presentation/pages/hadith_chapter_hadiths_page.dart | 186 | _HadithPreviewCard | onTap | `onTap: onTap,` | unverified |
| INT-105 | features/hadith/presentation/pages/hadith_chapters_page.dart | 122 | HadithChaptersPage | onTap | `onTap: () {` | unverified |
| INT-106 | features/hadith/presentation/pages/hadith_chapters_page.dart | 186 | HadithChaptersPage | onTap | `onTap: () {` | unverified |
| INT-107 | features/hadith/presentation/pages/hadith_chapters_page.dart | 309 | _ChapterTile | onTap | `required this.onTap,` | unverified |
| INT-108 | features/hadith/presentation/pages/hadith_chapters_page.dart | 315 | _ChapterTile | onTap | `final VoidCallback onTap;` | unverified |
| INT-109 | features/hadith/presentation/pages/hadith_chapters_page.dart | 328 | _ChapterTile | onTap | `onTap: onTap,` | unverified |
| INT-110 | features/hadith/presentation/pages/hadith_chapters_page.dart | 328 | _ChapterTile | onTap | `onTap: onTap,` | unverified |
| INT-111 | features/hadith/presentation/pages/hadith_page.dart | 123 | _HadithPageState | onPressed | `onPressed: () {` | unverified |
| INT-112 | features/hadith/presentation/pages/hadith_page.dart | 133 | _HadithPageState | onPressed | `onPressed: () {` | unverified |
| INT-113 | features/hadith/presentation/pages/hadith_page.dart | 144 | _HadithPageState | onPressed | `onPressed: _startQuiz,` | unverified |
| INT-114 | features/hadith/presentation/pages/hadith_page.dart | 154 | _HadithPageState | onTap | `onTap: () async {` | unverified |
| INT-115 | features/hadith/presentation/pages/hadith_page.dart | 202 | _HadithPageState | onTap | `onTap: () {` | unverified |
| INT-116 | features/hadith/presentation/pages/hadith_page.dart | 264 | _HadithPageState | onTap | `onTap: () {` | unverified |
| INT-117 | features/hadith/presentation/pages/hadith_page.dart | 315 | _HadithPageState | onTap | `onTap: () => context.go('/hadith/memorization'),` | unverified |
| INT-118 | features/hadith/presentation/pages/hadith_page.dart | 321 | _HadithPageState | onTap | `onTap: () => context.go('/hadith/stats'),` | unverified |
| INT-119 | features/hadith/presentation/pages/hadith_page.dart | 327 | _HadithPageState | onTap | `onTap: () => context.go('/hadith/tags'),` | unverified |
| INT-120 | features/hadith/presentation/pages/hadith_page.dart | 333 | _HadithPageState | onTap | `onTap: () => context.go('/hadith/topics'),` | unverified |
| INT-121 | features/hadith/presentation/pages/hadith_page.dart | 339 | _HadithPageState | onTap | `onTap: () => context.go('/hadith/advanced'),` | unverified |
| INT-122 | features/hadith/presentation/pages/hadith_page.dart | 374 | _ContinueReadingCard | onTap | `const _ContinueReadingCard({required this.progress, required this.onTap});` | unverified |
| INT-123 | features/hadith/presentation/pages/hadith_page.dart | 376 | _ContinueReadingCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-124 | features/hadith/presentation/pages/hadith_page.dart | 396 | _ContinueReadingCard | onTap | `onTap: onTap,` | unverified |
| INT-125 | features/hadith/presentation/pages/hadith_page.dart | 396 | _ContinueReadingCard | onTap | `onTap: onTap,` | unverified |
| INT-126 | features/hadith/presentation/pages/hadith_page.dart | 477 | _HadithOfTheDayCard | onTap | `const _HadithOfTheDayCard({required this.hadith, required this.onTap});` | unverified |
| INT-127 | features/hadith/presentation/pages/hadith_page.dart | 479 | _HadithOfTheDayCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-128 | features/hadith/presentation/pages/hadith_page.dart | 487 | _HadithOfTheDayCard | onTap | `onTap: onTap,` | unverified |
| INT-129 | features/hadith/presentation/pages/hadith_page.dart | 487 | _HadithOfTheDayCard | onTap | `onTap: onTap,` | unverified |
| INT-130 | features/hadith/presentation/pages/hadith_page.dart | 608 | _StudyToolTile | onTap | `required this.onTap,` | unverified |
| INT-131 | features/hadith/presentation/pages/hadith_page.dart | 613 | _StudyToolTile | onTap | `final VoidCallback onTap;` | unverified |
| INT-132 | features/hadith/presentation/pages/hadith_page.dart | 624 | _StudyToolTile | onTap | `onTap: onTap,` | unverified |
| INT-133 | features/hadith/presentation/pages/hadith_page.dart | 624 | _StudyToolTile | onTap | `onTap: onTap,` | unverified |
| INT-134 | features/hadith/presentation/pages/hadith_reader_page.dart | 195 | _HadithReaderPageState | onPageChanged | `void _onPageChanged(int index) {` | unverified |
| INT-135 | features/hadith/presentation/pages/hadith_reader_page.dart | 250 | _HadithReaderPageState | onPressed | `onPressed: () => HadithSharhSheet.show(` | unverified |
| INT-136 | features/hadith/presentation/pages/hadith_reader_page.dart | 264 | _HadithReaderPageState | onPressed | `onPressed: _toggleBookmark,` | unverified |
| INT-137 | features/hadith/presentation/pages/hadith_reader_page.dart | 269 | _HadithReaderPageState | onPressed | `onPressed: _copyHadith,` | unverified |
| INT-138 | features/hadith/presentation/pages/hadith_reader_page.dart | 274 | _HadithReaderPageState | onPressed | `onPressed: _shareHadith,` | unverified |
| INT-139 | features/hadith/presentation/pages/hadith_reader_page.dart | 284 | _HadithReaderPageState | onPageChanged | `onPageChanged: _onPageChanged,` | unverified |
| INT-140 | features/hadith/presentation/pages/hadith_reader_page.dart | 284 | _HadithReaderPageState | onPageChanged | `onPageChanged: _onPageChanged,` | unverified |
| INT-141 | features/hadith/presentation/pages/hadith_reader_page.dart | 632 | _BottomNav | onTap | `onTap: onPrevious,` | unverified |
| INT-142 | features/hadith/presentation/pages/hadith_reader_page.dart | 670 | _BottomNav | onTap | `onTap: onNext,` | unverified |
| INT-143 | features/hadith/presentation/pages/hadith_reader_page.dart | 685 | _NavButton | onTap | `required this.onTap,` | unverified |
| INT-144 | features/hadith/presentation/pages/hadith_reader_page.dart | 691 | _NavButton | onTap | `final VoidCallback? onTap;` | unverified |
| INT-145 | features/hadith/presentation/pages/hadith_reader_page.dart | 697 | _NavButton | onTap | `final enabled = onTap != null;` | unverified |
| INT-146 | features/hadith/presentation/pages/hadith_reader_page.dart | 703 | _NavButton | onTap | `onTap: onTap,` | unverified |
| INT-147 | features/hadith/presentation/pages/hadith_reader_page.dart | 703 | _NavButton | onTap | `onTap: onTap,` | unverified |
| INT-148 | features/hadith/presentation/pages/hadith_reader_page.dart | 707 | _NavButton | onTap | `onTap: onTap,` | unverified |
| INT-149 | features/hadith/presentation/pages/hadith_reader_page.dart | 707 | _NavButton | onTap | `onTap: onTap,` | unverified |
| INT-150 | features/hadith/presentation/pages/hadith_search_page.dart | 127 | _HadithSearchPageState | onTap | `onTap: () {` | unverified |
| INT-151 | features/hadith/presentation/pages/hadith_search_page.dart | 178 | _HadithSearchPageState | onPressed | `onPressed: () {` | unverified |
| INT-152 | features/hadith/presentation/pages/hadith_search_page.dart | 195 | _HadithSearchPageState | onChanged | `onChanged: (_) {` | unverified |
| INT-153 | features/hadith/presentation/pages/hadith_search_page.dart | 202 | _HadithSearchPageState | onSubmitted | `onSubmitted: (_) => _performSearch(),` | unverified |
| INT-154 | features/hadith/presentation/pages/hadith_search_page.dart | 233 | _HadithSearchPageState | onChanged | `onChanged: (value) => setState(() => _selectedCollectionId = value),` | unverified |
| INT-155 | features/hadith/presentation/pages/hadith_search_page.dart | 243 | _HadithSearchPageState | onPressed | `onPressed: _searchController.text.trim().isNotEmpty ? _performSearch : null,` | unverified |
| INT-156 | features/hadith/presentation/pages/hadith_search_page.dart | 351 | _HadithSearchPageState | onTap | `onTap: () {` | unverified |
| INT-157 | features/hadith/presentation/pages/hadith_search_page.dart | 402 | _SearchResultCard | onTap | `required this.onTap,` | unverified |
| INT-158 | features/hadith/presentation/pages/hadith_search_page.dart | 406 | _SearchResultCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-159 | features/hadith/presentation/pages/hadith_search_page.dart | 426 | _SearchResultCard | onTap | `onTap: onTap,` | unverified |
| INT-160 | features/hadith/presentation/pages/hadith_search_page.dart | 426 | _SearchResultCard | onTap | `onTap: onTap,` | unverified |
| INT-161 | features/hadith/presentation/pages/isnad_chain_page.dart | 103 | _IsnadChainPageState | onPressed | `onPressed: () {` | unverified |
| INT-162 | features/hadith/presentation/pages/isnad_chain_page.dart | 207 | _IsnadChainPageState | onTap | `onTap: () {` | unverified |
| INT-163 | features/hadith/presentation/pages/isnad_chain_page.dart | 327 | _NarratorCard | onTap | `required this.onTap,` | unverified |
| INT-164 | features/hadith/presentation/pages/isnad_chain_page.dart | 333 | _NarratorCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-165 | features/hadith/presentation/pages/isnad_chain_page.dart | 367 | _NarratorCard | onTap | `onTap: onTap,` | unverified |
| INT-166 | features/hadith/presentation/pages/isnad_chain_page.dart | 367 | _NarratorCard | onTap | `onTap: onTap,` | unverified |
| INT-167 | features/hadith/presentation/pages/isnad_chain_page.dart | 634 | _NarratorDetailPanel | onPressed | `onPressed: onClose,` | unverified |
| INT-168 | features/hadith/presentation/pages/layered_hadith_page.dart | 85 | _LayeredHadithPageState | onPressed | `onPressed: () => _openScholarMode(context),` | unverified |
| INT-169 | features/hadith/presentation/pages/layered_hadith_page.dart | 90 | _LayeredHadithPageState | onPressed | `onPressed: () => _share(context),` | unverified |
| INT-170 | features/hadith/presentation/pages/layered_hadith_page.dart | 164 | _LayeredHadithPageState | onPressed | `onPressed: () => _copyText(widget.hadith.text),` | unverified |
| INT-171 | features/hadith/presentation/pages/layered_hadith_page.dart | 170 | _LayeredHadithPageState | onPressed | `onPressed: () => _shareAsImage(context),` | unverified |
| INT-172 | features/hadith/presentation/pages/layered_hadith_page.dart | 305 | _LayeredHadithPageState | onPressed | `onPressed: () => _searchByCompanion(widget.hadith.companion),` | unverified |
| INT-173 | features/hadith/presentation/pages/layered_hadith_page.dart | 435 | _LayeredHadithPageState | onTap | `onTap: () => _openHadith(result.entry),` | unverified |
| INT-174 | features/hadith/presentation/pages/layered_hadith_page.dart | 611 | _LayeredHadithPageState | onTap | `onTap: () => _openHadith(result.entry),` | unverified |
| INT-175 | features/hadith/presentation/pages/layered_hadith_page.dart | 622 | _LayeredHadithPageState | onPressed | `onPressed: _copyFullTakhrij,` | unverified |
| INT-176 | features/hadith/presentation/pages/memorization_page.dart | 121 | _MemorizationPageState | onTap | `onTap: _toggleCard,` | unverified |
| INT-177 | features/hadith/presentation/pages/memorization_page.dart | 342 | _MemorizationPageState | onTap | `onTap: () => _reviewCard(rating),` | unverified |
| INT-178 | features/hadith/presentation/pages/memorization_page.dart | 373 | _MemorizationPageState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |
| INT-179 | features/hadith/presentation/pages/memorization_page.dart | 434 | _RatingButton | onTap | `required this.onTap,` | unverified |
| INT-180 | features/hadith/presentation/pages/memorization_page.dart | 438 | _RatingButton | onTap | `final VoidCallback onTap;` | unverified |
| INT-181 | features/hadith/presentation/pages/memorization_page.dart | 459 | _RatingButton | onTap | `onTap: onTap,` | unverified |
| INT-182 | features/hadith/presentation/pages/memorization_page.dart | 459 | _RatingButton | onTap | `onTap: onTap,` | unverified |
| INT-183 | features/hadith/presentation/pages/narration_comparison_page.dart | 101 | _NarrationComparisonPageState | onPressed | `onPressed: () => setState(() => _showDiff = !_showDiff),` | unverified |
| INT-184 | features/hadith/presentation/pages/narration_comparison_page.dart | 121 | _NarrationComparisonPageState | onTap | `onTap: () {` | unverified |
| INT-185 | features/hadith/presentation/pages/narration_comparison_page.dart | 159 | _NarrationComparisonPageState | onPageChanged | `onPageChanged: (index) => setState(() => _currentIndex = index),` | unverified |
| INT-186 | features/hadith/presentation/pages/narration_comparison_page.dart | 171 | _NarrationComparisonPageState | onPressed | `onPressed: _showSideBySideComparison,` | unverified |
| INT-187 | features/hadith/presentation/pages/quiz_page.dart | 195 | _QuizPageState | onTap | `onTap: state.showResult ? null : () => _selectAnswer(option),` | unverified |
| INT-188 | features/hadith/presentation/pages/quiz_page.dart | 314 | _QuizPageState | onPressed | `onPressed: () {` | unverified |
| INT-189 | features/hadith/presentation/pages/quiz_page.dart | 329 | _QuizPageState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |
| INT-190 | features/hadith/presentation/pages/scholar_mode_page.dart | 118 | _ScholarModePageState | onPressed | `onPressed: () => setState(() => _highlightKeywords = !_highlightKeywords),` | unverified |
| INT-191 | features/hadith/presentation/pages/scholar_mode_page.dart | 123 | _ScholarModePageState | onPressed | `onPressed: _shareWithTakhrij,` | unverified |
| INT-192 | features/hadith/presentation/pages/scholar_mode_page.dart | 368 | _ScholarModePageState | onChanged | `onChanged: _saveNote,` | unverified |
| INT-193 | features/hadith/presentation/pages/scholar_mode_page.dart | 429 | _ScholarModePageState | onTap | `onTap: () {` | unverified |
| INT-194 | features/hadith/presentation/pages/scholar_mode_page.dart | 550 | _ScholarModePageState | onTap | `onTap: () => _showNarratorDetail(narrator, profile),` | unverified |
| INT-195 | features/hadith/presentation/pages/scholar_mode_page.dart | 675 | _ScholarModePageState | onPressed | `onPressed: _copyWithTakhrij,` | unverified |
| INT-196 | features/hadith/presentation/pages/scholar_mode_page.dart | 680 | _ScholarModePageState | onPressed | `onPressed: () => _shareAsImage(context),` | unverified |
| INT-197 | features/hadith/presentation/pages/scholar_mode_page.dart | 685 | _ScholarModePageState | onPressed | `onPressed: _addToReview,` | unverified |
| INT-198 | features/hadith/presentation/pages/tags_management_page.dart | 210 | _TagsManagementPageState | onTap | `onTap: () => setModalState(() => _selectedIcon = icon),` | unverified |
| INT-199 | features/hadith/presentation/pages/tags_management_page.dart | 239 | _TagsManagementPageState | onTap | `onTap: () => setModalState(() => _selectedColor = color),` | unverified |
| INT-200 | features/hadith/presentation/pages/tags_management_page.dart | 271 | _TagsManagementPageState | onPressed | `onPressed: _createTag,` | unverified |
| INT-201 | features/hadith/presentation/pages/tags_management_page.dart | 341 | _TagsManagementPageState | onTap | `onTap: () => _toggleHadithInTag(tag),` | unverified |
| INT-202 | features/hadith/presentation/pages/tags_management_page.dart | 406 | _TagsManagementPageState | onPressed | `onPressed: _showCreateTagDialog,` | unverified |
| INT-203 | features/hadith/presentation/pages/topic_tree_page.dart | 137 | _TopicTreePageState | onTap | `onTap: () => _openTopic(topic),` | unverified |
| INT-204 | features/hadith/presentation/widgets/hadith_share_sheet.dart | 153 | _HadithShareSheetState | onPressed | `onPressed: _isProcessing ? null : _captureAndShare,` | unverified |
| INT-205 | features/hadith/presentation/widgets/hadith_sharh_sheet.dart | 177 | _HadithSharhSheetState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |
| INT-206 | features/hadith/presentation/widgets/hadith_sharh_sheet.dart | 284 | _HadithSharhSheetState | onPressed | `onPressed: () {` | unverified |
| INT-207 | features/hadith/presentation/widgets/hadith_sharh_sheet.dart | 361 | _HadithSharhSheetState | onTap | `onTap: () {` | unverified |
| INT-208 | features/hadith/presentation/widgets/hadith_sharh_sheet.dart | 378 | _HadithSharhSheetState | onTap | `onTap: () {` | unverified |
| INT-209 | features/hadith/presentation/widgets/hadith_sharh_sheet.dart | 394 | _HadithSharhSheetState | onTap | `onTap: () {` | unverified |
| INT-210 | features/hadith/presentation/widgets/hadith_sharh_sheet.dart | 409 | _HadithSharhSheetState | onTap | `onTap: () {` | unverified |
| INT-211 | features/hadith/presentation/widgets/hadith_sharh_sheet.dart | 564 | _StudyToolButton | onTap | `required this.onTap,` | unverified |
| INT-212 | features/hadith/presentation/widgets/hadith_sharh_sheet.dart | 570 | _StudyToolButton | onTap | `final VoidCallback onTap;` | unverified |
| INT-213 | features/hadith/presentation/widgets/hadith_sharh_sheet.dart | 577 | _StudyToolButton | onTap | `onTap: onTap,` | unverified |
| INT-214 | features/hadith/presentation/widgets/hadith_sharh_sheet.dart | 577 | _StudyToolButton | onTap | `onTap: onTap,` | unverified |
| INT-215 | features/hifz/presentation/pages/hifz_page.dart | 102 | _HifzPageState | onPressed | `onPressed: () => _openSession(due.isNotEmpty ? due : newCards),` | unverified |
| INT-216 | features/hifz/presentation/pages/hifz_page.dart | 242 | _HifzCardTile | onPressed | `onPressed: onDelete,` | unverified |
| INT-217 | features/hifz/presentation/pages/hifz_page.dart | 246 | _HifzCardTile | onPressed | `onPressed: onReview,` | unverified |
| INT-218 | features/hifz/presentation/pages/hifz_page.dart | 304 | _HifzCardTile | onTap | `onTap: () => onRepeatChanged(count),` | unverified |
| INT-219 | features/hifz/presentation/pages/hifz_session_page.dart | 112 | _HifzSessionPageState | onPressed | `onPressed: () {` | unverified |
| INT-220 | features/hifz/presentation/pages/hifz_session_page.dart | 187 | _HifzSessionPageState | onPressed | `onPressed: () async {` | unverified |
| INT-221 | features/hifz/presentation/pages/hifz_session_page.dart | 199 | _HifzSessionPageState | onPressed | `onPressed: _startRepeat,` | unverified |
| INT-222 | features/hifz/presentation/pages/hifz_session_page.dart | 232 | _HifzSessionPageState | onTap | `onTap: () => _rate(rating),` | unverified |
| INT-223 | features/hifz/presentation/pages/hifz_session_page.dart | 252 | _RatingButton | onTap | `required this.onTap,` | unverified |
| INT-224 | features/hifz/presentation/pages/hifz_session_page.dart | 256 | _RatingButton | onTap | `final VoidCallback onTap;` | unverified |
| INT-225 | features/hifz/presentation/pages/hifz_session_page.dart | 263 | _RatingButton | onTap | `onTap: onTap,` | unverified |
| INT-226 | features/hifz/presentation/pages/hifz_session_page.dart | 263 | _RatingButton | onTap | `onTap: onTap,` | unverified |
| INT-227 | features/home/presentation/pages/home_page.dart | 97 | _HomePageState | onPressed | `onPressed: () => ref.invalidate(homeDataProvider),` | unverified |
| INT-228 | features/home/presentation/pages/home_page.dart | 99 | _HomePageState | onRetry | `label: Text(AppLocalizations.of(context).commonRetry),` | unverified |
| INT-229 | features/home/presentation/pages/home_page.dart | 165 | _HomePageState | onPressed | `onPressed: () => context.go('/tools/search'),` | unverified |
| INT-230 | features/home/presentation/pages/home_page.dart | 171 | _HomePageState | onPressed | `onPressed: () => context.go('/tools/settings'),` | unverified |
| INT-231 | features/home/presentation/pages/home_page.dart | 323 | _HomePageState | onTap | `onTap: () => context.go('/adhkar'),` | unverified |
| INT-232 | features/home/presentation/widgets/adhkar_status_card.dart | 10 | AdhkarStatusCard | onTap | `const AdhkarStatusCard({required this.stats, required this.onTap, super.key});` | unverified |
| INT-233 | features/home/presentation/widgets/adhkar_status_card.dart | 12 | AdhkarStatusCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-234 | features/home/presentation/widgets/adhkar_status_card.dart | 22 | AdhkarStatusCard | onTap | `onTap: onTap,` | unverified |
| INT-235 | features/home/presentation/widgets/adhkar_status_card.dart | 22 | AdhkarStatusCard | onTap | `onTap: onTap,` | unverified |
| INT-236 | features/home/presentation/widgets/continue_reading_card.dart | 21 | ContinueReadingCard | onTap | `onTap: () {` | unverified |
| INT-237 | features/home/presentation/widgets/favorites_section.dart | 24 | FavoritesSection | onTap | `onTap: () => context.go('/quran/surah/67'),` | unverified |
| INT-238 | features/home/presentation/widgets/favorites_section.dart | 31 | FavoritesSection | onTap | `onTap: () => context.go('/adhkar'),` | unverified |
| INT-239 | features/home/presentation/widgets/favorites_section.dart | 38 | FavoritesSection | onTap | `onTap: () => context.go('/quran/surah/36'),` | unverified |
| INT-240 | features/home/presentation/widgets/favorites_section.dart | 52 | _FavoriteItemCard | onTap | `required this.onTap,` | unverified |
| INT-241 | features/home/presentation/widgets/favorites_section.dart | 58 | _FavoriteItemCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-242 | features/home/presentation/widgets/favorites_section.dart | 66 | _FavoriteItemCard | onTap | `onTap: onTap,` | unverified |
| INT-243 | features/home/presentation/widgets/favorites_section.dart | 66 | _FavoriteItemCard | onTap | `onTap: onTap,` | unverified |
| INT-244 | features/onboarding/presentation/pages/onboarding_page.dart | 112 | _OnboardingPageState | onPressed | `onPressed: _completeOnboarding,` | unverified |
| INT-245 | features/onboarding/presentation/pages/onboarding_page.dart | 126 | _OnboardingPageState | onPageChanged | `onPageChanged: (index) => setState(() => _currentPage = index),` | unverified |
| INT-246 | features/onboarding/presentation/pages/onboarding_page.dart | 164 | _OnboardingPageState | onPressed | `onPressed: _nextPage,` | unverified |
| INT-247 | features/prayer/presentation/pages/prayer_page.dart | 47 | PrayerPage | onPressed | `onPressed: () => context.go('/tools/prayer/qada'),` | unverified |
| INT-248 | features/prayer/presentation/pages/prayer_page.dart | 52 | PrayerPage | onPressed | `onPressed: () => context.go('/tools/prayer/settings'),` | unverified |
| INT-249 | features/prayer/presentation/pages/prayer_page.dart | 82 | PrayerPage | onPressed | `onPressed: () => ref.invalidate(prayerDataProvider),` | unverified |
| INT-250 | features/prayer/presentation/pages/prayer_page.dart | 84 | PrayerPage | onRetry | `label: Text(l10n.commonRetry, style: GoogleFonts.cairo()),` | unverified |
| INT-251 | features/prayer/presentation/pages/prayer_page.dart | 192 | _PrayerContent | onToggle | `onToggle: prayerType == null` | unverified |
| INT-252 | features/prayer/presentation/pages/prayer_page.dart | 377 | _TimelinePrayerRow | onToggle | `this.onToggle,` | unverified |
| INT-253 | features/prayer/presentation/pages/prayer_page.dart | 390 | _TimelinePrayerRow | onToggle | `final VoidCallback? onToggle;` | unverified |
| INT-254 | features/prayer/presentation/pages/prayer_page.dart | 403 | _TimelinePrayerRow | onTap | `onTap: onToggle,` | unverified |
| INT-255 | features/prayer/presentation/pages/prayer_page.dart | 403 | _TimelinePrayerRow | onToggle | `onTap: onToggle,` | unverified |
| INT-256 | features/prayer/presentation/pages/prayer_page.dart | 544 | _TimelinePrayerRow | onPressed | `onPressed: onBellPressed,` | unverified |
| INT-257 | features/prayer/presentation/pages/prayer_settings_page.dart | 134 | _PrayerSettingsPageState | onChanged | `onChanged: (method) {` | unverified |
| INT-258 | features/prayer/presentation/pages/prayer_settings_page.dart | 191 | _PrayerSettingsPageState | onChanged | `onChanged: (v) {` | unverified |
| INT-259 | features/prayer/presentation/pages/prayer_settings_page.dart | 246 | _PrayerSettingsPageState | onChanged | `onChanged: (v) {` | unverified |
| INT-260 | features/prayer/presentation/pages/prayer_settings_page.dart | 273 | _PrayerSettingsPageState | onChanged | `onChanged: (v) => notifier.setMosqueDuration(v.round()),` | unverified |
| INT-261 | features/prayer/presentation/pages/prayer_settings_page.dart | 286 | _PrayerSettingsPageState | onTap | `onTap: () {` | unverified |
| INT-262 | features/prayer/presentation/pages/prayer_settings_page.dart | 299 | _PrayerSettingsPageState | onTap | `onTap: () {` | unverified |
| INT-263 | features/prayer/presentation/pages/prayer_settings_page.dart | 312 | _PrayerSettingsPageState | onTap | `onTap: () {` | unverified |
| INT-264 | features/prayer/presentation/pages/prayer_settings_page.dart | 389 | _PrayerSettingsPageState | onChanged | `onChanged: (v) {` | unverified |
| INT-265 | features/prayer/presentation/pages/prayer_settings_page.dart | 425 | _PrayerSettingsPageState | onPressed | `onPressed: () {` | unverified |
| INT-266 | features/prayer/presentation/pages/prayer_settings_page.dart | 461 | _PrayerSettingsPageState | onPressed | `onPressed:` | unverified |
| INT-267 | features/prayer/presentation/pages/prayer_settings_page.dart | 551 | _QuickMosqueButton | onTap | `const _QuickMosqueButton({required this.minutes, required this.onTap});` | unverified |
| INT-268 | features/prayer/presentation/pages/prayer_settings_page.dart | 553 | _QuickMosqueButton | onTap | `final VoidCallback onTap;` | unverified |
| INT-269 | features/prayer/presentation/pages/prayer_settings_page.dart | 559 | _QuickMosqueButton | onPressed | `onPressed: onTap,` | unverified |
| INT-270 | features/prayer/presentation/pages/prayer_settings_page.dart | 559 | _QuickMosqueButton | onTap | `onPressed: onTap,` | unverified |
| INT-271 | features/prayer/presentation/pages/prayer_settings_page.dart | 664 | _HealthIssueCard | onPressed | `onPressed: onFix,` | unverified |
| INT-272 | features/prayer/presentation/pages/qada_page.dart | 109 | _QadaTrackerPageState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |
| INT-273 | features/prayer/presentation/pages/qada_page.dart | 159 | _QadaList | onPressed | `onPressed: onAdd,` | unverified |
| INT-274 | features/prayer/presentation/pages/qada_page.dart | 176 | _QadaList | onPressed | `onPressed: onAdd,` | unverified |
| INT-275 | features/prayer/presentation/pages/qada_page.dart | 265 | _QadaCard | onPressed | `onPressed: onDelete,` | unverified |
| INT-276 | features/prayer/presentation/pages/qada_page.dart | 343 | _QadaCard | onTap | `onTap: onIncrement,` | unverified |
| INT-277 | features/prayer/presentation/pages/qada_page.dart | 455 | _AddQadaDialogState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |
| INT-278 | features/prayer/presentation/pages/qada_page.dart | 459 | _AddQadaDialogState | onPressed | `onPressed: () {` | unverified |
| INT-279 | features/profile/presentation/pages/profile_page.dart | 296 | ProfilePage | onPressed | `onPressed: () async {` | unverified |
| INT-280 | features/qibla/presentation/pages/qibla_page.dart | 177 | _QiblaPageState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |
| INT-281 | features/qibla/presentation/pages/qibla_page.dart | 181 | _QiblaPageState | onPressed | `onPressed: () {` | unverified |
| INT-282 | features/qibla/presentation/pages/qibla_page.dart | 270 | _QiblaPageState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |
| INT-283 | features/qibla/presentation/pages/qibla_page.dart | 329 | _QiblaPageState | onPressed | `onPressed: () => setState(() => _showDebug = !_showDebug),` | unverified |
| INT-284 | features/qibla/presentation/pages/qibla_page.dart | 334 | _QiblaPageState | onPressed | `onPressed: _showCalibrationHelp,` | unverified |
| INT-285 | features/qibla/presentation/pages/qibla_page.dart | 390 | _QiblaPageState | onPressed | `onPressed: _getLocation,` | unverified |
| INT-286 | features/qibla/presentation/pages/qibla_page.dart | 392 | _QiblaPageState | onRetry | `AppLocalizations.of(context).commonRetry,` | unverified |
| INT-287 | features/qibla/presentation/pages/qibla_page.dart | 519 | _QiblaPageState | onPressed | `onPressed: _showCalibrationHelp,` | unverified |
| INT-288 | features/qibla/presentation/pages/qibla_page.dart | 676 | _QiblaPageState | onPressed | `onPressed: _toggleLock,` | unverified |
| INT-289 | features/qibla/presentation/pages/qibla_page.dart | 696 | _QiblaPageState | onPressed | `onPressed: _toggleMosqueMode,` | unverified |
| INT-290 | features/qibla/presentation/pages/qibla_page.dart | 714 | _QiblaPageState | onPressed | `onPressed: _getLocation,` | unverified |
| INT-291 | features/quran/presentation/pages/khatmah_page.dart | 30 | _KhatmahPlannerPageState | onPressed | `onPressed: _showCreateKhatmahDialog,` | unverified |
| INT-292 | features/quran/presentation/pages/khatmah_page.dart | 51 | _KhatmahPlannerPageState | onPressed | `onPressed: _showCreateKhatmahDialog,` | unverified |
| INT-293 | features/quran/presentation/pages/khatmah_page.dart | 70 | _KhatmahPlannerPageState | onResume | `onResume: () {` | unverified |
| INT-294 | features/quran/presentation/pages/khatmah_page.dart | 184 | _ActiveKhatmahCard | onResume | `required this.onResume,` | unverified |
| INT-295 | features/quran/presentation/pages/khatmah_page.dart | 193 | _ActiveKhatmahCard | onResume | `final VoidCallback onResume;` | unverified |
| INT-296 | features/quran/presentation/pages/khatmah_page.dart | 327 | _ActiveKhatmahCard | onPressed | `onPressed: onResume,` | unverified |
| INT-297 | features/quran/presentation/pages/khatmah_page.dart | 327 | _ActiveKhatmahCard | onResume | `onPressed: onResume,` | unverified |
| INT-298 | features/quran/presentation/pages/khatmah_page.dart | 590 | _CreateKhatmahDialogState | onChanged | `onChanged: (value) {` | unverified |
| INT-299 | features/quran/presentation/pages/khatmah_page.dart | 605 | _CreateKhatmahDialogState | onPressed | `onPressed: _isLoading ? null : () => Navigator.pop(context),` | unverified |
| INT-300 | features/quran/presentation/pages/khatmah_page.dart | 609 | _CreateKhatmahDialogState | onPressed | `onPressed: _isLoading` | unverified |
| INT-301 | features/quran/presentation/pages/quran_mushaf_page.dart | 147 | _QuranMushafPageState | onTap | `onTap: _toggleControls,` | unverified |
| INT-302 | features/quran/presentation/pages/quran_mushaf_page.dart | 174 | _QuranMushafPageState | onPreview | `onPreview: (page) =>` | unverified |
| INT-303 | features/quran/presentation/pages/quran_mushaf_page.dart | 176 | _QuranMushafPageState | onSettle | `onSettle: (page) {` | unverified |
| INT-304 | features/quran/presentation/pages/quran_mushaf_page.dart | 270 | _QuranMushafPageState | onTap | `onTap: () {` | unverified |
| INT-305 | features/quran/presentation/pages/quran_mushaf_page.dart | 367 | MushafPageView | onPageChanged | `onPageChanged: (index) => onPageSettled(index + 1),` | unverified |
| INT-306 | features/quran/presentation/pages/quran_page.dart | 111 | QuranPage | onChanged | `onChanged: (query) {` | unverified |
| INT-307 | features/quran/presentation/pages/quran_page.dart | 151 | QuranPage | onTap | `onTap: () => context.push(` | unverified |
| INT-308 | features/quran/presentation/pages/quran_page.dart | 244 | QuranPage | onTap | `onTap: () {` | unverified |
| INT-309 | features/quran/presentation/pages/quran_page.dart | 265 | QuranPage | onRetry | `onRetry: () => ref.refresh(surahsProvider),` | unverified |
| INT-310 | features/quran/presentation/pages/quran_page.dart | 283 | QuranPage | onPressed | `onPressed: () => context.push('/quran/mushaf'),` | unverified |
| INT-311 | features/quran/presentation/pages/quran_page.dart | 293 | QuranPage | onPressed | `onPressed: () => context.push('/quran/khatmah'),` | unverified |
| INT-312 | features/quran/presentation/pages/quran_page.dart | 303 | QuranPage | onPressed | `onPressed: () => context.push('/tafsir'),` | unverified |
| INT-313 | features/quran/presentation/pages/quran_page.dart | 343 | _FilterBarDelegate | onTap | `onTap: () => onFilterChanged('all'),` | unverified |
| INT-314 | features/quran/presentation/pages/quran_page.dart | 349 | _FilterBarDelegate | onTap | `onTap: () => onFilterChanged('meccan'),` | unverified |
| INT-315 | features/quran/presentation/pages/quran_page.dart | 355 | _FilterBarDelegate | onTap | `onTap: () => onFilterChanged('medinan'),` | unverified |
| INT-316 | features/quran/presentation/pages/quran_page.dart | 375 | _FilterChip | onTap | `required this.onTap,` | unverified |
| INT-317 | features/quran/presentation/pages/quran_page.dart | 379 | _FilterChip | onTap | `final VoidCallback onTap;` | unverified |
| INT-318 | features/quran/presentation/pages/quran_page.dart | 384 | _FilterChip | onTap | `onTap: onTap,` | unverified |
| INT-319 | features/quran/presentation/pages/quran_page.dart | 384 | _FilterChip | onTap | `onTap: onTap,` | unverified |
| INT-320 | features/quran/presentation/pages/quran_page.dart | 416 | _SearchBar | onChanged | `const _SearchBar({required this.onChanged});` | unverified |
| INT-321 | features/quran/presentation/pages/quran_page.dart | 417 | _SearchBar | onChanged | `final ValueChanged<String> onChanged;` | unverified |
| INT-322 | features/quran/presentation/pages/quran_page.dart | 442 | _SearchBarState | onChanged | `onChanged: widget.onChanged,` | unverified |
| INT-323 | features/quran/presentation/pages/quran_page.dart | 442 | _SearchBarState | onChanged | `onChanged: widget.onChanged,` | unverified |
| INT-324 | features/quran/presentation/pages/quran_page.dart | 460 | _SearchBarState | onPressed | `onPressed: () {` | unverified |
| INT-325 | features/quran/presentation/pages/quran_page.dart | 462 | _SearchBarState | onChanged | `widget.onChanged('');` | unverified |
| INT-326 | features/quran/presentation/pages/quran_page.dart | 491 | _SurahListTile | onTap | `required this.onTap,` | unverified |
| INT-327 | features/quran/presentation/pages/quran_page.dart | 499 | _SurahListTile | onTap | `final VoidCallback onTap;` | unverified |
| INT-328 | features/quran/presentation/pages/quran_page.dart | 518 | _SurahListTile | onTap | `onTap: onTap,` | unverified |
| INT-329 | features/quran/presentation/pages/quran_page.dart | 518 | _SurahListTile | onTap | `onTap: onTap,` | unverified |
| INT-330 | features/quran/presentation/pages/quran_page.dart | 725 | _ErrorWidget | onRetry | `const _ErrorWidget({required this.error, required this.onRetry});` | unverified |
| INT-331 | features/quran/presentation/pages/quran_page.dart | 727 | _ErrorWidget | onRetry | `final VoidCallback onRetry;` | unverified |
| INT-332 | features/quran/presentation/pages/quran_page.dart | 753 | _ErrorWidget | onPressed | `onPressed: onRetry,` | unverified |
| INT-333 | features/quran/presentation/pages/quran_page.dart | 753 | _ErrorWidget | onRetry | `onPressed: onRetry,` | unverified |
| INT-334 | features/quran/presentation/pages/quran_page.dart | 755 | _ErrorWidget | onRetry | `label: Text(AppLocalizations.of(context).commonRetry),` | unverified |
| INT-335 | features/quran/presentation/pages/surah_page.dart | 171 | _SurahPageState | onTap | `onTap: settings.isKhushuMode ? _toggleKhushuMode : null,` | unverified |
| INT-336 | features/quran/presentation/pages/surah_page.dart | 207 | _SurahPageState | onPressed | `onPressed: () =>` | unverified |
| INT-337 | features/quran/presentation/pages/surah_page.dart | 210 | _SurahPageState | onRetry | `label: Text(AppLocalizations.of(context).commonRetry),` | unverified |
| INT-338 | features/quran/presentation/pages/surah_page.dart | 256 | _SurahPageState | onPressed | `onPressed: _toggleKhushuMode,` | unverified |
| INT-339 | features/quran/presentation/pages/surah_page.dart | 266 | _SurahPageState | onPressed | `onPressed: () => _showAudioPlayer(context),` | unverified |
| INT-340 | features/quran/presentation/pages/surah_page.dart | 276 | _SurahPageState | onSelected | `onSelected: (value) {` | unverified |
| INT-341 | features/quran/presentation/pages/surah_page.dart | 367 | _SurahPageState | onTap | `onTap: () {` | unverified |
| INT-342 | features/quran/presentation/pages/surah_page.dart | 380 | _SurahPageState | onLongPress | `onLongPress: () =>` | unverified |
| INT-343 | features/quran/presentation/pages/surah_page.dart | 501 | _SurahPageState | onChanged | `onChanged: (v) {` | unverified |
| INT-344 | features/quran/presentation/pages/surah_page.dart | 513 | _SurahPageState | onChanged | `onChanged: (v) {` | unverified |
| INT-345 | features/quran/presentation/pages/surah_page.dart | 536 | _SurahPageState | onSelected | `onSelected: (_) {` | unverified |
| INT-346 | features/quran/presentation/pages/surah_page.dart | 554 | _SurahPageState | onSelected | `onSelected: (_) {` | unverified |
| INT-347 | features/quran/presentation/pages/surah_page.dart | 601 | _SurahPageState | onTap | `onTap: () {` | unverified |
| INT-348 | features/quran/presentation/pages/surah_page.dart | 616 | _SurahPageState | onTap | `onTap: () async {` | unverified |
| INT-349 | features/quran/presentation/pages/surah_page.dart | 635 | _SurahPageState | onTap | `onTap: () async {` | unverified |
| INT-350 | features/quran/presentation/pages/surah_page.dart | 655 | _SurahPageState | onTap | `onTap: () {` | unverified |
| INT-351 | features/quran/presentation/pages/surah_page.dart | 673 | _SurahPageState | onTap | `onTap: () {` | unverified |
| INT-352 | features/quran/presentation/pages/surah_page.dart | 685 | _SurahPageState | onTap | `onTap: () {` | unverified |
| INT-353 | features/quran/presentation/pages/tadabbur_page.dart | 123 | _TadabburMihrabPageState | onPressed | `onPressed: _showPrivacyInfo,` | unverified |
| INT-354 | features/quran/presentation/pages/tadabbur_page.dart | 212 | _TadabburMihrabPageState | onPressed | `onPressed: _saveNote,` | unverified |
| INT-355 | features/quran/presentation/pages/tadabbur_page.dart | 318 | _TadabburMihrabPageState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |
| INT-356 | features/quran/presentation/pages/tadabbur_page.dart | 365 | _NoteCard | onPressed | `onPressed: onDelete,` | unverified |
| INT-357 | features/quran/presentation/pages/tafsir_reader_page.dart | 125 | TafsirReaderPageState | onPressed | `onPressed: () => _showFontSizeSheet(context),` | unverified |
| INT-358 | features/quran/presentation/pages/tafsir_reader_page.dart | 134 | TafsirReaderPageState | onPressed | `onPressed: () {` | unverified |
| INT-359 | features/quran/presentation/pages/tafsir_reader_page.dart | 148 | TafsirReaderPageState | onSelected | `onSelected: (source) {` | unverified |
| INT-360 | features/quran/presentation/pages/tafsir_reader_page.dart | 229 | TafsirReaderPageState | onSelected | `onSelected: (_) {` | unverified |
| INT-361 | features/quran/presentation/pages/tafsir_reader_page.dart | 278 | TafsirReaderPageState | onSelected | `onSelected: (selected) {` | unverified |
| INT-362 | features/quran/presentation/pages/tafsir_reader_page.dart | 310 | TafsirReaderPageState | onPressed | `onPressed: _compareAyah > 1` | unverified |
| INT-363 | features/quran/presentation/pages/tafsir_reader_page.dart | 352 | TafsirReaderPageState | onPressed | `onPressed: atEnd` | unverified |
| INT-364 | features/quran/presentation/pages/tafsir_reader_page.dart | 458 | TafsirReaderPageState | onTap | `onTap: () => _showTadabburSheet(` | unverified |
| INT-365 | features/quran/presentation/pages/tafsir_reader_page.dart | 481 | TafsirReaderPageState | onTap | `onTap: () {` | unverified |
| INT-366 | features/quran/presentation/pages/tafsir_reader_page.dart | 564 | TafsirReaderPageState | onPressed | `onPressed: _loadCompareData,` | unverified |
| INT-367 | features/quran/presentation/pages/tafsir_reader_page.dart | 748 | TafsirReaderPageState | onChanged | `onChanged: (v) {` | unverified |
| INT-368 | features/quran/presentation/pages/tafsir_reader_page.dart | 796 | WordAnalysisButton | onTap | `onTap: () => _showWordAnalysis(context),` | unverified |
| INT-369 | features/quran/presentation/pages/tafsir_reader_page.dart | 1206 | WordAnalysisSheetState | onTap | `onTap: () => setState(` | unverified |
| INT-370 | features/quran/presentation/pages/tafsir_reader_page.dart | 1456 | InlineAnnotationsPanel | onTap | `onTap: onAddNote,` | unverified |
| INT-371 | features/quran/presentation/pages/tafsir_reader_page.dart | 1672 | TadabburNoteSheetState | onTap | `onTap: () => _deleteNote(note),` | unverified |
| INT-372 | features/quran/presentation/pages/tafsir_reader_page.dart | 1753 | TadabburNoteSheetState | onTap | `onTap: _addNote,` | unverified |
| INT-373 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 187 | _AyahActionsSheetState | onTap | `onTap: () {` | unverified |
| INT-374 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 207 | _AyahActionsSheetState | onTap | `onTap: () async {` | unverified |
| INT-375 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 232 | _AyahActionsSheetState | onTap | `onTap: () {` | unverified |
| INT-376 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 300 | _AyahActionsSheetState | onPressed | `onPressed: () => setState(` | unverified |
| INT-377 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 336 | _AyahActionsSheetState | onRetry | `onRetry: _loadTafsir,` | unverified |
| INT-378 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 358 | _AyahActionsSheetState | onPressed | `onPressed: () =>` | unverified |
| INT-379 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 388 | _AyahActionsSheetState | onTap | `onTap: () {` | unverified |
| INT-380 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 448 | TafsirEmptyState | onRetry | `required this.onRetry,` | unverified |
| INT-381 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 453 | TafsirEmptyState | onRetry | `final VoidCallback onRetry;` | unverified |
| INT-382 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 474 | TafsirEmptyState | onPressed | `onPressed: onRetry,` | unverified |
| INT-383 | features/quran/presentation/widgets/mushaf/ayah_actions_sheet.dart | 474 | TafsirEmptyState | onRetry | `onPressed: onRetry,` | unverified |
| INT-384 | features/quran/presentation/widgets/mushaf/mushaf_canvas.dart | 112 | MushafPageCanvas | onRetry | `onRetry: () => ref.refresh(quranPageProvider(pageNumber)),` | unverified |
| INT-385 | features/quran/presentation/widgets/mushaf/mushaf_canvas.dart | 188 | MushafErrorPane | onRetry | `required this.onRetry,` | unverified |
| INT-386 | features/quran/presentation/widgets/mushaf/mushaf_canvas.dart | 193 | MushafErrorPane | onRetry | `final VoidCallback onRetry;` | unverified |
| INT-387 | features/quran/presentation/widgets/mushaf/mushaf_canvas.dart | 228 | MushafErrorPane | onPressed | `onPressed: onRetry,` | unverified |
| INT-388 | features/quran/presentation/widgets/mushaf/mushaf_canvas.dart | 228 | MushafErrorPane | onRetry | `onPressed: onRetry,` | unverified |
| INT-389 | features/quran/presentation/widgets/mushaf/mushaf_canvas.dart | 470 | _ContinuousVerseBlockState | onTap | `..onTap = () => widget.onVerseTap?.call(verse);` | unverified |
| INT-390 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 23 | MushafControlsOverlay | onPreview | `required this.onPreview,` | unverified |
| INT-391 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 24 | MushafControlsOverlay | onSettle | `required this.onSettle,` | unverified |
| INT-392 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 32 | MushafControlsOverlay | onPreview | `final ValueChanged<int> onPreview;` | unverified |
| INT-393 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 33 | MushafControlsOverlay | onSettle | `final ValueChanged<int> onSettle;` | unverified |
| INT-394 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 58 | MushafControlsOverlay | onPreview | `onPreview: onPreview,` | unverified |
| INT-395 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 58 | MushafControlsOverlay | onPreview | `onPreview: onPreview,` | unverified |
| INT-396 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 59 | MushafControlsOverlay | onSettle | `onSettle: onSettle,` | unverified |
| INT-397 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 59 | MushafControlsOverlay | onSettle | `onSettle: onSettle,` | unverified |
| INT-398 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 106 | MushafTopBar | onPressed | `onPressed: onBack,` | unverified |
| INT-399 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 112 | MushafTopBar | onPressed | `onPressed: onTheme,` | unverified |
| INT-400 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 128 | MushafBottomBar | onPreview | `required this.onPreview,` | unverified |
| INT-401 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 129 | MushafBottomBar | onSettle | `required this.onSettle,` | unverified |
| INT-402 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 134 | MushafBottomBar | onPreview | `final ValueChanged<int> onPreview;` | unverified |
| INT-403 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 135 | MushafBottomBar | onSettle | `final ValueChanged<int> onSettle;` | unverified |
| INT-404 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 177 | MushafBottomBar | onChanged | `onChanged: (v) => onPreview(v.round()),` | unverified |
| INT-405 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 177 | MushafBottomBar | onPreview | `onChanged: (v) => onPreview(v.round()),` | unverified |
| INT-406 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 178 | MushafBottomBar | onSettle | `onChangeEnd: (v) => onSettle(v.round()),` | unverified |
| INT-407 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 235 | MushafZoomControls | onPressed | `onPressed: idx > 0` | unverified |
| INT-408 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 247 | MushafZoomControls | onPressed | `onPressed: zoom == 1.0 ? null : () => setZoom(1.0),` | unverified |
| INT-409 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 257 | MushafZoomControls | onPressed | `onPressed: idx >= 0 && idx < kMushafZoomLevels.length - 1` | unverified |
| INT-410 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 280 | MushafActionButton | onTap | `required this.onTap,` | unverified |
| INT-411 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 287 | MushafActionButton | onTap | `final VoidCallback onTap;` | unverified |
| INT-412 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 295 | MushafActionButton | onTap | `onTap: onTap,` | unverified |
| INT-413 | features/quran/presentation/widgets/mushaf/mushaf_controls.dart | 295 | MushafActionButton | onTap | `onTap: onTap,` | unverified |
| INT-414 | features/quran/presentation/widgets/surah_audio_widgets.dart | 74 | AudioPlayerSheetState | onChanged | `onChanged: (value) {` | unverified |
| INT-415 | features/quran/presentation/widgets/surah_audio_widgets.dart | 91 | AudioPlayerSheetState | onPressed | `onPressed: () => context.push(` | unverified |
| INT-416 | features/quran/presentation/widgets/surah_audio_widgets.dart | 114 | AudioPlayerSheetState | onPressed | `onPressed: QuranAudioService.stop,` | unverified |
| INT-417 | features/quran/presentation/widgets/surah_audio_widgets.dart | 142 | AudioPlayerSheetState | onPressed | `onPressed: () {` | unverified |
| INT-418 | features/quran/presentation/widgets/surah_audio_widgets.dart | 178 | OptionTile | onTap | `required this.onTap,` | unverified |
| INT-419 | features/quran/presentation/widgets/surah_audio_widgets.dart | 183 | OptionTile | onTap | `final VoidCallback onTap;` | unverified |
| INT-420 | features/quran/presentation/widgets/surah_audio_widgets.dart | 198 | OptionTile | onTap | `onTap: onTap,` | unverified |
| INT-421 | features/quran/presentation/widgets/surah_audio_widgets.dart | 198 | OptionTile | onTap | `onTap: onTap,` | unverified |
| INT-422 | features/quran/presentation/widgets/surah_audio_widgets.dart | 240 | MiniAudioPlayer | onTap | `onTap: () {` | unverified |
| INT-423 | features/quran/presentation/widgets/surah_audio_widgets.dart | 287 | MiniAudioPlayer | onPressed | `onPressed: QuranAudioService.stop,` | unverified |
| INT-424 | features/quran/presentation/widgets/surah_verse_widgets.dart | 69 | DynamicVerseCard | onTap | `required this.onTap,` | unverified |
| INT-425 | features/quran/presentation/widgets/surah_verse_widgets.dart | 70 | DynamicVerseCard | onLongPress | `required this.onLongPress,` | unverified |
| INT-426 | features/quran/presentation/widgets/surah_verse_widgets.dart | 78 | DynamicVerseCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-427 | features/quran/presentation/widgets/surah_verse_widgets.dart | 79 | DynamicVerseCard | onLongPress | `final VoidCallback onLongPress;` | unverified |
| INT-428 | features/quran/presentation/widgets/surah_verse_widgets.dart | 93 | DynamicVerseCard | onTap | `onTap: onTap,` | unverified |
| INT-429 | features/quran/presentation/widgets/surah_verse_widgets.dart | 93 | DynamicVerseCard | onTap | `onTap: onTap,` | unverified |
| INT-430 | features/quran/presentation/widgets/surah_verse_widgets.dart | 94 | DynamicVerseCard | onLongPress | `onLongPress: onLongPress,` | unverified |
| INT-431 | features/quran/presentation/widgets/surah_verse_widgets.dart | 94 | DynamicVerseCard | onLongPress | `onLongPress: onLongPress,` | unverified |
| INT-432 | features/quran/presentation/widgets/surah_verse_widgets.dart | 257 | DynamicTafsirPanel | onChanged | `onChanged: (id) {` | unverified |
| INT-433 | features/quran/presentation/widgets/surah_verse_widgets.dart | 271 | DynamicTafsirPanel | onPressed | `onPressed: () => context.push(` | unverified |
| INT-434 | features/quran/presentation/widgets/surah_verse_widgets.dart | 294 | DynamicTafsirPanel | onPressed | `onPressed: onClose,` | unverified |
| INT-435 | features/search/presentation/pages/search_page.dart | 73 | _SearchPageState | onChanged | `onChanged: _onQueryChanged,` | unverified |
| INT-436 | features/search/presentation/pages/search_page.dart | 159 | _SearchResultCard | onTap | `onTap: () => _openResult(context),` | unverified |
| INT-437 | features/settings/presentation/pages/notifications_settings_page.dart | 60 | _NotificationsSettingsPageState | onChanged | `onChanged: (v) => _updateSettings(` | unverified |
| INT-438 | features/settings/presentation/pages/notifications_settings_page.dart | 71 | _NotificationsSettingsPageState | onChanged | `onChanged: (v) => _updateSettings(` | unverified |
| INT-439 | features/settings/presentation/pages/notifications_settings_page.dart | 88 | _NotificationsSettingsPageState | onChanged | `onChanged: (v) => _updateSettings(` | unverified |
| INT-440 | features/settings/presentation/pages/notifications_settings_page.dart | 112 | _NotificationsSettingsPageState | onChanged | `onChanged: (v) => _updateSettings(` | unverified |
| INT-441 | features/settings/presentation/pages/notifications_settings_page.dart | 132 | _NotificationsSettingsPageState | onChanged | `onChanged: (v) => _updateSettings(` | unverified |
| INT-442 | features/settings/presentation/pages/notifications_settings_page.dart | 147 | _NotificationsSettingsPageState | onPressed | `onPressed: _pickTime,` | unverified |
| INT-443 | features/settings/presentation/pages/notifications_settings_page.dart | 177 | _NotificationsSettingsPageState | onChanged | `onChanged: (v) => _updateSettings(` | unverified |
| INT-444 | features/settings/presentation/pages/notifications_settings_page.dart | 188 | _NotificationsSettingsPageState | onPressed | `onPressed: () async {` | unverified |
| INT-445 | features/settings/presentation/pages/notifications_settings_page.dart | 302 | _SettingsTile | onChanged | `required this.onChanged,` | unverified |
| INT-446 | features/settings/presentation/pages/notifications_settings_page.dart | 309 | _SettingsTile | onChanged | `final ValueChanged<bool> onChanged;` | unverified |
| INT-447 | features/settings/presentation/pages/notifications_settings_page.dart | 326 | _SettingsTile | onChanged | `onChanged: (v) {` | unverified |
| INT-448 | features/settings/presentation/pages/notifications_settings_page.dart | 328 | _SettingsTile | onChanged | `onChanged(v);` | unverified |
| INT-449 | features/settings/presentation/pages/settings_page.dart | 150 | _SettingsPageState | onChanged | `onChanged: (value) {` | unverified |
| INT-450 | features/settings/presentation/pages/settings_page.dart | 197 | _SettingsPageState | onChanged | `onChanged: (value) {` | unverified |
| INT-451 | features/settings/presentation/pages/settings_page.dart | 211 | _SettingsPageState | onChanged | `onChanged: (value) {` | unverified |
| INT-452 | features/settings/presentation/pages/settings_page.dart | 221 | _SettingsPageState | onTap | `onTap: _showClearCacheDialog,` | unverified |
| INT-453 | features/settings/presentation/pages/settings_page.dart | 251 | _SettingsPageState | onTap | `onTap: () => context.go('/tools/settings/notifications'),` | unverified |
| INT-454 | features/settings/presentation/pages/settings_page.dart | 258 | _SettingsPageState | onTap | `onTap: () => context.go('/tools/settings/storage'),` | unverified |
| INT-455 | features/settings/presentation/pages/settings_page.dart | 286 | _SettingsPageState | onTap | `onTap: () => _showPrivacySheet(context),` | unverified |
| INT-456 | features/settings/presentation/pages/settings_page.dart | 313 | _SettingsPageState | onTap | `onTap: () => _showAboutSheet(context),` | unverified |
| INT-457 | features/settings/presentation/pages/settings_page.dart | 450 | _SettingsPageState | onTap | `onTap: () {` | unverified |
| INT-458 | features/settings/presentation/pages/settings_page.dart | 489 | _SettingsPageState | onChanged | `required ValueChanged<bool> onChanged,` | unverified |
| INT-459 | features/settings/presentation/pages/settings_page.dart | 496 | _SettingsPageState | onChanged | `onChanged: onChanged,` | unverified |
| INT-460 | features/settings/presentation/pages/settings_page.dart | 496 | _SettingsPageState | onChanged | `onChanged: onChanged,` | unverified |
| INT-461 | features/settings/presentation/pages/settings_page.dart | 506 | _SettingsPageState | onTap | `VoidCallback? onTap,` | unverified |
| INT-462 | features/settings/presentation/pages/settings_page.dart | 514 | _SettingsPageState | onTap | `onTap: onTap,` | unverified |
| INT-463 | features/settings/presentation/pages/settings_page.dart | 514 | _SettingsPageState | onTap | `onTap: onTap,` | unverified |
| INT-464 | features/settings/presentation/pages/settings_page.dart | 536 | _SettingsPageState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |
| INT-465 | features/settings/presentation/pages/settings_page.dart | 540 | _SettingsPageState | onPressed | `onPressed: () async {` | unverified |
| INT-466 | features/settings/presentation/pages/storage_settings_page.dart | 136 | _StorageSettingsPageState | onTap | `onTap: _clearing ? null : _clearCache,` | unverified |
| INT-467 | features/settings/presentation/pages/storage_settings_page.dart | 157 | _StorageSettingsPageState | onTap | `onTap: _syncing ? null : _refreshStats,` | unverified |
| INT-468 | features/settings/presentation/pages/storage_settings_page.dart | 188 | _StorageSettingsPageState | onPressed | `onPressed: () {` | unverified |
| INT-469 | features/settings/presentation/pages/storage_settings_page.dart | 213 | _StorageSettingsPageState | onPressed | `onPressed: () {` | unverified |
| INT-470 | features/tafsir/presentation/pages/tafsir_page.dart | 107 | _TafsirPageState | onSelected | `onSelected: (source) {` | unverified |
| INT-471 | features/tafsir/presentation/pages/tafsir_page.dart | 139 | _TafsirPageState | onPressed | `onPressed: () => _showSearch(context),` | unverified |
| INT-472 | features/tafsir/presentation/pages/tafsir_page.dart | 225 | _TafsirPageState | onChanged | `onChanged: (value) {` | unverified |
| INT-473 | features/tafsir/presentation/pages/tafsir_page.dart | 274 | _TafsirPageState | onBookmark | `onBookmark: () => setState(() {}),` | unverified |
| INT-474 | features/tafsir/presentation/pages/tafsir_page.dart | 328 | _TafsirPageState | onPressed | `onPressed: () async {` | unverified |
| INT-475 | features/tafsir/presentation/pages/tafsir_page.dart | 337 | _TafsirPageState | onTap | `onTap: () {` | unverified |
| INT-476 | features/tafsir/presentation/pages/tafsir_page.dart | 388 | _TafsirPageState | onTap | `onTap: () {` | unverified |
| INT-477 | features/tafsir/presentation/pages/tafsir_page.dart | 434 | _TafsirCard | onBookmark | `required this.onBookmark,` | unverified |
| INT-478 | features/tafsir/presentation/pages/tafsir_page.dart | 438 | _TafsirCard | onBookmark | `final VoidCallback onBookmark;` | unverified |
| INT-479 | features/tafsir/presentation/pages/tafsir_page.dart | 514 | _TafsirCard | onPressed | `onPressed: () async {` | unverified |
| INT-480 | features/tafsir/presentation/pages/tafsir_page.dart | 528 | _TafsirCard | onBookmark | `onBookmark();` | unverified |
| INT-481 | features/tafsir/presentation/pages/tafsir_page.dart | 595 | _TafsirSearchDelegate | onPressed | `onPressed: () => query = '',` | unverified |
| INT-482 | features/tafsir/presentation/pages/tafsir_page.dart | 607 | _TafsirSearchDelegate | onPressed | `onPressed: () => close(context, null),` | unverified |
| INT-483 | features/tafsir/presentation/pages/tafsir_page.dart | 654 | _TafsirSearchDelegate | onTap | `onTap: () => close(context, entry),` | unverified |
| INT-484 | features/tafsir/presentation/pages/tafsir_page.dart | 714 | _TafsirSearchDelegate | onPressed | `onPressed: () {` | unverified |
| INT-485 | features/tafsir/presentation/pages/tafsir_page.dart | 769 | _SearchResultCard | onTap | `required this.onTap,` | unverified |
| INT-486 | features/tafsir/presentation/pages/tafsir_page.dart | 773 | _SearchResultCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-487 | features/tafsir/presentation/pages/tafsir_page.dart | 809 | _SearchResultCard | onTap | `onTap: onTap,` | unverified |
| INT-488 | features/tafsir/presentation/pages/tafsir_page.dart | 809 | _SearchResultCard | onTap | `onTap: onTap,` | unverified |
| INT-489 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 15 | TafsirInlineView | onExpand | `this.onExpand,` | unverified |
| INT-490 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 22 | TafsirInlineView | onExpand | `final VoidCallback? onExpand;` | unverified |
| INT-491 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 105 | _TafsirInlineViewState | onExpand | `widget.onExpand?.call();` | unverified |
| INT-492 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 147 | _TafsirInlineViewState | onTap | `onTap: _toggle,` | unverified |
| INT-493 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 190 | _TafsirInlineViewState | onPressed | `onPressed: () async {` | unverified |
| INT-494 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 295 | _TafsirInlineViewState | onPressed | `onPressed: () {` | unverified |
| INT-495 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 309 | _TafsirInlineViewState | onPressed | `onPressed: () => _showCompare(context),` | unverified |
| INT-496 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 405 | _TafsirFullScreenPageState | onSelected | `onSelected: (source) {` | unverified |
| INT-497 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 434 | _TafsirFullScreenPageState | onPressed | `onPressed: () => _showFontSizeDialog(context),` | unverified |
| INT-498 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 509 | _TafsirFullScreenPageState | onPressed | `onPressed: () {` | unverified |
| INT-499 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 524 | _TafsirFullScreenPageState | onPressed | `onPressed: () {` | unverified |
| INT-500 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 558 | _TafsirFullScreenPageState | onChanged | `onChanged: (value) {` | unverified |
| INT-501 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 572 | _TafsirFullScreenPageState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |
| INT-502 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 576 | _TafsirFullScreenPageState | onPressed | `onPressed: () {` | unverified |
| INT-503 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 699 | _TafsirCompareSheetState | onSelected | `onSelected: (selected) {` | unverified |
| INT-504 | features/tafsir/presentation/widgets/tafsir_widgets.dart | 931 | _TafsirSheetContentState | onSelected | `onSelected: (source) {` | unverified |
| INT-505 | features/tools/presentation/pages/tasbih_page.dart | 94 | _TasbihPageState | onPressed | `onPressed: _reset,` | unverified |
| INT-506 | features/tools/presentation/pages/tasbih_page.dart | 115 | _TasbihPageState | onTap | `onTap: () => _setTarget(33),` | unverified |
| INT-507 | features/tools/presentation/pages/tasbih_page.dart | 122 | _TasbihPageState | onTap | `onTap: () => _setTarget(100),` | unverified |
| INT-508 | features/tools/presentation/pages/tasbih_page.dart | 129 | _TasbihPageState | onTap | `onTap: () => _setTarget(0),` | unverified |
| INT-509 | features/tools/presentation/pages/tasbih_page.dart | 142 | _TasbihPageState | onTap | `onTap: _increment,` | unverified |
| INT-510 | features/tools/presentation/pages/tasbih_page.dart | 146 | _TasbihPageState | onTap | `onTap: _increment,` | unverified |
| INT-511 | features/tools/presentation/pages/tasbih_page.dart | 244 | _PresetChip | onTap | `required this.onTap,` | unverified |
| INT-512 | features/tools/presentation/pages/tasbih_page.dart | 249 | _PresetChip | onTap | `final VoidCallback onTap;` | unverified |
| INT-513 | features/tools/presentation/pages/tasbih_page.dart | 259 | _PresetChip | onTap | `onTap: onTap,` | unverified |
| INT-514 | features/tools/presentation/pages/tasbih_page.dart | 259 | _PresetChip | onTap | `onTap: onTap,` | unverified |
| INT-515 | features/tools/presentation/pages/tasbih_page.dart | 263 | _PresetChip | onTap | `onTap: onTap,` | unverified |
| INT-516 | features/tools/presentation/pages/tasbih_page.dart | 263 | _PresetChip | onTap | `onTap: onTap,` | unverified |
| INT-517 | features/tools/presentation/pages/tools_page.dart | 53 | ToolsPage | onTap | `onTap: () {` | unverified |
| INT-518 | features/tools/presentation/pages/tools_page.dart | 66 | ToolsPage | onTap | `onTap: () {` | unverified |
| INT-519 | features/tools/presentation/pages/tools_page.dart | 79 | ToolsPage | onTap | `onTap: () {` | unverified |
| INT-520 | features/tools/presentation/pages/tools_page.dart | 92 | ToolsPage | onTap | `onTap: () {` | unverified |
| INT-521 | features/tools/presentation/pages/tools_page.dart | 105 | ToolsPage | onTap | `onTap: () {` | unverified |
| INT-522 | features/tools/presentation/pages/tools_page.dart | 118 | ToolsPage | onTap | `onTap: () {` | unverified |
| INT-523 | features/tools/presentation/pages/tools_page.dart | 131 | ToolsPage | onTap | `onTap: () {` | unverified |
| INT-524 | features/tools/presentation/pages/tools_page.dart | 163 | _ToolCard | onTap | `required this.onTap,` | unverified |
| INT-525 | features/tools/presentation/pages/tools_page.dart | 169 | _ToolCard | onTap | `final VoidCallback onTap;` | unverified |
| INT-526 | features/tools/presentation/pages/tools_page.dart | 174 | _ToolCard | onTap | `onTap: onTap,` | unverified |
| INT-527 | features/tools/presentation/pages/tools_page.dart | 174 | _ToolCard | onTap | `onTap: onTap,` | unverified |
| INT-528 | l10n/generated/app_localizations.dart | 159 | - | onRetry | `String get commonRetry;` | unverified |
| INT-529 | l10n/generated/app_localizations_ar.dart | 40 | AppLocalizationsAr | onRetry | `String get commonRetry => 'إعادة المحاولة';` | unverified |
| INT-530 | l10n/generated/app_localizations_en.dart | 41 | AppLocalizationsEn | onRetry | `String get commonRetry => 'Retry';` | unverified |
| INT-531 | shared/widgets/share_card_widget.dart | 410 | _ShareCardPreviewDialogState | onTap | `onTap: () => setState(() => _selectedStyle = style),` | unverified |
| INT-532 | shared/widgets/share_card_widget.dart | 448 | _ShareCardPreviewDialogState | onPressed | `onPressed: _shareCard,` | unverified |
| INT-533 | shared/widgets/share_card_widget.dart | 454 | _ShareCardPreviewDialogState | onPressed | `onPressed: () => Navigator.pop(context),` | unverified |

<!-- INVENTORY:END -->

Pure formatting and small presentation callbacks take focused widget tests; data, navigation, permission, audio, share, destructive, or cross-feature actions require a state assertion plus device evidence where platform plugins are involved.
