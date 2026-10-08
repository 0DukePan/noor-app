# Noor master remediation, Mushaf, Tafsir, and release plan

## Purpose and honest scope

This is the implementation plan for two linked outcomes:

1. Find, fix, and prevent defects in the Noor app, with Qur'an content, user
   data, privacy, accessibility, and release safety taking priority over
   cosmetic defects.
2. Replace the current Mushaf experience with a continuous, page-based reader
   inspired by the supplied reference: Arabic Qur'an text flows naturally
   across a page, end-of-ayah ornaments occur inline, and it feels like a
   calm Mushaf rather than a stack of ayah cards.

The supplied image is a visual reference only. It is not a source of Qur'an
text, font artwork, or instructions. The implementation will use only
reviewed, licensed assets and the frozen, scholarly-reviewed Qur'an source.

“All problems” cannot truthfully mean that every possible defect is known
before the app has run on every supported device, language, permission state,
and data set. This plan therefore separates:

- Known findings: evidence-backed defects or release blockers observed in this
  checkout.
- Completion gates: an exhaustive supported-matrix audit that makes remaining
  defects discoverable and prevents a false declaration of completion.

This document is a plan only. It does not change Qur'an text, app behaviour,
release configuration, or existing user files.

### Consolidated-plan rule

This is the single active master plan for this work. It consolidates the active
Mushaf/Tafsir/button audit with the useful non-duplicated scope from the
pre-existing `final-plan-verified-path-to-10 (1).md`. That older file remains
unchanged as historical input, but it is not a second execution plan.

Evidence collected in this checkout and the release build always wins over a
historical status claim. In particular, the older plan records a full-suite
pass on 2026-09-07, whereas this planning audit observed a current full-suite
failure caused by insufficient system-temp disk and unsafe teardown. The
master ledger must mark such claims **re-verify**, not copy “done” status into
the release gate. Historical work that is confirmed by source, CI, or a fresh
test run may be retained as completed evidence; otherwise it stays an open
verification item.

## What the reference requires

- A restrained near-black page background with soft off-white Arabic text.
- Minimal header: current surah at the left and page/part context at the right.
- A single RTL Arabic text field, not a card, tile, divider, or large gap per
  ayah.
- Decorative end-of-ayah markers placed in the natural text flow.
- An actual page number at the bottom.
- No nested vertical scroll inside an otherwise fixed Mushaf page.
- Controls that can disappear, leaving an undistracted reading page.

The goal is to match this reading experience and these visual characteristics,
not to copy the image pixel-for-pixel.

## Baseline audit record

### Repository state

- Branch: main.
- Pre-existing untracked items found: .zed/ and
  final-plan-verified-path-to-10 (1).md. They must not be changed by this
  work.
- There are 119 unit/widget test files and one integration-test file. This is
  useful coverage, but it does not prove visual fidelity, device correctness,
  permission states, or release readiness.

### Checks run during planning

| Check | Result | Meaning |
|---|---|---|
| Scoped analyzer for Mushaf page and local Qur'an source | Passed | The two inspected files type-check; this is not a full-app analyzer result. |
| Mushaf integrity test | Passed, 3 tests | The separate canonical source has 114 surahs and 6,236 non-empty entries. |
| Mushaf page widget test | Passed, 4 tests | The default screen can render basic continuous spans and theme controls. It does not prove page fidelity or correct interactions. |
| Content checksum verifier | Hashes passed | Frozen hashes match the checkout, but provenance warnings remain. |
| Release preflight | Failed | Signing is missing and 13 scholarly-review rows are pending. |
| Entire test suite | Failed early | Tafsir test setup ran out of system-temp disk space; teardown then threw a second error. |

The full analyzer and full suite must run on a machine with enough system-drive
space before a release.

### Interaction-audit boundary

- A static scan found 545 callback declarations (`onPressed`, `onTap`,
  `onLongPress`, `onChanged`, or `onSelected`) in `lib/`. This count includes
  controls and state callbacks; it is an inventory starting point, not a count
  of unique user-visible buttons.
- The only existing app-level integration smoke test navigates the five bottom
  tabs. It does not exercise the feature-level actions a user described as
  non-working.
- A source scan found no direct empty callback body in the common callback
  forms. That removes one narrow failure pattern only; it does not validate
  wrong arguments, failed futures, unreachable controls, or platform behavior.
- Source inspection can prove that a handler discards state, sends a wrong
  command, or swallows an error. It cannot prove physical target size,
  platform-plugin result, screen-reader behavior, or gesture competition; those
  remain device-test obligations.
- `flutter devices` exposed Windows and Edge only; `flutter emulators` reported
  no configured Android emulator. No claim in this plan treats browser/desktop
  behavior as a substitute for the Android/iOS reader.
- The checkout contains `assets/db/tafsir.db` (about 65.8 MB) and `pubspec.yaml`
  includes `assets/db/`; the earlier checksum check passed. This verifies the
  source checkout, not the installed build or first-launch writable-copy path,
  which still needs the TAF-01 device/release-artifact tests.

### Confirmed healthy page-map property

The existing assets/quran/quran_pages.json map has:

- 604 keys, numbered 1 through 604;
- 6,236 page-map entries;
- 6,236 unique (surah, ayah) identities;
- no duplicate ayah identity; and
- no identity absent from the separate Qur'an source.

This is a sound page-boundary foundation. It does not establish that the two
text representations are byte-identical or that the renderer is a faithful
Mushaf layout.

## Evidence-backed findings

P0 means do not ship. P1 means fix in this remediation. P2 means fix before
the next feature release. P3 is hardening, not a claim that the app is broken.

