# 009 — Source-available, not open-source

**Status:** Accepted (2026-09-18)

## Context

The repository is public but licensed proprietary, while the project's trust
claims (checksums, privacy design, "verify it yourself") read like an
open-source project. The README FAQ answered "is the source open?" with a flat
"No", which invited the question rather than answering it. Three options were
on the table: stay proprietary-and-quiet, re-license the code as open-source,
or formalize the current state.

Re-licensing is not a one-line change here: the app bundles Quran text, four
tafsir sources, nine hadith collections and adhkar corpora whose redistribution
terms are independent of the code license. A real open-source move requires a
content-licensing audit first.

## Decision

Formalize the current posture as **source-available**:

- The code license stays proprietary ([LICENSE](../../LICENSE)).
- The source is published deliberately so the integrity and privacy claims can
  be verified by anyone.
- The README says this explicitly in both the FAQ and the License section,
  instead of reading as a refusal.
- Bug reports and reproducibility findings are welcome; external code
  contributions require prior discussion because of the license.
- Contributor tooling (templates, CODEOWNERS, Dependabot) is framed as
  maintainer-workflow quality, not open-source contributor experience.

## Consequences

- No content re-licensing is needed for this posture.
- If the project ever moves to a true open-source license, the first step is a
  per-dataset licensing audit recorded in
  [content-manifest.json](../content-manifest.json) (the `license` fields are
  currently `unrecorded` for most sets) — see
  [content-pipeline.md](../content-pipeline.md).
