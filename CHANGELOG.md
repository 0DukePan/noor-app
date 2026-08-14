# Changelog

All notable changes to Noor (نور) are documented in this file.

## [Unreleased]

### Added
- Adhkar library: 106 sourced duas in 20 categories with verbatim
  references, browsable from a new category page (under scholarly review)
- Quran: offline Arabic translation (تفسير الميسر, Tanzil data) shown via
  the existing «إظهار الترجمة» toggle; reciters expanded 6 → 17 on the
  open islamic.network CDN; the ayah currently playing is highlighted in
  the surah page
- Hadith refined grades: bundled scholar-verdict dataset (الألباني starter
  set, under review) with per-hadith lookup, per-book fallback, and the
  scholar's name shown in the hukm tab
- Deferred (data sourcing pending a verified open dataset): tajweed-colored
  mushaf and word-by-word Quran — no open bulk dataset with the required
  markup/glosses was available from the sources probed
- On-device integration test (boots the real app on an Android emulator in CI:
  first-launch DB import, onboarding, all five tabs) — the first automated
  "the app runs on Android" evidence
- Golden (visual regression) tests for the day-state card and onboarding
- `tools/create_keystore.ps1` — one-command release keystore generator
- CI job that produces a properly signed release AAB when signing secrets are
  configured
- `docs/qa-checklist.md` — manual on-device QA checklist for the store run
- CI now runs tests with coverage, uploads the lcov report, and enforces an
  app-wide line-coverage floor via `tools/coverage_summary.py` (2.6% → 7.4%
  of all `lib/` lines with this batch; the floor is raised as coverage grows)

### Changed
- Adopted `very_good_analysis` (strict lints + strict-casts/inference/raw-types);
  `flutter analyze` reports **0 issues** across the whole codebase
- Removed dead cloud stack: Supabase service, cloud settings page, and the
  `supabase_flutter`, `firebase_core`, `firebase_messaging`, `fl_chart`
  dependencies — the app is fully local (SQLite/Hive); README no longer
  advertises features that do not exist

### Fixed
- Quran search missed matches containing the alef-wasla (ٱ) — e.g. «الرحمن»
  never matched «ٱلرحمن»; all three normalizers now map it to ا
- Hadith index: companions/topics now extracted from de-diacritized text
  (the Companions tab spun forever and the Topics tab was empty); search
  cache key now covers every filter (a grade-filtered search no longer
  poisons later plain searches)
- Hadith grades: per-book basis (Sahihain = صحيح, others = من المصدر with
  an honest explanation) instead of a dead empty grade
- Hadith reader is paged — large chapters can be read end-to-end; resume
  returns to the exact chapter + hadith (bookId/chapterId/number)
- Musnad Ahmad filter/search now uses the correct `ahmed` collection id
- Surah page menu (التفسير/مظهر القراءة), settings cache clear, per-prayer
  adhan bell, and adhkar notification location all actually work now
- Real share sheet everywhere (was copy-to-clipboard), Arabic sanad parsing
  in the layered page, working topic/companion navigation, notes unified
  between Scholar Mode and the sharh sheet, same-day quiz results kept
- RTL: reader prev/next arrows, 10 trailing chevrons, 4 back buttons,
  12 directional insets, text alignment
- Dark mode on settings, adhkar, search, quran, hadith and tasbih pages;
  ink-splash surfaces wrapped in Material; mounted guards after async gaps;
  adhkar counter can no longer lose rapid taps; qibla dialog no longer
  closes the page; version shown dynamically
- Hadith database v2 migration: searches are normalized (de-diacritized) and
  the FTS index is rebuilt over the normalized text
- Clearing the search cache could fail with a locked database file
- `QuranDataSource` filled its data map with `Color.toARGB32` — the whole
  Quran never loaded through that path
- Mojibake (U+FFFD) in two home-screen greeting strings; a guard test now
  fails the build if any mojibake is ever reintroduced
- ~200 unchecked `dynamic` accesses typed (JSON/Hive reads now use explicit
  casts); dead stubs removed (`getVersesByJuz`, tafsir API loader, hijri
  provider); all 20 TODO/FIXME comments resolved

## [1.0.0] - 2026-08-09

First public release.

### Added
- Full offline Mushaf (604 pages), surah reader, and khatmah planner
- 9 major hadith collections + Nawawi 40 in a SQLite-backed library with
  full-text search, isnad parsing, scholar mode, and FSRS memorization
- GPS prayer times (19 calculation methods), adhan scheduling, qibla compass
  and AR mode, prayer completion tracking with streaks
- Morning/evening/post-prayer adhkar, digital tasbih, smart suggestions
- 4 bundled tafsir sources (Muyassar, Ibn Kathir, Sa'di, Tabari)
- Unified search across Quran, hadith, and adhkar
- Day-state machine, statistics dashboard, home-screen widgets

### Fixed
- Prayer times now respect the device timezone (were off by the UTC offset)
- Hadith full-text search (FTS5 index was never aligned with the content)
- Asr calculation (was computed with a below-horizon angle)
- Quran audio playback URLs (were invalid for multi-digit ayahs)
- First-launch hadith import now shows progress instead of a blank screen
- Removed ~3,000 lines of dead duplicate architecture; one codebase remains

### Security
- Encrypted tadabbur notes now use a device-derived key (no hardcoded keys)
- Crash reporting is PII-free (Sentry, no screenshots, no tracking)
