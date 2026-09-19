# Offline-first behaviour

What works with the network off, what can use the network, and how each
failure mode is expected to behave. The privacy angle is in
[privacy.md](privacy.md); this file is about availability.

## Works with no network at all

Everything a user does daily:

- Quran reading: mushaf pages, Uthmani text, translations — bundled assets.
- Tafsir: all four sources — bundled `assets/db/tafsir.db`.
- Hadith: nine collections + forties, search, Isnad tools — bundled
  `assets/db/hadith.db` (read-only after the first-launch copy).
- Adhkar, tasbih, day-state machine, streaks, statistics — local.
- Prayer times and qibla: computed on-device from bundled math and presets.
- Bookmarks, notes (encrypted), progress, qada, hifz/FSRS — local storage.

There is no account and no sign-in, so there is no "offline mode" to enable —
the default state is offline.

## What can use the network

| Feature | Host | Behaviour offline |
|---|---|---|
| Recitation playback (remote reciters) | `cdn.islamic.network` | Fails gracefully; the UI reports the failure and previously downloaded surahs still play |
| Mosque finder fallback | `masjidnear.me` | Returns an empty list — the UI shows "no mosques found" |
| Opt-in usage counters | owner-configured endpoint (default: none) | Counts stay on device and retry later |
| Crash reports (only if built with a DSN) | Sentry | Events queue/are dropped by the SDK; the app is unaffected |

## Failure modes and expected behaviour

| Scenario | Expected |
|---|---|
| First launch, no network | Normal path: the prebuilt hadith database is copied from bundled assets (~1–3 s). No network is touched during startup |
| Network lost mid-session | Nothing breaks: no core path depends on a live connection |
| Network permanently unavailable | Same as above; only remote audio and the mosque finder are reduced |
| Hadith database missing/corrupt at first launch | The gate surfaces the import/error screen instead of an empty library (`HadithDatabase` copy path, `_DatabaseImportScreen`) |
| Search index missing | Rebuilt lazily on first search (`noor_search.db`) |
| Content asset missing | Integrity tests fail in CI before it can ship; at runtime the affected screen shows an error state |

## Verification status

- The emulator integration job boots the real app end to end (DB import,
  onboarding, all five tabs) — `flutter test integration_test`.
- The integration job attempts to disable the emulator's wifi and mobile data
  before the run (`svc wifi disable` / `svc data disable`, best-effort), so the
  boot path is exercised without connectivity on CI.
- Integrity and failure-path tests run on every push (`flutter test`).
- **Not yet automated:** a physical-device airplane-mode pass, and a
  forced-offline run that fails the job when the platform refuses the toggle.
  Both are tracked in [qa-checklist.md](qa-checklist.md) and this file rather
  than being claimed as covered.
