# Remediation ledger (Phase 0.1)

Tracked finding ID, priority, reproduction, regression test, status, and
release decision. Evidence in this checkout wins over historical claims.
P0 = do not ship. P1 = fixed in this remediation. P2 = scheduled.
P3 = hardening.

## Content and Mushaf (QUR)

| ID | Pri | Reproduction / evidence | Regression test | Status | Release decision |
|---|---|---|---|---|---|
| QUR-01 | P0 | Page map vs surah source differ in 6,160 entries (orthography + basmala prefixes); undocumented, unreviewed | test/data/mushaf_token_codec_test.dart; generator report | Fixed (single canonical + display convention + deterministic tokens + quantified diff for review) | Ship only after scholarly review rows 1/13 |
| QUR-02 | P0 | Hard-coded basmala in `_SurahStartBanner` duplicated page-map basmala; Fatiha double in study reader | test/data/mushaf_token_codec_test.dart (basmala-once); widget smoke | Fixed (no widget-held Qur'an text) | Same as QUR-01 |
| QUR-03 | P1 | Inner scroll per page, bracket markers, banner cards, generic header | test/widget/quran_mushaf_page_test.dart; test/widget/quran_pages_test.dart; test/widget/mushaf_a11y_test.dart (contrast ≥4.5 all 5 skins incl. new high-contrast, EN chrome, semantics, 48dp) | Fixed (fixed canvas, inline markers, zoom/pan, localized labels; UI decomposed per Phase 2.3 into MushafReaderPage/PageView/Canvas/Header/TextRegion/Footer/ControlsOverlay/AyahActionsSheet under lib/features/quran/presentation/widgets/mushaf/) | Needs device + golden review |
| QUR-04 | P1 | `/quran/mushaf?page=100` set controller to 99 while provider started at 1; unbounded input | test/unit/route_decoder_test.dart | Fixed (clamp + single source before first paint) | Done |
| QUR-05 | P1 | Page-load error showed raw text, no retry | test/widget/quran_mushaf_page_test.dart (retry recovers) | Fixed | Done |
| QUR-06 | P1 | Per-ayah recognizers untested for correct-ayah selection vs control toggle; a11y unproven | code contract (350ms suppression, semantics, 48dp) | Fixed in code; device TalkBack/VoiceOver pending | Ship after device pass |
| QUR-07 | P2 | Theme/controls provider-local, Arabic hard-coded labels | test/unit/mushaf_preferences_test.dart | Fixed (versioned record + ARB + migration tests) | Done; relaunch device check pending |
| QUR-08 | P2 | Bookmark→page scanned all pages per lookup | index built once at page-map load; typed MushafPageModel/MushafTokenModel with ±1 prefetch window + 25-entry cap (test/data/local_quran_data_source_test.dart) | Fixed | Done |
| QUR-09 | P1 | Home/library continue and Khatmah/search dropped the ayah | test/widget/surah_initial_ayah_test.dart; test/unit/route_decoder_test.dart | Fixed (validated QuranLocation everywhere) | Device pass pending |
| QUR-10 | P1 | Khatmah resume opened surah start | same as QUR-09 | Fixed | Same |
| QUR-11 | P1 | Search result opened surah start | same as QUR-09 | Fixed (exact ayah + stable back path) | Same |
| QUR-12 | P1 | “Add bookmark” overwrote last-reading singleton | test/data/quran_bookmarks_test.dart | Fixed (separate idempotent records) | Done |

## Audio (AUD)

| ID | Pri | Reproduction / evidence | Regression test | Status | Release decision |
|---|---|---|---|---|---|
| AUD-01 | P1 | Per-ayah play called `playSurah` (started at ayah 1) | code contract + test/services/audio_boundary_test.dart (typing) | Fixed (typed playVerse passthrough) | Device audio pass pending |
| AUD-02 | P0 | Final-ayah completion incremented ayah without boundary; `surah` mode never looped | test/services/audio_boundary_test.dart (114 surahs × modes) | Fixed (verse-count map; stop/loop policy) | Done pending device |
| AUD-03 | P1 | Failures debug-printed only | PlaybackFailure stream + localized strings | Fixed in code | Device offline/error pass pending |

## Tafsir (TAF)

| ID | Pri | Reproduction / evidence | Regression test | Status | Release decision |
|---|---|---|---|---|---|
| TAF-01 | P0 | Missing/corrupt DB collapsed into “unavailable” via empty schema | test/unit/mushaf_preferences_test.dart (availability resolver); typed TafsirDbInitFailure | Fixed (typed reasons + truthful UI + safe retry) | DB-failure device pass pending |
| TAF-02 | P1 | Competing presentations with divergent behavior | Single availability model + shared preview/full/compare contract (`TafsirViewState`/`TafsirStateView`, test/widget/tafsir_state_view_test.dart); lazy content builder; load-error capture in reader/compare | Unified in contract and components; variants differ only in content | Full reader visual unification review + device pending |
| TAF-03 | P1 | `initialAyah` accepted but ignored | code contract (scroll + highlight); TafsirLocation threaded through router→page with source parsing (test/unit/quran_location_test.dart) | Fixed | Automated scroll test + device pending |
| TAF-04 | P1 | Compare next-ayah unbounded; empty set spun forever | code contract (bound + distinct states) | Fixed | Widget test + device pending |
| TAF-05 | P2 | Inline preload recorded history | code contract (record on expand only) | Fixed | Done |

## App, nav, infra (APP/NAV/INT/QA)

| ID | Pri | Reproduction / evidence | Regression test | Status | Release decision |
|---|---|---|---|---|---|
| APP-01 | P1 | Tafsir test setup ran out of system-temp disk; teardown double-fault | test/test_utils/tafsir_test_db.dart (preflight + NOOR_TEST_TMP + nullable teardown) | Already fixed in checkout; retained | Done |
| APP-02 | P1 | `dart run tool/release_preflight.dart` fails: no `android/key.properties`, 13 pending scholarly rows | preflight itself | Open — honest blocker | DO NOT SHIP |
| APP-03 | P1 | Manifest `unrecorded` licence/retrieval for quran/tafsir/hadith/grades/adhkar | tool/verify_content_checksums.dart passes; mushaf-tokens provenance added | Partially fixed (hashes + transformation recorded; upstream licence/review still pending) | DO NOT SHIP before review |
| APP-04 | P2 | Double `Hive.initFlutter` (main + HiveService) | code contract | Fixed (single owner) | Done |
| APP-05 | P3 | 102+ packages beyond constraints | — | Triage scheduled, no blind upgrade | Not a release blocker |
| NAV-01 | P1 | `int.parse` on surah/tadabbur params; no normalization | test/unit/route_decoder_test.dart | Fixed | Done |
| INT-01 | P1 | 545-callback inventory; integration covered 5 tabs only | docs/interaction-catalogue.md (525 rows + 15 critical contracts); contract tests above | Catalogue built; coverage in progress | Ship after catalogue coverage + device |
| QA-01 | P1 | No Android/iOS emulator on this machine | docs/qa-device-matrix.md | Open lane requirement | DO NOT call mobile complete without device evidence |

## Execution environment (separate from product results)
- Pinned toolchain: Flutter 3.44.9 / Dart 3.12.2 (matches CI).
- This workstation: Windows + Edge targets only; no Android emulator or iOS
  simulator configured. Browser/desktop behavior is never treated as mobile
  evidence. Missing mobile evidence is a release-blocking gap, not a pass.
- Pre-existing untracked workspace files (`.zed/`,
  `final-plan-verified-path-to-10 (1).md`) were not modified.

## Phase 5/7 sweep finds (full-suite evidence, 2026-10-06)

Final verification in this session: full suite **732 tests pass**
(`flutter test`, exit 0); `dart analyze` reports zero errors and zero
warnings (infos only, mostly pre-existing); `dart run
tool/verify_content_checksums.dart` prints OK; ARB parity 693/693 keys;
`tool/generate_mushaf_tokens.dart --check` passes (byte-identical).

Round-two additions (2026-10-07): high-contrast skin + WCAG contrast tests;
Phase 2.3 widget decomposition; typed token models + prefetch cache;
route-scoped Mushaf ProviderScope; TafsirLocation end-to-end + source
fallback; copy/share BOM/joiner contract; EN chrome + semantics + 48dp
tests; Amiri/Cairo versions from TTF tables (`assets/fonts/README.md`);
Hadith FTS hit-to-detail identity test; prayer polar/DST/date-line/leap
tests; post-Isha rollover fix (SWP-01); post-Isha-proof suite; integration
quran-reader flows (CI emulator lane); privacy/permissions audit
(`docs/privacy-permissions-audit.md`); assets+lib 225/230 MB budget check;
FSRS + prayer-engine pre-existing reference/property coverage re-verified
passing. Full TAF-02 presentation unification remains future work (shared
availability/location models in place).

Round-two final verification (2026-10-07): full suite **748 tests pass**,
`dart analyze` zero errors/warnings, checksums OK, ARB 693/693,
assets+lib 225/230 MB.

Round four/e2e (2026-10-08): `npx e2e init` + web target on the Flutter
release build, example + Mushaf reader flow + cold deep-link flow all green
(`npx e2e run`: 2 files, 3 tests, ~11s, no model). e2e-driven product fixes:
SWP-02 (path URLs + imperative-URL reflection), pending deep link across
onboarding with `stashInitialDeepLink` (+ unit tests), SWP-03 (home garnish
hardening). Mobile e2e blocked on upstream agent-device Windows bugs
(reported, refs in e2e/notes.md); emulator image + debug APK ready.

Round three (2026-10-07): TAF-02 shared view contract
(`TafsirViewState` + `TafsirStateView` in core, adopted by Mushaf preview,
inline excerpt, full-reader single, and comparison views; lazy content
builder; surah/compare load error capture instead of spinner-forever);
TAF-03 automated scroll+highlight test; keyboard-focus order + chrome
focusability + small/landscape overflow tests; missing back-button tooltip
filled via new `commonBack` ARB key; Khatmah legacy-box migration +
corrupt-row tests; Hadith FTS identity; prayer polar/DST/date-line/leap
edges; post-Isha rollover (SWP-01); privacy/permissions audit; debug APK
built locally (`flutter build apk --debug` → 284.9 MB, debug-signed
verification-only artifact; release signing still requires CI secrets).

| ID | Pri | Reproduction / evidence | Regression test | Status | Release decision |
|---|---|---|---|---|---|
| SWP-01 | P1 | `PrayerTimes.getNextPrayer()` returned null after Isha (no next-day rollover); `AdhkarTimerService.getNextPrayer()` propagated the null so the post-Isha countdown had no next prayer. Found by `test/services/adhkar_timer_service_test.dart` failing after local Isha; pre-existing, time-dependent, in code untouched by the Mushaf work | same test file (now passes at all hours) | Fixed (type-level Fajr rollover + day-added countdown, never negative) | Done; full prayer reference-vector verification (methods, DST, polar) remains Phase 7 work with device evidence |
| SWP-02 | P2 | Web URL never reflected pushes (framework default `GoRouter.optionURLReflectsImperativeAPIs = false`) and hash strategy ignored path-style deep links. Found by e2e: reader rendered while the URL stayed put; direct `/quran/mushaf?page=2` loads missed the route | `tests/quran-flow.e2e.ts` (indicator + URL assertions) | Fixed (web-only `usePathUrlStrategy()` + imperative-URL reflection in `main()`; mobile untouched) | Done; e2e evidence on rebuild |
| SWP-03 | P2 | Home dashboard blanked (`homeLoadError`) whenever the daily-hadith fetch threw outside `Exception` (e.g. SQLite has no web backend; native plugin Errors). Found by e2e: home body errored while nav labels masked it | `tests/quran-flow.e2e.ts` (navigates through home) | Fixed (`_getDailyHadith` catches `Object` → null; UI already hides a null hadith) | Done; mobile behavior unchanged (garnish-only) |