| ID | Priority | Finding and evidence | Required resolution |
|---|---|---|---|
| QUR-01 | P0 | The page map and the surah/search source are separate text representations. Direct comparison found 6,182 exact-string differences. For example, the page representation of the opening of Al-Baqarah includes a display basmala while quran_uthmani.json ayah 2:1 contains only the disjoint letters. This might be an intentional display convention, not automatically incorrect text, but it is undocumented and unreviewed. | Establish one reviewed canonical source plus an explicit, tested display-token transformation. No view may silently invent, remove, or duplicate text. |
| QUR-02 | P0 | The current Mushaf renderer adds a hard-coded basmala in _SurahStartBanner while the page map already includes one in many first-ayah display strings. It can visibly repeat the basmala. Evidence: quran_mushaf_page.dart lines 429-435 and 555-565. | Remove hard-coded Qur'an text from presentation. Render a basmala exactly once only when the approved token map specifies it. Test all 114 surah starts, Al-Fatihah, and At-Tawbah. |
| QUR-03 | P1 | The reader does not meet the requested page experience. It has SingleChildScrollView inside every PageView page, generic bracket markers, large modern surah banners, and a generic app header. Evidence: quran_mushaf_page.dart lines 350-385 and 627-665. | Implement a fixed continuous page canvas with an approved Qur'anic font and inline marker tokens. Keep card-based interaction in the separate surah study reader. |
| QUR-04 | P1 | A deep link such as /quran/mushaf?page=100 sets PageController to 99, but the provider that drives header, footer, and slider starts at 1. The first frame has conflicting state. Route input is not bounded. Evidence: app_router.dart lines 130-138, quran_providers.dart line 95, quran_mushaf_page.dart lines 113-117 and 138-141. | Validate/clamp input to 1-604, initialize one source of truth before first paint, and add deep-link tests for 1, 604, zero, negative, malformed, and too-large input. |
| QUR-05 | P1 | Page-load error state exposes error text but offers no retry or controlled recovery from a missing/corrupt page asset. | Add a localized error pane with retry, safe diagnostics, and a regression test. |
| QUR-06 | P1 | Per-ayah gesture recognizers live inside one rich text field, but there is no test that ayah actions select the correct ayah without also toggling reader controls. Keyboard/screen-reader reachability is unproven. | Define text hit testing and semantics explicitly, then test touch, keyboard, TalkBack, and VoiceOver paths. |
| QUR-07 | P2 | Theme and control visibility are provider-local and do not restore across launches. Four theme labels are hard-coded Arabic. | Persist a versioned reader-preferences record; add ARB keys and migration/restore tests. |
| QUR-08 | P2 | Mapping a bookmark ayah to a page scans every page and ayah on each lookup. It is bounded but repeated unnecessarily on interaction paths. | Build and validate one immutable (surah, ayah) to page index at page-map load time. |
| APP-01 | P1 | The full suite failed because setUpTafsirTestDb copies the real database into system temp, where only 0.11 GB was free. Its tearDownAll then reads an uninitialized late tempDir, causing a second misleading error. | Make setup failure-safe, preflight free space, support a configured temp root, and retain the real database test. |
| APP-02 | P1 | Release preflight failed: android/key.properties is missing, so a release would be debug-signed; docs/scholarly-review.md has 13 pending rows. | Do not ship. Provision signing through documented secure CI/local configuration and obtain documented reviews. Never commit a key or password. |
| APP-03 | P1 | Checksums match, but the manifest warns that Qur'an, tafsir, hadith/grades, and adhkar content lack recorded licence and retrieval date. | Record authoritative source/version, licence or permission, retrieval date, transformation, reviewer, and freeze hash. |
| APP-04 | P2 | Hive.initFlutter runs in main.dart and immediately again in HiveService.initialize. This makes boot ownership unclear and is redundant. | Keep one documented initializer, then test cold start, failed initialization, and existing-store migration. |
| APP-05 | P3 | Dependency resolution reports 102 newer packages outside constraints. This is not proof of a defect or vulnerability. | Triage by security advisory, platform support, and breaking change; upgrade in small tested batches, never blindly. |
| NAV-01 | P1 | Router handlers parse several path parameters with `int.parse`; malformed values can throw before a usable error page is shown. The existing Mushaf query has no universal route-normalization policy. Evidence: `app_router.dart` Surah and Tadabbur route builders. | Add one typed, range-aware route decoder. Validate Surah 1-114, ayah against the approved verse-count table, and Mushaf page 1-604. Send invalid URLs to a safe localized recovery screen, never an uncaught exception. |
| QUR-09 | P1 | Home and Qur'an-library “continue reading” cards display the saved ayah (and, in the library, page) but navigate only to `/quran/surah/:surah`. `SurahPage` accepts no initial ayah, so the promised reading position is silently discarded. | Use a shared `QuranLocation` intent and navigate to the exact study ayah or its mapped Mushaf page. Preserve a visible fallback only when a legacy position cannot be resolved. |
| QUR-10 | P1 | Khatmah resume displays current surah, verse, and page but its resume action opens only the surah route. It discards the plan’s saved verse/page. | Make resume use the same validated `QuranLocation` resolver as every other Qur'an entry point; test the restored verse, page, and progress state. |
| QUR-11 | P1 | A Qur'an search result navigates only to its surah even though result metadata includes its ayah. A user therefore lands at the beginning of a surah instead of the match selected. | Route search results to exact ayah context, highlight it without changing canonical text, and provide a stable back path to the query/results list. |
| QUR-12 | P1 | The Surah-page action labelled “add bookmark” calls `saveReadingProgress`; it overwrites the singleton last-reading record rather than creating a bookmark. This is an incorrect data mutation, not merely a missing screen. | Separate progress from bookmarks in a shared Qur'an repository. Implement idempotent add/remove, duplicate prevention, migration, list UI, and confirmation/error feedback. |
| AUD-01 | P1 | The per-ayah “play audio” action calls `playSurah` without the selected ayah. The service defaults `startVerse` to 1, so selecting any later ayah begins at ayah 1. | Call a typed `playVerse(surah, ayah)` intent or pass validated start ayah. Reflect selected/loading/playing/error state in the action sheet. |
| AUD-02 | P0 | Completion for the final ayah of a surah increments the ayah number without a surah boundary check. It can request the next absolute recording while retaining an invalid `(currentSurah, currentAyah)` label, causing wrong-content playback or an invalid request. Evidence: `quran_audio_engine.dart` completion and `nextAyah` paths. | Use the approved verse-count map for all advance/seek operations. At each final ayah, stop or deliberately advance both surah and ayah according to an explicit queue policy; never construct an out-of-range identity. Test the final ayah of all 114 surahs. |
| AUD-03 | P1 | Audio failures are caught and only debug-printed by the playback path. A user can tap play and receive no visible failure, retry, or offline explanation. | Return/stream a typed playback state and localized error. Keep controls coherent, offer retry where safe, and test offline, bad URL, interruption, and completion cases. |
| TAF-01 | P0 | “Tafsir currently unavailable” conflates actual absent content with a damaged/missing bundled database. If the prebuilt DB copy fails, `TafsirDatabase` logs the failure and opens an empty schema; later data-layer failures become `null`; the Mushaf and Tafsir UIs show only an unavailable message. This can make a bundled feature appear broken with no user recovery path. | Validate the bundled DB before release and at first use. Preserve a typed failure reason (asset/copy/storage/open/schema/row/source/unknown), show a localized recoverable state with retry or verified re-copy where safe, and retain a non-sensitive diagnostic ID. Never silently substitute an empty production corpus for an expected bundled corpus. |
| TAF-02 | P1 | Tafsir is implemented by several overlapping presentations (`TafsirPage`, `TafsirReaderPage`, inline view, bottom sheet, full-screen page, and a separate Mushaf preview). They use different loading, source switching, typography, localization, history, error, and accessibility behavior. | Define one Tafsir domain state and one composable presentation system: preview sheet, full reader, compare view, and inline excerpt are variants of the same contract rather than competing readers. |
| TAF-03 | P1 | `TafsirPage.initialAyah` is accepted but not used to scroll/highlight. Bookmark and history taps set the surah/source then reopen the list at its start, discarding the selected ayah. | Route all Tafsir entry points through validated `TafsirLocation`; scroll and visually identify the exact saved/search result ayah after content is ready, with a test for a non-first ayah. |
| TAF-04 | P1 | Tafsir comparison’s next-ayah control increments without a surah verse-count boundary. When comparison data is empty, the UI renders an indefinite progress indicator rather than an empty/error state. | Bound navigation by the canonical verse-count map; differentiate loading, zero available sources, partial comparison, and failure. Disable/end-label the final-ayah action and test every surah boundary. |
| TAF-05 | P2 | The inline Tafsir widget records reading history as soon as it loads, including when the user never expands or reads it. Full-reader/history behavior is inconsistent. | Define “read” as an explicit meaningful action (for example expansion dwell threshold or open full reader), deduplicate events, and let users clear history. |
| INT-01 | P1 | Static inventory found 545 callback declarations across `lib/`, but the integration test exercises only the five bottom-navigation destinations and existing widget tests cover a small subset of interactions. This is a verification gap, not proof that all 545 callbacks are defective. | Build an interaction catalogue and contract suite so every reachable action has an owner, precondition, observable success/failure result, persistence expectation, and automated/manual evidence. |
| QA-01 | P1 | This workstation has Windows and Edge targets but no Android/iOS emulator available, so mobile tap, permission, audio, RTL, and accessibility outcomes have not been physically verified here. | Add an Android virtual/physical-device lane and supported iOS device/simulator lane to CI/release QA. Treat missing mobile evidence as a release-blocking test gap, not as a passed test. |

