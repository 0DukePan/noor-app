# Performance baseline — Noor (نور)

Targets and measurements for the store-grade performance bar. Everything in
the automated table is re-measured on every push; the device numbers are the
manual half, filled in from `docs/qa-checklist.md` runs on real hardware.

## Automated gates (CI-enforced)

| Metric | Current | Target | Enforcement |
|---|---|---|---|
| Hadith search latency (full corpus) | 1–3 ms | < 150 ms single word, < 300 ms phrase/root | `test/services/hadith_engine_v2_test.dart` full-corpus benchmark |
| Cold start → first frame (emulator) | published per run | < 120 s on the CI emulator | `integration_test/app_test.dart` ceiling + job summary |
| Cold start → interactive (emulator) | published per run | < 180 s on the CI emulator | same |
| App-wide line coverage | see the README Numbers table | raised in steps 30 → 40 → 50 → 60 (`docs/coverage-inventory.md`) | `tools/coverage_summary.py` floor |
| Analysis | 0 issues | 0 issues | `flutter analyze` in CI |
| Tests | see the README Numbers table | green always | `flutter test` in CI |
| APK size | reported per run | < 150 MB compressed | CI "Report APK size" step (reported, not gated) |
| Android boot with wifi/data disabled | emulator integration suite | green always | CI `integration-test` job (best-effort offline, see `docs/offline-first.md`) |
| Dynamic-type layout (home dashboard) | no overflow at 1.3×/2.0× | no overflow | `test/widget/text_scale_test.dart` |

## How the startup numbers are recorded

`integration_test/app_test.dart` prints `STARTUP first-frame: <ms>` and
`STARTUP interactive: <ms>`. The CI `integration-test` job captures the run
log and `tools/perf_summary.py` publishes both numbers — with the emulator
environment line — into the job summary, so every run records what it actually
measured instead of relying on someone remembering to re-measure.

The pass/fail gate is the test's own ceiling assertion, deliberately generous
because an emulator cold boot is far slower than a device.

**Environment for the automated numbers:** Android API 34, `pixel_5` profile,
x86_64, Flutter 3.44.9 (pinned in CI). Device numbers below are manual and are
meaningful only together with the hardware they came from.

## First-launch experience

- **Before (JSON import):** one-time 17-book import with a progress screen
  (30–60 s on device).
- **Now (prebuilt DB):** first launch copies `assets/db/hadith.db`
  (~147 MB) into app documents (~1–3 s), then opens instantly.
  `HadithDatabase._tryCopyPrebuilt` logs the copy; the import path remains
  only as a dev fallback. No network is involved.

## Measuring on device (manual, via QA checklist)

1. **Cold start to interactive:** stop the app from recents → relaunch →
   time from tap to home screen usable. Target < 2 s on mid-range hardware.
2. **First launch after install:** time from install to home. Target < 10 s
   (dominated by the DB copy).
3. **Search latency:** open hadith search, type a word, time to results.
   Target < 200 ms on mid-range hardware.
4. **Background audio:** recitation continues with screen off; lock-screen
   controls respond within 1 s.
5. **App size:** Play Console "App size" per device, and the CI APK report.
6. **Large text:** set the system font scale to 2.0× and walk the five tabs.
   The home dashboard is CI-gated (`text_scale_test.dart`); the other dense
   screens are still a manual check (see `docs/accessibility.md`).

## Size ledger (measured 2026-09-18 via `tools/check_assets_size.py`)

Total bundled: **221.8 MB** against the 230 MB CI budget. The script prints the
same breakdown on every run.

| Item | Size | Notes |
|---|---|---|
| `assets/db/` | 210.1 MB | `hadith.db` (content + FTS index) and the consolidated `tafsir.db`; compressed in the APK |
| `assets/quran/translations/` | 4.6 MB | Bundled translations |
| `assets/quran/` | 3.7 MB | Uthmani text, page map, surah metadata |
| `assets/fonts/` | 1.4 MB | Cairo (variable) + Amiri |
| `assets/adhkar/` | 0.1 MB | Seven collections |
| `lib/` + the rest | ~1.9 MB | Dart source; the AOT size comes from the CI report |

There is no bundled audio: recitation streams or downloads on demand.

## Optimization candidates (ordered by payoff)

1. ~~**Tafsir into the prebuilt DB**~~ — **done**: the 25,401 loose tafsir files
   were consolidated into `assets/db/tafsir.db` (272.2 -> 221.5 MB at the time).
2. **Asset packs / Play Feature Delivery** to get the base install under
   ~100 MB — consciously deferred post-1.0 (`docs/store-checklist.md`, decision
   D2, and `docs/adr/006-bundled-content.md`); the FTS index measured ~24 MB of
   the bundled DB, so an on-device rebuild is not worth it while headroom
   remains. Android-only mechanism; iOS ships the full bundle.
3. **SQLite `VACUUM`/page-size tuning** on the prebuilt DB at build time.
4. **Startup: keep deferring non-critical work past the first frame** — the
   service init is already parallelised (`Future.wait`) with the DB warm-up,
   search-index build and offline sync left `unawaited`; anything new added to
   `_initializeServices` should justify blocking the first frame.
