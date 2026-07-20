#!/usr/bin/env python3
"""
Audit CUSTODIAN operator modular sprite sources.

Default roots tried from repo root:
  custodian/content/sprites/operator/new_operator/modular
  content/sprites/operator/new_operator/modular
  sprites/operator/new_operator/modular

Examples:
  python3 check_operator_modular_assets.py
  python3 check_operator_modular_assets.py --root sprites/operator/new_operator/modular
  python3 check_operator_modular_assets.py --write-default-expected operator_expected_assets.json
  python3 check_operator_modular_assets.py --expected-json operator_expected_assets.json --md-out operator_asset_audit.md
"""
from __future__ import annotations

import argparse
import json
import re
import struct
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

DIRS8 = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
DIR_ORDER = {d: i for i, d in enumerate(DIRS8 + ["omni"])}
VALID_DIRS = set(DIR_ORDER)
ROOT_CANDIDATES = [
    "custodian/content/sprites/operator/new_operator/modular",
    "content/sprites/operator/new_operator/modular",
    "sprites/operator/new_operator/modular",
]

# Keep this editable. Export it with --write-default-expected, then maintain the JSON
# instead of editing the script every time the target animation suite changes.
EXPECTED_SETS: list[dict[str, Any]] = [
    # Combat gaps currently tracked for modular operator.
    dict(id="fast_strike_lower_ns", folder="fast_attack", layer="modular_lower_body", loadout="unarmed", action="fast_strike_01", directions=["n", "s"], frames=3, frame_size=96, status="needed"),
    dict(id="fast_windup_upper_fx_all", folder="fast_attack", layer="modular_upper_fx", loadout="unarmed", action="fast_windup_01", directions=DIRS8, frames=3, frame_size=96, status="needed"),
    dict(id="parry_start_lower_all", folder="parry", layer="modular_lower_body", loadout="unarmed", action="parry_start_01", directions=DIRS8, frames=4, frame_size=96, status="needed"),
    dict(id="parry_start_upper_all", folder="parry", layer="modular_upper_body", loadout="unarmed", action="parry_start_01", directions=DIRS8, frames=4, frame_size=96, status="needed"),
    dict(id="parry_success_upper_all", folder="parry", layer="modular_upper_body", loadout="unarmed", action="parry_success_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),
    dict(id="parry_recovery_upper_all", folder="parry", layer="modular_upper_body", loadout="unarmed", action="parry_recovery_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),
    dict(id="parry_fx_all", folder="parry", layer="modular_upper_fx", loadout="unarmed", action="parry_fx_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),

    # Locomotion/fallback gaps currently tracked for modular operator.
    dict(id="lower_action_fallback_all", folder="lower", layer="modular_lower_body", loadout="unarmed", action="action_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),
    dict(id="upper_action_fallback_all", folder="upper", layer="modular_upper_body", loadout="unarmed", action="action_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),
    dict(id="lower_idle_ne_nw", folder="idle", layer="modular_lower_body", loadout="unarmed", action="idle_01", directions=["ne", "nw"], frames=5, frame_size=96, status="needed"),
    dict(id="upper_idle_all", folder="idle", layer="modular_upper_body", loadout="unarmed", action="idle_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),
    dict(id="lower_walk_missing", folder="walk", layer="modular_lower_body", loadout="unarmed", action="walk_01", directions=["n", "ne", "s", "se", "sw", "nw"], frames=5, frame_size=96, status="needed"),
    dict(id="upper_walk_all", folder="walk", layer="modular_upper_body", loadout="unarmed", action="walk_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),
    dict(id="upper_run_ne_nw", folder="run", layer="modular_upper_body", loadout="unarmed", action="run_01", directions=["ne", "nw"], frames=5, frame_size=96, status="needed"),

    # Full dodge lives in this modular source tree even though filename layer is body/fx, not modular_*.
    dict(id="dodge_body_remaining", folder="dodge", layer="body", loadout="full", action="dodge_01", directions=["ne", "e", "se", "sw", "w", "nw"], frames=9, frame_size=96, status="needed"),
    dict(id="dodge_fx_remaining", folder="dodge", layer="fx", loadout="full", action="dodge_01", directions=["ne", "e", "se", "sw", "w", "nw"], frames=9, frame_size=96, status="needed"),
]

BASELINE_SETS: list[dict[str, Any]] = [
    dict(id="dodge_body_existing_ns", folder="dodge", layer="body", loadout="full", action="dodge_01", directions=["n", "s"], frames=9, frame_size=96, status="baseline"),
    dict(id="dodge_fx_existing_ns", folder="dodge", layer="fx", loadout="full", action="dodge_01", directions=["n", "s"], frames=9, frame_size=96, status="baseline"),
]

@dataclass(frozen=True)
class Expected:
    set_id: str
    status: str
    rel_path: str
    filename: str
    layer: str
    loadout: str
    action: str
    direction: str
    frames: int
    frame_size: int

    @property
    def key(self) -> tuple[str, str, str, str, int, int]:
        return (self.layer, self.loadout, self.action, self.direction, self.frames, self.frame_size)

    @property
    def expected_wh(self) -> tuple[int, int]:
        return (self.frames * self.frame_size, self.frame_size)

@dataclass
class Found:
    rel_path: str
    filename: str
    layer: str
    loadout: str
    action: str
    direction: str
    frames: int
    frame_size: int
    width: int | None
    height: int | None
    warning: str | None = None

    @property
    def key(self) -> tuple[str, str, str, str, int, int]:
        return (self.layer, self.loadout, self.action, self.direction, self.frames, self.frame_size)

    @property
    def declared_wh(self) -> tuple[int, int]:
        return (self.frames * self.frame_size, self.frame_size)

@dataclass
class Bad:
    rel_path: str
    filename: str
    reason: str

def filename(layer: str, loadout: str, action: str, direction: str, frames: int, frame_size: int) -> str:
    return f"operator__{layer}__{loadout}__{action}__{direction}__{frames}f__{frame_size}.png"

def expand_expected(sets: list[dict[str, Any]]) -> list[Expected]:
    out: list[Expected] = []
    for s in sets:
        folder = str(s.get("folder", "")).strip("/")
        for d in s["directions"]:
            if d not in VALID_DIRS:
                raise ValueError(f"{s['id']}: invalid direction {d}")
            fn = filename(s["layer"], s["loadout"], s["action"], d, int(s["frames"]), int(s["frame_size"]))
            rel = f"{folder}/{fn}" if folder else fn
            out.append(Expected(str(s["id"]), str(s.get("status", "needed")), rel, fn, s["layer"], s["loadout"], s["action"], d, int(s["frames"]), int(s["frame_size"])))
    return out

def png_size(path: Path) -> tuple[int | None, int | None]:
    try:
        data = path.read_bytes()[:24]
        if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
            return None, None
        return struct.unpack(">II", data[16:24])
    except OSError:
        return None, None

def parse_found(path: Path, root: Path) -> Found | Bad | None:
    if path.suffix.lower() != ".png" or not path.name.startswith("operator__"):
        return None
    rel = path.relative_to(root).as_posix()
    parts = path.stem.split("__")
    if len(parts) < 7:
        return Bad(rel, path.name, "noncanonical name; expected operator__<layer>__<loadout>__<action>__<dir>__<frames>f__<size>.png")
    owner, layer, loadout = parts[0], parts[1], parts[2]
    action = "__".join(parts[3:-3])
    direction, frames_token, size_token = parts[-3], parts[-2], parts[-1]
    if owner != "operator":
        return Bad(rel, path.name, "owner token is not operator")
    if not action:
        return Bad(rel, path.name, "empty action token; probable missing loadout token")
    if direction not in VALID_DIRS:
        return Bad(rel, path.name, f"bad direction token: {direction}")
    if not re.fullmatch(r"\d+f", frames_token):
        return Bad(rel, path.name, f"bad frames token: {frames_token}")
    if not re.fullmatch(r"\d+", size_token):
        return Bad(rel, path.name, f"bad frame-size token: {size_token}")
    w, h = png_size(path)
    warning = None
    if layer.startswith("modular_") and loadout in {"idle", "walk", "run", "lower", "upper"}:
        warning = "loadout token looks like an action/folder; filename may be missing loadout, usually unarmed"
    return Found(rel, path.name, layer, loadout, action, direction, int(frames_token[:-1]), int(size_token), w, h, warning)

def choose_root(arg: str | None) -> Path:
    if arg:
        root = Path(arg)
        if not root.exists():
            raise SystemExit(f"ERROR: root does not exist: {root}")
        return root
    for c in ROOT_CANDIDATES:
        p = Path(c)
        if p.exists():
            return p
    raise SystemExit("ERROR: could not find modular root; pass --root. Tried:\n  " + "\n  ".join(ROOT_CANDIDATES))

def scan(root: Path) -> tuple[list[Found], list[Bad]]:
    found: list[Found] = []
    bad: list[Bad] = []
    for p in sorted(root.rglob("*.png")):
        r = parse_found(p, root)
        if isinstance(r, Found):
            found.append(r)
        elif isinstance(r, Bad):
            bad.append(r)
    return found, bad

def dirsort(xs: list[str]) -> list[str]:
    return sorted(xs, key=lambda d: DIR_ORDER.get(d, 999))

def load_sets(path: str | None, include_baseline: bool) -> list[dict[str, Any]]:
    if path:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
        sets = data["sets"] if isinstance(data, dict) and "sets" in data else data
        if not isinstance(sets, list):
            raise SystemExit("ERROR: expected-json must be a list or {'sets': [...]} object")
        return sets
    sets = list(EXPECTED_SETS)
    if include_baseline:
        sets.extend(BASELINE_SETS)
    return sets

def write_default_expected(path: str, include_baseline: bool) -> None:
    sets = list(EXPECTED_SETS)
    if include_baseline:
        sets.extend(BASELINE_SETS)
    payload = {
        "schema": "custodian.operator_modular_expected_assets.v1",
        "notes": [
            "Edit sets when the expected operator modular suite changes.",
            "Each set expands directions into concrete filenames.",
        ],
        "sets": sets,
    }
    Path(path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

def evaluate(root: Path, expected: list[Expected]) -> dict[str, Any]:
    found, bad = scan(root)
    by_rel = {f.rel_path: f for f in found}
    by_name: dict[str, list[Found]] = {}
    for f in found:
        by_name.setdefault(f.filename, []).append(f)

    missing, wrong_path, dim_bad = [], [], []
    expected_keys = {e.key for e in expected}
    for e in expected:
        f = by_rel.get(e.rel_path)
        if f:
            if f.width is not None and f.height is not None and (f.width, f.height) != e.expected_wh:
                dim_bad.append({"expected": asdict(e), "found": asdict(f), "reason": f"expected {e.expected_wh[0]}x{e.expected_wh[1]}, got {f.width}x{f.height}"})
            continue
        if e.filename in by_name:
            wrong_path.append({"expected": asdict(e), "found_paths": [x.rel_path for x in by_name[e.filename]]})
        else:
            missing.append(asdict(e))

    unexpected = [asdict(f) for f in found if f.key not in expected_keys]
    warnings = [asdict(f) for f in found if f.warning]
    declared_dim_bad = [
        {"found": asdict(f), "reason": f"filename declares {f.declared_wh[0]}x{f.declared_wh[1]}, got {f.width}x{f.height}"}
        for f in found
        if f.width is not None and f.height is not None and (f.width, f.height) != f.declared_wh
    ]

    coverage: dict[tuple[str, str, str, int, int], dict[str, Any]] = {}
    found_keys = {f.key for f in found}
    for e in expected:
        k = (e.layer, e.loadout, e.action, e.frames, e.frame_size)
        row = coverage.setdefault(k, dict(layer=e.layer, loadout=e.loadout, action=e.action, frames=e.frames, frame_size=e.frame_size, present=[], missing=[]))
        (row["present"] if e.key in found_keys else row["missing"]).append(e.direction)
    coverage_rows = []
    for row in coverage.values():
        row["present"] = dirsort(list(set(row["present"])))
        row["missing"] = dirsort(list(set(row["missing"])))
        coverage_rows.append(row)
    coverage_rows.sort(key=lambda r: (r["layer"], r["loadout"], r["action"]))

    return {
        "root": root.as_posix(),
        "summary": {
            "expected_files": len(expected),
            "found_operator_pngs": len(found),
            "missing_expected": len(missing),
            "wrong_folder_matches": len(wrong_path),
            "unexpected_operator_pngs": len(unexpected),
            "malformed_operator_pngs": len(bad),
            "warnings": len(warnings),
            "dimension_mismatches_vs_expected": len(dim_bad),
            "dimension_mismatches_vs_filename": len(declared_dim_bad),
        },
        "coverage": coverage_rows,
        "missing": missing,
        "wrong_path": wrong_path,
        "unexpected": unexpected,
        "malformed": [asdict(x) for x in bad],
        "warnings": warnings,
        "dimension_mismatches_vs_expected": dim_bad,
        "dimension_mismatches_vs_filename": declared_dim_bad,
    }

def dirs(xs: list[str]) -> str:
    return ",".join(xs) if xs else "-"

def text_report(r: dict[str, Any]) -> str:
    out = ["Operator Modular Sprite Audit", "=============================", f"Root: {r['root']}", ""]
    out += [f"{k}: {v}" for k, v in r["summary"].items()]
    out += ["", "Coverage", "--------", f"{'layer':<22} {'loadout':<10} {'action':<24} {'f':>2} {'px':>3} {'present':<24} missing"]
    for row in r["coverage"]:
        out.append(f"{row['layer']:<22} {row['loadout']:<10} {row['action']:<24} {row['frames']:>2} {row['frame_size']:>3} {dirs(row['present']):<24} {dirs(row['missing'])}")

    sections = [
        ("Missing", r["missing"], lambda x: f"- {x['rel_path']} [{x['set_id']}]"),
        ("Wrong folder", r["wrong_path"], lambda x: f"- expected {x['expected']['rel_path']} | found: {', '.join(x['found_paths'])}"),
        ("Malformed names", r["malformed"], lambda x: f"- {x['rel_path']}: {x['reason']}"),
        ("Warnings", r["warnings"], lambda x: f"- {x['rel_path']}: {x['warning']}"),
        ("Dimension mismatches vs expected", r["dimension_mismatches_vs_expected"], lambda x: f"- {x['expected']['rel_path']}: {x['reason']}"),
        ("Dimension mismatches vs filename", r["dimension_mismatches_vs_filename"], lambda x: f"- {x['found']['rel_path']}: {x['reason']}"),
        ("Unexpected operator PNGs", r["unexpected"], lambda x: f"- {x['rel_path']} ({x['layer']}/{x['loadout']}/{x['action']}/{x['direction']} {x['frames']}f {x['frame_size']}px)"),
    ]
    for title, items, fmt in sections:
        out += ["", title, "-" * len(title)]
        out += [fmt(x) for x in items] if items else ["(none)"]
    return "\n".join(out) + "\n"

def md_report(r: dict[str, Any]) -> str:
    out = ["# Operator Modular Sprite Audit", "", f"Root: `{r['root']}`", "", "## Summary", "", "| Metric | Count |", "|---|---:|"]
    out += [f"| `{k}` | {v} |" for k, v in r["summary"].items()]
    out += ["", "## Coverage", "", "| Layer | Loadout | Action | Frames | Px | Present | Missing |", "|---|---|---|---:|---:|---|---|"]
    for row in r["coverage"]:
        out.append(f"| `{row['layer']}` | `{row['loadout']}` | `{row['action']}` | {row['frames']} | {row['frame_size']} | `{dirs(row['present'])}` | `{dirs(row['missing'])}` |")
    for title, key in [("Missing", "missing"), ("Wrong folder", "wrong_path"), ("Malformed", "malformed"), ("Warnings", "warnings"), ("Unexpected", "unexpected")]:
        out += ["", f"## {title}", ""]
        if not r[key]:
            out.append("_None._")
        else:
            for x in r[key]:
                out.append(f"- `{x.get('rel_path') or x.get('expected', {}).get('rel_path')}`")
    return "\n".join(out) + "\n"

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root")
    ap.add_argument("--expected-json")
    ap.add_argument("--write-default-expected")
    ap.add_argument("--include-existing-baseline", action="store_true")
    ap.add_argument("--json-out")
    ap.add_argument("--md-out")
    ap.add_argument("--fail-on-missing", action="store_true")
    ap.add_argument("--fail-on-malformed", action="store_true")
    ap.add_argument("--fail-on-dimensions", action="store_true")
    args = ap.parse_args()

    if args.write_default_expected:
        write_default_expected(args.write_default_expected, args.include_existing_baseline)
        print(f"Wrote {args.write_default_expected}")
        return 0

    root = choose_root(args.root)
    expected = expand_expected(load_sets(args.expected_json, args.include_existing_baseline))
    result = evaluate(root, expected)
    print(text_report(result))

    if args.json_out:
        Path(args.json_out).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if args.md_out:
        Path(args.md_out).write_text(md_report(result), encoding="utf-8")

    fail = False
    if args.fail_on_missing and (result["summary"]["missing_expected"] or result["summary"]["wrong_folder_matches"]):
        fail = True
    if args.fail_on_malformed and result["summary"]["malformed_operator_pngs"]:
        fail = True
    if args.fail_on_dimensions and (result["summary"]["dimension_mismatches_vs_expected"] or result["summary"]["dimension_mismatches_vs_filename"]):
        fail = True
    return 1 if fail else 0

if __name__ == "__main__":
    raise SystemExit(main())
