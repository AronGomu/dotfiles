#!/usr/bin/env python3
"""Offline native-source checks. No app bootstrap, dependency install, HOME changes."""
import ast
from collections import Counter
import configparser
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tomllib
import xml.etree.ElementTree as ET

from desktop_exec import validate_exec
from secret_scan import findings

ROOT = Path(__file__).resolve().parents[1]
SKIP = {'.git', '.tmp', '__pycache__'}
counts = Counter()
failures = []


def fail(path, detail):
    failures.append(f'{path}: {detail}')


def main():
    files = [p for p in sorted(ROOT.rglob('*'))
             if p.relative_to(ROOT).parts[0] != '.pi-subagents'
             and not any(s in SKIP for s in p.relative_to(ROOT).parts) and p.is_file()]
    for path in ROOT.rglob('*'):
        rel = path.relative_to(ROOT)
        if rel.parts[0] != '.pi-subagents' and not any(s in SKIP for s in rel.parts) and path.is_symlink():
            fail(rel, 'symlink in source export')
    ignored = subprocess.run(['git', '-C', str(ROOT), 'check-ignore', '--stdin'],
                             input='\n'.join(str(p.relative_to(ROOT)) for p in files) + '\n',
                             capture_output=True, text=True)
    for path in ignored.stdout.splitlines():
        fail(path, 'deliverable ignored by Git')
    for path in files:
        rel = path.relative_to(ROOT)
        if path.suffix == '.nix':
            fail(rel, 'framework source excluded')
        try:
            text = path.read_text()
        except UnicodeDecodeError:
            counts['binary assets'] += 1
            continue
        try:
            if path.suffix == '.json':
                json.loads(text)
                counts['JSON'] += 1
            elif path.suffix == '.toml':
                tomllib.loads(text)
                counts['TOML'] += 1
            elif path.suffix in {'.xbel'}:
                ET.fromstring(text)
                counts['XML'] += 1
            elif path.suffix in {'.service', '.path'}:
                parser = configparser.ConfigParser(interpolation=None, strict=False)
                parser.read_string(text)
                assert parser.has_section('Unit')
                assert parser.has_section('Service') or parser.has_section('Path')
                counts['unit templates'] += 1
            elif path.suffix == '.desktop':
                parser = configparser.ConfigParser(interpolation=None)
                parser.read_string(text)
                assert parser['Desktop Entry']['Type'] == 'Application'
                validate_exec(parser['Desktop Entry']['Exec'])
                counts['desktop entries'] += 1
            if path.suffix == '.py' or (rel.parts[0] == 'bin' and 'python' in text.splitlines()[0]) or path.name == 'ytmusic-sync':
                ast.parse(text, filename=str(rel))
                counts['Python'] += 1
            if path.suffix == '.sh' or text.startswith('#!/usr/bin/env bash'):
                result = subprocess.run(['bash', '-n', str(path)], capture_output=True, text=True)
                if result.returncode:
                    fail(rel, 'Bash syntax failed')
                counts['Bash'] += 1
            executable = path.suffix in {'.lua', '.ts', '.js', '.sh', '.py', '.desktop'} or rel.parts[0] == 'bin'
            if executable and rel.parts[0] in {'config', 'bin', 'desktop', 'services'}:
                if re.search(r'/home/aron(?:/|\b)|/nix/store/|/etc/profiles/per-user/|/run/current-system/|/run/opengl-driver/', text):
                    fail(rel, 'old host executable path')
            if rel.parts[0] in {'config', 'bin', 'desktop', 'services'} and 'dev-config' in text:
                fail(rel, 'superseded repo name')
        except (ValueError, SyntaxError, AssertionError, configparser.Error):
            fail(rel, 'native source parse failed (value suppressed)')
    # All ordinary source groups must be mapped; no accidental runtime dump.
    allowed = {'config', 'vendor', 'bin', 'desktop', 'services', 'manifests', 'docs', 'scripts', 'tests'}
    root_files = {'README.md', 'AGENTS.md', '.gitignore'}
    for path in files:
        rel = path.relative_to(ROOT)
        if rel.parts[0] not in allowed and str(rel) not in root_files:
            fail(rel, 'unmapped source group')
    for row in (ROOT / 'manifests/coverage.tsv').read_text().splitlines():
        if not row or row.startswith('#'):
            continue
        criterion, paths = row.split('\t')
        for name in paths.split(';'):
            if not (ROOT / name).exists():
                fail(criterion, 'missing coverage path ' + name)
        counts['coverage rows'] += 1
    for name in ('grok-imagine', 'nix-aron', '.system', '.pi', '.pi-subagents'):
        if (ROOT / 'config/agents/skills' / name).exists():
            fail(name, 'excluded/duplicate skill discovery')
    if (ROOT / 'bin/grok-imagine').exists():
        fail('bin/grok-imagine', 'excluded CLI')
    for path in (ROOT / 'bin').iterdir():
        if not os.access(path, os.X_OK):
            fail(path.name, 'entrypoint not executable')
    for path in (ROOT / 'config/agents/skills').glob('*/SKILL.md'):
        text = path.read_text()
        if not text.startswith('---\n') or '\nname: ' + path.parent.name + '\n' not in text:
            fail(path.relative_to(ROOT), 'skill name/frontmatter mismatch')
        counts['shared skills'] += 1
    _, secrets = findings(ROOT)
    for path, line, rule in secrets:
        fail(f'{path}:{line}', f'{rule} [REDACTED]')
    counts['secret findings'] = len(secrets)
    counts['files'] = len(files)
    for key, value in sorted(counts.items()):
        print(f'{key}: {value}')
    for message in failures:
        print('FAIL: ' + message)
    print('PASS: offline source validation' if not failures else f'FAIL: {len(failures)} checks')
    return bool(failures)


if __name__ == '__main__':
    sys.exit(main())
