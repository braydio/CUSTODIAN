#!/usr/bin/env python3
"""
Audit CUSTODIAN operator modular sprite sources.

Readable output:
- terminal dashboard
- N/NE/E/SE/S/SW/W/NW direction grid
- clear PASS/FAIL verdict
- copy/paste missing asset batch
- optional Markdown / HTML / JSON reports
- CI-friendly fail flags

Default roots tried from repo root:
  custodian/content/sprites/operator/new_operator/modular
  content/sprites/operator/new_operator/modular
  sprites/operator/new_operator/modular

Examples:
  python3 check_operator_modular_assets.py
  python3 check_operator_modular_assets.py --missing-only
  python3 check_operator_modular_assets.py --present-only
  python3 check_operator_modular_assets.py --html-out reports/operator_modular_asset_audit.html
  python3 check_operator_modular_assets.py --md-out reports/operator_modular_asset_audit.md
  python3 check_operator_modular_assets.py --json-out reports/operator_modular_asset_audit.json
  python3 check_operator_modular_assets.py --write-default-expected operator_expected_assets.json
  python3 check_operator_modular_assets.py --expected-json operator_expected_assets.json --fail-on-missing
"""
from __future__ import annotations

import argparse
import html
import json
import re
import struct
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Callable

DIRS8 = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
DIR_ORDER = {d: i for i, d in enumerate(DIRS8 + ["omni"])}
VALID_DIRS = set(DIR_ORDER)

ROOT_CANDIDATES = [
    "custodian/content/sprites/operator/new_operator/modular",
    "content/sprites/operator/new_operator/modular",
    "sprites/operator/new_operator/modular",
]

