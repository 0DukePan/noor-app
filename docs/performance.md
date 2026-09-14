# Performance baseline — Noor (نور)

Targets and measurements for the store-grade performance bar. CI enforces
the automated ones; the device measurements are filled in from
`docs/qa-checklist.md` runs on real hardware.

## Automated gates (CI-enforced)

| Metric | Current | Target | Enforcement |
|---|---|---|---|
| Hadith search latency (full corpus) | 1–3 ms | < 150 ms single word, < 300 ms phrase/root | `hadith_engine_v2_test.dart` full-corpus benchmark |
| App-wide line coverage | 30.70% | raised in steps as pages land | `tools/coverage_summary.py` floor (30 today) |
| Analysis | 0 issues | 0 issues | `flutter analyze` in CI |
| Tests | 651, all green | green always | `flutter test` in CI |
| APK size | to be reported | < 150 MB compressed | CI "Report APK size" step |
| Android boot | emulator integration suite | green always | CI `integration-test` job |

## First-launch experience

- **Before (JSON import):** one-time 17-book import with a progress screen
  (30–60 s on device).
- **Now (prebuilt DB):** first launch copies `assets/db/hadith.db`
  (~147 MB) into app documents (~1–3 s), then opens instantly.
  `HadithDatabase._tryCopyPrebuilt` logs the copy; the import path remains
  only as a dev fallback.

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

## Size ledger (measured via `tools/check_assets_size.py`)

Total bundled: **221.8 MB** against the 230 MB CI budget.

| Item | Size (raw) | Notes |
|---|---|---|
| Content databases (`assets/db/`) | 210.1 MB | `hadith.db` (content + FTS index) and the consolidated `tafsir.db`; compressed in the APK |
| Quran text + translations | 8.3 MB | `quran_uthmani` + Saheeh International + other translations |
| Fonts | 1.4 MB | Cairo (variable) + Amiri |
| Adhkar + misc | < 0.5 MB | |
| Code (AOT) | — | From the CI size report |

## Hifz (P3) and English translation (P4) notes

- The hifz store is a small Hive box (`hifz_box`) — negligible size and
  zero cold-start cost (lazy `HifzNotifier.ready`).
- The English translation (`en_sahih.json`, 1.6 MB) is parsed in an
  isolate on first use and cached in memory; it loads only when the reader
  asks for it.

## Optimization candidates (ordered by payoff)

1. ~~**Tafsir into the prebuilt DB**~~ — **done**: the 25,401 loose tafsir files
   were consolidated into `assets/db/tafsir.db` (272.2 -> 221.5 MB at the time,
   the same pattern as `hadith.db`).
2. **Asset packs / Play Feature Delivery** to get the base install under
   ~100 MB — consciously deferred post-1.0 (`docs/store-checklist.md`, decision
   D2); the FTS index measured ~24 MB of the bundled DB, so an on-device rebuild
   is not worth it while headroom remains.
3. **SQLite `VACUUM`/page-size tuning** on the prebuilt DB at build time.
4. **Startup: keep deferring non-critical work past the first frame** — the
   service init is already parallelised (`Future.wait`) with the DB warm-up,
   search-index build and offline sync left `unawaited`; anything new added to
   `_initializeServices` should justify blocking the first frame.
