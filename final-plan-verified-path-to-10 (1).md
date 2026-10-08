# Final Plan — Verified-Data Edition: Path to a Defensible 10/10

This supersedes the earlier draft. Same structure, now built on your real numbers instead of estimates, plus two new findings that change the priority order.

**Last updated:** 2026-09-07 — reconciled with the CHANGELOG's WP2/WP3/WP4 record and a fresh full-suite verification (see Status Snapshot below; phase sections below the snapshot are marked inline as they close).

---

## Status Snapshot (live)

| Phase | Status |
|---|---|
| −1. Integrity fixes | ✅ Done |
| 0. Baseline tooling | ✅ Done |
| 1. Architecture stabilization | ✅ Done (prayer/surah/tafsir splits + size ratchet) |
| 2. Test pyramid/tooling | 🔄 Tooling + exclusion cap + coverage ratchet done; growth ongoing (630 tests, 31.0%). Seeded-bug review ✅ passed 2026-09-07 |
| 3. Page/feature rollout | 🔄 Items 1–3 done (item 3 = hadith FTS5 search + detail, closed 2026-09-07); remaining items 4–6 + the sweep continue |
| 4. Domain correctness | 🔄 EoT drift bug found + regression-guarded; seeded-bug review passed; CHANGELOG bug-mine (timezone, Asr, RTL — rowid now closed) still open |
| 5. Size reduction | 🟡 Substantial progress — tafsir 25,401 loose files consolidated to SQLite (272.2 → 221.5 MB); FTS-diet decision recorded (D2: keep bundled); feature delivery/asset packs still deferred (post-10) |
| 6. Docs cleanup | 🔄 README/store/claim-guard done (Phase −1); `API_SOURCES.md` + CI grep-check + scholarly-review hashes done in WP4; store listing polish pending |
| 7. Real l10n | ✅ Largely done — full ARB ar/en extraction across all feature modules (659/659 keys, CI parity-gated); the Phase 7 checklist's remaining item is the polish pass + verification |
| 8. Release readiness | 🔄 Coverage/Sentry/CI release gates in; store data-safety + keystore + signing job exist; staged rollout + a11y/error-boundary pass pending |
| 9. Accessibility | ⬜ Not started (Semantics/large-text/TalkBack pass still open) |
| 10. Privacy-preserving analytics | ✅ Done (2026-09-05 WP4) — opt-in aggregate counters, settings toggle, privacy-sheet copy, no PII |
| 11. Cloud sync & accounts | ⬜ Not started — resolved to Firebase, no Supabase |
| 12. Monetization | ⬜ Not started — business decision pending |
| 13. UI "wow factor" | ⬜ Not started |
| 14. Community & gamification | ⬜ Not started — sequence last |
| 15. AI-powered features | ⬜ Not started — retrieval-only constraint on tafsir assistant |

**Immediate next actions, in order:**
1. ~~Tighten the CI coverage ratchet from 13 → 15~~ — **done and superseded**: floor is now **30** against **31.04%** actual. Next tighten: 30 → 31 once a little more coverage lands.
2. ~~Run the seeded-bug review on `prayer_time_engine.dart`~~ — **done 2026-09-07, PASS**: reintroduced the historical EoT bug (missing ×180/π); exactly the three expected tests failed (both `equationOfTime` units + the three-city golden solar-noon test, Mecca 12:21 vs 12:29); mutation reverted, file byte-identical.
3. ~~Phase 3 item #3 — Hadith FTS5 search + detail~~ — **done 2026-09-07**: rowid-alignment regression suite (4 tests: FTS/content set identity, phantom-row scan, INSERT-OR-REPLACE-without-rebuild staleness + rebuild recovery, hit→detail API closure) + search→reader tap-through widget test.

**Next open engineering items:**
1. Phase 4 CHANGELOG bug-mine remainder: regression tests for timezone handling, the Asr-angle bug, and the RTL chevrons/insets/back-buttons fixes.
2. Phase 3 items #4–#6 page-coverage sweep (FSRS, tafsir/mushaf pages, reciter/audio/khatmah/settings/onboarding), then the Phase 2 push to the next coverage ratchet (31).
3. Phase 8 release readiness (global error-boundary pass, a11y, staged rollout) gates the ship.