## Product decisions

### Two intentional Qur'an reading modes

Do not force all Qur'an features into one widget.

| Mode | Purpose | Layout | Ayah interaction |
|---|---|---|---|
| Mushaf reader | Immersive page reading and page progress | Fixed pages 1-604, continuous Arabic, inline markers, minimal overlays | Tap or long-press a correct ayah region to open actions without changing the text flow |
| Surah study reader | Translation, tafsir, audio, notes, and search context | Structured ayah sections/cards can remain appropriate | Obvious row-level controls, translation/tafsir on demand |

The route named Mushaf always opens the first mode. Search results and study
tools can use the second mode or deep-link to the precise Mushaf page.

### Qur'an data rule

The canonical Qur'an payload is immutable content. Presentation is a
reversible view over it.

1. Choose and document one approved Uthmani/Hafs source and its display
   conventions.
2. Preserve its exact Unicode sequence in a canonical asset.
3. Generate an approved page-layout/token asset. Token types can be:
   surahHeading, basmala, quranText, ayahEnd, sajdah, metadata, and spacing.
4. A token never holds manually retyped Qur'an text. It references or contains
   text produced deterministically from the reviewed canonical asset.
5. If basmala is separate, tokenization moves the exact approved substring to
   exactly one token. Concatenating content-bearing tokens reconstructs the
   approved display text.
6. Al-Fatihah, At-Tawbah, all surah starts, and every page transition receive
   explicit tests and scholarly review.
7. Generated asset, manifest, checksum, source metadata, and review record
   change together in one controlled content workflow.

### Font and ornament rule

Amiri is an Arabic font, but it is not automatically the reference glyph
system. Before implementation select a font that:

- has required Uthmani shaping and end-of-ayah glyphs;
- has a licence compatible with Android and iOS binary bundling;
- has recorded source/version and licence text in assets/fonts;
- is reviewed on both mobile platforms; and
- does not change canonical Unicode text through unexpected fallbacks.

If it lacks a required ornament, add a separately licensed vector/asset marker
only after validating RTL text behaviour, contrast, and accessibility. Do not
substitute emoji, generic brackets, or copied art.

### Interaction contract: no silent or ambiguous buttons

“All buttons work” needs a testable definition. Before fixing individual
screens, create a versioned interaction catalogue. It is a living release
artefact, not a one-time checklist. Each reachable callback, gesture, menu
item, dialog choice, selector, and permission prompt gets one stable ID with:

| Catalogue field | Required detail |
|---|---|
| ID and location | Feature, route, widget key/semantic label, and source owner. Do not identify actions solely by translated visible text. |
| Trigger and preconditions | Tap, long press, keyboard, swipe, selection, or permission result; signed-in/offline/location/audio/storage state; disabled reason. |
| Intended outcome | Exact route and typed arguments, state mutation, copied/shared payload, playback identity, or external system request. |
| Immediate feedback | Pending, selected, success, cancellation, disabled explanation, or localized failure state visible to the user. A handler may not fail only in logs. |
| Persistence and reversibility | Storage record touched, migration implications, idempotency, undo/remove behavior, and whether the action can overwrite another feature’s state. |
| Evidence | Unit/widget/integration/manual device test ID, supported platforms, accessibility assertion, last execution, and open issue link. |

Use stable `Key` values and semantic labels for controls that need automation;
do not add them to the Qur'an text itself. Every action follows a visible state
model: `idle -> pending -> success or failure -> ready`. Duplicate taps while a
mutation is pending must not double-save, double-start audio, or push duplicate
routes. A disabled action must state why it is unavailable; it cannot behave as
an unexplained inert button. Errors must be surfaced at the action context,
with retry only when retry is safe.

The catalogue is not an instruction to create 545 end-to-end tests. Pure
formatting and small presentation callbacks can have focused widget tests;
data, navigation, permission, audio, share, destructive, or cross-feature
actions require a state assertion and appropriate device evidence. The release
gate is catalogue coverage, not an arbitrary callback-count target.

### Tafsir experience and availability contract

Tafsir must support study without breaking the quiet, fixed-page Mushaf
experience. It is explanatory material, never part of the canonical Qur'an
page token stream and never a visual ayah-card replacement for the Mushaf.

**One location model.** Define `TafsirLocation` as a validated Qur'an location
plus `source`, display mode, and return context. Every entry—Mushaf ayah
action, Surah study reader, Tafsir home, search, bookmark, history, and
notification/deep link—passes the full location. The destination must show the
same surah and ayah that the user selected, then restore the calling screen and
scroll position on Back.