EXPECTED_SETS: list[dict[str, Any]] = [
    dict(id="fast_strike_lower_ns", folder="fast_attack", layer="modular_lower_body", loadout="unarmed", action="fast_strike_01", directions=["n", "s"], frames=3, frame_size=96, status="needed"),
    dict(id="fast_windup_upper_fx_all", folder="fast_attack", layer="modular_upper_fx", loadout="unarmed", action="fast_windup_01", directions=DIRS8, frames=3, frame_size=96, status="needed"),

    dict(id="parry_start_lower_all", folder="parry", layer="modular_lower_body", loadout="unarmed", action="parry_start_01", directions=DIRS8, frames=4, frame_size=96, status="needed"),
    dict(id="parry_start_upper_all", folder="parry", layer="modular_upper_body", loadout="unarmed", action="parry_start_01", directions=DIRS8, frames=4, frame_size=96, status="needed"),
    dict(id="parry_success_upper_all", folder="parry", layer="modular_upper_body", loadout="unarmed", action="parry_success_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),
    dict(id="parry_recovery_upper_all", folder="parry", layer="modular_upper_body", loadout="unarmed", action="parry_recovery_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),
    dict(id="parry_fx_all", folder="parry", layer="modular_upper_fx", loadout="unarmed", action="parry_fx_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),

    dict(id="lower_action_fallback_all", folder="lower", layer="modular_lower_body", loadout="unarmed", action="action_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),
    dict(id="upper_action_fallback_all", folder="upper", layer="modular_upper_body", loadout="unarmed", action="action_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),

    dict(id="lower_idle_ne_nw", folder="idle", layer="modular_lower_body", loadout="unarmed", action="idle_01", directions=["ne", "nw"], frames=5, frame_size=96, status="needed"),
    dict(id="upper_idle_all", folder="idle", layer="modular_upper_body", loadout="unarmed", action="idle_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),

    dict(id="lower_walk_missing", folder="walk", layer="modular_lower_body", loadout="unarmed", action="walk_01", directions=["n", "ne", "s", "se", "sw", "nw"], frames=5, frame_size=96, status="needed"),
    dict(id="upper_walk_all", folder="walk", layer="modular_upper_body", loadout="unarmed", action="walk_01", directions=DIRS8, frames=5, frame_size=96, status="needed"),
    dict(id="upper_run_ne_nw", folder="run", layer="modular_upper_body", loadout="unarmed", action="run_01", directions=["ne", "nw"], frames=5, frame_size=96, status="needed"),

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
    def group_key(self) -> tuple[str, str, str, int, int, str]:
        return (self.layer, self.loadout, self.action, self.frames, self.frame_size, self.status)

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


class Color:
    def __init__(self, enabled: bool) -> None:
        self.enabled = enabled

    def c(self, text: str, code: str) -> str:
        if not self.enabled:
            return text
        return f"\033[{code}m{text}\033[0m"

    def red(self, text: str) -> str:
        return self.c(text, "31;1")

    def green(self, text: str) -> str:
        return self.c(text, "32;1")

    def yellow(self, text: str) -> str:
        return self.c(text, "33;1")

    def dim(self, text: str) -> str:
        return self.c(text, "2")

    def bold(self, text: str) -> str:
        return self.c(text, "1")


def canonical_filename(layer: str, loadout: str, action: str, direction: str, frames: int, frame_size: int) -> str:
    return f"operator__{layer}__{loadout}__{action}__{direction}__{frames}f__{frame_size}.png"


def expand_expected(sets: list[dict[str, Any]]) -> list[Expected]:
    out: list[Expected] = []

    for item in sets:
        set_id = str(item["id"])
        folder = str(item.get("folder", "")).strip("/")
        layer = str(item["layer"])
        loadout = str(item["loadout"])
        action = str(item["action"])
        frames = int(item["frames"])
        frame_size = int(item["frame_size"])
        status = str(item.get("status", "needed"))

        for direction in item["directions"]:
            direction = str(direction)
            if direction not in VALID_DIRS:
                raise ValueError(f"{set_id}: invalid direction {direction}")

            name = canonical_filename(layer, loadout, action, direction, frames, frame_size)
            rel_path = f"{folder}/{name}" if folder else name

            out.append(Expected(
                set_id=set_id,
                status=status,
                rel_path=rel_path,
                filename=name,
                layer=layer,
                loadout=loadout,
                action=action,
                direction=direction,
                frames=frames,
                frame_size=frame_size,
            ))

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

    rel_path = path.relative_to(root).as_posix()
    parts = path.stem.split("__")

    if len(parts) < 7:
        return Bad(
            rel_path,
            path.name,
            "noncanonical name; expected operator__<layer>__<loadout>__<action>__<dir>__<frames>f__<size>.png",
        )

    owner = parts[0]
    layer = parts[1]
    loadout = parts[2]
    action = "__".join(parts[3:-3])
    direction = parts[-3]
    frames_token = parts[-2]
    size_token = parts[-1]

    if owner != "operator":
        return Bad(rel_path, path.name, "owner token is not operator")
    if not action:
        return Bad(rel_path, path.name, "empty action token; probable missing loadout token")
    if direction not in VALID_DIRS:
        return Bad(rel_path, path.name, f"bad direction token: {direction}")
    if not re.fullmatch(r"\d+f", frames_token):
        return Bad(rel_path, path.name, f"bad frames token: {frames_token}")
    if not re.fullmatch(r"\d+", size_token):
        return Bad(rel_path, path.name, f"bad frame-size token: {size_token}")

    width, height = png_size(path)

    warning = None
    if layer.startswith("modular_") and loadout in {"idle", "walk", "run", "lower", "upper"}:
        warning = "loadout token looks like an action/folder; filename may be missing loadout, usually unarmed"

    return Found(
        rel_path=rel_path,
        filename=path.name,
        layer=layer,
        loadout=loadout,
        action=action,
        direction=direction,
        frames=int(frames_token[:-1]),
        frame_size=int(size_token),
        width=width,
        height=height,
        warning=warning,
    )


def choose_root(root_arg: str | None) -> Path:
    if root_arg:
        root = Path(root_arg)
        if not root.exists():
            raise SystemExit(f"ERROR: root does not exist: {root}")
        return root

    for candidate in ROOT_CANDIDATES:
        root = Path(candidate)
        if root.exists():
            return root

    raise SystemExit(
        "ERROR: could not find modular root; pass --root. Tried:\n  "
        + "\n  ".join(ROOT_CANDIDATES)
    )


def scan(root: Path) -> tuple[list[Found], list[Bad]]:
    found: list[Found] = []
    bad: list[Bad] = []

    for path in sorted(root.rglob("*.png")):
        parsed = parse_found(path, root)
        if isinstance(parsed, Found):
            found.append(parsed)
        elif isinstance(parsed, Bad):
            bad.append(parsed)

    return found, bad


def dirsort(values: list[str]) -> list[str]:
    return sorted(values, key=lambda value: DIR_ORDER.get(value, 999))


def dirs(values: list[str]) -> str:
    return " ".join(value.upper().ljust(2) for value in dirsort(values)) if values else "-"


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
    found, malformed = scan(root)

    by_rel = {item.rel_path: item for item in found}
    by_name: dict[str, list[Found]] = {}

    for item in found:
        by_name.setdefault(item.filename, []).append(item)

    found_keys = {item.key for item in found}
    expected_keys = {item.key for item in expected}

    missing: list[dict[str, Any]] = []
    wrong_path: list[dict[str, Any]] = []
    dim_bad_expected: list[dict[str, Any]] = []

    for item in expected:
        found_at_path = by_rel.get(item.rel_path)

        if found_at_path:
            if (
                found_at_path.width is not None
                and found_at_path.height is not None
                and (found_at_path.width, found_at_path.height) != item.expected_wh
            ):
                dim_bad_expected.append({
                    "expected": asdict(item),
                    "found": asdict(found_at_path),
                    "reason": f"expected {item.expected_wh[0]}x{item.expected_wh[1]}, got {found_at_path.width}x{found_at_path.height}",
                })
            continue

        if item.filename in by_name:
            wrong_path.append({
                "expected": asdict(item),
                "found_paths": [match.rel_path for match in by_name[item.filename]],
            })
        else:
            missing.append(asdict(item))

    unexpected = [asdict(item) for item in found if item.key not in expected_keys]
    warnings = [asdict(item) for item in found if item.warning]

    dim_bad_filename = [
        {
            "found": asdict(item),
            "reason": f"filename declares {item.declared_wh[0]}x{item.declared_wh[1]}, got {item.width}x{item.height}",
        }
        for item in found
        if item.width is not None and item.height is not None and (item.width, item.height) != item.declared_wh
    ]

    coverage: dict[tuple[str, str, str, int, int, str], dict[str, Any]] = {}

    for item in expected:
        group = item.group_key
        row = coverage.setdefault(group, {
            "set_ids": set(),
            "status": item.status,
            "layer": item.layer,
            "loadout": item.loadout,
            "action": item.action,
            "frames": item.frames,
            "frame_size": item.frame_size,
            "present": [],
            "missing": [],
            "wrong_folder": [],
            "expected_paths": [],
        })

        row["set_ids"].add(item.set_id)
        row["expected_paths"].append(item.rel_path)

        if item.key in found_keys:
            row["present"].append(item.direction)
        elif item.filename in by_name:
            row["wrong_folder"].append(item.direction)
        else:
            row["missing"].append(item.direction)

    for row in coverage.values():
        row["set_ids"] = sorted(row["set_ids"])
        row["present"] = dirsort(list(set(row["present"])))
        row["missing"] = dirsort(list(set(row["missing"])))
        row["wrong_folder"] = dirsort(list(set(row["wrong_folder"])))

    coverage_rows = list(coverage.values())
    coverage_rows.sort(key=lambda row: (
        0 if row["missing"] else 1,
        0 if row["wrong_folder"] else 1,
        row["layer"],
        row["loadout"],
        row["action"],
        row["frames"],
        row["frame_size"],
    ))

    present_expected = sum(1 for item in expected if item.key in found_keys)

    return {
        "root": root.as_posix(),
        "summary": {
            "expected_files": len(expected),
            "present_expected": present_expected,
            "missing_expected": len(missing),
            "wrong_folder_matches": len(wrong_path),
            "found_operator_pngs": len(found),
            "unexpected_operator_pngs": len(unexpected),
            "malformed_operator_pngs": len(malformed),
            "warnings": len(warnings),
            "dimension_mismatches_vs_expected": len(dim_bad_expected),
            "dimension_mismatches_vs_filename": len(dim_bad_filename),
        },
        "coverage": coverage_rows,
        "missing": missing,
        "wrong_path": wrong_path,
        "unexpected": unexpected,
        "malformed": [asdict(item) for item in malformed],
        "warnings": warnings,
        "dimension_mismatches_vs_expected": dim_bad_expected,
        "dimension_mismatches_vs_filename": dim_bad_filename,
    }


def state_for_row(row: dict[str, Any]) -> str:
    if row["missing"]:
        return "MISSING"
    if row["wrong_folder"]:
        return "WRONG PATH"
    return "COMPLETE"


def color_state(state: str, color: Color) -> str:
    if state == "MISSING":
        return color.red(state)
    if state == "WRONG PATH":
        return color.yellow(state)
    return color.green(state)


def cell_for_dir(row: dict[str, Any], direction: str, color: Color) -> str:
    if direction in row["present"]:
        return color.green("OK")
    if direction in row["wrong_folder"]:
        return color.yellow("PATH")
    if direction in row["missing"]:
        return color.red("MISS")
    return color.dim("--")


def dashboard(result: dict[str, Any], color: Color) -> str:
    summary = result["summary"]

    expected = max(1, int(summary["expected_files"]))
    present = int(summary["present_expected"])
    missing = int(summary["missing_expected"])
    wrong = int(summary["wrong_folder_matches"])
    dim_bad = int(summary["dimension_mismatches_vs_expected"]) + int(summary["dimension_mismatches_vs_filename"])
    malformed = int(summary["malformed_operator_pngs"])

    coverage_pct = present / expected * 100.0

    if missing == 0 and wrong == 0 and dim_bad == 0 and malformed == 0:
        verdict = color.green("PASS — all expected operator modular assets are present and dimension-clean.")
    else:
        parts: list[str] = []
        if missing:
            parts.append(color.red(f"{missing} missing"))
        if wrong:
            parts.append(color.yellow(f"{wrong} wrong-folder"))
        if dim_bad:
            parts.append(color.red(f"{dim_bad} dimension issue(s)"))
        if malformed:
            parts.append(color.red(f"{malformed} malformed"))
        verdict = "FAIL — " + ", ".join(parts)

    bar_width = 42
    filled = int(round((present / expected) * bar_width))
    bar = color.green("█" * filled) + color.dim("░" * (bar_width - filled))

    def count_line(label: str, value: int, paint: Callable[[str], str]) -> str:
        return f"{label:<28} {paint(str(value).rjust(5))}"

    return "\n".join([
        "",
        color.bold("OPERATOR MODULAR SPRITE AUDIT"),
        "=" * 104,
        f"Root: {result['root']}",
        "",
        f"Verdict: {verdict}",
        f"Coverage: {present}/{expected} expected present ({coverage_pct:.1f}%)  {bar}",
        "",
        count_line("Expected", summary["expected_files"], color.dim),
        count_line("Present expected", summary["present_expected"], color.green),
        count_line("Missing expected", summary["missing_expected"], color.red if summary["missing_expected"] else color.green),
        count_line("Wrong folder matches", summary["wrong_folder_matches"], color.yellow if summary["wrong_folder_matches"] else color.green),
        count_line("Dimension issues", dim_bad, color.red if dim_bad else color.green),
        count_line("Malformed operator PNGs", summary["malformed_operator_pngs"], color.red if summary["malformed_operator_pngs"] else color.green),
        count_line("Unexpected PNGs", summary["unexpected_operator_pngs"], color.yellow if summary["unexpected_operator_pngs"] else color.green),
        "",
        "Legend: "
        + color.green("OK")
        + " = present   "
        + color.red("MISS")
        + " = missing   "
        + color.yellow("PATH")
        + " = found in wrong folder   "
        + color.dim("--")
        + " = not expected",
    ])


def coverage_table(
    result: dict[str, Any],
    color: Color,
    *,
    missing_only: bool = False,
    present_only: bool = False,
) -> str:
    rows = result["coverage"]

    if missing_only:
        rows = [row for row in rows if row["missing"] or row["wrong_folder"]]
    if present_only:
        rows = [row for row in rows if row["present"]]

    lines = [
        "",
        color.bold("DIRECTION COVERAGE"),
        "-" * 104,
        f"{'state':<12} {'layer':<22} {'action':<24} {'f':>2} {'px':>3}  "
        f"{'N':<5} {'NE':<5} {'E':<5} {'SE':<5} {'S':<5} {'SW':<5} {'W':<5} {'NW':<5}",
        "-" * 104,
    ]

    for row in rows:
        state = state_for_row(row)
        cells = " ".join(cell_for_dir(row, direction, color).ljust(5) for direction in DIRS8)

        lines.append(
            f"{color_state(state, color):<21} "
            f"{row['layer']:<22} "
            f"{row['action']:<24} "
            f"{row['frames']:>2} "
            f"{row['frame_size']:>3}  "
            f"{cells}"
        )

    if not rows:
        lines.append("(none)")

    return "\n".join(lines)


def compact_asset_batch(title: str, items: list[dict[str, Any]], formatter: Callable[[dict[str, Any]], str]) -> str:
    lines = ["", title, "-" * len(title)]

    if not items:
        lines.append("(none)")
        return "\n".join(lines)

    for item in items:
        lines.append(formatter(item))

    return "\n".join(lines)


def detail_sections(
    result: dict[str, Any],
    *,
    missing_only: bool = False,
    present_only: bool = False,
) -> str:
    if present_only:
        return ""

    sections: list[str] = []

    sections.append(compact_asset_batch(
        "COPY/PASTE NEXT MISSING ASSET BATCH",
        result["missing"],
        lambda item: f"- {item['rel_path']}    [{item['frames']}f x {item['frame_size']}px | {item['set_id']}]",
    ))

    sections.append(compact_asset_batch(
        "WRONG FOLDER MATCHES",
        result["wrong_path"],
        lambda item: f"- expected {item['expected']['rel_path']} | found: {', '.join(item['found_paths'])}",
    ))

    sections.append(compact_asset_batch(
        "DIMENSION MISMATCHES VS EXPECTED",
        result["dimension_mismatches_vs_expected"],
        lambda item: f"- {item['expected']['rel_path']}: {item['reason']}",
    ))

    sections.append(compact_asset_batch(
        "DIMENSION MISMATCHES VS FILENAME",
        result["dimension_mismatches_vs_filename"],
        lambda item: f"- {item['found']['rel_path']}: {item['reason']}",
    ))

    sections.append(compact_asset_batch(
        "MALFORMED OPERATOR PNGS",
        result["malformed"],
        lambda item: f"- {item['rel_path']}: {item['reason']}",
    ))

    sections.append(compact_asset_batch(
        "WARNINGS",
        result["warnings"],
        lambda item: f"- {item['rel_path']}: {item['warning']}",
    ))

    if not missing_only:
        sections.append(compact_asset_batch(
            "UNEXPECTED OPERATOR PNGS",
            result["unexpected"],
            lambda item: (
                f"- {item['rel_path']} "
                f"({item['layer']}/{item['loadout']}/{item['action']}/{item['direction']} "
                f"{item['frames']}f {item['frame_size']}px)"
            ),
        ))

    return "\n".join(sections)


def text_report(
    result: dict[str, Any],
    *,
    color: Color,
    missing_only: bool = False,
    present_only: bool = False,
) -> str:
    return "\n".join([
        dashboard(result, color),
        coverage_table(result, color, missing_only=missing_only, present_only=present_only),
        detail_sections(result, missing_only=missing_only, present_only=present_only),
        "",
    ])


def md_report(result: dict[str, Any]) -> str:
    summary = result["summary"]
    dim_issues = summary["dimension_mismatches_vs_expected"] + summary["dimension_mismatches_vs_filename"]

    has_fail = (
        summary["missing_expected"]
        or summary["wrong_folder_matches"]
        or summary["malformed_operator_pngs"]
        or dim_issues
    )

    out = [
        "# Operator Modular Sprite Audit",
        "",
        f"Root: `{result['root']}`",
        "",
        "## Verdict",
        "",
        "**FAIL** — missing, wrong-folder, malformed, or dimension-problem assets remain."
        if has_fail
        else "**PASS** — all expected operator modular assets are present and dimension-clean.",
        "",
        "## Summary",
        "",
        "| Metric | Count |",
        "|---|---:|",
    ]

    out += [f"| `{key}` | {value} |" for key, value in summary.items()]

    out += [
        "",
        "## Direction Coverage",
        "",
        "| State | Layer | Action | Frames | Px | N | NE | E | SE | S | SW | W | NW |",
        "|---|---|---|---:|---:|---|---|---|---|---|---|---|---|",
    ]

    for row in result["coverage"]:
        def md_cell(direction: str) -> str:
            if direction in row["present"]:
                return "OK"
            if direction in row["wrong_folder"]:
                return "PATH"
            if direction in row["missing"]:
                return "MISS"
            return "—"

        out.append(
            f"| {state_for_row(row)} | `{row['layer']}` | `{row['action']}` | "
            f"{row['frames']} | {row['frame_size']} | "
            + " | ".join(md_cell(direction) for direction in DIRS8)
            + " |"
        )

    sections: list[tuple[str, str, Callable[[dict[str, Any]], str]]] = [
        ("Missing", "missing", lambda item: f"- `{item['rel_path']}` — `{item['frames']}f`, `{item['frame_size']}px`, set `{item['set_id']}`"),
        ("Wrong Folder", "wrong_path", lambda item: f"- expected `{item['expected']['rel_path']}`; found `{', '.join(item['found_paths'])}`"),
        ("Dimension Mismatches vs Expected", "dimension_mismatches_vs_expected", lambda item: f"- `{item['expected']['rel_path']}` — {item['reason']}"),
        ("Dimension Mismatches vs Filename", "dimension_mismatches_vs_filename", lambda item: f"- `{item['found']['rel_path']}` — {item['reason']}"),
        ("Malformed", "malformed", lambda item: f"- `{item['rel_path']}` — {item['reason']}"),
        ("Warnings", "warnings", lambda item: f"- `{item['rel_path']}` — {item['warning']}"),
        ("Unexpected", "unexpected", lambda item: f"- `{item['rel_path']}`"),
    ]

    for title, key, formatter in sections:
        out += ["", f"## {title}", ""]
        if not result[key]:
            out.append("_None._")
        else:
            out += [formatter(item) for item in result[key]]

    return "\n".join(out) + "\n"


def html_report(result: dict[str, Any]) -> str:
    summary = result["summary"]
    dim_issues = summary["dimension_mismatches_vs_expected"] + summary["dimension_mismatches_vs_filename"]

    has_fail = (
        summary["missing_expected"]
        or summary["wrong_folder_matches"]
        or summary["malformed_operator_pngs"]
        or dim_issues
    )

    verdict_class = "bad" if has_fail else "good"
    verdict = "FAIL" if has_fail else "PASS"

    def esc(value: Any) -> str:
        return html.escape(str(value))

    def hcell(row: dict[str, Any], direction: str) -> str:
        if direction in row["present"]:
            return "<td class='ok'>OK</td>"
        if direction in row["wrong_folder"]:
            return "<td class='path'>PATH</td>"
        if direction in row["missing"]:
            return "<td class='miss'>MISS</td>"
        return "<td class='empty'>—</td>"

    coverage_rows = []

    for row in result["coverage"]:
        state = state_for_row(row)
        state_class = state.lower().replace(" ", "-")

        coverage_rows.append(
            "<tr>"
            f"<td class='{esc(state_class)}'>{esc(state)}</td>"
            f"<td>{esc(row['layer'])}</td>"
            f"<td>{esc(row['action'])}</td>"
            f"<td>{esc(row['frames'])}</td>"
            f"<td>{esc(row['frame_size'])}</td>"
            + "".join(hcell(row, direction) for direction in DIRS8)
            + "</tr>"
        )

    missing_items = "\n".join(
        f"<li><code>{esc(item['rel_path'])}</code></li>"
        for item in result["missing"]
    ) or "<li>None.</li>"

    wrong_items = "\n".join(
        f"<li>Expected <code>{esc(item['expected']['rel_path'])}</code>; "
        f"found <code>{esc(', '.join(item['found_paths']))}</code></li>"
        for item in result["wrong_path"]
    ) or "<li>None.</li>"

    return f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Operator Modular Sprite Audit</title>
<style>
body {{
  background: #101014;
  color: #e8e2d0;
  font-family: system-ui, sans-serif;
  margin: 24px;
}}
h1, h2 {{
  color: #f2d28b;
}}
.status {{
  border-radius: 10px;
  padding: 18px;
  margin: 16px 0;
  font-size: 28px;
  font-weight: 900;
}}
.status.good {{
  background: #12351d;
  color: #bfffd0;
  border: 1px solid #43d46c;
}}
.status.bad {{
  background: #421818;
  color: #ffd0d0;
  border: 1px solid #ff6868;
}}
.cards {{
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
  gap: 12px;
  margin: 18px 0;
}}
.card {{
  background: #1a1a22;
  border: 1px solid #383848;
  border-radius: 8px;
  padding: 14px;
}}
.card b {{
  display: block;
  font-size: 32px;
}}
table {{
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}}
th, td {{
  border: 1px solid #333340;
  padding: 7px 8px;
  text-align: center;
}}
th {{
  background: #2c261a;
  color: #f2d28b;
  position: sticky;
  top: 0;
}}
td:nth-child(2),
td:nth-child(3) {{
  text-align: left;
}}
.ok {{
  background: #15351f;
  color: #b9ffc8;
  font-weight: 800;
}}
.miss {{
  background: #421818;
  color: #ffd0d0;
  font-weight: 900;
}}
.path {{
  background: #3b3115;
  color: #ffe89a;
  font-weight: 900;
}}
.empty {{
  color: #777;
}}
.complete {{
  color: #b9ffc8;
  font-weight: 800;
}}
.missing {{
  color: #ffd0d0;
  font-weight: 900;
}}
.wrong-path {{
  color: #ffe89a;
  font-weight: 900;
}}
code {{
  color: #f2d28b;
}}
</style>
</head>
<body>
<h1>Operator Modular Sprite Audit</h1>
<p>Root: <code>{esc(result['root'])}</code></p>

<div class="status {verdict_class}">{verdict}</div>

<div class="cards">
  <div class="card">Expected<b>{esc(summary['expected_files'])}</b></div>
  <div class="card">Present<b>{esc(summary['present_expected'])}</b></div>
  <div class="card">Missing<b>{esc(summary['missing_expected'])}</b></div>
  <div class="card">Wrong Folder<b>{esc(summary['wrong_folder_matches'])}</b></div>
  <div class="card">Malformed<b>{esc(summary['malformed_operator_pngs'])}</b></div>
  <div class="card">Dimension Issues<b>{esc(dim_issues)}</b></div>
</div>

<h2>Direction Coverage</h2>
<table>
<thead>
<tr>
<th>State</th>
<th>Layer</th>
<th>Action</th>
<th>Frames</th>
<th>Px</th>
<th>N</th>
<th>NE</th>
<th>E</th>
<th>SE</th>
<th>S</th>
<th>SW</th>
<th>W</th>
<th>NW</th>
</tr>
</thead>
<tbody>
{''.join(coverage_rows)}
</tbody>
</table>

<h2>Missing Asset Batch</h2>
<ul>{missing_items}</ul>

<h2>Wrong Folder Matches</h2>
<ul>{wrong_items}</ul>
</body>
</html>
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root")
    parser.add_argument("--expected-json")
    parser.add_argument("--write-default-expected")
    parser.add_argument("--include-existing-baseline", action="store_true")

    parser.add_argument("--json-out")
    parser.add_argument("--md-out")
    parser.add_argument("--html-out")

    parser.add_argument("--missing-only", action="store_true", help="Only show incomplete rows in the coverage grid.")
    parser.add_argument("--present-only", action="store_true", help="Only show rows with at least one present direction.")
    parser.add_argument("--no-color", action="store_true")

    parser.add_argument("--fail-on-missing", action="store_true")
    parser.add_argument("--fail-on-malformed", action="store_true")
    parser.add_argument("--fail-on-dimensions", action="store_true")

    args = parser.parse_args()

    if args.write_default_expected:
        write_default_expected(args.write_default_expected, args.include_existing_baseline)
        print(f"Wrote {args.write_default_expected}")
        return 0

    color = Color(enabled=(not args.no_color and sys.stdout.isatty()))
    root = choose_root(args.root)
    expected = expand_expected(load_sets(args.expected_json, args.include_existing_baseline))
    result = evaluate(root, expected)

    print(text_report(
        result,
        color=color,
        missing_only=args.missing_only,
        present_only=args.present_only,
    ))

    if args.json_out:
        json_path = Path(args.json_out)
        json_path.parent.mkdir(parents=True, exist_ok=True)
        json_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")

    if args.md_out:
        md_path = Path(args.md_out)
        md_path.parent.mkdir(parents=True, exist_ok=True)
        md_path.write_text(md_report(result), encoding="utf-8")
        print(f"Wrote Markdown report: {md_path}")

    if args.html_out:
        html_path = Path(args.html_out)
        html_path.parent.mkdir(parents=True, exist_ok=True)
        html_path.write_text(html_report(result), encoding="utf-8")
        print(f"Wrote HTML report: {html_path}")

    fail = False

    if args.fail_on_missing and (
        result["summary"]["missing_expected"]
        or result["summary"]["wrong_folder_matches"]
    ):
        fail = True

    if args.fail_on_malformed and result["summary"]["malformed_operator_pngs"]:
        fail = True

    if args.fail_on_dimensions and (
        result["summary"]["dimension_mismatches_vs_expected"]
        or result["summary"]["dimension_mismatches_vs_filename"]
    ):
        fail = True

    return 1 if fail else 0


if __name__ == "__main__":
    raise SystemExit(main())
