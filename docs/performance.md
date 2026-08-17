# Performance baseline — Noor (نور)

Targets and measurements for the store-grade performance bar. CI enforces
the automated ones; the device measurements are filled in from
`docs/qa-checklist.md` runs on real hardware.

## Automated gates (CI-enforced)

| Metric | Current | Target | Enforcement |
|---|---|---|---|
| Hadith search latency (full corpus) | 1–3 ms | < 150 ms single word, < 300 ms phrase/root | `hadith_engine_v2_test.dart` full-corpus benchmark |
| App-wide line coverage | 12.1% | 25% (raised in steps) | `tools/coverage_summary.py` floor (12 today) |
| Analysis | 0 issues | 0 issues | `flutter analyze` in CI |
| Tests | 228 | green always | `flutter test` in CI |
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

## Size ledger (fill in after first CI build)

| Item | Size (raw) | Notes |
|---|---|---|
| Prebuilt hadith DB | ~147 MB raw | Compressed in APK; ships in assets/db |
| Tafsir JSONs | ~50 MB raw | In base APK today; candidate for asset pack if needed |
| Quran text + translations | ~10 MB | quran_uthmani + muyassar + en.sahih |
| Adhkar + fonts + images | < 5 MB | |
| Code (AOT) | — | From CI size report |

## Hifz (P3) and English translation (P4) notes

- The hifz store is a small Hive box (`hifz_box`) — negligible size and
  zero cold-start cost (lazy `HifzNotifier.ready`).
- The English translation (`en_sahih.json`, 1.6 MB) is parsed in an
  isolate on first use and cached in memory; it loads only when the reader
  asks for it.

## Optimization candidates (ordered by payoff)

1. **Tafsir into the prebuilt DB** (`tafsir_verses` table) — removes the
   tafsir JSONs from the APK and makes tafsir lookups indexed.
2. **Split tafsir into a fast-follow asset pack** if the base APK exceeds
   Play's install-time limits (~200 MB compressed).
3. **SQLite `VACUUM`/page-size tuning** on the prebuilt DB at build time.
4. **Startup: lazy-load non-critical services** behind the first frame
   (audit `_initializeServices` order).