**Mushaf preview.** An ayah action opens an accessible, draggable bottom sheet
that contains: Surah name and ayah number; selected source and scholar; a
clear content state; an excerpt only after it is available; source switcher;
copy/bookmark/note/share actions where approved; and a prominent “Open full
Tafsir” action. The preview can truncate explanatory prose, but never with a
bare `GestureDetector`; controls require labels, 48dp targets, focus order,
and visible pending/error states. It must not inject Tafsir into the fixed
Mushaf page.

**Full reader.** The full screen is a single reader component with stable
header context, selected ayah highlight, exact initial scroll after layout,
source selector, optional comparison mode, selectable RTL text, source author
and provenance, reader font-size controls, bookmark/note actions, and an
explicit return route. It uses localized strings for both Arabic and English;
no hard-coded chrome. Font size and source preference persist through the
versioned preferences record while text remains readable at system font scale.

**Comparison.** Comparison is a deliberate study mode. It starts on the
selected ayah, keeps at least one available source selected, limits selectors
to sources known to contain that ayah, and stops at the final ayah of the
surah. It renders a card for each available source and an informative partial
availability row for each requested-but-unavailable source. “No sources”,
loading, and error have distinct states; an empty result must never spin
forever. Do not rank sources or suggest scholarly equivalence.

**Truthful data availability.** Before publishing a build, verify the Tafsir
asset’s manifest hash, SQLite schema version, source list, row identity/counts,
and source/ayah coverage. At runtime expose one of: available; source not
bundled by product design; missing content for this ayah; recoverable local DB
copy/open/storage failure; or unexpected failure. The UI text and action must
match that state. In particular, a DB copy/open failure is not “no Tafsir for
this ayah.” Retry must re-run the verified initialization; re-copy is allowed
only after checksum verification. No network fetch may be silently introduced
unless its source, licence, consent, cache, offline behavior, and privacy
policy are approved.

**History and bookmarks.** A bookmark is an explicit, idempotent save of a
`TafsirLocation`; opening it restores exact ayah/source. A history record is
created only after a defined reading action, not when a collapsed widget happens
to preload. Users can remove individual entries and clear history with
confirmation. These records remain separate from Qur'an reading progress and
Khatmah progress.

## Reference layout specification

### Page canvas

- One horizontal PageView only. Arabic locale page direction is tested rather
  than assumed.
- Each child is a complete page canvas, not a scroll view nested inside another
  scrollable.
- Current page drives controller, header, footer, slider, saved progress, and
  semantics from one state source.
- Default dark tokens should be close to the reference: background around
  #121214 to #171719, primary text around #E8E5E1, and muted metadata around
  #8B8E99. Exact values are centralized, contrast-tested tokens.
- Cream, white, sepia, and high-contrast variants change colours only; never
  ordering, boundaries, or Qur'an text.
- Canvas has safe-area inset, header zone, text frame, footer zone, optional
  page edge/shadow. Controls never overlap text.

### Header and footer

- Header left uses Arabic surah name when the page begins in it; otherwise the
  approved page-context label.
- Header right is derived from real page metadata: juz, hizb, rub, or the
  approved equivalent of “Part”. Never infer or invent “Part 1.”
- Header never injects a basmala or a modern card into the text frame.
- Footer announces “Page N of 604” semantically even if its visual number is
  ornamental.

### Continuous Arabic text

- One semantic RTL text region per page, or only the minimum contiguous regions
  required by a true surah-heading token.
- Nonbreaking boundary between ayah text and end marker so a marker cannot
  start an unrelated line.
- Preserve natural shaping, diacritics, pause signs, and marker placement. Do
  not split text on ASCII spaces and rejoin it.
- Tune line height, spacing, and optical bounds with the approved font. Do not
  create a false Mushaf by using oversized line height or generic brackets.
- Page mode is fixed composition. On smaller screens use pinch zoom/pan with
  reset rather than silently reflowing page boundaries. A later reflow mode
  must be explicitly labelled non-page-faithful.
- System font scale applies to controls and metadata. Qur'an text provides
  approved discrete zoom/size levels plus semantic accessible text because
  unrestricted scaling breaks fixed page boundaries.

### Controls and touch behaviour

- Tap blank page space to toggle controls. It cannot turn a page, save
  something, or steal an ayah action.
- Turn pages through horizontal swipe, slider, validated page jump, and a
  keyboard/assistive action.
- While slider dragging, update preview state; persist only after page settle.
  Debounce/cancel obsolete writes so an older save cannot overwrite a later
  page.
- Every ayah region has correct (surah, ayah) semantics. Actions: copy,
  bookmark, share, audio/tafsir, and open in study reader. These controls do
  not add visible cards to the page.
- Controls auto-hide only when no accessibility focus, keyboard navigation,
  bottom sheet, or drag is active.
- Store theme, zoom/size, controls preference, and last page in a versioned
  local preferences record. Corrupt values return safe defaults.

## Architecture and implementation phases

### Phase 0: safety, evidence, and issue ledger

1. Create a tracked ledger with finding ID, priority, reproduction, owner,
   platforms, regression test, status, and release decision.
2. Freeze current hashes before content changes.
3. Capture baseline screenshots/video for Mushaf, surah, tafsir, prayer,
   qibla, hadith, adhkar, onboarding, settings, profile, hifz, search,
   notification, and offline flows.
4. Run full analysis, formatter, full tests/coverage, content checks, builds,
    and Android integration tests on a runner with enough temp disk. Preserve
    failures as issues rather than rerunning until green.
5. Confirm results against the CI-pinned Flutter 3.44.9 toolchain.
6. Preserve pre-existing untracked workspace files and unrelated changes.
7. Generate the interaction catalogue from the callback inventory, then review
   it screen by screen. Classify each entry as navigation, read-only UI,
   persisted mutation, audio/media, external intent, permission, destructive,
   or developer-only. Every unclassifiable callback remains a P1 investigation.
8. Record the execution environment separately from product results: no
   Android/iOS target is evidence of an incomplete device test, never evidence
   that a mobile flow passed.
9. Inspect every bundled content database at build time: asset presence,
   checksum, schema migration, writable-copy behavior, source/row coverage,
   low-storage behavior, and the exact user-visible state for each failure.

Exit: the ledger captures all static, test, asset, configuration, and
manual-flow defects observed in the supported matrix; every P0/P1 has an
approved design.

### Phase 1: stop content-risk defects

1. Add a content decision record covering Qur'an source, page convention,
   typography, basmala policy, markers, and scholarly approval.
2. Compare current representations by identity with exact Unicode comparison,
   documented diagnostic normalization, and a human-reviewed intentional
   difference list.
3. Introduce typed data:

       MushafPage
         pageNumber
         headerMetadata
         tokens: List<MushafToken>

       MushafToken
         kind
         surahNumber?
         ayahNumber?
         canonicalText?
         semanticLabel?

