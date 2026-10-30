#!/usr/bin/env python3
"""Check explicitly authored task packet categories against the shared registry.

Read-only authoring aid: never changes packets, the queue or Git refs.
Usage: python3 custodian/tools/agent/check_packet_categories.py path/to/PACKET.md [...]
"""
import argparse
import json
from pathlib import Path
import re
import sys

REPO = Path(__file__).resolve().parents[3]
MANIFEST = REPO / 'custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json'
FIELD = re.compile(r'^- Category:\\s*`?([a-z0-9]+(?:-[a-z0-9]+)*)`?\\s*$')


def check_packet(text, ids):
    head = text.split('\\n\\n', 1)[0]
    category_lines = [line for line in head.splitlines() if line.startswith('- Category:')]
    if len(category_lines) != 1:
        raise ValueError('expected exactly one Category header')
    m = FIELD.fullmatch(category_lines[0])
    if not m or m.group(1) not in ids:
        raise ValueError('Category must be one exact ID from TASK_PACKET_CATEGORIES.json')
    return m.group(1)


def main(argv=None):
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument('packets', nargs='+', type=Path)
    parsed = args.parse_args(argv)
    registry = json.loads(MANIFEST.read_text(encoding='utf-8'))
    if registry.get('schema') != 'custodian.packet_categories.v1':
        raise ValueError('unexpected taxonomy schema')
    ids = [c['id'] for c in registry['categories']]
    if len(ids) != len(set(ids)) or not ids:
        raise ValueError('duplicate/empty taxonomy')
    failed = False
    for path in parsed.packets:
        try:
            category = check_packet(path.read_text(encoding='utf-8'), set(ids))
            print(f'OK {path}: {category}')
        except (OSError, ValueError) as error:
            failed = True
            print(f'INVALID {path}: {error}', file=sys.stderr)
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
