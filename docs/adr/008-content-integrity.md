# 008 — Content integrity as a release gate

**Status:** Accepted (restated 2026-09-18)

## Context

For a religious app, a silently altered text is the worst possible defect: it
is a trust failure, not a bug, and it can survive review because nothing in a
normal test suite notices a changed byte. The project also states (in the
README and store copy) that content is reviewed, so an unreviewed change would
make the documentation false.

## Decision

Treat bundled content as a frozen artifact with three independent layers:

1. **Checksums.** Every content set carries SHA-256 hashes — sidecars next to
   the files and the complete freeze surface in
   [content-manifest.json](../content-manifest.json).
2. **Automated verification.** `dart run tool/verify_content_checksums.dart`
   runs on every push and again in the release job, checking files, sidecars
   and manifest against each other, plus coverage (no file in a covered root
   may be unlisted).
3. **Human review.** [scholarly-review.md](../scholarly-review.md) maps each
   set to a reviewer and verdict; a `pending` row blocks a release
   (`tool/release_preflight.dart`), with an explicit dry-run flag only.

A deliberate content change invalidates the freeze by design: rebuild,
regenerate hashes, update the manifest, and re-review in the same commit.

## Consequences

- Content changes are review events, not routine edits — that is the point.
- The narrator database's "no fabricated verdicts" policy is enforced the same
  way: fields without a citation (or with a weak one) stay empty or are marked
  under review.
- Any future content set must land with provenance fields, a hash, a review
  row and coverage in the manifest, or CI fails.