4. Add deterministic generator under tool/ that reads approved content and
   emits page tokens plus manifest. Do not generate on the device.
5. Remove hard-coded presentation basmala. The renderer consumes an approved
   token or no token.
6. Set a policy for BOM/non-content format characters. Strip only documented
   non-content characters in generator; test copy/share output.
7. Add source, licence, retrieval date, transformation, and review reference
   for manifest rows currently marked unrecorded.

Exit: all pages derive from one reviewed path; every display token is traceable;
no widget injects Qur'an text.

### Phase 2: Mushaf rendering subsystem

1. Add dedicated Mushaf page model/data source rather than giving raw
   List<Verse> directly to visual page code.
2. Load requested page plus small neighbour prefetch window; cache immutable
   decoded models; measure memory across page 1 to 604.
3. Refactor UI into:

       MushafReaderPage
         MushafPageView
         MushafPageCanvas
           MushafPageHeader
           MushafTextRegion
           MushafPageFooter
         MushafControlsOverlay
         AyahActionsSheet

4. Build spans from tokens while retaining identity for hit tests and semantics.
   Dispose recognizers or use a custom text-painter hit-test map with explicit
   lifecycle.
5. Register the reviewed font as a local Flutter font; never fetch at runtime.
6. Define one immutable Mushaf colour scheme used by dark, cream, white, sepia,
   and high-contrast variants. Localize every label.
7. Remove inner SingleChildScrollView in fixed page mode; add constrained zoom,
   pan, and reset.
8. Use the same page frame for loading, empty, error, and retry states. Never
   show raw exceptions.

Exit: real pages swipe smoothly with continuous text, inline markers, correct
interactions, and no duplication or manual Qur'an injection.

### Phase 3: navigation, state, and persistence

1. Make route-scoped MushafReaderState the only current-page state:

       currentPage
       loading/error
       preferences
       settledPage for persistence
       page metadata

2. Normalize initialPage before first frame. Reject invalid route input before
    PageController sees it.
3. Introduce a typed `QuranLocation` (`surah`, `ayah`, optional `page`, source
   and reading mode) and one resolver backed by the approved verse-count and
   ayah-to-page indexes. It owns validation, page derivation, and legacy-data
   fallback; screens may not hand-build partial Qur'an URLs.
4. Define route contracts: `/quran/mushaf?page=` accepts only 1-604; the Surah
   route accepts a validated path Surah plus optional validated `ayah` query;
   malformed, missing, and out-of-range input reaches a localized recovery
   screen with a safe return link. Apply the same decoder to Tadabbur and every
   other numeric Qur'an route.
5. Remove/reset conflicting global current-page provider deterministically.
6. On page settle, save page plus an explicitly defined reading position. Decide
    whether current ayah means first visible, last completed, or selected ayah;
    do not choose the first array entry by accident.
7. Keep separate typed records for `lastReadingPosition`, `bookmark`, and
   `khatmahPosition`; no action labelled bookmark may write last-reading state.
   Migrate legacy data once, with a reversible backup and telemetry-free local
   diagnostic for skipped corrupt rows.
8. Reconcile home continuation, Qur'an-library continuation, Khatmah resume,
   search result, bookmark, audio, and study-reader deep links through shared
   typed repository APIs. Each entry must restore the selected location or show
   a truthful fallback explanation.
9. Route Tafsir through `TafsirLocation` and a single availability state. A
   selected source must be known available before a user can select it; do not
   use `null` as the common representation for no row, failed initialization,
   corrupt storage, and unexpected exception.
10. Version preferences/last position; corrupt Hive values produce safe fallback
    and nonfatal diagnostic.
11. Keep exactly one Hive initialization owner, then test first launch, upgrade,
    store failure, and existing data.

Exit: all reader entry points agree from first paint, after relaunch, and after
malformed deep link.

### Phase 4: accessibility and localization

1. Add semantic page labels containing page/surah/juz context and direction.
2. Expose ayah action regions as labelled semantic buttons without reading
   ornaments as ordinary prose.
3. Test keyboard focus, TalkBack, VoiceOver, sheet focus trap/release.
4. Meet 48 by 48 logical-pixel tap targets for chrome while preventing
   accidental adjacent-ayah actions.
5. Add ARB keys plus translator descriptions for all reader settings, errors,
   zoom controls, navigation, and themes. Remove hard-coded reader labels.
6. Test Arabic/English chrome; Qur'an remains RTL in both.
7. Verify dark/cream/white/sepia/high-contrast contrast and non-colour-only
   meaning. Test large system type for chrome and page zoom for Qur'an.

Exit: new reader completes Android/iOS accessibility checklist with no missing
localization and documented text-scale behaviour.

### Phase 5: application-wide defect sweep

Use this exact matrix to make the “all problems” commitment repeatable:

| Area | Required checks |
|---|---|
| Startup/storage | fresh install, upgrade, corrupt Hive, no storage, init failure, first-frame timing |
| Qur'an/tafsir/audio | offline reader/surah/search/Tafsir preview/full/compare, exact ayah restoration, bundled-DB copy/corruption/low storage, source availability, bookmarks/history/notes, copy/share, background audio, bad assets |
| Hadith/isnad | DB import, Arabic FTS normalization, source/grade citations, errors, exports, large lists |
| Prayer/adhan/qibla | denied/approximate/no location, DST/time-zone, alarm/notification denial, compass unavailable |
| Adhkar/hifz/khatmah | daily reset/time-zone, persistence, counters, back navigation, completion/re-entry |
| Search/routing | malformed links, back stack, restoration, Arabic/English query, loading/error/no result |
| Interaction contracts | every catalogue ID has an enabled/disabled reason, exact route or state outcome, duplicate-tap behavior, localized failure feedback, persistence assertion, and accessibility path |
| Privacy/security | opt-in boundaries, offline promises, secure secrets, just-in-time permission, scan/SBOM |
| UI/accessibility | RTL/LTR, light/dark/contrast, font scale, narrow/wide/landscape, cutout, keyboard, focus |
| Release packaging | Android APK/AAB, iOS archive, signing, privacy/store copy, bundle size, cold start |

For each failure, add ledger row, write smallest proper regression test, fix,
rerun affected flows. Never hide an issue by deleting a test, swallowing an
exception, or raising a timeout without root cause.

### Phase 6: test infrastructure and release blockers

1. Update test/test_utils/tafsir_test_db.dart to check free temp space before
   copying the real DB and report required/available bytes.
2. Make teardown safe when setup fails: nullable directory or a setup-success
   flag, never uninitialized late state.
3. Allow configured temp directory for local/CI tests without weakening real DB
   integration.
4. Clean only the exact temporary directory created by each test, including
   failed setup paths.
