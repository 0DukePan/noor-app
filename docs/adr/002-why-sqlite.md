# 002 — SQLite for relational content, shipped prebuilt

**Status:** Accepted (restated 2026-09-18)

## Context

The bundled corpus is relational and large: nine hadith collections with
chapters and ~50,000 narrations, four tafsir sources with 6,236 entries each,
plus free-text search over all of it. First launch must be usable quickly, and
the search index must not cost tens of seconds to build on device. The
alternatives (loose JSON files, building an index on first import) failed in
practice: the tafsir corpus was previously 25,401 loose files and first launch
imported 17 books from JSON (30–60 s on device).

## Decision

Use SQLite through `sqflite`, and ship the databases as prebuilt assets:

- `assets/db/hadith.db` — built in CI (`tool/build_hadith_db.dart`), gitignored,
  copied from the bundle into app documents on first launch (`~1–3 s`).
- `assets/db/tafsir.db` — committed, opened from assets.
- `noor_search.db` — built lazily on device for cross-content search.

Search uses SQLite's FTS5 (see [007](007-search-architecture.md)).

## Consequences

- The databases dominate the bundle (~210 MB of 221.8 MB), which is why bundle
  size is a CI budget and why on-demand delivery is a recorded future decision
  ([006](006-bundled-content.md)).
- Builders are part of the shipped toolchain and validate their own output
  (malformed entries refuse to ship; row counts are asserted), and every
  database has a checksum and integrity test
  ([008](008-content-integrity.md)).
- Schema changes are versioned: `hadith.db` is at version 2 with an explicit
  `migrateToV2` (adding `arabic_norm` and rebuilding FTS); see
  [data-model.md](../data-model.md).
