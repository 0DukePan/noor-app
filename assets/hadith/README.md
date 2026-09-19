# Hadith assets

## Files

- `narrators.json` — 63 narrator biographies with per-entry citations
  (`rankSource`). Reliability fields without a citation stay empty by policy:
  an invented *Ilm al-Rijal* verdict is worse than a blank. Frozen by
  `narrators.sha256` and `narrators.json.sha256`.
- `grades.json` — selected gradings (al-Albani); its `_meta` records that every
  number is under scholarly review before release.

The hadith corpus itself is **not** here: it lives in `tool/data/hadith/` and
is built into `assets/db/hadith.db` by `tool/build_hadith_db.dart` (the
database is gitignored and regenerated in CI). Provenance and the freeze
procedure are in [`docs/content-pipeline.md`](../../docs/content-pipeline.md).