5. Run full suite twice cleanly: ordinary and offline where promised.
6. Provision Android signing via secure CI secrets/configuration; commit only
    example configuration, never keys/passwords.
7. Get real content review/provenance before store eligibility. Pending reviews
    are release blockers, not documentation chores.
8. Add a device lane before calling interaction work complete: Android API
    29/34/current target plus a supported physical Android device; supported iOS
    simulator and physical iOS device. Record OS, device, app build, locale,
    font scale, network, permission, and test result with each manual run.
9. Expand the existing integration smoke test beyond bottom navigation. Run the
    catalogue's critical actions on device: permission denial/grant, location,
    notification, share, audio playback/interruption, background/foreground,
    Qur'an location entry points, and destructive confirmations. Keep mockable
    lower-level tests for deterministic failure paths.
10. Add audio engine boundary tests before any audio release: final ayah of all
    114 surahs, repeat modes, queue transitions, stop, retry, interruption,
    background resume, and no request for an invalid `(surah, ayah)` pair.

Exit: full suite passes reliably; release preflight passes without bypass;
provenance, licence, review, and signing requirements are complete.

### Phase 7: application reliability, domain correctness, and product truth

This phase integrates the still-relevant work from the older plan. It runs
after P0/P1 reader and release blockers, except that a newly discovered P0/P1
in any stream immediately returns to the earlier phases.

1. Establish one coverage source of truth. Generate coverage from a clean run,
   exclude generated code consistently, publish numerator/denominator and the
   reason for each exclusion, and cap/audit exclusions. Coverage is a signal;
   critical paths still require explicit behavioral and domain assertions.
2. Re-verify historical “done” claims with fresh evidence: analyzer, format,
   full test/coverage, ARB parity, content hashes, size budget, claim guard,
   database migrations, and CI configuration. Record the command, toolchain,
   platform, date, output link, and commit in the ledger.
3. Mine the changelog and previous defect records. Add regression tests for
   timezone/DST handling, Asr-angle calculation, RTL chevrons/insets/back
   navigation, and any other documented historical defect before deciding it
   remains fixed. A changelog entry is a test lead, not proof of current status.
4. Verify prayer-time correctness against approved references across methods,
   polar latitude rules, date-line crossings, DST boundaries, leap years,
   location denial/fallback, and device time-zone changes. Separate displayed
   approximation/fallback from calculated user location.
5. Verify Hadith database import, FTS row-to-detail identity, Arabic
   normalization, source/grade citation completeness, regeneration checksum,
   corruption recovery, and large-list search performance. A search hit must
   always open the same record that was indexed.
6. Verify Hifz/FSRS scheduling against its approved specification with fixed
   reference vectors, time-zone/day rollover, lapse/review order, restart, and
   corrupt/migrated data cases. Never accept merely “returns a date” as proof.
7. Audit startup and performance: classify service initialization as essential,
   parallel-safe, deferred, or lazy; measure first-frame, cold start, memory,
   scroll/page jank, database open, search, and audio startup on the device
   matrix. Optimize only with before/after measurements and no loss of error
   reporting or content integrity.
8. Keep assets and distribution honest: enforce a release-bundle size budget,
   verify Android App Bundle density/ABI splits and iOS archive size, decide
   any on-demand asset delivery before implementation, and test offline
   behavior for every asset-placement choice. Never remove bundled religious
   content merely to make a size metric pass.
9. Re-audit product claims, store copy, privacy policy, permissions, analytics,
   and data-safety labels against the built binary. Advertise no unavailable
   feature, request each permission just in time, keep analytics opt-in and
   content-free if retained, and confirm secrets/signing material never enter
   source control or diagnostic output.
10. Complete the design-system sweep: consistent Arabic/English localization,
    RTL/LTR direction, error/empty/loading states, 48dp interactive targets,
    contrast, large type, keyboard, TalkBack, VoiceOver, rotation, and cutout
    behavior in every feature—not only the Qur'an screens.

Exit: every historical claim is either fresh-verified, replaced by a current
finding, or explicitly retired; critical domain features have reference-based
tests and measured device evidence.

### Phase 8: optional product expansion (requires separate approval)

The following items were present in the earlier plan but are not defects and
must not delay repair of the current app. They are intentionally not authorized
implementation merely because they appear here. Scope, privacy, budget,
scholarly review, store policy, and success metrics require a product decision
before work starts.

| Opportunity | Preconditions and non-negotiable guardrails |
|---|---|
| Opt-in account/sync | Offline-first core remains fully usable; choose backend intentionally; explicit consent, encryption, conflict policy, export/delete, account recovery, and offline reconciliation are designed/tested before sign-in UI. |
| Donation/premium/sponsorship | Business owner chooses model; no ads by default; purchase restoration, regional/store policy, financial disclosures, cancellation, and entitlement tests are complete before release. |
| Visual polish | Use licensed original Islamic patterns/illustrations and restrained motion; retain performance, contrast, localization, and accessibility gates. It must not imitate the supplied Quran screenshot’s artwork or alter canonical text. |
| Community/gamification | Requires proven opt-in sync/privacy/moderation model first; no social graph or leaderboard is shipped as an untested add-on. |
| Voice/Tajweed/AI assistance | Voice search follows consent/platform rules. Any Tafsir assistant is retrieval-only, cites approved bundled sources, never presents generated interpretation as scholarship, and has a scholarly safety review before user exposure. |

## File-by-file change map

