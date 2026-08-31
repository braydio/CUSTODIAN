#!/usr/bin/env python3
import csv
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

EXPECTED_GRID = 14
EXPECTED_ENTRIES = 196
EXPECTED_FAMILIES = 21
EXPECTED_AUTO_SAFE = 80
EXPECTED_MANUAL_ONLY = 116
DEFAULT_MANIFEST = (
    Path(__file__).resolve().parents[3]
    / "custodian/content/metadata/assets/meridian_civic_wall.semantic.json"
)
DEFAULT_REVIEW_CSV = (
    Path(__file__).resolve().parents[3]
    / "custodian/docs/asset_review/meridian_civic_wall.semantic.csv"
)
DEFAULT_GENERATOR = (
    Path(__file__).resolve().parents[3]
    / "custodian/tools/art/build_meridian_civic_wall_runtime_catalog.py"
)
DEFAULT_RUNTIME_CATALOG = (
    Path(__file__).resolve().parents[3]
    / "custodian/game/world/levels/authored/ash_bell/common/meridian_civic_wall_runtime_catalog.gd"
)
DEFAULT_COMPOSITION = (
    Path(__file__).resolve().parents[3]
    / "custodian/game/world/levels/authored/ash_bell/common/ash_bell_wall_composition_first_pass.json"
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

    if doc.get("schema") != "custodian.semantic_wall_manifest.v2":
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

        composer = entry.get("composer", {})
        if composer.get("review_state") not in {"reviewed_safe", "reviewed_manual"}:
            fail(f"{entry_id}: unresolved composer review state")
        auto_compose = composer.get("auto_compose")
        if not isinstance(auto_compose, bool):
            fail(f"{entry_id}: auto_compose must be boolean")
        ports = composer.get("ports", [])
        if auto_compose and not ports:
            fail(f"{entry_id}: auto-safe entry has no cardinal ports")
        if not auto_compose and composer.get("selection_scope") != "explicit_authored_only":
            fail(f"{entry_id}: manual entry is not fail-closed")
        if any(port not in {"N", "E", "S", "W"} for port in ports):
            fail(f"{entry_id}: invalid cardinal ports {ports}")

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

    if any(bool(e.get("review_required")) for e in entries):
        fail("v2 manifest still contains unresolved review-required entries")
    auto_count = sum(bool(e["composer"]["auto_compose"]) for e in entries)
    if auto_count != EXPECTED_AUTO_SAFE:
        fail(f"expected {EXPECTED_AUTO_SAFE} auto-safe entries, got {auto_count}")
    manual_count = len(entries) - auto_count
    if manual_count != EXPECTED_MANUAL_ONLY:
        fail(f"expected {EXPECTED_MANUAL_ONLY} manual-only entries, got {manual_count}")

    review_path = DEFAULT_REVIEW_CSV
    if not review_path.is_file():
        fail(f"missing human-review CSV: {review_path}")
    with review_path.open(newline="", encoding="utf-8-sig") as review_file:
        review_rows = list(csv.DictReader(review_file))
    if len(review_rows) != EXPECTED_ENTRIES:
        fail(
            f"expected {EXPECTED_ENTRIES} CSV review rows, "
            f"got {len(review_rows)}"
        )
    entries_by_coord = {
        tuple(entry["source_coord"]): entry
        for entry in entries
    }
    for row in review_rows:
        csv_coord = tuple(int(value) for value in row["coord"].split(","))
        entry = entries_by_coord.get(csv_coord)
        if entry is None:
            fail(f"CSV references unknown coordinate: {csv_coord}")
        entry_id = entry["id"]
        if csv_coord != tuple(entry["source_coord"]):
            fail(f"{entry_id}: CSV coordinate drifted to {csv_coord}")
        for key in ("semantic_name", "family", "geometry_class", "condition"):
            if row.get(key) != str(entry.get(key, "")):
                fail(f"{entry_id}: CSV {key} drifted")
        composer = entry["composer"]
        csv_auto = row.get("auto_compose", "").lower() == "true"
        if csv_auto != composer["auto_compose"]:
            fail(f"{entry_id}: CSV auto_compose drifted")
        csv_ports = row.get("ports", "").split("|") if row.get("ports") else []
        if csv_ports != composer["ports"]:
            fail(f"{entry_id}: CSV ports drifted")
        for key in ("topology", "review_state", "selection_scope"):
            if row.get(key) != str(composer.get(key, "")):
                fail(f"{entry_id}: CSV {key} drifted")

    composition = json.loads(DEFAULT_COMPOSITION.read_text())
    if composition.get("schema") != "custodian.authored_wall_composition.v1":
        fail("unexpected Lower Quarter wall-composition schema")
    rects = [mass.get("rect") for mass in composition.get("masses", [])]
    if rects != [[48, 66, 10, 18], [70, 68, 10, 16], [26, 55, 6, 25]]:
        fail(f"Lower Quarter authored wall masses drifted: {rects}")

    with tempfile.TemporaryDirectory() as tmp:
        generated = Path(tmp) / "catalog.gd"
        subprocess.run(
            [sys.executable, str(DEFAULT_GENERATOR), str(path), str(generated)],
            check=True,
            capture_output=True,
            text=True,
        )
        if generated.read_bytes() != DEFAULT_RUNTIME_CATALOG.read_bytes():
            fail("checked-in runtime catalog differs from deterministic generator output")
    catalog_text = DEFAULT_RUNTIME_CATALOG.read_text()
    auto_section = catalog_text.split("const AUTO_VARIANTS := {", 1)[1].split(
        "\n}\n\nstatic func", 1
    )[0]
    catalog_auto_coords = {
        (int(x), int(y))
        for x, y in re.findall(r"Vector2i\((\d+), (\d+)\)", auto_section)
    }
    expected_auto_coords = {
        tuple(entry["runtime_coord"])
        for entry in entries
        if entry["composer"]["auto_compose"]
    }
    if catalog_auto_coords != expected_auto_coords:
        fail("automatic runtime lookup contains manual-only or missing variants")

    print("[PASS] Meridian civic wall semantic manifest")
    print(f"  entries: {len(entries)}")
    print(f"  families: {len(families)}")
    print(f"  auto_safe: {auto_count}")
    print(f"  manual_only: {manual_count}")
    print("  logical grid: 14x14 complete")
    print("  runtime mapping: same-coordinate 14x14 within 16x16 atlas")
    print("  reserved runtime rows/cols 14-15: unused")
    print("  scale: 1.0")
    print("  rotation/mirroring: disabled")
    print("  human-review CSV: synchronized")
    print("  runtime catalog: deterministic")
    print("  Lower Quarter masses: 3 exact authored rectangles")

if __name__ == "__main__":
    main()
