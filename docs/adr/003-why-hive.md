# 003 — Hive for on-device user data

**Status:** Accepted (restated 2026-09-18)

## Context

Alongside the relational corpus there is a wide, shallow set of per-user state:
reading progress, bookmarks, adhkar counts, prayer settings and offsets, qada
records, hifz/FSRS card states, quiz history, widget caches, audio progress,
and encrypted reflections. Most of it is "a map of values", not relations, and
it evolves every release.

## Decision

Store user data in Hive boxes. Box names live in one registry,
`lib/core/services/hive_box_registry.dart` (`HiveBoxes`), and services are
expected to reference the constants rather than string literals.
Boxes are opened lazily by their owning service; `openAll`/`closeAll` exist for
tests and lifecycle operations.

## Consequences

- User-data evolution adds keys instead of running migrations — the relational
  content that does need migrations lives in SQLite instead
  ([002](002-why-sqlite.md)).
- The registry makes the storage surface auditable: ~48 boxes, each with a
  documented owner (see [data-model.md](../data-model.md)).
- Encryption is applied at the value level where it is needed: `tadabbur`
  notes are AES-encrypted before they reach Hive (`DefaultPrivacyPolicy`,
  key held in platform secure storage). No other box stores personal free text.
- Analytics counters live in their own box with a reserved opt-in key that is
  excluded from every snapshot and upload.