| Area | Planned change |
|---|---|
| lib/features/quran/domain/entities/ | Add immutable Mushaf page/token/metadata entities. Keep Verse for study domain. |
| lib/features/quran/data/datasources/local_quran_data_source.dart | Typed validated page loading and indexed ayah-to-page lookup. |
| lib/features/quran/data/ | Add token repository/data source if separate from local source. |
| lib/features/quran/presentation/providers/quran_providers.dart | Route-scoped reader state and persisted preferences; remove state conflict. |
| lib/features/quran/presentation/pages/quran_mushaf_page.dart | Reduce to orchestration or replace; remove banner injection, inner scroll, hard-coded labels. |
| lib/features/quran/presentation/widgets/ | Add page canvas, text region, controls, metadata, ayah actions as small widgets. |
| lib/features/quran/presentation/pages/surah_page.dart | Preserve study mode; consume exact location intent; replace false bookmark mutation; start selected-ayah audio. |
| lib/features/quran/presentation/pages/quran_page.dart | Make the displayed last position and its action resolve to the same exact location. |
| lib/features/quran/presentation/pages/khatmah_page.dart | Resume the saved surah, ayah, and page through shared location resolution. |
| lib/features/home/presentation/widgets/continue_reading_card.dart | Make home continuation truthful: restore the saved ayah/page or explicitly explain the safe fallback. |
| lib/features/search/presentation/pages/search_page.dart | Open the selected Qur'an search ayah, preserve result-list return path, and expose no-result/error states. |
| lib/features/quran/data/ and domain/ | Add `QuranLocation`, separate progress/bookmark records and repositories, migration, idempotent bookmark operations, and location/page indexes. |
| lib/core/models/tafsir_models.dart and Tafsir domain/data | Add `TafsirLocation`, typed availability/failure result, per-source capability metadata, validated source/ayah coverage, and versioned user preferences/history/bookmarks. |
| lib/core/data/data_sources/tafsir_database.dart and tafsir_data_source.dart | Verify packaged DB/schema/coverage, preserve failure reasons, safely recover/re-copy verified assets, and never hide a failed corpus initialization behind an empty schema. |
| lib/features/tafsir/presentation/pages/tafsir_page.dart | Replace the competing all-surah reader with the shared full-reader composition; honor exact initial ayah and restore bookmark/history selections. |
| lib/features/quran/presentation/pages/tafsir_reader_page.dart | Become the canonical full Tafsir reader; localize controls, persist preferences, bound comparison navigation, handle partial/empty/error states, and expose semantic actions. |
| lib/features/tafsir/presentation/widgets/tafsir_widgets.dart | Consolidate inline/preview/full/compare components around shared state; add retry, truthful availability, explicit history events, keys, and semantics. |
| lib/core/router/app_router.dart | Use common typed route decoding, bounds-check all numeric parameters, and show localized safe recovery. |
| lib/core/services/quran_audio_service.dart and quran_audio_engine.dart | Typed selected-ayah playback state, visible failures/retry, verse-count boundary logic, interruption and queue policy. |
| lib/main.dart and lib/core/services/hive_service.dart | One storage-init owner plus migration/error checks. |
| lib/features/prayer/ and core prayer calculation modules | Reference-vector tests for method, timezone/DST, Asr, polar/date-line cases; truthful fallback state and permission behavior. |
| lib/features/hadith/, Hadith database/search modules | FTS hit-to-detail identity, Arabic normalization, citation/provenance, regeneration/checksum, corruption, and performance contracts. |
| lib/features/hifz/ and FSRS modules | Reference scheduling vectors, rollover/lapse/restart/migration behavior, and deterministic data tests. |
| lib/main.dart and service initialization modules | Measured essential/parallel/deferred/lazy initialization plan, global error reporting, and first-frame performance tests. |
| docs/, store metadata, privacy assets, CI | Current claim audit, coverage definition/exclusion audit, size budget, SBOM, permissions/data-safety review, and release-evidence ledger. |
| lib/l10n/app_ar.arb, lib/l10n/app_en.arb | Reader strings and descriptions, then normal l10n generation. |
| pubspec.yaml and assets/fonts/ | Approved licensed Qur'anic font plus licence/provenance. |
| assets/quran/, tool/, docs/content-manifest.json | Reviewed token asset, deterministic generator, provenance/review metadata. |
| docs/scholarly-review.md | Real reviewer/date/reference/verdict, never placeholder completion. |
| docs/interaction-catalogue.md or a generated equivalent | Stable ID, owner, preconditions, outcomes, storage effect, accessibility state, regression evidence, and release status for every reachable interaction. |
| test/ and integration_test/ | Content, widget, semantics, persistence, route, audio, golden, contract, and device-integration regression tests. |
| test/test_utils/tafsir_test_db.dart and tafsir tests | Low-disk/setup/teardown robustness. |

## Test plan and acceptance assertions

### Content and generator

- Approved source: exactly 114 surahs and 6,236 ayahs.
- Generated 604-page token map: pages 1-604 and every canonical ayah identity
  exactly once.
- No invalid/empty Qur'an tokens, unknown page, invalid ayah, or bad metadata.
- Content-bearing tokens reconstruct the approved display text under the
  documented convention.
- Basmala appears exactly once where approved, never at At-Tawbah start, never
  appended by widget code.
- Review snapshots: first/last page, all surah starts/transitions, juz
  transitions, special markers, pages 1, 2, and 604.
- Generator is deterministic: same inputs produce byte-identical output and
  manifest hash.

### Widgets and state

- Controller/header/footer/slider/saved progress/semantic label always agree.
- Valid page-604 deep link is correct before first paint.
- Invalid link cannot crash PageController.
- Fixed page mode contains no nested vertical scrollable.
- Text/markers are continuous RTL; marker cannot begin unrelated line.
- Blank tap toggles controls; ayah action selects correct ayah only.
- Error has retry and does not expose raw exception.
- Preferences restore after restart and recover from invalid stored values.
- Controllers and recognizers dispose correctly.

### Navigation, actions, and audio contracts

The following regression cases are mandatory because source inspection already
found them. Each test asserts the destination/state, not only that a callback
was invoked or a widget remains on screen.

| Contract | Setup | Required assertion |
|---|---|---|
| Home continue | Save a non-first ayah location; tap the card. | Study reader or Mushaf opens the same surah and ayah/page, with visible context matching the card. |
| Qur'an-library continue | Save distinct surah, ayah, and page; tap last position. | All stored location fields are honored; no initial-frame mismatch. |
| Khatmah resume | Create an in-progress Khatmah at a non-first ayah/page. | Resume restores that exact plan position and does not reset it to the surah start. |
| Qur'an search result | Search to a known non-first ayah; select it. | Reader highlights/positions the selected ayah and Back returns to the original results/query. |
| Bookmark action | Add the same ayah twice, remove it, then relaunch. | One bookmark is stored then removed; last-reading position remains unchanged throughout. |
| Per-ayah audio | Select a non-first ayah and tap play. | Service receives that exact `(surah, ayah)`; pending/playing/error UI is accurate. |
| Audio end boundary | Simulate completion on each Surah's final ayah under every repeat/queue mode. | Engine stops or advances to a valid next identity as specified; it never emits an out-of-range pair or mislabeled recording. |
| Playback failure | Offline, invalid URL, and player error. | Localized visible error, coherent stopped state, and one safe retry path; no debug-log-only failure. |
| Numeric deep link | Valid edges, zero, negative, too large, non-numeric, missing, and mismatched Surah/ayah. | Valid location is present before first paint; invalid location cannot crash and reaches recovery UI. |
| Duplicate mutation tap | Double-tap save/bookmark/start while pending. | Exactly one persistent mutation/play request/route push occurs; UI resolves to a deterministic state. |

For every remaining catalogue row, add the smallest effective test at the
right layer. A router/repository unit test is sufficient for pure decoding or
data rules; a widget test is required for visible enabled, pending, error, and
semantics states; an integration/device test is required whenever platform
plugins, OS permissions, background work, real audio, share sheets, compass,
or navigation restoration are involved.

