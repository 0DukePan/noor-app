#!/usr/bin/env python3
"""Extracts the startup benchmark lines from an integration-test log.

The integration suite prints `STARTUP first-frame: <ms>` and
`STARTUP interactive: <ms>` (integration_test/app_test.dart); CI captures the
full log and runs this script to publish the numbers into the job summary, so
every run records what it measured instead of relying on someone noticing a
slowdown. The pass/fail gate lives in the test's own assertions.

Usage: python tools/perf_summary.py <log-file>
Exit codes: always 0 — this step reports, it does not gate.
"""
import re
import sys

LINE = re.compile(r'^STARTUP (?P<metric>[a-z-]+): (?P<value>\d+)ms\s*$')


def main() -> int:
    if len(sys.argv) < 2:
        print('usage: python tools/perf_summary.py <log-file>')
        return 0

    try:
        with open(sys.argv[1], encoding='utf-8', errors='replace') as fh:
            lines = fh.readlines()
    except OSError as error:
        print(f'(no integration log to summarize: {error})')
        return 0

    measurements = {}
    for line in lines:
        match = LINE.match(line.strip())
        if match:
            measurements[match.group('metric')] = int(match.group('value'))

    if not measurements:
        print('(no STARTUP benchmark lines found in the integration log)')
        return 0

    print('| Metric | This run | CI ceiling |')
    print('|---|---|---|')
    ceilings = {'first-frame': 120000, 'interactive': 180000}
    for metric, value in sorted(measurements.items()):
        ceiling = ceilings.get(metric)
        ceiling_text = f'{ceiling} ms' if ceiling else '—'
        print(f'| {metric} | {value} ms | {ceiling_text} |')
    return 0


if __name__ == '__main__':
    sys.exit(main())