**Verified progress vs. plan baseline (fresh 2026-09-07 run):**

| Metric | Plan baseline | Now |
|---|---|---|
| Tests | 245 / 39 files | **630 / ~110 files** — full suite green |
| Coverage of lib/ | 12.1% | **31.04%** (CI floor: 30 — next tighten at 31) |
| ARB parity (ar/en) | — (no l10n existed) | **659/659 keys** (CI-gated) |
| Exclusions | — | 1.2% of LOC (661 lines), cap 10% |
| `flutter analyze` | 0 issues | 0 issues |
| Dead dependencies | 1 known (`camera`) | 0 — `camera` + 5 more removed |
| Bundled assets | 270.7 MB | **221.5 MB** (tafsir DB consolidation; CI budget 230 MB) |
| God-files | 3 (41-46 KB) | 0 — all split + size ratchet in CI |

Test-count context: 630 of a rough ~1,800–2,200 target is ~28-35% — meaningful progress but not a plateau; the WP2–WP4 batches added the most coverage to date, and the 2026-09-07 batch added the FTS rowid suite + search-detail closure test.

---

## ⚠️ Verify Before Trusting the Latest Review

A new external review (7.5/10, broader product scope) surfaced real findings, but also two claims that conflict with facts already verified in this plan. Resolve these before anything below is treated as settled:

| Claim in new review | Conflicts with | Resolve by |
|---|---|---|
| Coverage is 7.4% | Tracked at 31.01% as of the 2026-09-07 fresh run | See diagnostic below — most likely cause is generated code (`*.g.dart`/`*.freezed.dart`, and now `lib/l10n/generated/`) in one denominator and not the other. The l10n generated files are already excluded from the coverage metric and the god-file check. |

**Diagnostic commands to run:**
```bash
flutter test --coverage
lcov --summary coverage/lcov.info
find . -name '*.g.dart' -o -name '*.freezed.dart' | xargs wc -l | tail -1
grep -c 'SF:' coverage/lcov.info
```
If the generated-code line count is large relative to total LOC, that's almost certainly the source of the gap. Fix: filter generated files out of the lcov report consistently everywhere coverage is reported (CI, local, this plan) —
```bash
lcov --remove coverage/lcov.info '*.g.dart' '*.freezed.dart' -o coverage/lcov_filtered.info
```
— and use the filtered number as the single source of truth from here on.
| "You already have the `supabase/` dir" for cloud sync | CHANGELOG says Supabase stack was removed; Phase −1's claim audit verified this | ✅ Resolved — no Supabase, confirmed. That review's claim was wrong. Phase 11 below now assumes a fresh build. |
| 3 new god-files: `quran_mushaf_page.dart` (42KB), `hadith_search_engine.dart` (35KB), `advanced_hadith_browser_page.dart` (38KB) | Not in the original top-3 list (already split in Phase 1) | Cross-check against `coverage-inventory.md` — if tracked and deprioritized, fine; if missing entirely, Phase 0's inventory has a gap worth patching |

---

## 0. What "10/10 / best in market" honestly means here

A code audit can't promise "best in market" — that also depends on reviews, competitors, and content upkeep after launch. What this plan *can* deliver, and what I'm calling "10" below, is the technical ceiling:

- Zero features advertised that don't exist.
- Zero unjustified test-coverage gaps: 100% of non-excluded lines covered, with `coverage_exclusions.md` capped and audited so it can't be gamed.
- Domain-critical logic (prayer times, isnad, mushaf/hadith text) provably correct against reference sources, not just "exercised."
- Install size that doesn't fight the store.
- Real bilingual support, not a scaffold.

Hit all five and you have the strongest possible foundation to become best-in-market. That's the honest target.

**A second, broader tier now exists too.** The latest review scores on product/growth dimensions the original five didn't cover: accessibility, analytics, monetization, community, and UI polish. These are real and worth pursuing (see Phases 9-15 below), but they're layered on top of the technical ceiling, not a substitute for it — an app with gamification and no coverage integrity is worse off than one that's quietly, provably correct. Sequence stays: technical ceiling first, growth layer second.

