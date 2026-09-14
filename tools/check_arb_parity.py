#!/usr/bin/env python3
"""ARB parity check (Phase 7 gate).

Fails the build if a localization key exists in one locale's ARB file but
not the other. Keeps the ar/en string sets identical so a partial extraction
can't silently ship.

Usage: python tools/check_arb_parity.py
"""
import json
import os
import sys

ARB_DIR = 'lib/l10n'


def keys(path):
    with open(path, encoding='utf-8') as fh:
        data = json.load(fh)
    return {k for k in data if not k.startswith('@')}


def main():
    arbs = [f for f in os.listdir(ARB_DIR) if f.endswith('.arb')]
    if len(arbs) < 2:
        print(f'FAIL: expected at least two .arb files in {ARB_DIR}, '
              f'found: {arbs}')
        return 1

    by_locale = {}
    for name in arbs:
        path = os.path.join(ARB_DIR, name)
        by_locale[name] = keys(path)
        print(f'{name}: {len(by_locale[name])} keys')

    ok = True
    names = list(by_locale)
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            a, b = names[i], names[j]
            missing_in_b = by_locale[a] - by_locale[b]
            missing_in_a = by_locale[b] - by_locale[a]
            if missing_in_b or missing_in_a:
                ok = False
                print(f'FAIL: {a} vs {b} parity broken')
                if missing_in_b:
                    print(f'  in {a} but not {b}: {sorted(missing_in_b)}')
                if missing_in_a:
                    print(f'  in {b} but not {a}: {sorted(missing_in_a)}')

    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())