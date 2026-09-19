#!/usr/bin/env python3
"""CycloneDX SBOM generator for the locked dependency set.

The Dart/Flutter ecosystem has no polished first-party SBOM tool, so this
walks pubspec.lock (a small, stable YAML shape) and emits CycloneDX 1.5 JSON.
CI uploads the result as a build artifact on every push; a release can attach
it to the store submission.

Usage: python tools/generate_sbom.py [--output build/sbom.cdx.json]
                                       [--pretty]
Exit codes: 0 ok, 1 lockfile missing/unreadable.
"""
import argparse
import datetime
import json
import os
import re
import sys
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOCK = os.path.join(ROOT, 'pubspec.lock')
PUBSPEC = os.path.join(ROOT, 'pubspec.yaml')

PACKAGE_RE = re.compile(r'^  ([A-Za-z0-9_]+):\s*$')
FIELD_RE = re.compile(r'^    ([a-z_]+):\s*(.*)$')
DESC_FIELD_RE = re.compile(r'^      ([a-z_]+):\s*(.*)$')


def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in '\'"':
        return value[1:-1]
    return value


def parse_packages():
    with open(LOCK, encoding='utf-8') as fh:
        lines = fh.readlines()

    packages = []
    current = None
    in_description = False
    for line in lines:
        match = PACKAGE_RE.match(line)
        if match:
            current = {'name': match.group(1)}
            packages.append(current)
            in_description = False
            continue
        if current is None:
            continue
        stripped = line.strip()
        if stripped == 'description:':
            in_description = True
            continue
        if in_description and line.startswith('      '):
            desc = DESC_FIELD_RE.match(line)
            if desc:
                if desc.group(1) == 'name':
                    current['real_name'] = unquote(desc.group(2))
                elif desc.group(1) == 'sha256':
                    current['sha256'] = unquote(desc.group(2))
            continue
        if line.startswith('    ') and not line.startswith('      '):
            in_description = False
            field = FIELD_RE.match(line)
            if field:
                current[field.group(1)] = unquote(field.group(2))
    return packages


def app_metadata():
    name, version = 'noor_app', None
    if os.path.exists(PUBSPEC):
        with open(PUBSPEC, encoding='utf-8') as fh:
            for line in fh:
                if line.startswith('name:'):
                    name = line.split(':', 1)[1].strip()
                elif line.startswith('version:'):
                    version = line.split(':', 1)[1].strip()
    return name, version


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', default='-',
                        help='output path, or - for stdout (default)')
    parser.add_argument('--pretty', action='store_true',
                        help='indent the JSON (default: compact)')
    args = parser.parse_args()

    if not os.path.exists(LOCK):
        print(f'FAIL: {LOCK} not found — run `flutter pub get` first')
        return 1

    packages = parse_packages()
    if not packages:
        print('FAIL: pubspec.lock parsed to zero packages')
        return 1

    app_name, app_version = app_metadata()
    timestamp = (
        datetime.datetime.now(datetime.timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace('+00:00', 'Z')
    )

    components = []
    for package in sorted(packages, key=lambda p: p.get('real_name', p['name'])):
        name = package.get('real_name', package['name'])
        version = package.get('version')
        if not version:
            continue
        component = {
            'type': 'library',
            'bom-ref': f'pkg:pub/{name}@{version}',
            'name': name,
            'version': version,
            'scope': 'required' if package.get('dependency', '').endswith('main')
            else 'optional',
            'purl': f'pkg:pub/{name}@{version}',
            'properties': [
                {'name': 'pub:dependency', 'value': package.get('dependency', 'unknown')},
                {'name': 'pub:source', 'value': package.get('source', 'unknown')},
            ],
        }
        if package.get('sha256'):
            component['hashes'] = [
                {'alg': 'SHA-256', 'content': package['sha256']},
            ]
        components.append(component)

    bom = {
        'bomFormat': 'CycloneDX',
        'specVersion': '1.5',
        'serialNumber': f'urn:uuid:{uuid.uuid4()}',
        'version': 1,
        'metadata': {
            'timestamp': timestamp,
            'tools': [
                {'vendor': app_name, 'name': 'tools/generate_sbom.py'},
            ],
            'component': {
                'type': 'application',
                'bom-ref': f'pkg:pub/{app_name}@{app_version or "0.0.0"}',
                'name': app_name,
                'version': app_version or '0.0.0',
                'purl': f'pkg:pub/{app_name}@{app_version or "0.0.0"}',
            },
        },
        'components': components,
    }

    body = json.dumps(bom, indent=2 if args.pretty else None, sort_keys=False)
    if args.output == '-':
        print(body)
    else:
        out = os.path.abspath(args.output)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, 'w', encoding='utf-8') as fh:
            fh.write(body + '\n')
        direct = sum(
            1 for p in packages
            if p.get('dependency', '').startswith('direct main')
        )
        print(
            f'SBOM: {len(components)} components '
            f'({direct} direct, {len(components) - direct} transitive) '
            f'-> {args.output}'
        )
    return 0


if __name__ == '__main__':
    sys.exit(main())
