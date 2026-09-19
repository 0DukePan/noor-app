# Contributing

Noor is **source-available, not open-source**: the code is published so the
content-integrity and privacy claims can be verified, but the license stays
proprietary ([LICENSE](LICENSE)). Bug reports and reproducibility findings are
welcome through issues; code contributions require prior discussion before any
work starts, because of that license. This document also doubles as the
maintainer's own runbook.

## Development setup

```bash
flutter --version        # must be 3.41+ (Dart 3.11+); CI pins 3.44.9
flutter pub get
dart run tool/build_hadith_db.dart   # assets/db/hadith.db is gitignored
flutter run
```

The hadith database is not committed — generate it once before running the
app or the test suite. The build takes a couple of minutes and produces a
~154 MB file.

## Running every gate locally

CI runs exactly these; a PR is expected to pass them unchanged.

```bash
dart run tool/build_hadith_db.dart            # prerequisite for tests
dart run tool/verify_content_checksums.dart   # content vs frozen manifest
flutter analyze                               # 0 issues
flutter test --coverage
python3 tools/coverage_summary.py 30          # app-wide coverage floor
python3 tools/file_size_check.py              # god-file guard
python3 tools/check_assets_size.py 230        # bundle budget
python3 tools/check_exclusions.py             # coverage-exclusion budget
python3 tools/check_arb_parity.py             # ARB parity, N locales
python3 tools/generate_sbom.py --output build/sbom.cdx.json
flutter test integration_test                 # needs a device/emulator
```

## Engineering conventions

- **Architecture.** Feature-first under `lib/features/`, engines and shared
  services under `lib/core/`. State is Riverpod providers; services are static
  singletons initialized in `main()`. See
  [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and the ADRs in
  [docs/adr/](docs/adr/README.md).
- **Localization.** No hardcoded user-facing strings: every string goes through
  `AppLocalizations`, with both `app_ar.arb` and `app_en.arb` updated together
  (the parity gate fails otherwise, and it now also checks empty values and ICU
  placeholders).
- **Tests.** Follow [docs/testing-guidelines.md](docs/testing-guidelines.md).
  New behavior needs tests; bug fixes get a regression test named after the
  failure mode, and every fixed bug gets a `CHANGELOG.md` entry. Complex
  invariants are welcome as property tests
  (`test/property/`, helper in `test/test_utils/property.dart`).
- **File size.** Soft cap 400 lines, hard cap 700 with a tracked baseline and a
  10% growth allowance (`tools/file_size_check.py`). Split before raising.
- **Privacy.** Never log user content (notes, queries, coordinates). Any new
  outbound call must be opt-in or content-only and documented in
  [docs/privacy.md](docs/privacy.md).
- **Dependencies.** Small utilities are written in-repo rather than pulling in a
  young package (the hand-rolled property-testing helper is the reference
  example). Anything added must survive the OSV scan in CI, be actually used,
  and be justified in the PR description.

## Content changes (the strictest rule)

Bundled religious content is frozen and reviewed:

1. Never fabricate. A narrator reliability field without a citation stays
   empty; a weak attribution is worse than a blank.
2. Any content edit is a review event: rebuild the database, regenerate the
   affected hashes, update `docs/content-manifest.json`, and update the
   affected rows in `docs/scholarly-review.md` in the same commit.
3. `dart run tool/verify_content_checksums.dart` must pass; CI also rejects an
   unlisted file under a covered root.

The full procedure is in [docs/content-pipeline.md](docs/content-pipeline.md).

## Pull requests

Use the PR template. Keep changes focused; include the gate output when a gate
is relevant. Security reports go through
[SECURITY.md](SECURITY.md), never a public issue.
