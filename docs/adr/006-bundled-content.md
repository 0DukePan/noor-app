# 006 — Keep content bundled for v1; on-demand packs deferred

**Status:** Accepted (decision D2 recorded 2026-09-05; iOS note added 2026-09-18)

## Context

The bundle is ~221.8 MB against a 230 MB CI budget, almost entirely the two
SQLite databases. The obvious lever — Play Feature Delivery / asset packs to
get the base install under ~100 MB — is feature-sized work: it needs hosting,
checksummed resume, and an offline fallback story. Measured on the shipped
database, rebuilding the FTS index on device would reclaim at most ~24 MB of
the 154 MB hadith DB, which is not worth the first-run cost while budget
headroom remains.

## Decision

Keep the content bundled for v1. On-demand delivery is deferred as a
*purposely recorded* post-1.0 option, not an oversight. The size budget stays a
CI gate so it cannot drift. The platform split is explicit: Flutter deferred
components are Android-only, and Apple's On-Demand Resources has no Flutter
engine support, so **iOS ships the full bundle indefinitely** — the platforms
are allowed to have different content-delivery stories.

## Consequences

- The 230 MB CI gate (`tools/check_assets_size.py`) is the regression guard;
  revisit the decision if the budget ratchets below ~205 MB.
- New content must fit or the decision gets revisited — the gate is not raised
  casually (see [store-checklist.md](../store-checklist.md) §6).
- If Android splitting ships later, it must be justified on its own evidence
  before iOS parity is even discussed.
