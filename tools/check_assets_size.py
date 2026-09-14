#!/usr/bin/env python3
"""Assets size budget check.

The WP3 decision (2026-09-05): keep the hadith/tafsir DBs bundled — the
FTS index is only ~16.6 MB of the 154.5 MB hadith.db, so a diet saves
< 20% while degrading search. On-demand DB download with sha256 resume is
post-10 roadmap. This check fails CI when bundled assets regress past the
current budget. Default 230 MB: a tight gate that passes today (221.5 MB
after the tafsir SQLite consolidation: 272.2 -> 221.5) and fails on any
real regression. CI passes the same 230 explicitly; the default matches
so local runs and CI agree.

Usage: python tools/check_assets_size.py [budget_mb]
"""
import os
import sys

BUDGET_MB = float(sys.argv[1]) if len(sys.argv) > 1 else 230.0

ASSET_ROOTS = [
    'assets',
    'lib',
]


def walk(dirpath):
    total = 0
    per_dir = {}
    for root, _, files in os.walk(dirpath):
        sub = 0
        for f in files:
            try:
                size = os.path.getsize(os.path.join(root, f))
            except OSError:
                continue
            sub += size
            total += size
        if sub:
            per_dir[root] = sub
    return total, per_dir


def main():
    total = 0
    breakdown = {}
    for root in ASSET_ROOTS:
        if not os.path.isdir(root):
            continue
        t, per = walk(root)
        total += t
        for k, v in per.items():
            breakdown[k] = v

    print(f'Bundled size: {total / (1024 * 1024):.1f} MB (budget '
          f'{BUDGET_MB:.0f} MB)')
    for k, v in sorted(breakdown.items(), key=lambda kv: -kv[1])[:10]:
        print(f'  {v / (1024 * 1024):8.1f} MB  {k}')

    if total > BUDGET_MB * 1024 * 1024:
        print(f'FAIL: assets exceed the {BUDGET_MB:.0f} MB budget')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())