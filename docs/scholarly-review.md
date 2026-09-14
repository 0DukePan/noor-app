# Scholarly review tracker

**Status: BLOCKING for store release.** No version ships to the Play Store /
App Store until every row below is signed off by a qualified reviewer.
Engineering can be 10/10 and still be unreleasable without this.

## How to use

1. The owner nominates a reviewer (azhari scholar / hadith specialist / fiqh
   reference per topic).
2. The reviewer checks the bundled content against trusted print editions.
3. The reviewer fills `Reviewer`, `Date`, and `Verdict`; the owner commits the
   update. A row is done only when `Verdict` is `approved`.

## Scope under review

| # | Content | Location in repo | Reviewer | Date | Verdict |
|---|---|---|---|---|---|
| 1 | Quran uthmani text (6,236 verses) | `assets/quran/` | — | — | pending |
| 2 | Bengali-free Arabic: surah names, metadata | `lib/` surah-names entity | — | — | pending |
| 3 | Tafsir Al-Muyassar (6,236 entries) | `tool/data/tafsir/muyassar/` + `assets/db/tafsir.db` | — | — | pending |
| 4 | Tafsir As-Saadi (6,236 entries) | `tool/data/tafsir/saadi/` + `assets/db/tafsir.db` | — | — | pending |
| 5 | Tafsir At-Tabari (6,236 entries) | `tool/data/tafsir/tabari/` + `assets/db/tafsir.db` | — | — | pending |
| 6 | Tafsir Ibn Kathir (6,236 entries) | `tool/data/tafsir/ibn_kathir/` + `assets/db/tafsir.db` | — | — | pending |
| 7 | The nine hadith books | `tool/data/hadith/` + `assets/db/hadith.db` | — | — | pending |
| 8 | Forty/forty-Qudsi/other collections | `tool/data/hadith/` + `assets/db/hadith.db` | — | — | pending |
| 9 | Narrator biographies (`narrators.json`, 63 entries) | `assets/` narrators asset | — | — | pending |
| 10 | Adhkar texts + sources | `assets/adhkar/` | — | — | pending |
| 11 | Prayer calculation defaults (method per region) | `prayer_country_presets.dart` | — | — | pending |
| 12 | Qibla guidance copy (in-app strings) | ARB files (`app_ar.arb`) | — | — | pending |
| 13 | English translations shown in-app | ARB files (`app_en.arb`) | — | — | pending |

## Frozen content hashes (engineering support, done 2026-09-05)

Each row below is pinned by a content hash so a sign-off stays valid until the
content actually changes. Regenerate with
`dart run tool/content_checksum.dart <out> <file-or-dir>...` when content is
edited deliberately, and note the new hash next to the reviewer's verdict.

| # | Frozen artifact | Hash file |
|---|---|---|
| 1 | Quran uthmani text (`assets/quran/quran_uthmani.json`) | `assets/quran/quran_uthmani.sha256` |
| 3-6 | Tafsir DB (`assets/db/tafsir.db`, embeds Muyassar/Saadi/Tabari/Ibn Kathir) | `assets/db/tafsir.db.sha256` |
| 7-8 | Hadith DB (`assets/db/hadith.db`, nine books + collections) | `assets/db/hadith.db.sha256` |
| 9 | Narrator biographies (`assets/hadith/narrators.json`) | `assets/hadith/narrators.json.sha256` |
| 10 | Adhkar corpus (7 JSON collections) | `assets/adhkar/adhkar.sha256` (per-file manifest) |

Rows 2 (surah names/metadata), 11 (prayer presets), 12-13 (ARB UI copy) live
in code and are covered by the test suite + `check_arb_parity.py`; they are
frozen by review, not by a separate hash.

## Out of scope for reviewers

- Code correctness, test coverage, performance (engineering's job, CI-gated).
- UI copy that carries no religious ruling (button labels, error states).

## Content freeze hashes (2026-09-05)

Every row below ships a fixed corpus; reviewers check the corpus, and the
hashes below pin exactly what was reviewed (regenerate + commit after any
content change). Verifying: `Get-FileHash -Algorithm SHA256 <file>` (or
`sha256sum -c <file>.sha256` where a sidecar exists).

| # | Content | SHA-256 |
|---|---|---|
| 1 | Quran uthmani text (`assets/quran/quran_uthmani.json`, `quran_pages.json`, `surahs.json`) | verified by `mushaf_integrity_test.dart` (6,236 verses) + `tafsir.db.sha256` covers the built DB |
| 2 | Surah names + metadata (`lib/core/domain/entities/surah_names.dart`) | `surah_names_test.dart` (114 names) |
| 3–6 | Tafsir corpus (`assets/db/tafsir.db`) | `assets/db/tafsir.db.sha256` |
| 7–8 | Hadith corpus (`assets/db/hadith.db`) | `assets/db/hadith.db.sha256` |
| 9 | Narrator biographies (`assets/hadith/narrators.json`) | `ab83c386add8ef2ebd0d91a07a071f803d7b9af9778f08bdf94e1a4ce5d71a97` (sidecar: `assets/hadith/narrators.sha256`) |
| 10 | Adhkar texts (`assets/adhkar/*.json`) | `assets/adhkar/adhkar.sha256` |
| 11 | Prayer method presets (`prayer_country_presets.dart`) | code-frozen; reviewed against the source-of-truth table in `docs/API_SOURCES.md` |
| 12–13 | In-app copy (`lib/l10n/app_ar.arb`, `app_en.arb`) | ARB parity gate + review pass on the keys listed in rows 12–13 |
