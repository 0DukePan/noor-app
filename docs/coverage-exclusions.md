# Coverage exclusions & dispositions

Policy: **no blanket ignores**. Every lib/ file that is not loaded by the
test suite, or that has low coverage, gets a written disposition here. When
a file's disposition changes (e.g. a Phase 3 split lands), this doc is
updated in the same commit. Coverage is measured by
`tools/coverage_summary.py` (hit / non-blank lines of all lib/ files).

Last updated: 2026-09-06 (floor 30, 624 tests, 30.89%).

## Accepted low/zero coverage (written reasons)

| File | Coverage | Disposition |
|---|---|---|
| `lib/main.dart` | 0% | App entry + service wiring; boots the real app on the Android emulator in CI (integration test). Per-line unit coverage here is ceremony, not risk reduction. |
| `lib/core/services/services.dart`, `lib/core/domain/policies/policies.dart` | loaded (no executable lines) | Pure export barrels — verified resolvable by `test/domain/barrels_test.dart`. Dart coverage emits no records for executable-less libraries, so they still read "zero" on the report; dispositioned, not neglected. |
| `lib/core/domain/repositories/*.dart` (hadith, tafsir, search) | 0% | Abstract interfaces; implementations (`*_impl.dart`) carry the logic and are tested. |
| `lib/core/domain/policies/*.dart` | partial | Pure policy/const classes; privacy policy behavior **covered as of 2026-09-05** (`privacy_policy_test.dart`: AES round-trip, random IVs, corrupt-input safety, local-only denials). Remaining policy files exercised via the engines that consume them. |
| `lib/core/models/tafsir_models.dart`, `lib/core/domain/entities/*.dart` (partially) | partial | Plain data classes; covered where serialization/behavior exists (model round-trip tests). |
| `lib/core/services/prayer_calculation_service.dart` | covered | Thin facade over `PrayerTimeEngine`; **covered** (`prayer_calculation_service_test.dart`, 9 tests incl. method-delta and exactly-one-next invariants). |
| `lib/features/audio/presentation/pages/audio_player_page.dart`, `lib/features/hifz/presentation/pages/hifz_session_page.dart` | covered | Audio + hifz UI — **covered as of 2026-09-05** (audio page ×5: Fatiha load, repeat cycle, speed slider, reciter-sheet switch, surah sheet — engine never initialized, playback on-device; hifz ×4 via Hive-free fake notifier — render/pass/re-queue/complete). Real fix: the 16-tile reciter sheet overflowed phones (now scrollable). |
| `lib/core/services/quran_audio_engine.dart`, `quran_audio_service.dart`, `secure_key_service.dart`, `prayer_health_check.dart`, `adhan_scheduler_service.dart` | covered | Engine/facade/keys/scheduler/health — **covered as of 2026-09-05** (engine pure surface; facade projection + LoopMode; keys stored/generate/empty/namespaces; health healthy/critical/warning + records + fixes; scheduler chronology + skip rules + Arabic args + toggles; channels mocked, playback/http on-device). |
| `lib/features/quran/data/datasources/quran_datasources.dart`, `local_quran_data_source.dart`, `lib/features/quran/data/repositories/quran_repository_impl.dart`, `lib/core/theme/theme_service.dart`, `lib/core/services/hadith_data_source.dart`, `lib/features/prayer/presentation/pages/prayer_page.dart` | covered | Quran data + theme + hadith facade + prayer UI — **covered as of 2026-09-05** (model aliases/round-trips; real-asset source; repo offline-first + progress; theme prefs + generation; seeded-DB catalog/enrichment; prayer shimmer + real-retry + timeline light/dark). |
| `lib/core/services/qibla_engine.dart` | 100% (exec) | Safety-critical geodesy — **covered as of 2026-08-18** (`qibla_engine_test.dart`, 32 tests, golden bearings/distances). |
| `lib/features/qibla/presentation/pages/qibla_page.dart` | covered | Qibla UI — **covered as of 2026-08-19** (`qibla_page_test.dart`, 11 widget tests: location fallback/success via mocked geolocator channel, compass heading/error via mocked event channel, debug/calibration/lock/mosque-mode/refresh interactions). Also fixed a real robustness gap: compass stream errors now degrade to "unknown accuracy" instead of surfacing an unhandled stream error.
| `lib/core/services/narrator_database_service.dart` | 82% (exec) | Narrator DB — **covered as of 2026-08-19** (`narrator_database_service_test.dart`, 10 tests against the real bundled `narrators.json` asset: 63-narrator load, data integrity (1 Prophet / 23 Companions / 62 death years), exact/alias/hamza-normalized lookup, empty/unknown misses, `lookupFromNarratorInfo`, profile getters). |
| `lib/features/hadith/presentation/pages/isnad_graph_page.dart` | 43% (exec) | Isnad DAG — **covered as of 2026-08-19** (`isnad_graph_page_test.dart`, 5 widget tests: loading, parsed-chain chip count, source banner + legend, empty state, node-tap → narrator profile bottom sheet). |
| `lib/core/domain/policies/offline_policy.dart`, `lib/core/domain/entities/surah_names.dart`, `lib/core/domain/entities/tafsir.dart`, `lib/features/quran/domain/entities/quran_entities.dart`, `lib/features/search/domain/entities/search_result.dart` | covered | Pure domain policy/entities — **covered as of 2026-08-19** (`test/domain/*`: offline-first policy mapping + cache, 114-surah names, Equatable value semantics for Tafsir/RevelationCause/Tadabbur/SearchResult). |
| `lib/features/quran/data/datasources/remote_quran_data_source.dart` | covered | Offline-first remote stub — **covered as of 2026-08-19** (`remote_quran_data_source_test.dart`: empty list / placeholder tafsir / null revelation cause / safe no-op sync). |
| `lib/features/search/data/repositories/search_repository_impl.dart`, `lib/core/data/repositories/tafsir_repository_impl.dart` | covered | Thin repositories — **covered as of 2026-08-19** (`repository_impl_test.dart` with fake data sources: row→SearchResult mapping incl. original-text + metadata, 4-book source list, delegate wiring). |
| `lib/core/data/data_sources/local_tafsir_data_source.dart` | covered | Tafsir DB reader — **covered as of 2026-09-03** (`local_tafsir_data_source_test.dart` against the real prebuilt DB: per-book loads, Muyassar fallback, missing-verse null, clearCache). |
| `lib/core/services/adhkar_timer_service.dart`, `offline_data_service.dart`, `silent_ui_controller.dart`, `export_share_service.dart` | 0% | Platform-adjacent services (notifications, plugins, filesystem). Thin wrappers; risks live in the plugins. Phase 3 standard-logic batch. |
| `lib/core/services/widget_service.dart` | covered | Home-widget bridge — **covered as of 2026-09-05** (`widget_service_test.dart`, 5 tests: callback dispatch, qibla persist, adhkar round-trip, Makkah-fallback prayer update, bundled-cache verse update; home_widget + geolocator channels mocked). Also fixed a real bug: the verse widget read `surah['ayahs']` while the bundled cache stores `verses` — the widget never updated offline. |
| `lib/shared/widgets/*`, `lib/core/widgets/category_card.dart` | covered | Skeletons (6), category card (3), share cards + preview dialog (6) — **covered as of 2026-09-03**. |
| `lib/features/quran/presentation/pages/surah_page.dart`, `tafsir_reader_page.dart`, `quran_mushaf_page.dart` | loaded | Text-integrity-critical Quran readers — **now imported as of 2026-08-19** (`quran_pages_test.dart`, 3 smoke tests: each page loads against the real bundled assets and renders without crashing; platform channel mocked, GoogleFonts fetch disabled). `quran_mushaf_page.dart` deepened **2026-09-05** (`quran_mushaf_page_test.dart`, 4 tests: verse render, controls toggle, theme-sheet open + dark-skin mapping, empty state; paging persistence stays best-effort on-device). Full loading/empty/populated states still pending for the other two. |
| `lib/features/onboarding/presentation/pages/onboarding_page.dart`, `lib/features/settings/presentation/pages/settings_page.dart` | loaded | **now imported as of 2026-08-19** (`misc_pages_test.dart`, 2 smoke tests; PackageInfo + platform channels mocked). |
| Remaining zero-covered files | 0% | **5 lib files, ALL declaration-only** (2 export barrels + 3 abstract repository interfaces — see rows above). Zero plugin-bound or logic files remain uncovered. |

## What counts as covered (and why)

- **Interfaces and barrels**: excluded by nature — no executable behavior.
- **`main.dart`**: excluded by disposition (integration test is the right
  tool).
- **Everything else**: a file stays on the list only until its Phase 3/4
  tests land; entries are removed when loaded. Growth of the *number* of
  zero-loaded files fails the file-size and coverage reviews.

## Ratchet rule

The CI floor (`coverage_summary.py` threshold) is raised whenever the actual
number exceeds it by ≥1 point, and is **never lowered**. Current floor: 30
(actual 30.89%).
