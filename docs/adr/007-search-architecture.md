# 007 — Arabic normalization in-repo, SQLite FTS5 for search

**Status:** Accepted (restated 2026-09-18)

## Context

Arabic search is not a substring problem. «الرحمن» must find «ٱلرحمن»; queries
must match text with or without tashkeel, across hamza/alef variants, ta
marbuta and alef maqsura. Options were: adopt a search package, push the
normalization into SQLite's tokenizer, or normalize in Dart and let SQLite do
the indexing.

## Decision

Normalize in Dart with a small in-repo function
(`lib/core/utils/arabic_text.dart`) and index the normalized text with SQLite
FTS5:

- hadith: `hadiths_fts` is an external-content FTS5 index over `hadiths`
  (`content_rowid='rowid'`), searching the `arabic_norm` column
  ([002](002-why-sqlite.md), [data-model.md](../data-model.md));
- unified search: `noor_search.db` uses
  `tokenize = "unicode61 remove_diacritics 1"` and pre-normalized query text.

No third-party search or Arabic-text dependency is used.

## Consequences

- The normalization function is property-tested: idempotence, diacritic
  stripping, equivalence of variant letters, whitespace collapsing
  (`test/property/arabic_normalization_property_test.dart`).
- The external-content index creates a rowid-alignment contract between what
  FTS reports and what the content table holds; it is pinned by regression
  tests (set identity per token, phantom-row scan, rebuild-on-replace
  staleness, hit→detail closure).
- Index behavior is deterministic and inspectable with plain SQL, which is what
  makes the "verify it yourself" claims possible.
