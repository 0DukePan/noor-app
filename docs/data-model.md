# Data model

Where every piece of state lives, and why. Diagrams (component, class,
ER, sequence, state machine, deployment) are in
[ARCHITECTURE.md](ARCHITECTURE.md); this file is the reference for schemas and
storage locations.

## Overview

| Store | Kind | Contents | Lifecycle |
|---|---|---|---|
| `assets/db/hadith.db` | SQLite (bundled asset) | Hadith corpus + FTS5 index | Built by `tool/build_hadith_db.dart`; copied into app documents on first launch |
| `assets/db/tafsir.db` | SQLite (bundled asset) | Four tafsir sources | Committed; opened read-only from assets |
| `noor_search.db` | SQLite (on device) | Unified search FTS5 index | Built lazily on device; clearable from settings |
| Hive boxes | Key-value (on device) | User data: progress, bookmarks, settings, notes, counters | Opened lazily per service; names centralized in `HiveBoxes` |
| `assets/**/*.json` | Bundled JSON | Quran text/pages/translations, adhkar, narrators, grades | Frozen by checksums ([content-manifest.json](content-manifest.json)) |

## SQLite: `hadith.db` (version 2)

Schema owner: `lib/core/data/data_sources/hadith_db_builder.dart`
(`kHadithDbVersion = 2`, with `HadithDbImporter.migrateToV2` adding
`arabic_norm` and rebuilding the index).

| Table | Columns | Notes |
|---|---|---|
| `collections` | `id` (PK), `title_arabic`, `title_english`, `author_arabic`, `author_english`, `introduction`, `hadith_count` | one row per book |
| `chapters` | `id`, `collection_id` (PK with `id`), `title_arabic`, `title_english` | FK → `collections(id)` |
| `hadiths` | `id`, `id_in_book`, `collection_id`, `chapter_id`, `arabic`, `arabic_norm`, `english_narrator`, `english_text`; PK `(id, collection_id)` | `arabic_norm` is the normalized text used by search |
| `hadiths_fts` | `arabic_norm`, `english_text`, `english_narrator` | FTS5, `content='hadiths'`, `content_rowid='rowid'` — an external-content index |

Indices: `idx_hadiths_collection`, `idx_hadiths_chapter`,
`idx_chapters_collection`.

**Invariant:** the FTS index and the content table must stay rowid-aligned.
The regression suite (`test/services/hadith_search_fts_test.dart`) pins set
identity per token, scans for phantom rows, and covers the
INSERT-OR-REPLACE-without-rebuild staleness contract.

## SQLite: `tafsir.db` (version 1)

Schema owner: `lib/core/data/data_sources/tafsir_db_builder.dart`.

| Table | Columns |
|---|---|
| `tafsir` | `source`, `surah`, `ayah`, `text` |

Index: `idx_tafsir_lookup` on `(source, surah)`. Sources: Muyassar, As-Saadi,
At-Tabari, Ibn Kathir — 6,236 entries each. The builder refuses to ship a
database whose row count disagrees with the importer's report.

## SQLite: `noor_search.db` (on device)

Schema owner: `lib/features/search/data/data_sources/search_local_data_source.dart`.

```sql
CREATE VIRTUAL TABLE search_index USING fts5(
  text,
  source UNINDEXED,
  reference UNINDEXED,
  tokenize = "unicode61 remove_diacritics 1"
)
```

Indexes Quran, hadith and adhkar in one place; rebuilt lazily on first search
and deleted by "clear cache". Queries are pre-normalized in Dart
(`normalizeArabic`) in addition to SQLite's own diacritic handling.

## Hive boxes (user data, on device)

Names are registered in `lib/core/services/hive_box_registry.dart` (one source
of truth; `HiveBoxes.allBoxNames` is what `closeAll`/`openAll` use). Grouped by
owner:

| Group | Boxes |
|---|---|
| Core caches | `surahs`, `verses`, `tafsir`, `hadiths`, `adhkar`, `quran_cache`, `home_cache`, `hadith_search_index`, `hadith_search_cache`, `tafsir_cache` |
| User Quran data | `reading_progress`, `bookmarks`, `tadabbur` (encrypted), `khatmah_plans`, `tajweed` highlights/annotations (`tafsir_highlights`, `tafsir_annotations`) |
| Hadith user data | `hadith_progress`, `hadith_bookmarks`, `hadith_notes`, `hadith_review`, `hadith_tags`, `memorization_cards` (FSRS), `quiz_history` |
| Prayer & location | `prayer_settings`, `prayer_offsets`, `qada`, `location_trust`, `health_check`, `adhan_settings`, `notification_settings`, `mosque_mode`, `day_state` |
| Statistics | `app_statistics`, `activity_history`, `analytics`, `adhkar_progress`, `adhkar_stats`, `adhkar_settings`, `hifz_data` |
| Preferences | `settings`, `theme_settings`, `tafsir_settings` |
| Offline sync | `quran_offline`, `hadith_offline` |
| Audio | `audio_cache`, `audio_progress` |

Notes:

- `tadabbur` values are ciphertext: `DefaultPrivacyPolicy` encrypts before
  writing (AES, random IV per write, key from platform secure storage). No
  other box carries personal free text.
- `analytics` holds counters plus the opt-in flag, which is excluded from
  snapshots and uploads.
- Hive is deliberately schema-light: user-data evolution adds keys rather than
  running migrations. Relational content lives in SQLite instead (see
  [adr/003-why-hive.md](adr/003-why-hive.md)).

## Bundled JSON

| Path | Contents | Frozen by |
|---|---|---|
| `assets/quran/quran_uthmani.json` | 6,236 verses, Uthmani | sidecar + manifest |
| `assets/quran/quran_pages.json` | 604-page mushaf map | manifest |
| `assets/quran/surahs.json` | Surah metadata | manifest |
| `assets/quran/translations/en_sahih.json`, `ar_muyassar.json` | Bundled translations | manifest |
| `assets/hadith/narrators.json` | 63 narrator biographies with citations | sidecar + manifest |
| `assets/hadith/grades.json` | Selected gradings (al-Albani), marked under review | manifest |
| `assets/adhkar/*.json` | Seven adhkar collections | sidecar + manifest |

Content provenance, review status and the change procedure are documented in
[content-pipeline.md](content-pipeline.md).