---

## 1. Verified Baseline

| Metric | Value |
|---|---|
| Dart code | 42,258 LOC / 140 files |
| Tests | 245 cases / 39 files |
| Coverage floor | 12.1% of lib/ |
| Bundled assets | 270.7 MB raw, 25,427 files |
| — hadith.db | 147.3 MB, single SQLite file |
| — tafsir | 113.5 MB across **25,401 individual files** |
| Largest source files | `full_tafsir_reader.dart` 46 KB, `surah_page.dart` 42 KB, `prayer_time_engine.dart` 41 KB |
| Dead dependency | `camera` in pubspec, imported nowhere in `lib/` |
| Advertised-but-missing feature | "AR Qibla" — actual implementation is a compass page, no AR |
| Marketing overstatement | "AI-driven Smart Notification Engine" — actual implementation is time-of-day rule scheduling |
| l10n | No `.arb` files, no `l10n.yaml` — not scaffolded, doesn't exist. Arabic is hardcoded. |

---

## Phase −1 — Integrity Fixes ✅ DONE

- [x] **AR Qibla → Path A (strip).** Removed from README, store listing, QA checklist, store checklist, and iOS `NSCameraUsageDescription`.
- [x] **Dead dependencies removed** — `camera` plus 5 more (`audio_service`, `intl`, `url_launcher`, `sensors_plus`, `flutter_svg`); `pub get` dropped 19 packages.
- [x] **"AI-driven Smart Notification Engine" → "context-aware"** in README.
- [x] **Full claim audit** — complete doc-drift table in the inventory (Supabase, masjid-finder, failover chains all checked against code).
- [x] **Regression guard added** — `mojibake_guard_test.dart` now fails CI if any of the stripped terms (ar qibla, ai-driven, and the 5 removed package names) reappear in README. This is a stronger close than the original plan asked for: the claim audit is now enforced, not just a one-time pass.
- [ ] **Follow-up from the new review:** `dartz` flagged as "likely underused" and `encrypt` as "unclear usage." `encrypt` is probably legitimate — it likely backs the device-derived encryption keys already established in the earlier audit — so document that usage with a comment rather than remove it. `dartz` is worth an actual grep for real usage; if it's just sitting in `pubspec.yaml`, it's dead weight the same way `camera` was.

---

## Phase 0 — Baseline Tooling ✅ DONE

- [x] `coverage-inventory.md` — 146-file inventory (LOC × coverage × risk tag).
- [x] Doc-drift table (see Phase −1).
- [x] v1 scope frozen, approved as-is.

---

## Phase 1 — Architecture Stabilization ✅ DONE

- [x] `prayer_time_engine.dart` split: 1,204 → ~300 lines + new `prayer_solar_calculator.dart`.
- [x] `surah_page.dart` split: 1,143 → 533 lines.
- [x] `full_tafsir_reader.dart` → standalone `tafsir_reader_page.dart`.
- [x] CI file-size ratchet (`tools/file_size_check.py`) — prevents regrowth going forward.
- [ ] **Phase 1b (pending verification):** the new review names 3 more large files not in the original list — `quran_mushaf_page.dart` (42KB), `hadith_search_engine.dart` (35KB), `advanced_hadith_browser_page.dart` (38KB). Confirm status against `coverage-inventory.md` first (see verification callout above); if real, split them the same way, same order logic (data-integrity-relevant ones first).

---

## Phase 2 — Test Pyramid, With Real Targets

Current state: 245 tests / 39 files → 12.1% of 42,258 lines (~5,100 lines exercised), roughly 1 test per 21 lines at current density.