### Tafsir content and presentation contracts

| Contract | Setup | Required assertion |
|---|---|---|
| Packaged Tafsir corpus | Build a release-like asset bundle and open the prebuilt DB in a fresh writable directory. | Manifest hash, schema version, expected source list, valid rows, and coverage checks pass before the reader is offered. |
| DB asset failure | Simulate missing asset, checksum mismatch, copy/storage failure, corrupt DB, and failed schema open. | Each becomes a distinct typed state with truthful localized UI and safe retry/recovery; none is rendered as a generic “no Tafsir” message. |
| Exact Tafsir entry | Open from Mushaf, Surah, search, bookmark, history, and a deep link at a non-first ayah. | The full reader/preview identifies, scrolls to, and highlights the exact surah, ayah, and source; Back restores origin context. |
| Source availability | Test an available source, product-disabled source, missing row, and partial source set. | Selectors expose only legitimate choices or explain availability; no false promise and no indefinite loader. |
| Comparison boundary | Move forward/back at first and final ayah for every Surah; select a partial source set. | Navigation remains within valid ayah range; each source has available/absent/error content state and the screen never spins forever. |
| Reader preferences | Change font/source/display mode, restart, and inject invalid saved values. | Approved values persist, invalid values safely default, and chrome remains localized/accessible. |
| History/bookmarks | Render an inline excerpt without opening it; then expand/read/bookmark/remove/relaunch. | Passive preload adds no history; explicit reading is deduplicated; bookmark restores exact `TafsirLocation`; progress is unchanged. |
| Semantics and layout | Arabic and English, screen reader/keyboard, narrow/large font/landscape. | All controls are labelled and focusable, touch targets meet policy, RTL explanatory text reads correctly, and no text/control is clipped. |

### Application-wide reference and release contracts

| Area | Required acceptance evidence |
|---|---|
| Test health | Clean full suite twice from a writable configured temp root; intentional low-disk test fails with one actionable diagnostic and safe cleanup; coverage report uses one documented generated-code/exclusion policy. |
| Prayer | Approved reference vectors for calculation method, Asr, timezone/DST, polar and date-line cases; device permission/fallback display is explicit and never claims precise current location when it is using fallback. |
| Hadith | Regenerated database checksum/source metadata, FTS result-to-detail identity for Arabic queries, citation/grade display, offline/corrupt-DB state, and large-list timing budget. |
| Hifz | Approved FSRS vectors plus lapse, queue, day rollover/time-zone, restart, migration, and corrupted storage tests. |
| Startup/performance | Per-device measurements for cold start, first frame, database copy/open, Mushaf settle, Tafsir open, search, audio start, scroll/jank, memory, and bundle size; each regression has a defined budget/owner. |
| Claims/privacy | Release-binary review confirms store/README/privacy/data-safety/permission claims, analytics consent/default/export behavior, signing/secrets/SBOM, and no advertised capability without passing user journey evidence. |

### Visual and device

Capture stable goldens at agreed 9:20 portrait reference size, small Android,
large phone, tablet portrait, landscape, cream, dark, high contrast, and
controls hidden/shown. Review clipping, spacing, font fallback, safe-area
clearance, RTL page direction, and absence of ayah-card visuals.

Device matrix includes Android API 29/34/current target and supported iOS
versions; fresh install, upgrade, offline, denied permission, background,
rotation, dark mode, font scale, and low storage. Test entry from FAB, home
continuation, khatmah, bookmark, search, and deep link; test page turn, jump,
zoom, copy, bookmark, share, tafsir, audio, and relaunch persistence. Run
TalkBack/VoiceOver and keyboard passes. Measure cold-open, page settle, jank,
cache memory, and binary-size change.

The current machine is not evidence for the mobile portion of this matrix: it
has no Android/iOS emulator configured. Provision the devices above, retain
screenshots/video and test logs, and mark every unrun mobile catalogue entry
as unverified until its device evidence exists.

## Release gate

The remediation is complete only when:

- Every P0/P1 ledger item is fixed with regression evidence; P2/P3 have an
  approved scheduled disposition.
- Full analysis, format, test/coverage, size, l10n, checksum, dependency scan,
  SBOM, Android build, and iOS build pass on pinned toolchain.
- Tafsir tests pass with adequate disk and fail cleanly/actionably without it.
- Content source, licence, retrieval date, transformation, checksum, and
  scholarly review are complete; no store-release review remains pending.
- The Tafsir database is present and verified in the built artifact; its source
  coverage is documented. Tafsir surfaces distinguish unavailable content from
  initialization/storage failure and provide tested, truthful recovery.
- Signing is secure and preflight passes.
- Android/iOS manual QA covers the feature matrix.
- The interaction catalogue has no reachable action without an owner,
  precondition, observable outcome, and current regression or device evidence.
- Critical entry points (home continue, Qur'an continue, Khatmah resume, search,
  bookmark, selected-ayah audio, and audio completion) pass their exact-state
  contract tests. No visible button may rely on debug output as its only error
  path.
- Android and iOS device evidence exists for every platform-dependent catalogue
  action; any unavailable device or unrun case remains a release blocker.
- Prayer, Hadith, Hifz, startup, asset-size, claim, and privacy contracts have
  fresh evidence; historical “done” statements are not used as a substitute
  for current test or release-binary verification.
- Mushaf reader has continuous approved text, no duplicated basmala, correct
  state restoration, approved fonts/assets, and accessibility evidence.
- Privacy/data-safety/store documentation matches the shipped binary.

## Implementation order

1. Stop content and release risks: QUR-01, QUR-02, AUD-02, TAF-01, APP-02,
   APP-03.
2. Repair test infrastructure and provision the mobile test lanes: APP-01,
   QA-01.
3. Build/review the interaction catalogue and turn each confirmed issue into a
   failing contract test: INT-01, NAV-01, QUR-09 through QUR-12, AUD-01,
   AUD-03, and TAF-02 through TAF-05.
4. Approve page-token source and font.
5. Implement the page canvas and continuous Arabic renderer.
6. Implement typed routes, Quran/Tafsir location state, separate persistence
   records, exact continuation/search/Khatmah/Tafsir entry, Tafsir availability
   recovery, and audio queue/error behavior.
7. Complete accessibility/localization and goldens/device review.
8. Sweep every feature through phase-5 matrix and remediate its ledger rows.
9. Execute phase 7: re-verify historical status claims, close domain-correctness
   and performance/claim/privacy contracts, and attach fresh evidence.
10. Complete signing, content review, clean test runs, QA, and preflight.
11. Consider phase-8 optional product expansions only after release gates pass
    and a separate product decision authorizes their scope.

No production release should occur between steps 1 and 10.
