# Architecture decision records

Short records of decisions that were already made, kept so the reasoning does
not have to be reverse-engineered from the code later. Each ADR is a few
paragraphs: context, decision, consequences. Statuses: **Accepted** (in force),
**Superseded by ADR-NNN** (kept for history).

These document decisions; they are not proposals. Changing one means writing a
new ADR that supersedes it, in the same pull request as the change.

| ADR | Decision | Status |
|---|---|---|
| [001](001-why-flutter.md) | Flutter as the application framework | Accepted |
| [002](002-why-sqlite.md) | SQLite (sqflite) for relational content, prebuilt as bundled assets | Accepted |
| [003](003-why-hive.md) | Hive for on-device user data | Accepted |
| [004](004-why-riverpod.md) | Riverpod for state management | Accepted |
| [005](005-offline-first.md) | Offline-first: bundle the core, keep the network optional | Accepted |
| [006](006-bundled-content.md) | Keep content bundled for v1; on-demand packs deferred | Accepted |
| [007](007-search-architecture.md) | In-repo Arabic normalization + SQLite FTS5 search | Accepted |
| [008](008-content-integrity.md) | Checksums, a manifest and scholarly review as release gates | Accepted |
| [009](009-source-available-licensing.md) | Source-available, not open-source | Accepted |
