# Qur'an content decision record (Phase 1.1)

Status: implemented in code and tooling; scholarly approval of the underlying
text remains pending (see `docs/scholarly-review.md` rows 1 and 13 — a
release blocker, not a documentation chore).

## 1. Approved sources

| Role | Asset | Notes |
|---|---|---|
| Canonical bare-ayah text | `assets/quran/quran_uthmani.json` | 114 surahs, 6,236 non-empty ayahs. Surah 2:1 holds only the disjoint letters; Al-Fatihah's basmala is ayah 1:1. |
| Page display convention | `assets/quran/quran_pages.json` | 604 pages, 6,236 entries, every canonical identity exactly once. Carries Madani page orthography and display basmala prefixes at surah starts. |
| Surah metadata | `assets/quran/surahs.json` | Names, verse counts, revelation type. |
| Generated page tokens | `assets/quran/mushaf_tokens.json` (+ `.sha256`) | Deterministic output of `tool/generate_mushaf_tokens.dart` over `lib/features/quran/data/mushaf_token_codec.dart`. Registered as manifest set `mushaf-tokens`. |

The canonical payload is immutable content; presentation is a reversible view
over it. No view may silently invent, remove, or duplicate text (QUR-01).

## 2. Measured relationship between the two representations

`dart run tool/generate_mushaf_tokens.dart` reports, as of 2026-10-06:

- 604 pages, 6,236 unique identities, zero duplicates, zero unknown identities.
- 76 byte-identical entries; 6,160 display-vs-canonical differences.
  These are overwhelmingly page-map display orthography (maddah, diacritic,
  and letter-form conventions — e.g. 4:1 `يَـٰٓأَيُّهَا` vs `يَٰٓأَيُّهَا`)
  plus surah-start basmala prefixes. They are a documented display
  convention, not automatically incorrect text — but the convention was
  undocumented and unreviewed, which is the defect. The generator quantifies
  it; scholarship adjudicates it (pending review rows 1/13).
- 112 surah starts require a basmala decision (all except Al-Fatihah and
  At-Tawbah): 24 split cleanly as an identical observed prefix, 88 keep the
  full display string with a listed `basmala-unsplit` anomaly because the
  ayah-1 body differs orthographically from canonical. Every anomaly is
  printed by the generator and embedded in the artifact report.

## 3. Basmala policy (QUR-02)

- The renderer consumes an approved token or no token. Widget code holds no
  hard-coded Qur'an text; the former `_SurahStartBanner` basmala and the
  study-reader Al-Fatihah duplicate are removed.
- Basmala appears exactly once where approved (surah start, surah ≠ 1, 9);
  never at At-Tawbah (9); Al-Fatihah keeps its canonical ayah 1 untouched.
- Token-kind rule: a `basmala` token holds the exact observed display
  prefix; concatenating content-bearing tokens reconstructs the approved
  display text.

## 4. Typography and markers

- Qur'an text renders in the locally bundled `Amiri` family (`assets/fonts`,
  `pubspec.yaml`) — never fetched at runtime. Amiri Regular/Bold v1.002
  (SIL OFL 1.1, licence text embedded in the binaries and copied as
  `assets/fonts/OFL-Amiri.txt`; versions read from the TTF `name` tables,
  recorded in `assets/fonts/README.md`) carries the required Uthmani shaping;
  platform review on Android/iOS is tracked in the QA matrix.
- End-of-ayah ornaments (`﴿n﴾`) are inline in the natural RTL text flow,
  joined to their ayah by U+00A0 + U+2060 so a marker cannot begin an
  unrelated line. Ornament spans carry an empty semantics label: they are
  never read as ordinary prose and never enter plain-text search/copy.
- System font scale applies to chrome and metadata. Qur'an text uses the
  approved discrete zoom levels (`kMushafZoomLevels`); unrestricted scaling
  would break fixed page boundaries. Smaller screens use pinch zoom/pan with
  reset, never silent reflow.

## 5. BOM / format-character policy

- The generator strips exactly one documented non-content character, U+FEFF
  (BOM, observed at page 1 ayah 1), before comparison and token emission.
- All other characters — including U+2060 word joiners added at render time
  inside marker spans only — are preserved byte-exact in stored text.
- Copy/share output carries verse text without render-time joiners (covered
  by widget contract tests).

### Reading-position rule (Phase 3.6)

Page progress and ayah selection are different records:

- **Page progress** (`reading_progress:last_position`) is a page anchor: the
  first ayah of the settled page plus its page number. It answers "where in
  the Mushaf", powers home/library continuation, and is written only on page
  settle with generation-guarded, obsolete-write-safe persistence.
- **Selection** (tapped ayah, audio position, Tafsir target) is transient UI
  or feature state, never the progress record.
- **Bookmarks** are explicit idempotent saves, never progress writes.

## 6. Change control
Generated asset, manifest entry, checksum sidecar, source metadata, and this
record change together in one controlled content workflow:

1. Edit only the reviewed inputs.
2. `dart run tool/generate_mushaf_tokens.dart` (must exit 0).
3. `dart run tool/generate_mushaf_tokens.dart --check` (byte-identical).
4. Update `docs/content-manifest.json` + sidecar; `dart run
   tool/verify_content_checksums.dart` must print OK.
5. Attach the generator report to the scholarly review request.

## 7. Open review items (release blockers)

- Scholarly sign-off of the canonical text and the display convention,
  including the 88 `basmala-unsplit` anomalies and the orthography
  convention (rows 1/13 pending).
- Upstream source/version/licence/retrieval for the Qur'an text (manifest
  `unrecorded` fields) — recorded honestly, never guessed.
- iOS/Android glyph review of the bundled Amiri cut.
