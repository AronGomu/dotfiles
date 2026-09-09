#!/usr/bin/env python3
"""Small redacted offline guard; not a substitute for full secret/privacy review."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SKIP = {'.git', '.tmp', '__pycache__'}
PATTERNS = {
    'private-key': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
    'github-token': re.compile(r'\bgh[pousr]_[A-Za-z0-9]{30,}\b|\bgithub_pat_[A-Za-z0-9_]{30,}\b'),
    'api-token': re.compile(r'\bsk-(?:proj-|ant-)?[A-Za-z0-9_-]{24,}\b'),
    'aws-access-id': re.compile(r'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b'),
    'credential-url': re.compile(r'https?://[^\s/@:]+:[^\s/@]+@'),
    'private-message-url': re.compile(r'facebook\.com/messages/(?:e2ee/)?t/\d+|discord\.com/channels/\d+/\d+'),
    'jwt': re.compile(r'\beyJ[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}'),
}
PRIVATE_NAMES = {'auth.json', 'auth.toml', 'credentials.json', 'rclone.conf',
                 'trust.json', 'models-store.json', '.env'}


def findings(root):
    hits = []
    count = 0
    for path in sorted(root.rglob('*')):
        rel = path.relative_to(root)
        if any(part in SKIP for part in rel.parts) or not path.is_file():
            continue
        count += 1
        if path.name in PRIVATE_NAMES or path.suffix in {'.pem', '.key', '.kdbx', '.p12', '.pfx'}:
            hits.append((str(rel), 0, 'private-state-file'))
        try:
            text = path.read_text()
        except UnicodeDecodeError:
            continue
        for line_no, line in enumerate(text.splitlines(), 1):
            for label, pattern in PATTERNS.items():
                if pattern.search(line):
                    hits.append((str(rel), line_no, label))
    return count, hits


def main():
    count, hits = findings(ROOT)
    for path, line, label in hits:
        # Paths, line numbers, rule IDs only. Never emit matched values.
        print(f'{path}:{line}: {label} [REDACTED]')
    print(f'Secret guard: {count} files; {len(hits)} findings. Pattern-only; manual review required.')
    return bool(hits)


if __name__ == '__main__':
    sys.exit(main())
