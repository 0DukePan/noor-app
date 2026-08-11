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

### Fixed
- Quran search missed matches containing the alef-wasla (ٱ) — e.g. «الرحمن»
  never matched «ٱلرحمن»; all three normalizers now map it to ا
- Hadith database v2 migration: searches are normalized (de-diacritized) and
  the FTS index is rebuilt over the normalized text
- Clearing the search cache could fail with a locked database file

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
