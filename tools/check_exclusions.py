#!/usr/bin/env python3
"""Coverage-exclusions budget check (Phase 2 gate).

The plan caps the exclusion list at ~10% of total lib/ LOC and requires the
list not to grow without justification. This check:

  1. Extracts every `lib/...` path listed in docs/coverage-exclusions.md,
     sums the LOC of those files, and fails if the excluded set exceeds 10%
     of all lib/ LOC.
  2. Fails if docs/coverage-exclusions.md itself grew past its recorded
     baseline (a growth signal that needs a PR justification).

Usage: python tools/check_exclusions.py
"""
import os
import re
import sys

CAP_FRACTION = 0.10
DOC = 'docs/coverage-exclusions.md'
# Recorded baseline (lines) — bump deliberately, only with a justification.
DOC_BASELINE = 48
GROWTH_ALLOWANCE = 0.10


def lib_loc():
    total = 0
    for root, _, files in os.walk('lib'):
        for f in files:
            if f.endswith('.dart'):
                try:
                    total += sum(1 for _ in open(os.path.join(root, f), encoding='utf-8'))
                except OSError:
                    pass
    return total


def excluded_loc(doc):
    """Sum LOC of files listed in *uncovered* rows only.

    Rows whose disposition marks the entry as covered/loaded are not
    exclusions — counting them would inflate the excluded set and turn the
    cap into a lie.
    """
    total = 0
    text = open(doc, encoding='utf-8').read()
    rows = text.split('\n')
    for line in rows:
        if not line.strip().startswith('|'):
            continue
        if 'covered' in line.lower() or 'loaded' in line.lower():
            continue
        for match in re.finditer(r'`(lib/[^`]+\.dart)`', line):
            rel = match.group(1).replace('/', os.sep)
            if os.path.isfile(rel):
                try:
                    total += sum(1 for _ in open(rel, encoding='utf-8'))
                except OSError:
                    pass
    return total


def main():
    ok = True
    total = lib_loc()
    excluded = excluded_loc(DOC)
    frac = excluded / total if total else 0
    print(f'lib LOC: {total} | excluded-listed LOC: {excluded} '
          f'({frac * 100:.1f}%)')
    if frac > CAP_FRACTION:
        ok = False
        print(f'FAIL: exclusion list exceeds the {CAP_FRACTION * 100:.0f}% cap — '
              'restructure code to be testable instead of excluding more')

    doc_lines = sum(1 for _ in open(DOC, encoding='utf-8'))
    cap = DOC_BASELINE * (1 + GROWTH_ALLOWANCE)
    print(f'exclusions doc: {doc_lines} lines (baseline {DOC_BASELINE})')
    if doc_lines > cap:
        ok = False
        print('FAIL: exclusions doc grew >10% past baseline — add the '
              'justification in the PR description')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())