**Rough sizing** (planning estimate, not a commitment — actual count depends heavily on how Phase 1's refactor changes testability per line):

| Target coverage | Approx. lines exercised | Approx. additional tests needed (at similar density) | Cumulative test count |
|---|---|---|---|
| 12.1% (current) | ~5,100 | — | 245 |
| 30% (safety-critical done) | ~12,700 | ~360 | ~600 |
| 55% (+ data-integrity done) | ~23,200 | ~500 | ~1,100 |
| 75% (+ main pages done) | ~31,700 | ~400 | ~1,500 |
| **100% of non-excluded lines** (final target) | ~38,000-39,000 (everything not in `coverage_exclusions.md`) | ~350-400 | ~1,850-1,900 |

**This is now the real target, not "90%+."** The honest version of 100% isn't "every line including generated code and unavoidable platform boilerplate" — that number is meaningless. It's **100% of everything that isn't explicitly listed in `coverage_exclusions.md`**, where that file itself is kept small and audited so it can't become a place to quietly dump untested logic. Concretely:

- [ ] **Cap the exclusion list.** Target ≤10% of total LOC in `coverage_exclusions.md`. If it's creeping past that, the answer is almost never "add more exclusions" — it's "this code needs restructuring to be testable" (usually a Phase 1-style split).
- [ ] **Every exclusion entry needs a one-line technical reason**, not "hard to test" — e.g. "platform channel callback, no Dart-side branching logic" is valid; "complex" is not.
- [ ] **CI check**: fail the build if `coverage_exclusions.md` grows without a corresponding PR description justifying the addition.
- [ ] Once this is in place, 100% coverage of the non-excluded set is the actual CI gate, replacing the 90%+ placeholder.

So: expect to roughly **7-8x the test suite**, from ~245 to somewhere around 1,850-2,000 cases, to reach a genuine, CI-enforced 100% of non-excluded code. That's the real cost of "full test" at this codebase size — worth stating plainly rather than promising it's a quick pass.

Pyramid shape:

| Layer | Share | Notes |
|---|---|---|
| Unit | ~65-70% | Engines, parsers, repositories, FSRS algorithm, isnad DAG logic |
| Widget | ~20% | Every page, all states, mocked controllers |
| Golden | ~5-8% | Every page × light/dark × Arabic-RTL/English-LTR × 3 text scales |
| Integration/E2E | remainder | Expand beyond the single emulator test into named user-journey scenarios |

Tooling status:

- [x] `coverage-exclusions.md` in place, no blanket ignores.
- [x] CI coverage ratchet live — **now at 30 against 31.0% actual** (raised repeatedly through the WP2–WP4 batches; the old "13 → tighten to 15" note is superseded). Next tighten to 31 once a little more coverage lands.
- [x] `very_good_analysis` at 0 — holding.
- [x] **Manual seeded-bug review — DONE 2026-09-07 (PASS).** Reintroduced the historical EoT bug in `SolarCalculator.equationOfTime` (dropped the ×180/π factor) and ran the two prayer suites: exactly the three expected tests failed (both `equationOfTime` unit tests — actual ≈±0.25/0.29 min vs expected ±14.2/16.4 — and the three-city golden solar-noon test, Mecca 12:21 vs 12:29). All loose-band/ordering tests stayed green as predicted, proving the coverage on this file is trustworthy. Mutation reverted; file byte-identical to before (verified via git diff).

---

## Phase 3 — Page/Feature Rollout, Attack Order 🔄 IN PROGRESS

| # | Item | Status |
|---|---|---|
| 1 | `prayer_time_engine.dart` + Qibla | ✅ Engine (+32) + page (+11) + compass onError fix. Found & fixed real EoT drift bug (~16 min) with golden regression tests. |
| 2 | `isnad_graph_page.dart` + narrator data | ✅ Graph (+5) + narrator DB (+10). |
| 3 | Hadith search (FTS5) + hadith detail | ✅ Closed 2026-09-07 — rowid-alignment regression suite (4 tests in `hadith_search_fts_test.dart`: FTS/content set identity per token, phantom-row scan of raw FTS rowids, INSERT-OR-REPLACE-without-rebuild staleness + rebuild recovery, hit→id-based-detail closure) + a search→reader tap-through widget test. |
| 4 | `FSRSAlgorithm` | ⬜ |
| 5 | `full_tafsir_reader.dart` / `surah_page.dart` / mushaf | ⬜ (already split structurally in Phase 1; test coverage still pending) |
| 6 | Reciter/audio/khatmah/settings/onboarding | ⬜ |
| extra | Standard-logic batch (not in original order) | ✅ +29 tests, covering 9 of the previously never-loaded files. Also caught and fixed a stale never-loaded-file list (was listing a deleted file, `full_tafsir_reader.dart`, among others) — good instinct to distrust and re-verify your own tracking docs. |

Use this checklist per item:

```
- [ ] Unit tests: business logic, happy path + edge cases + error path
- [ ] Widget tests: loading/empty/error/populated, RTL(Arabic)/LTR(English)
- [ ] Golden tests: light/dark × RTL/LTR × 3 text-scale factors
- [ ] Integration test: one real user journey
- [ ] Accessibility: screen-reader labels, tap targets ≥48dp, contrast
- [ ] Domain review if data-integrity/safety-critical (Phase 4)
- [ ] Zero unjustified excluded lines
```

---

## Phase 4 — Domain Correctness Program 🔄 EFFECTIVELY STARTED

- [x] *(partial)* EoT drift bug found in `prayer_time_engine.dart` now has golden regression tests — this is a Phase 4-style fix delivered ahead of schedule via Phase 3 item #1. Worth formally listing it here so the tracker reflects reality.
- [x] **FTS5 rowid mismatch regression** — closed 2026-09-07 with Phase 3 item #3 (set-identity + phantom-row + rebuild-contract + detail-closure tests).
- [ ] **Mine the CHANGELOG for the remaining documented bugs and add regression tests**: timezone handling, Asr-angle bug, RTL chevrons/insets/back-buttons. These are proof of real historical failure modes — closing the loop between "honest changelog" and "test suite" is high-value and cheap, since the bugs are already found and described.
- [ ] Prayer times: golden-value tests against Umm al-Qura and other standard methods, across polar latitudes, date-line, DST, leap years.
- [ ] Hadith DB: version/checksum it, automated diff on regeneration, make `API_SOURCES.md` code-accurate.
- [ ] Narrators/isnad: CI guard test failing the build if any Ilm al-Rijal field lacks a citation — enforces the existing good policy instead of relying on habit.
- [ ] Mushaf text: extend the mojibake guard into a full checksum diff against canonical source.
- [ ] FSRS algorithm: verify scheduling output against reference FSRS implementation/spec, not just "it returns a date."
- [ ] Scholarly sign-off on anything doctrinal — separate from engineering correctness, still a release blocker if not already done.

---

## Phase 5 — Size Reduction, With Real Numbers 🟡 SUBSTANTIAL PROGRESS

Total: 270.7 MB (147.3 MB hadith.db + 113.5 MB tafsir + ~10 MB mushaf/misc).

- [x] **Consolidate tafsir's 25,401 loose files into a single SQLite DB** — done (same pattern as `hadith.db`; `tool/build_tafsir_db.dart` + `assets/db/`). The app tree went **272.2 → 221.5 MB**.
- [x] CI size-budget check — live via `tools/check_assets_size.py` at a **230 MB** budget (passes today at 221.5; ratchet down as delivery changes).
- [x] **WP3 decision D2 recorded** (`docs/store-checklist.md`): keep DBs bundled for v1; the measured FTS5 index (~24 MB of the 154 MB hadith DB) is not worth on-device rebuild while headroom remains. The remaining half of this phase — Play Feature Delivery / asset packs to get base install under ~100 MB — is consciously **deferred to post-10**, not forgotten.
- [ ] Confirm App Bundle density/ABI splits are enabled (still open).
- [ ] Target: base install well under 100 MB, ideally 50-80 MB, with the rest on-demand (post-10, per D2).

---

## Phase 6 — Docs Cleanup 🟡 MOSTLY DONE

- [x] Rewrite README and `API_SOURCES.md` to match current code exactly — done (README/store in Phase −1; `API_SOURCES.md` reconciled to the live API list in WP4).
- [x] CI grep-check: fail if any of the removed terms reappear in docs without a matching code reference — implemented as the README claim-guard test + `mojibake_guard_test.dart` (ar qibla, ai-driven, removed package names).
- [x] Content-freeze hashes documented in `docs/scholarly-review.md` (WP4): narrator/adhkar/quran sidecars, tafsir DB sidecars, map of every scholarly row to its hash.
- [ ] Remaining: store-listing polish + one final README touch-up if the store copy changes.

---

## Phase 7 — Real l10n 🟡 LARGELY DONE (2026-09-07)

Originally "built from scratch — it doesn't currently exist". That changed across the WP2 batches (2026-09-04→09-06): full ARB extraction, then WP4's analytics copy. Current state:

- [x] Set up `flutter_localizations` + `intl` properly: `l10n.yaml`, `.arb` files for `ar` and `en` — done; generated `lib/l10n/generated/` is excluded from the coverage metric and god-file check.
- [x] Extract every hardcoded Arabic string into ARB keys — done across all feature modules (WP2 batches 1–5; hadith/hifz/quran/prayer/home chrome; analytics/privacy copy in WP4).
- [x] Full English translation, not a scaffold — done (English is the non-Arabic fallback; en/ar parity CI-gated).
- [x] CI check: fail if a key exists in one locale's ARB and not the other — live via `tools/check_arb_parity.py` (**659/659**).
- [x] RTL correctness — the app's proven RTL fixes (chevron/inset/back-button) carried into this phase.
- [ ] **Remaining polish (2026-09-07):** the bottom-nav shell was still hardcoding Arabic labels (`main_shell.dart`); fixed to resolve `navHome`/`navQuran`/`navHadith`/`navAdhkar`/`navTools` through `AppLocalizations`, with a new `main_app_test.dart` English-locale assertion guarding it. Sweep for any other hardcoded UI chrome (the earlier audit's "kept as data" strings are intentional — surah names, search prefixes, digits, compass letters, khatmah names).

---

## Phase 8 — Release Readiness

- [ ] Store listing content re-verified against Phase −1 fixes specifically — this is a genuine app-store policy risk (misrepresented features can trigger rejection or removal), not just a nice-to-have.
- [ ] Privacy policy audit (should be low-effort given the PII-free Sentry / device-derived encryption design already in place).
- [ ] Accessibility pass: TalkBack/VoiceOver on all primary flows.
- [ ] Performance profiling: cold start, scroll jank, memory under the new on-demand asset model. **Specific item from the new review:** 37 services initialized sequentially in `main()` — parallelize independent inits with `Future.wait`, defer non-critical ones to after first frame, and move eager `main()` calls to lazy Riverpod providers where possible.
- [ ] **Global error handling** — no error boundary or global handler currently exists. Add `FlutterError.onError` + `PlatformDispatcher.instance.onError`, wire into the existing PII-free Sentry setup so uncaught errors are actually captured instead of silently crashing.
- [ ] Staged rollout: 5% → 20% → 100%.

---

## Phase 9 — Accessibility (a11y)

Currently no `Semantics` widgets, no large-text testing, no screen reader support — this excludes visually impaired users, arguably a core audience for a Quran audio app, and elderly users.

- [ ] Add `Semantics` labels to all interactive elements across the 14 feature modules.
- [ ] Support dynamic type scaling — pairs directly with the golden-test text-scale matrix already planned in Phase 2.
- [ ] TalkBack (Android) + VoiceOver (iOS) pass on every primary flow — same pass as Phase 8's item, formalized as its own workstream given the scope (0 Semantics widgets means this isn't a quick pass).
- [ ] High-contrast mode check alongside existing light/dark/sepia theming.

---

## Phase 10 — Privacy-Preserving Analytics ✅ DONE (2026-09-05, WP4)

Resolved in favor of the privacy-first option: **no third-party SDK**. The app ships its own anonymous, aggregate-only counters, off by default, with a first-party endpoint the owner configures.

- [x] **Decision:** implement as a built-in opt-in service (no PostHog/Aptabase SDK) — keeps the "no analytics SDKs" privacy strength while giving the owner usage signals.
- [x] Instrument feature-usage counters only (allowlisted: `app_open`, `prayer_viewed`, `surah_opened`, `tafsir_opened`, `hadith_opened`, `adhkar_completed`, `search_used`, `qibla_viewed`) — no identity, no timestamps, no content; counts leave the device only if a first-party endpoint is configured, and clear only on 2xx.
- [x] Settings opt-in toggle (off by default, persisted) + honest privacy-sheet copy ("off by default"); verified by widget tests.

---

## Phase 11 — Cloud Sync & Accounts

**Resolved: no Supabase.** Building fresh. Defaulting to **Firebase Auth + Firestore** for bookmark/progress sync unless you'd rather go with something else (Appwrite, a custom backend, etc.) — flag it if so, otherwise this is the assumption going forward.

- [ ] Scope Firebase Auth (email + Apple/Google sign-in) + Firestore for cross-device bookmark/progress sync.
- [ ] Keep it opt-in and clearly separate from the offline-first core — the app should work fully without an account; sync is additive, not required.
- [ ] This is a prerequisite for Phase 12 (premium tier needs accounts) and Phase 14 (community features need accounts) — sequence it before both if either is pursued.

---

## Phase 12 — Monetization (business decision — not mine to make)

No revenue path currently exists. Three real options, each with different engineering cost:

| Option | Engineering cost | Notes |
|---|---|---|
| Premium tier (ad-free, extra reciters, cloud backup) | High — needs Phase 11 (accounts) + IAP/subscription infra | Standard model, works for utility apps |
| Donation/Sadaqah flow | Low — one-time IAP, no accounts needed | Fits the brand better than a paywall; lower revenue ceiling |
| Sponsorship (tasteful, relevant only) | Low-medium | Risk of feeling off-brand if poorly curated |

No ads — consistent with the "Khushu" brand point the review itself makes. Pick one (or donation-first, premium-later) before scoping engineering work here; this is a product decision, not a technical one.

---

## Phase 13 — UI "Wow Factor" (visual design upgrade)

The design system foundation (HSL tokens, light/dark/sepia, the glassmorphic bottom nav) is genuinely strong — this phase extends it, not replaces it.

- [ ] Custom illustrations for onboarding and empty states (replace emoji/Material-icon placeholders).
- [ ] Geometric Islamic pattern work for headers — real design asset creation, budget accordingly.
- [ ] Glassmorphism extended to prayer-time cards (blur/transparency, not just the shadow work already present).
- [ ] Evaluate Lottie for onboarding only — keep it restrained, this is polish, not a rebuild.

---

## Phase 14 — Community & Gamification (major scope — sequence last)

Reading challenges, leaderboards, family groups, badges/achievements. This is a genuine feature build, not polish — treat it with the same discipline as everything else: nothing ships or gets advertised until it's real and tested, same rule that made Phase −1 necessary in the first place.

- [ ] Depends on Phase 11 (accounts).
- [ ] Start with the lowest-risk piece: opt-in, anonymous aggregate stats ("Muslims in your city read X pages today") — no social graph required.
- [ ] Family groups and leaderboards only after accounts + sync are solid — don't build social features on unproven sync infra.

---

## Phase 15 — AI-Powered Features (high scrutiny — retrieval-only constraint)

**Read this phase differently from the others.** Voice search is a normal feature request. Tajweed detection and an "AI Tafsir Assistant" are not — they carry real hallucination and misattribution risk for a religious app, in exactly the lane this project has built its credibility by avoiding (the honest CHANGELOG, the unfabricated narrator DB).

- [ ] Voice search for Quran verses — lowest risk, standard speech-to-text + existing search index, ship this first if any of this phase is pursued.
- [ ] Tajweed error detection — real technical difficulty (audio analysis against tajweed rules), evaluate feasibility honestly before promising it anywhere.
- [ ] **AI Tafsir Assistant: retrieval-only, or don't build it.** If pursued, it must only surface and cite the 4 bundled tafsir sources verbatim — never generate novel interpretation or paraphrase scholarly opinion. This is non-negotiable given the app's own stated principles, not a style preference.
- [ ] Nothing in this phase gets mentioned in README/store copy until it's built, tested, and verified working — this is exactly the AR Qibla lesson, applied preemptively instead of after the fact.

---

## Appendix A: Updated Scoring Targets

| Category | Baseline | Now (rough) | Phase | Realistic post-plan |
|---|---|---|---|---|
| Code quality & architecture | 8 | ~8.5 (god-files split, ratchet in place) | Phase 1 ✅ | 9-10 |
| Feature depth & ambition | 7.5 | ~9 (claims now match code) | Phase −1 ✅ | 9 — same features, now all real |
| Reliability/ship-readiness | 5 | ~5.5 (one real safety-critical bug found & fixed; coverage still early) | Phases 2-4 🔄 | 9, if domain-correctness (Phase 4) isn't skipped in favor of raw %s |
| Distribution viability | 4 | 4 (untouched) | Phase 5 ⬜ | 9 |
| Docs & honesty | 7 | ~8.5 (claims fixed + now CI-enforced via the guard test) | Phase −1 ✅ + 6 🔄 | 10 |
| Product/UX | 6 | 6 (untouched — l10n not started) | Phase 7 ⬜ | 8-9 |

**Overall realistic post-plan: still 9-9.5**, unchanged from the original target — good early execution moves the "now" column but doesn't change the ceiling. Distribution and Product/UX are the two categories still sitting at baseline; they're also the two with zero progress checkmarks above, which is consistent, not a red flag — Phases 5 and 7 haven't started yet by design (Phase 3/4 correctly took priority).

---

## Appendix B: Suggested Timeline

| Weeks | Focus | Status |
|---|---|---|
| 1 | Phase −1 (integrity fixes) + start Phase 0 | ✅ Done |
| 1-3 | Phase 1 (architecture) | ✅ Done |
| 2-4 | Phase 2 tooling stood up | ✅ Done (growth ongoing) |
| 3-8 | Phase 3 attack order + Phase 4 in lockstep (the bulk of the work — ~1,800-2,200 tests) | 🔄 In progress — items 1-2 + extra batch done, ~355 tests so far |
| 5-9 | Phase 5 (size) in parallel | ⬜ Not started |
| 6-9 | Phase 6 (docs) + Phase 7 (l10n) — slot into slack time | 🔄 Docs partial, l10n not started |
| 9-11 | Phase 8 release readiness + staged rollout | ⬜ Not started |
| 12-16 | Phases 9-10 (accessibility, analytics) | ⬜ Not started |
| 14-20 | Phase 11 (cloud sync, Firebase — no Supabase), then Phase 12 (monetization, decision-dependent) | ⬜ Not started |
| 16-20 | Phase 13 (UI wow factor) | ⬜ Not started |
| 20+ | Phase 14 (community/gamification) and Phase 15 (AI features, retrieval-only) — both major scope, both sequenced last on purpose | ⬜ Not started |

Solo maintainer: expect roughly double this calendar time — tracking so far is broadly consistent with that pace.

---

## Next step

Status as of 2026-09-07 (evening): **630/630 tests green, coverage 31.04% (CI floor 30), analyze 0, ARB 659/659, assets 221.5/230 MB.** Supabase is settled (no — Firebase for Phase 11 when it comes up). The seeded-bug review ✅ passed and Phase 3 item #3 (hadith FTS5 search + detail, rowid regression) ✅ closed today. The remaining genuine open engineering items, in order:

1. **Phase 4 CHANGELOG bug-mine remainder** — regression tests for the timezone-handling fix, the Asr-angle bug, and the RTL chevrons/insets/back-buttons fixes (the rowid item is now closed).
2. **Phase 3 items #4–#6** — FSRSAlgorithm, tafsir/mushaf pages, then the reciter/audio/khatmah/settings/onboarding sweep; raise the coverage ratchet 30 → 31 as this lands.
3. **Phase 5's deferred half** (feature delivery/asset packs, post-10 per D2) and **Phase 8** (release readiness: global error-boundary pass, a11y, staged rollout) gate the ship.

Phase 7 (l10n), Phase 10 (analytics), Phase 3 item #3 and the seeded-bug review are closed as of this update. Say the word when item 1 is ready to run.
