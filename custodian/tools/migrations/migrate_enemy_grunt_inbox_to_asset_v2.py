#!/usr/bin/env python3
"""Inventory and explicitly migrate legacy enemy_grunt inbox PNGs into Asset V2."""
from __future__ import annotations

import argparse
from dataclasses import replace
import hashlib
import json
import shutil
import sys
from pathlib import Path
from PIL import Image

PROJECT_DIR = Path(__file__).resolve().parents[2]
REPO_DIR = PROJECT_DIR.parent
ASSET_TOOLS = PROJECT_DIR / "tools/assets"
if str(ASSET_TOOLS) not in sys.path:
    sys.path.insert(0, str(ASSET_TOOLS))

from asset_naming import canonical_filename, parse_canonical_filename

SOURCE = PROJECT_DIR / "content/sprites/_pipeline/inbox"
DESTINATION = PROJECT_DIR / "asset_drop/inbox/enemy_grunt"
RUNTIME = PROJECT_DIR / "content/sprites/enemies/enemy_grunt/runtime"


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _identity(path: Path) -> tuple[str, ...] | None:
    try:
        return parse_canonical_filename(path.name, "enemy").semantic_identity
    except (TypeError, ValueError):
        return None


def build_inventory() -> list[dict]:
    runtime_by_identity: dict[tuple[str, ...], list[Path]] = {}
    for runtime_path in sorted(RUNTIME.rglob("*.png")):
        identity = _identity(runtime_path)
        if identity is not None:
            runtime_by_identity.setdefault(identity, []).append(runtime_path)

    rows: list[dict] = []
    for source in sorted(SOURCE.glob("enemy_grunt*.png")):
        identity = _identity(source)
        if identity is None:
            rows.append({"source": source.relative_to(REPO_DIR).as_posix(), "blocked": "malformed canonical filename"})
            continue
        key = parse_canonical_filename(source.name, "enemy")
        with Image.open(source) as image:
            physical_size = image.size
        physical_frames = physical_size[0] // key.frame_width if physical_size[1] == key.frame_height and physical_size[0] % key.frame_width == 0 else 0
        matches = runtime_by_identity.get(identity, [])
        source_hash = _sha(source)
        runtime_matches = [
            {
                "path": path.relative_to(REPO_DIR).as_posix(),
                "sha256": _sha(path),
                "exact_duplicate": _sha(path) == source_hash,
            }
            for path in matches
        ]
        destination_name = source.name
        canonicalized = False
        if physical_frames > 0 and physical_frames != key.frames:
            destination_name = canonical_filename(replace(key, frames=physical_frames))
            canonicalized = True
        rows.append({
            "source": source.relative_to(REPO_DIR).as_posix(),
            "destination": (DESTINATION / destination_name).relative_to(REPO_DIR).as_posix(),
            "semantic_identity": list(identity),
            "frames": key.frames,
            "physical_frames": physical_frames,
            "physical_size": list(physical_size),
            "frame_size": [key.frame_width, key.frame_height],
            "sha256": source_hash,
            "layer": key.layer,
            "body_fx_pair": _paired_identity_exists(identity),
            "runtime_matches": runtime_matches,
            "classification": "new" if not matches else ("duplicate" if any(item["exact_duplicate"] for item in runtime_matches) else "replacement"),
            "auto_mirror": key.direction in {"e", "w", "ne", "nw", "se", "sw"},
            "supersession_safe": False if matches else True,
            "safety_reason": "consumer scan required before semantic replacement" if matches else "no current runtime semantic generation",
            "canonicalized_frame_token": canonicalized,
        })
        if physical_frames <= 0:
            rows[-1]["blocked"] = "declared frame count does not match physical PNG"
    return rows


def _paired_identity_exists(identity: tuple[str, ...]) -> bool:
    owner, kind, layer, group, variant, direction = identity
    paired_layer = "fx" if layer == "body" else "body" if layer == "fx" else ""
    if not paired_layer:
        return False
    expected = (owner, kind, paired_layer, group, variant, direction)
    return any(
        _identity(path) == expected
        for root in (SOURCE, DESTINATION)
        for path in root.glob("enemy_grunt*.png")
    )


def apply_migration(rows: list[dict], *, quiet: bool = False) -> None:
    DESTINATION.mkdir(parents=True, exist_ok=True)
    for row in rows:
        if row.get("blocked"):
            print(f"BLOCKED {row['source']}: {row['blocked']}")
            continue
        source = REPO_DIR / row["source"]
        destination = REPO_DIR / row["destination"]
        if destination.exists():
            if _sha(destination) == _sha(source):
                source.unlink()
                sidecar = source.with_suffix(source.suffix + ".import")
                if sidecar.exists():
                    sidecar.unlink()
                if not quiet:
                    print(f"REMOVED migrated duplicate source: {source.relative_to(REPO_DIR)}")
                continue
            raise RuntimeError(f"destination conflict: {destination.relative_to(REPO_DIR)}")
        shutil.move(str(source), str(destination))
        if not quiet:
            print(f"MOVED {source.relative_to(REPO_DIR)} -> {destination.relative_to(REPO_DIR)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="Move the inventoried authored PNGs")
    parser.add_argument("--json", action="store_true", help="Emit only machine-readable inventory JSON")
    args = parser.parse_args()
    rows = build_inventory()
    if args.json or not args.apply:
        print(json.dumps({"schema": "custodian.enemy_grunt_asset_v2_migration.v1", "assets": rows}, indent=2))
    if args.apply:
        apply_migration(rows, quiet=args.json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
