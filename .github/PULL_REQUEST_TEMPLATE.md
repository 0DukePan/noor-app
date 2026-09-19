## What and why

<!-- One paragraph: the change and the reason for it. Link issues. -->

## Gates

- [ ] `dart run tool/verify_content_checksums.dart` passes (required if anything under `assets/` changed)
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test` — green; new behavior has tests, bug fixes have a named regression test
- [ ] Python gates pass (`coverage_summary.py`, `file_size_check.py`, `check_assets_size.py`, `check_exclusions.py`, `check_arb_parity.py`)
- [ ] `CHANGELOG.md` has an entry for user-visible changes

## Content (only if `assets/` or `tool/data/` changed)

- [ ] Hashes regenerated and `docs/content-manifest.json` updated in this PR
- [ ] `docs/scholarly-review.md` rows updated where the content changed
- [ ] Nothing fabricated: new narrator/grade fields carry a citation or stay empty

## Privacy and accessibility (only if the change touches them)

- [ ] No user content (notes, queries, coordinates) logged or sent anywhere new
- [ ] New UI is labelled for screen readers and meets the 48 dp tap-target rule
- [ ] Any new outbound call is opt-in or content-only and documented in `docs/privacy.md`

## License

- [ ] I understand this repository is source-available (proprietary license), not open-source
