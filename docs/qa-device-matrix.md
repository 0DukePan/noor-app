# QA device matrix (QA-01, Phase 5/6)

No claim below treats browser/desktop behavior as a substitute for the
Android/iOS reader. Every unrun mobile case stays a release blocker.

## Required lanes

| Lane | Purpose | Status |
|---|---|---|
| Android API 29 emulator | min-supported rendering, storage, permissions | Required; not run here |
| Android API 34 emulator | target behavior, notifications, audio focus | Required; CI `integration-test` job runs API 34 offline |
| Supported physical Android device | tap targets, TalkBack, compass, background audio, share sheets | Required; not run here |
| Supported iOS simulator | layout, VoiceOver, background/foreground | Required; not run here |
| Supported physical iOS device | audio interruption, haptics, store build | Required; not run here |
| Windows/Edge (this machine) | analyzer, unit/widget tests, desktop smoke | Available; used for this remediation |

## This machine (honest record)

- `flutter devices`: Windows + Edge only.
- `flutter emulators`: no configured Android emulator.
- All unit/widget/contract evidence in the ledger was produced on Windows.
- Mobile-only outcomes (tap feel, permission dialogs, audio plugins, RTL
  on-device shaping, TalkBack/VoiceOver, gesture competition, background
  playback, share sheets, compass, restoration) are unverified until the
  lanes above produce screenshots/video + logs.

## Per-run record template (attach to each manual run)

OS, device, app build, locale, font scale, network, permission state, feature
flow, result, tester, date, log/video link.

## Feature flows to cover on device (Phase 5 matrix)

Startup/storage (fresh install, upgrade, corrupt Hive, no storage, init
failure, first-frame timing); Qur'an/tafsir/audio offline + exact-ayah
restoration + DB copy/corruption/low storage + bookmarks/history/notes +
copy/share + background audio + bad assets; Hadith DB import/FTS/citations;
prayer/adhan/qibla permission/timezone/DST/compass states;
adhkar/hifz/khatmah reset/persistence/counters; search/routing malformed
links/back-stack/restoration; interaction catalogue critical rows incl.
duplicate-tap and disabled-reason cases; privacy/security opt-in boundaries;
RTL/LTR, themes, font scale, rotation, cutout, keyboard, focus;
Android APK/AAB + iOS archive signing, size, cold start.
