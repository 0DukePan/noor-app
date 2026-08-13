# Changelog

All notable changes to Noor (نور) are documented in this file.

## [Unreleased]

### Added
- On-device integration test (boots the real app on an Android emulator in CI:
  first-launch DB import, onboarding, all five tabs) — the first automated
  "the app runs on Android" evidence
- Golden (visual regression) tests for the day-state card and onboarding
- `tools/create_keystore.ps1` — one-command release keystore generator
- CI job that produces a properly signed release AAB when signing secrets are
  configured
- `docs/qa-checklist.md` — manual on-device QA checklist for the store run
- CI now runs tests with coverage and uploads the lcov report (baseline:
  58.5% lines hit)

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
