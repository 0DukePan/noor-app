#!/usr/bin/env python3
"""Computes app-wide line coverage over ALL of lib/ (not just files loaded
during the test run), so the reported number reflects the whole app.

Usage: python tools/coverage_summary.py [threshold]

Reads coverage/lcov.info (from `flutter test --coverage`), sums LH/LF across
every lib/*.dart file, counts the real source lines of all lib/*.dart files
as the denominator, and prints the app-wide percentage. Exits 1 when the
percentage is below the optional threshold.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'lib')
LCOV = os.path.join(ROOT, 'coverage', 'lcov.info')

def main() -> int:
    threshold = float(sys.argv[1]) if len(sys.argv) > 1 else None

    total_lines = 0
    for dirpath, _dirs, files in os.walk(LIB):
        for name in files:
            if not name.endswith('.dart'):
                continue
            path = os.path.join(dirpath, name)
            with open(path, encoding='utf-8') as f:
                total_lines += sum(1 for line in f if line.strip())

    hit = 0
    found = 0
    if os.path.exists(LCOV):
        with open(LCOV, encoding='utf-8') as f:
            for line in f:
                if line.startswith('LH:'):
                    hit += int(line[3:].strip())
                elif line.startswith('LF:'):
                    found += int(line[3:].strip())

    pct = (hit / total_lines * 100) if total_lines else 0.0
    print(f'App-wide line coverage: {pct:.2f}% '
          f'({hit} hits / {total_lines} lines in lib/)')
    print(f'(lcov tracks {found} instrumented lines across loaded files)')

    if threshold is not None and pct < threshold:
        print(f'FAIL: coverage {pct:.2f}% is below the {threshold:.1f}% floor')
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
