#!/usr/bin/env python3
"""Verify and optionally stage only the unapproved Sepulcher paving source candidate.

This is a dev-preview source transporter, not an Asset Pipeline V2 intake tool.
"""
from __future__ import annotations
import argparse
import hashlib
from pathlib import Path
import shutil
import sys

EXPECTED = "62341f6850cd526b5b03187d9c9035318453c2b7cf2d6e213f19f1597af967bf"
DEST_REL = Path("asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_floor_materials/paving_base_source.png")

def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path, help="extracted ZIP source/paving_base_source.png or exact raw PNG")
    parser.add_argument("--custodian", required=True, type=Path, help="path to checkout's custodian/ directory")
    parser.add_argument("--install", action="store_true", help="opt into staging verified source_work candidate (default: dry run)")
    args = parser.parse_args()
    source = args.source.expanduser().resolve(strict=True)
    root = args.custodian.expanduser().resolve(strict=True)
    assert (root / "project.godot").is_file() and (root / "asset_drop").is_dir(), "Not a Godot custodian/ project"
    assert source.is_file() and digest(source) == EXPECTED, "Input source SHA-256 mismatch"
    target = root / DEST_REL
    assert not target.is_symlink(), "Refusing symlinked target"
    if target.exists():
        assert target.is_file() and digest(target) == EXPECTED, "Existing source conflicts; refusing overwrite"
        print("PASS: same verified source already staged:", target)
        return 0
    if not args.install:
        print("DRY RUN: verified raw candidate:", source, "=>", target)
        return 0
    target.parent.mkdir(parents=True, exist_ok=True)
    assert target.parent.resolve().is_relative_to(root), "Source-work destination escapes custodian/"
    with source.open("rb") as src, target.open("xb") as dst:
        shutil.copyfileobj(src, dst)
    assert digest(target) == EXPECTED, "Staged source hash mismatch"
    print("STAGED UNAPPROVED source_work candidate:", target)
    print("NO Asset V2 inbox, ingestion, family registration or source art approval.")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError) as exc:
        print("BLOCKED:", exc, file=sys.stderr)
        raise SystemExit(2)
