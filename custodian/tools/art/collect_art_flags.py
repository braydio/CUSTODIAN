#!/usr/bin/env python3
"""Read-only grouping of ArtInspector JSON flags for Codex triage.

No Dropbox access, generation, source approval, asset ingestion or scene edits.
Usage: python3 custodian/tools/art/collect_art_flags.py --dir "/absolute/flags" --format markdown
"""
from __future__ import annotations

import argparse
import json
import math
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
GEOMETRY = ROOT / "design/04_architecture/SEPULCHER_GARDENS_GEOMETRY_V1.json"
SCHEMA = "custodian.art_inspection_flag.v1"
GROUP_PX = 256


def _inside_polygon(point: tuple[float, float], polygon: list[list[float]]) -> bool:
    x, y = point
    inside = False
    for a, b in zip(polygon, polygon[1:] + polygon[:1]):
        ax, ay = a
        bx, by = b
        if (ay > y) != (by > y):
            cut = (bx - ax) * (y - ay) / (by - ay) + ax
            if x < cut:
                inside = not inside
    return inside


def _describe(flag: dict, geometry: dict) -> dict:
    x, y = map(float, flag["world_position"])
    x0, y0, w, h = geometry["envelope"]["world_rect"]
    size = geometry["cell_size_world_px"]
    result = {"region": "unclassified", "nearest_landmark": None, "mask": "outside_envelope"}
    if x0 <= x < x0 + w and y0 <= y < y0 + h:
        col = math.floor((x - x0) / size)
        row = math.floor((y - y0) / size)
        mask = geometry["walkable_mask_rows"][row][col]
        result["mask"] = "walkable" if mask == "1" else "nonwalkable"
        result["region"] = "Gardens"
        for obstacle in geometry["obstacles"]:
            if _inside_polygon((x, y), obstacle["world_polygon"]):
                result["region"] = obstacle["id"] + ": " + obstacle["name"]
                break
        nearest = min(
            geometry["landmarks"],
            key=lambda l: (l["world"][0] - x) ** 2 + (l["world"][1] - y) ** 2,
        )
        distance = math.dist((x, y), nearest["world"])
        if distance <= 384:
            result["nearest_landmark"] = nearest["id"] + ": " + nearest["name"]
    return result


def collect(directory: Path, geometry: dict) -> tuple[list[dict], list[str]]:
    flags = []
    problems = []
    for path in sorted(directory.glob("*.json")):
        try:
            flag = json.loads(path.read_text(encoding="utf-8"))
            if flag.get("schema") != SCHEMA:
                problems.append(f"{path.name}: unknown schema")
                continue
            xy = flag.get("world_position")
            if not isinstance(xy, list) or len(xy) != 2 or not all(
                isinstance(v, (float, int)) and math.isfinite(v) for v in xy
            ):
                problems.append(f"{path.name}: invalid coordinates")
                continue
            scene = str(flag.get("scene_path", "unknown"))
            x, y = map(float, xy)
            flag["classification"] = _describe(flag, geometry)
            flag["stretch"] = (
                scene,
                math.floor(x / GROUP_PX),
                math.floor(y / GROUP_PX),
            )
            flag["report_file"] = str(path.resolve())
            png = path.with_suffix(".png")
            flag["snapshot_exists"] = png.is_file()
            flags.append(flag)
        except (ValueError, OSError, TypeError, KeyError, IndexError) as exc:
            problems.append(f"{path.name}: {exc}")
    return flags, problems


def summarize(flags: list[dict], problems: list[str]) -> dict:
    groups: dict[tuple, list[dict]] = defaultdict(list)
    for flag in flags:
        groups[flag["stretch"]].append(flag)
    return {
        "schema": "custodian.art_inspection_triage.v1",
        "policy": "read_only_never_auto_promote_or_install",
        "flags": len(flags),
        "stretches": [
            {
                "scene": scene,
                "bucket": [bx, by],
                "flag_count": len(members),
                "regions": sorted({f["classification"]["region"] for f in members}),
                "flag_ids": [f["id"] for f in members],
                "report_files": [f["report_file"] for f in members],
                "snapshots_found": sum(f["snapshot_exists"] for f in members),
            }
            for (scene, bx, by), members in sorted(groups.items())
        ],
        "problems": problems,
        "next_action": "Codex reviews flag evidence, resolves exact manifest identity and human-approved source receipt, prepares a scoped install diff and validates it. No automatic download or publishing.",
    }


def markdown(summary: dict) -> str:
    lines = [
        "# CUSTODIAN Art Inspector triage (read-only)",
        "",
        f"Flags: {summary['flags']} | 256px stretches: {len(summary['stretches'])}",
        "",
        "| Scene | World bucket | Flags | Region hints | PNGs |",
        "|---|---|---:|---|---:|",
    ]
    for stretch in summary["stretches"]:
        scene = stretch["scene"].replace("|", "/")
        region = ", ".join(stretch["regions"]).replace("|", "/")
        lines.append(
            f"| `{scene}` | {stretch['bucket']} | {stretch['flag_count']} | "
            f"{region} | {stretch['snapshots_found']}/{stretch['flag_count']} |"
        )
        for flag_id, report in zip(stretch["flag_ids"], stretch["report_files"]):
            lines.append(f"  - `{flag_id}`: `{report}`")
    if summary["problems"]:
        lines += ["", "## Invalid or unreadable records"]
        lines += ["- " + str(problem) for problem in summary["problems"]]
    lines += [
        "", "## Gate",
        summary["next_action"],
        "Geometry hints are provisional design context; the binary runtime mask owns actual walkability.",
    ]
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dir", type=Path, required=True, help="Godot user://art_inspector/flags absolute folder")
    parser.add_argument("--geometry", type=Path, default=GEOMETRY)
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    args = parser.parse_args()
    if not args.dir.is_dir():
        parser.error(f"flag directory does not exist: {args.dir}")
    geometry = json.loads(args.geometry.read_text(encoding="utf-8"))
    flags, problems = collect(args.dir, geometry)
    result = summarize(flags, problems)
    print(json.dumps(result, indent=2) if args.format == "json" else markdown(result))
    return 0 if not problems else 1


if __name__ == "__main__":
    raise SystemExit(main())
