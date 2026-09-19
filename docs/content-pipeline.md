# Content pipeline

How religious content gets from its source into the app, and what stops a
silent change from shipping. This is the written form of a process that was
previously only implicit in tooling; the scholarly side lives in
[scholarly-review.md](scholarly-review.md), the machine-readable side in
[content-manifest.json](content-manifest.json).

## Stages

```
source ─▶ raw corpus ─▶ build ─▶ validate ─▶ checksum ─▶ human review ─▶ freeze ─▶ ship ─▶ verify
```

**1. Source.** Upstream corpora are listed in [API_SOURCES.md](API_SOURCES.md)
(adhkar collections, tafsir sources, the hadith corpus). Narrator biographies
and grades are authored in-repo. Nothing is fetched at runtime to build the
shipped data.

**2. Raw corpus (`tool/data/`, not bundled).**
`tool/data/hadith/**` and `tool/data/tafsir/<source>/<surah>.json` hold the
build inputs. They are deliberately *not* shipped in the app bundle — only the
built databases are.

**3. Build.**
- `dart run tool/build_hadith_db.dart` → `assets/db/hadith.db`
  (schema in `lib/core/data/data_sources/hadith_db_builder.dart`, version 2).
- `dart run tool/build_tafsir_db.dart` → `assets/db/tafsir.db`
  (schema in `lib/core/data/data_sources/tafsir_db_builder.dart`, version 1).
Both builds refuse to produce output they can prove corrupt: tafsir aborts on
any malformed entry, and asserts the row count in the database equals the
importer's own count (catching duplicate-insert/batch-replay bugs).

**4. Validate (CI, every push).**
- `flutter test` — `hadith_db_integrity_test`, `tafsir_db_integrity_test`,
  `mushaf_integrity_test`, `surah_names_test`, `mojibake_guard_test`
  (no corrupted Arabic; no stripped claims in user-facing docs).
- `dart run tool/verify_content_checksums.dart` — every file in a covered root
  is listed in the manifest, and its bytes match the frozen hash.

**5. Human review (release-blocking).**
[scholarly-review.md](scholarly-review.md) maps each set to a reviewer,
date and verdict. A version does not ship while any row is `pending`;
`tool/release_preflight.dart` enforces that (with an explicit
`--allow-pending-scholar-review` escape for signing dry-runs only).

**6. Freeze.**
A review is only meaningful for exact bytes, so two artifacts pin them:
- `.sha256` sidecars next to the content (`assets/db/*.sha256`,
  `assets/quran/quran_uthmani.sha256`, `assets/adhkar/adhkar.sha256`,
  `assets/hadith/narrators*.sha256`), regenerated with
  `dart run tool/content_checksum.dart <out> <file-or-dir>...`;
- the manifest's `sha256` maps — the complete freeze surface, validated
  against both the files on disk and the sidecars.

Because `hadith.db` is gitignored and rebuilt in CI, the question "does the
shipped build still match the reviewed bytes?" is answered by the manifest
rather than by the sidecar (the builder rewrites its own sidecar). The build
is **byte-reproducible**: verified 2026-09-18, a fresh
`dart run tool/build_hadith_db.dart` produced exactly the SHA-256 recorded in
the manifest and the committed sidecar (`3ed05abe…d98da9`) — so the manifest
hash is a real gate for a generated artifact, not a formality.

**7. Ship.** The release job reruns the verifier immediately before
`flutter build appbundle`, after regenerating the gitignored `hadith.db`, so
the shipped build is checked against the frozen hashes rather than against
itself.

**8. Verify (anyone, any clone).**

```bash
dart run tool/verify_content_checksums.dart          # all sets, manifest-based
sha256sum -c assets/db/tafsir.db.sha256              # a single sidecar
Get-FileHash -Algorithm SHA256 assets/db/tafsir.db   # Windows equivalent
```

## Provenance metadata policy

Every set in the manifest carries `source`, `license`, `retrieved_at`,
`review_status` and `review_ref`. The verifier requires the fields to be
present on every set and checks `review_status` is `pending` or `approved`.

Values that are not known are written as the literal string `"unrecorded"`
and the verifier prints them as warnings. They are honest gaps, not
placeholders — **closing them is required before a store release**. Today
the gaps are `license` and `retrieved_at` on the Quran, tafsir, hadith and
adhkar sets; the narrator set records its in-repo authorship, and the adhkar
set records its upstream collections in `API_SOURCES.md`.

## Changing bundled content (deliberate edits)

1. Edit the raw corpus or authored file.
2. Rebuild the database if the change is in `tool/data/`.
3. Regenerate the affected sidecars (`tool/content_checksum.dart`) and update
   the manifest's `sha256` values in the same commit.
4. Re-review the affected rows in `scholarly-review.md` — a hash change
   invalidates the prior sign-off by design; that is the point of freezing.
5. Commit content, sidecars and manifest together; CI rejects a partial change.

## What CI catches

| Failure | Caught by |
|---|---|
| A file in a covered root that no set lists | manifest coverage walk |
| A content file edited without updating the freeze | manifest hash comparison |
| A sidecar regenerated without a re-review | manifest vs sidecar comparison |
| Corrupted Arabic (mojibake) in content | `mojibake_guard_test.dart` |
| A doc advertising content that does not exist | claim guard in the same test |
| A database build producing a different corpus | row-count assertion in the builder, integrity tests |
| Shipping while review rows are pending | `tool/release_preflight.dart` |
