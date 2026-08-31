#!/usr/bin/env python3
import json
import sys
from pathlib import Path

EXPECTED_GRID = 14
EXPECTED_ENTRIES = 196
EXPECTED_FAMILIES = 21
EXPECTED_REVIEW_REQUIRED = 43
DEFAULT_MANIFEST = (
    Path(__file__).resolve().parents[3]
    / "custodian/content/metadata/assets/meridian_civic_wall.semantic.json"
)

def fail(message: str) -> None:
    raise SystemExit(f"[FAIL] {message}")

def main() -> None:
    if len(sys.argv) > 2:
        raise SystemExit(
            "usage: meridian_civic_wall_semantic_manifest_smoke.py "
            "[meridian_civic_wall.semantic.json]"
        )

    path = Path(sys.argv[1]) if len(sys.argv) == 2 else DEFAULT_MANIFEST
    doc = json.loads(path.read_text())

    if doc.get("schema") != "custodian.semantic_wall_manifest.v1":
        fail(f"unexpected schema: {doc.get('schema')}")

    entries = doc.get("entries", [])
    if len(entries) != EXPECTED_ENTRIES:
        fail(f"expected {EXPECTED_ENTRIES} entries, got {len(entries)}")

    coords = set()
    ids = set()

    families = doc.get("families", {})
    if len(families) != EXPECTED_FAMILIES:
        fail(f"expected {EXPECTED_FAMILIES} families, got {len(families)}")

    source_master = doc.get("source_master", {})
    if source_master.get("size_px") != [1254, 1254]:
        fail(f"unexpected source master size: {source_master.get('size_px')}")
    if source_master.get("logical_grid") != [EXPECTED_GRID, EXPECTED_GRID]:
        fail(f"unexpected logical grid: {source_master.get('logical_grid')}")

    runtime_atlas = doc.get("runtime_atlas", {})
    if runtime_atlas.get("size_px") != [512, 512]:
        fail(f"unexpected runtime atlas size: {runtime_atlas.get('size_px')}")
    if runtime_atlas.get("grid") != [16, 16]:
        fail(f"unexpected runtime atlas grid: {runtime_atlas.get('grid')}")
    if runtime_atlas.get("cell_px") != [32, 32]:
        fail(f"unexpected runtime cell size: {runtime_atlas.get('cell_px')}")

    for entry in entries:
        entry_id = entry.get("id")
        if not entry_id or entry_id in ids:
            fail(f"duplicate/missing id: {entry_id}")
        ids.add(entry_id)

        source = tuple(entry.get("source_coord", []))
        runtime = tuple(entry.get("runtime_coord", []))

        if len(source) != 2:
            fail(f"{entry_id}: invalid source_coord {source}")
        if source in coords:
            fail(f"{entry_id}: duplicate source coord {source}")
        coords.add(source)

        x, y = source
        if not (0 <= x < EXPECTED_GRID and 0 <= y < EXPECTED_GRID):
            fail(f"{entry_id}: out-of-range logical coord {source}")

        if runtime != source:
            fail(
                f"{entry_id}: runtime coord {runtime} must equal "
                f"logical source coord {source}"
            )

        if x >= 14 or y >= 14:
            fail(f"{entry_id}: references reserved runtime row/column {runtime}")

        if entry.get("scale") != [1.0, 1.0]:
            fail(f"{entry_id}: runtime scale must remain [1.0, 1.0]")

        if entry.get("rotation_allowed") is not False:
            fail(f"{entry_id}: runtime rotation must fail closed")

        if entry.get("mirror_allowed") is not False:
            fail(f"{entry_id}: runtime mirroring must fail closed")

        family = entry.get("family")
        if family not in families:
            fail(f"{entry_id}: unknown family {family}")

    expected_coords = {
        (x, y)
        for y in range(EXPECTED_GRID)
        for x in range(EXPECTED_GRID)
    }
    if coords != expected_coords:
        missing = sorted(expected_coords - coords)
        extra = sorted(coords - expected_coords)
        fail(f"coordinate coverage mismatch missing={missing} extra={extra}")

    # Validate family member references.
    family_coords = set()
    for family_id, family in families.items():
        members = family.get("members", [])
        for coord in members:
            t = tuple(coord)
            if t not in expected_coords:
                fail(f"{family_id}: invalid family member coord {coord}")
            family_coords.add(t)

    if family_coords != expected_coords:
        fail("family member union does not cover all 196 logical modules")

    review_count = sum(bool(e.get("review_required")) for e in entries)
    if review_count != EXPECTED_REVIEW_REQUIRED:
        fail(
            f"expected {EXPECTED_REVIEW_REQUIRED} review-required entries, "
            f"got {review_count}"
        )

    print("[PASS] Meridian civic wall semantic manifest")
    print(f"  entries: {len(entries)}")
    print(f"  families: {len(families)}")
    print(f"  review_required: {review_count}")
    print("  logical grid: 14x14 complete")
    print("  runtime mapping: same-coordinate 14x14 within 16x16 atlas")
    print("  reserved runtime rows/cols 14-15: unused")
    print("  scale: 1.0")
    print("  rotation/mirroring: disabled")

if __name__ == "__main__":
    main()
