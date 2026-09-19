#!/usr/bin/env python3
"""ARB parity gate (Phase 7), generalized to any number of locales.

With two locales this used to check key-set equality only. Before a third
language (French) lands, the gate grows the checks that are painful to retrofit
afterwards:

  1. key parity   — no key missing from, or extra in, any locale vs the
                    template (app_en.arb);
  2. non-empty    — no empty or whitespace-only translation ships;
  3. placeholders — every ICU placeholder ({count}, {name}) used in the
                    template key must appear in the same key of every locale
                    (and vice versa), so `أكملت {count} من {total}` cannot
                    silently lose a substitution;
  4. shape        — every file is `app_<locale>.arb` and parses as JSON.

Usage: python tools/check_arb_parity.py
Exit codes: 0 all checks pass, 1 one or more checks fail.
"""
import json
import os
import re
import sys

ARB_DIR = 'lib/l10n'
TEMPLATE = 'app_en.arb'

PLACEHOLDER = re.compile(r'\{([A-Za-z_][A-Za-z0-9_]*)\}')
LOCALE_FILE = re.compile(r'^app_([A-Za-z0-9_-]+)\.arb$')


def load_entries(path):
    with open(path, encoding='utf-8') as fh:
        data = json.load(fh)
    return {k: v for k, v in data.items() if not k.startswith('@')}


def placeholders(value):
    if not isinstance(value, str):
        return set()
    return set(PLACEHOLDER.findall(value))


def main():
    if not os.path.isdir(ARB_DIR):
        print(f'FAIL: {ARB_DIR} does not exist')
        return 1

    files = sorted(f for f in os.listdir(ARB_DIR) if f.endswith('.arb'))
    if len(files) < 2:
        print(f'FAIL: expected at least two .arb files in {ARB_DIR}, '
              f'found: {files}')
        return 1

    failures = []
    entries_by_file = {}
    locale_by_file = {}

    for name in files:
        match = LOCALE_FILE.match(name)
        if not match:
            failures.append(f'{name}: does not match app_<locale>.arb')
            continue
        locale_by_file[name] = match.group(1)
        try:
            entries_by_file[name] = load_entries(os.path.join(ARB_DIR, name))
        except json.JSONDecodeError as error:
            failures.append(f'{name}: invalid JSON ({error})')
            continue
        print(f'{name}: {len(entries_by_file[name])} keys')

    if TEMPLATE not in entries_by_file:
        print(f'FAIL: template {TEMPLATE} missing or unreadable')
        return 1

    template = entries_by_file[TEMPLATE]
    template_locale = locale_by_file[TEMPLATE]

    for name, entries in entries_by_file.items():
        if name == TEMPLATE:
            continue
        locale = locale_by_file[name]

        missing = sorted(set(template) - set(entries))
        extra = sorted(set(entries) - set(template))
        if missing:
            failures.append(
                f'{name}: {len(missing)} key(s) missing vs {TEMPLATE}: '
                f'{missing}')
        if extra:
            failures.append(
                f'{name}: {len(extra)} key(s) not in {TEMPLATE}: {extra}')

        empty = sorted(
            key for key, value in entries.items()
            if isinstance(value, str) and not value.strip()
        )
        if empty:
            failures.append(
                f'{name}: {len(empty)} empty translation(s): {empty}')

        for key in sorted(set(template) & set(entries)):
            expected = placeholders(template[key])
            actual = placeholders(entries[key])
            if expected != actual:
                failures.append(
                    f'{name}: {key} placeholder mismatch — '
                    f'{template_locale}={sorted(expected)} vs '
                    f'{locale}={sorted(actual)}')

    if failures:
        print(f'FAIL: ARB parity broken ({len(failures)} issue(s))')
        for failure in failures:
            print(f'  - {failure}')
        return 1

    locales = ', '.join(sorted(locale_by_file.values()))
    print(f'PASS: {len(entries_by_file)} locale(s) [{locales}] — '
          f'{len(template)} keys each, no empty strings, placeholders match')
    return 0


if __name__ == '__main__':
    sys.exit(main())
