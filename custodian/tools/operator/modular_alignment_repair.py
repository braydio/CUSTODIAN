#!/usr/bin/env python3
"""Interactive, provenance-first repair conveyor for Modular Operator art."""

from __future__ import annotations

import argparse
import html
import importlib.util
import json
import os
import shutil
import statistics
import subprocess
import sys
import time
import webbrowser
from collections import defaultdict
from dataclasses import asdict, dataclass, field
from pathlib import Path
from types import SimpleNamespace
from typing import Callable

from PIL import Image

from operator_asset_reconciliation import (
    BUILDER as OPERATOR_BUILDER,
    DEFAULT_WORKSPACE,
    MODULE_ROOT,
    REPO_ROOT,
    SOURCE_ROOT,
    EditableSourceRecord,
    SourceReconciler,
    file_sha256,
    validate_sheet_contract,
)


CHECKER_PATH = Path(__file__).with_name("modular_combo_check.py")
BUILDER_PATH = REPO_ROOT / "custodian/tools/pipelines/build_operator_runtime.py"


def _load_checker():
    spec = importlib.util.spec_from_file_location("operator_modular_combo_checker", CHECKER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to import checker: {CHECKER_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


CHECKER = _load_checker()


@dataclass
class FrameFinding:
    pair_id: str
    frame: int
    lower_runtime_path: str
    upper_runtime_path: str
    connector_vertical_gap_px: float | None
    connector_center_delta_px: float | None
    connector_overlap_px: float
    connector_confidence: float
    vertical_gap_px: float | None
    horizontal_center_delta_px: float | None
    flagged: bool


@dataclass
class AssetSuspicion:
    runtime_path: str
    layer: str
    action: str
    direction: str
    total_pair_frames: int
    flagged_pair_frames: int
    flagged_ratio: float
    median_signed_connector_x_delta: float
    median_signed_vertical_gap: float
    maximum_violation: float
    distinct_partner_assets: int
    confidence: str
    flagged_frames: list[int]
    implicated_pairs: list[str]


@dataclass
class QueueEntry:
    id: str
    source_path: str
    runtime_paths: list[str]
    layer: str
    direction: str
    action: str
    confidence: str
    flagged_frames: list[int]
    implicated_pairs: list[str]
    max_connector_gap: float
    max_connector_center_delta: float
    status: str = "pending"
    source_hash: str | None = None
    resolution: str = "unresolved"
    provenance_note: str = ""
    selected_source_path: str | None = None
    roundtrip_pass: bool = False
    source_frame_count: int = 0
    source_frame_width: int = 0
    source_frame_height: int = 0


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Interactive Modular Operator artwork alignment repair.")
    parser.add_argument("selector", nargs="?", default="all")
    parser.add_argument("--all", action="store_true", dest="all_assets")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--report-only", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--reconcile-only", action="store_true")
    parser.add_argument("--aseprite", type=Path)
    parser.add_argument("--gap-threshold", type=int, default=3)
    parser.add_argument("--center-threshold", type=int, default=5)
    parser.add_argument("--no-open", action="store_true")
    parser.add_argument("--no-backup", action="store_true")
    parser.add_argument("--workspace", type=Path, default=DEFAULT_WORKSPACE)
    parser.add_argument("--runtime-root", type=Path, default=MODULE_ROOT)
    parser.add_argument("--source-root", type=Path, default=SOURCE_ROOT)
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    return parser.parse_args(argv)


def alpha_runs_on_row(
    image: Image.Image,
    y: int,
    x_min: int,
    x_max: int,
) -> list[tuple[int, int]]:
    """Return contiguous inclusive X runs where alpha > 0 on row `y`."""
    alpha = image.convert("RGBA").getchannel("A")
    if y < 0 or y >= alpha.height:
        return []
    x0 = max(0, x_min)
    x1 = min(alpha.width - 1, x_max)
    if x1 < x0:
        return []
    row = alpha.crop((x0, y, x1 + 1, y + 1)).tobytes()
    runs: list[tuple[int, int]] = []
    start: int | None = None
    for offset, value in enumerate(row):
        if value > 0:
            if start is None:
                start = x0 + offset
        elif start is not None:
            runs.append((start, x0 + offset - 1))
            start = None
    if start is not None:
        runs.append((start, x1))
    return runs


def substantial_runs(
    image: Image.Image,
    y: int,
    x_min: int,
    x_max: int,
    min_width: int,
) -> list[tuple[int, int]]:
    """alpha_runs_on_row() filtered to runs of width >= min_width."""
    return [
        (start, end)
        for start, end in alpha_runs_on_row(image, y, x_min, x_max)
        if end - start + 1 >= min_width
    ]


def connector_debug(lower_frame: Image.Image, upper_frame: Image.Image) -> dict:
    base = CHECKER.edge_contact_debug(lower_frame, upper_frame)
    frame_width = lower_frame.width
    frame_height = lower_frame.height
    min_connector_width = max(5, round(frame_width * 0.07))

    lower_connector = None
    lower_y = None
    for y in range(frame_height):
        runs = substantial_runs(
            lower_frame, y, round(frame_width * 0.25), round(frame_width * 0.75),
            min_connector_width,
        )
        if runs:
            lower_connector = min(
                runs, key=lambda run: abs(((run[0] + run[1]) / 2) - frame_width / 2)
            )
            lower_y = y
            break

    upper_connector = None
    upper_y = None
    if lower_connector is not None and lower_y is not None:
        lower_width = lower_connector[1] - lower_connector[0] + 1
        lower_center = (lower_connector[0] + lower_connector[1]) / 2
        upper_x_min = max(0, round(lower_center - max(12, 2 * lower_width)))
        upper_x_max = min(frame_width - 1, round(lower_center + max(12, 2 * lower_width)))
        y_lo = max(0, lower_y - max(24, frame_height // 4))
        y_hi = min(frame_height - 1, lower_y + max(8, frame_height // 12))
        expected_seam = lower_y - 1
        candidates: list[tuple[int, int, tuple[int, int], int]] = []
        for y in range(y_lo, y_hi + 1):
            for run in substantial_runs(upper_frame, y, upper_x_min, upper_x_max, min_connector_width):
                candidates.append((abs(y - expected_seam), run[1] - run[0] + 1, run, y))
        if candidates:
            _distance, _width, upper_connector, upper_y = min(
                candidates,
                key=lambda item: (
                    item[0],
                    -item[1],
                    abs((((item[2][0] + item[2][1]) / 2) - lower_center)),
                ),
            )

    vertical_gap = None
    center_delta = None
    overlap = 0.0
    confidence = 0.0
    if lower_connector is not None and upper_connector is not None and lower_y is not None and upper_y is not None:
        vertical_gap = lower_y - upper_y - 1
        upper_center = (upper_connector[0] + upper_connector[1]) / 2
        lower_center = (lower_connector[0] + lower_connector[1]) / 2
        center_delta = upper_center - lower_center
        overlap = max(0, min(upper_connector[1], lower_connector[1]) - max(upper_connector[0], lower_connector[0]) + 1)
        upper_width = upper_connector[1] - upper_connector[0] + 1
        lower_width = lower_connector[1] - lower_connector[0] + 1
        confidence = min(1.0, min(upper_width, lower_width) / max(8.0, min_connector_width * 1.5))
    return {
        **base,
        "connector_upper_span": list(upper_connector) if upper_connector else None,
        "connector_lower_span": list(lower_connector) if lower_connector else None,
        "connector_vertical_gap_px": vertical_gap,
        "connector_center_delta_px": center_delta,
        "connector_overlap_px": float(overlap),
        "connector_confidence": round(confidence, 3),
    }


def _sheet(path: Path):
    meta = CHECKER.parse_modular_png_name(path)
    return CHECKER.Sheet(
        source_path=path, workspace_path=path, actor=meta["actor"], part=meta["part"],
        variant=meta["variant"], anim_id=meta["anim_id"], direction=meta["direction"],
        frame_count=meta["frames"], frame_w=meta["frame_w"], identity=meta["identity"],
    )


def discover_sheets(runtime_root: Path, selector: str = "all") -> tuple[list, list]:
    selector = selector.lower().strip()
    direction = CHECKER.runtime_direction(selector)
    layers: list[list] = []
    for layer in ("lower_body", "upper_body"):
        sheets = []
        for path in sorted(runtime_root.rglob("*.png")):
            try:
                sheet = _sheet(path.resolve())
            except ValueError:
                continue
            if sheet.part != layer:
                continue
            haystack = f"{path.as_posix()} {sheet.anim_id} {sheet.domain} {sheet.direction}".lower()
            if selector not in {"", "all"} and direction is None and selector not in haystack:
                continue
            if direction is not None and sheet.direction != direction:
                continue
            sheets.append(sheet)
        layers.append(sheets)
    return layers[0], layers[1]


def v2_pair_key(path: Path) -> tuple[str, str, str, str]:
    identity = OPERATOR_BUILDER.identify_runtime_module(
        path.resolve(),
        MODULE_ROOT,
    )
    return (
        identity.loadout,
        identity.family,
        identity.action,
        identity.direction,
    )


def _sheet_frame_height(sheet) -> int:
    with Image.open(sheet.source_path) as image:
        return image.height


def find_exact_v2_pair_jobs(lower: list, upper: list) -> tuple[list, list]:
    """Pair lower/upper runtime sheets by exact V2 profile/group/action/direction.

    The repair conveyor never fans an action across partners. A key with more
    than one sheet on either side, or a frame-count/canvas mismatch, becomes a
    missing record instead of a guess.
    """
    lower_by_key: dict[tuple[str, str, str, str], list] = defaultdict(list)
    upper_by_key: dict[tuple[str, str, str, str], list] = defaultdict(list)
    for sheet in lower:
        lower_by_key[v2_pair_key(sheet.source_path)].append(sheet)
    for sheet in upper:
        upper_by_key[v2_pair_key(sheet.source_path)].append(sheet)
    jobs: list = []
    missing: list = []
    for key in sorted(set(lower_by_key) | set(upper_by_key)):
        lower_sheets = lower_by_key.get(key, [])
        upper_sheets = upper_by_key.get(key, [])
        if len(lower_sheets) == 1 and len(upper_sheets) == 1:
            lower_sheet, upper_sheet = lower_sheets[0], upper_sheets[0]
            if (
                lower_sheet.frame_count != upper_sheet.frame_count
                or lower_sheet.frame_w != upper_sheet.frame_w
                or _sheet_frame_height(lower_sheet) != _sheet_frame_height(upper_sheet)
            ):
                missing.append({
                    "upper": upper_sheet.workspace_path.name,
                    "reason": (
                        f"V2 pair frame count/canvas mismatch for "
                        f"{key}; refusing repair analysis."
                    ),
                })
                continue
            jobs.append(CHECKER.PairJob(
                lower=lower_sheet,
                upper=upper_sheet,
                output_id="",
                pair_mode="runtime_direction_exact",
            ))
            continue
        for sheet in lower_sheets:
            missing.append({
                "lower": sheet.workspace_path.name,
                "reason": f"No exact V2 upper counterpart (profile/group/action/direction {key}).",
            })
        for sheet in upper_sheets:
            missing.append({
                "upper": sheet.workspace_path.name,
                "reason": f"No exact V2 lower counterpart (profile/group/action/direction {key}).",
            })
    return jobs, missing


def analyze(
    runtime_root: Path,
    selector: str,
    gap_threshold: int,
    center_threshold: int,
    preview_root: Path | None = None,
) -> dict:
    lower, upper = discover_sheets(runtime_root, selector)
    jobs, missing = find_exact_v2_pair_jobs(lower, upper)
    findings: list[FrameFinding] = []
    pair_records: list[dict] = []
    preview_args = SimpleNamespace(
        output_frame_policy="min", lower_frame_repeat="loop", upper_frame_repeat="loop",
        lower_offset_x=0, lower_offset_y=0, upper_offset_x=0, upper_offset_y=0,
        fit_debug=True, scale=3, duration_ms=120,
    )
    if preview_root is not None:
        for directory in ("combined", "previews", "gif"):
            (preview_root / directory).mkdir(parents=True, exist_ok=True)
    for job in jobs:
        lower_image = Image.open(job.lower.source_path).convert("RGBA")
        upper_image = Image.open(job.upper.source_path).convert("RGBA")
        lower_count, lower_width, _ = CHECKER.sheet_meta(job.lower.source_path, lower_image)
        upper_count, upper_width, _ = CHECKER.sheet_meta(job.upper.source_path, upper_image)
        count = min(lower_count, upper_count)
        pair_id = CHECKER.build_output_id(job, count, max(lower_width, upper_width))
        flagged_count = 0
        for frame_index in range(count):
            lower_frame = lower_image.crop((frame_index * lower_width, 0, (frame_index + 1) * lower_width, lower_image.height))
            upper_frame = upper_image.crop((frame_index * upper_width, 0, (frame_index + 1) * upper_width, upper_image.height))
            metrics = connector_debug(lower_frame, upper_frame)
            gap = metrics["connector_vertical_gap_px"]
            delta = metrics["connector_center_delta_px"]
            confident = metrics["connector_confidence"] >= 0.35
            flagged = confident and (
                (gap is not None and abs(gap) >= gap_threshold)
                or (delta is not None and abs(delta) >= center_threshold)
            )
            flagged_count += int(flagged)
            findings.append(FrameFinding(
                pair_id, frame_index, str(job.lower.source_path), str(job.upper.source_path),
                gap, delta, metrics["connector_overlap_px"], metrics["connector_confidence"],
                metrics["vertical_gap_px"], metrics["horizontal_center_delta_px"], flagged,
            ))
        pair_record = {
            "id": pair_id, "lower": str(job.lower.source_path), "upper": str(job.upper.source_path),
            "frames": count, "flagged_frames": flagged_count,
        }
        if preview_root is not None and flagged_count:
            strip, frames, _meta, _fit = CHECKER.composite_pair(job, preview_args)
            review = CHECKER.make_review_sheet(job, frames, preview_args)
            combined_path = preview_root / "combined" / f"{pair_id}.png"
            review_path = preview_root / "previews" / f"{pair_id}_review.png"
            gif_path = preview_root / "gif" / f"{pair_id}.gif"
            strip.save(combined_path)
            review.save(review_path)
            CHECKER.make_gif(frames, gif_path, preview_args)
            pair_record.update({
                "combined": combined_path.relative_to(preview_root).as_posix(),
                "review": review_path.relative_to(preview_root).as_posix(),
                "gif": gif_path.relative_to(preview_root).as_posix(),
            })
        pair_records.append(pair_record)
    suspicions = score_suspicions(findings)
    return {
        "runtime_sheets": len(lower) + len(upper), "lower_sheets": len(lower), "upper_sheets": len(upper),
        "pairings": len(jobs), "pair_frames": len(findings),
        "flagged_pairings": sum(1 for record in pair_records if record["flagged_frames"]),
        "missing": missing, "pairs": pair_records,
        "findings": [asdict(item) for item in findings],
        "suspicions": [asdict(item) for item in suspicions],
    }


def score_suspicions(findings: list[FrameFinding]) -> list[AssetSuspicion]:
    by_asset: dict[str, list[tuple[FrameFinding, str, int]]] = {}
    for finding in findings:
        by_asset.setdefault(finding.lower_runtime_path, []).append((finding, finding.upper_runtime_path, -1))
        by_asset.setdefault(finding.upper_runtime_path, []).append((finding, finding.lower_runtime_path, 1))
    ratios = {
        asset: sum(item[0].flagged for item in items) / max(1, len(items))
        for asset, items in by_asset.items()
    }
    output = []
    for asset, items in by_asset.items():
        flagged = [item for item in items if item[0].flagged]
        if not flagged:
            continue
        partners = sorted({item[1] for item in items})
        partner_ratio = statistics.median(ratios.get(partner, 0.0) for partner in partners)
        ratio = ratios[asset]
        confidence = "ambiguous"
        if len(partners) >= 2 and ratio >= 0.5 and ratio - partner_ratio >= 0.2:
            confidence = "high"
        elif len(partners) >= 2 and ratio >= 0.35:
            confidence = "medium"
        metrics_x = [item[0].connector_center_delta_px * item[2] for item in flagged if item[0].connector_center_delta_px is not None]
        metrics_gap = [item[0].connector_vertical_gap_px for item in flagged if item[0].connector_vertical_gap_px is not None]
        maximum = max(
            max((abs(value) for value in metrics_x), default=0.0),
            max((abs(value) for value in metrics_gap), default=0.0),
        )
        meta = CHECKER.parse_modular_png_name(Path(asset))
        output.append(AssetSuspicion(
            asset, meta["part"], meta["anim_id"], meta["direction"], len(items), len(flagged), ratio,
            statistics.median(metrics_x) if metrics_x else 0.0,
            statistics.median(metrics_gap) if metrics_gap else 0.0,
            maximum, len(partners), confidence,
            sorted({item[0].frame for item in flagged}), sorted({item[0].pair_id for item in flagged}),
        ))
    order = {"high": 0, "medium": 1, "ambiguous": 2}
    return sorted(output, key=lambda item: (order[item.confidence], -item.maximum_violation, -item.distinct_partner_assets, item.runtime_path))


def runtime_record_key(path: Path) -> str:
    return str(path.expanduser().resolve())


def build_queue(
    report: dict,
    records: dict[str, EditableSourceRecord],
    repo_root: Path = REPO_ROOT,
) -> list[QueueEntry]:
    by_source: dict[str, QueueEntry] = {}
    for raw in report["suspicions"]:
        runtime = Path(raw["runtime_path"])
        identity = CHECKER.parse_modular_png_name(runtime)
        provenance = records.get(runtime_record_key(runtime))
        source = provenance.editable_path if provenance and provenance.editable_path else str(runtime)
        source_candidate = Path(source)
        if not source_candidate.is_absolute():
            source_candidate = repo_root / source_candidate
        source = str(source_candidate.resolve())
        key = source
        existing = by_source.get(key)
        if existing is None:
            source_path = Path(source)
            source_frames = identity["frames"]
            source_width = identity["frame_w"]
            source_height = 0
            if source_path.exists():
                with Image.open(source_path) as source_image:
                    source_width = source_image.width // source_frames
                    source_height = source_image.height
            semantic = "|".join((identity["part"], identity["variant"], identity["anim_id"], identity["direction"]))
            existing = QueueEntry(
                id=semantic, source_path=source, runtime_paths=[], layer=raw["layer"],
                direction=raw["direction"], action=raw["action"], confidence=raw["confidence"],
                flagged_frames=[], implicated_pairs=[], max_connector_gap=0.0,
                max_connector_center_delta=0.0,
                resolution=provenance.resolution if provenance else "unresolved",
                provenance_note=provenance.provenance_note if provenance else "",
                selected_source_path=provenance.selected_source_path if provenance else None,
                roundtrip_pass=bool(provenance and provenance.rebuilt_pixel_sha256 == provenance.runtime_pixel_sha256),
                source_frame_count=source_frames, source_frame_width=source_width,
                source_frame_height=source_height,
            )
            by_source[key] = existing
        existing.runtime_paths.append(str(runtime))
        existing.flagged_frames = sorted(set(existing.flagged_frames) | set(raw["flagged_frames"]))
        existing.implicated_pairs = sorted(set(existing.implicated_pairs) | set(raw["implicated_pairs"]))
        existing.max_connector_gap = max(existing.max_connector_gap, abs(raw["median_signed_vertical_gap"]))
        existing.max_connector_center_delta = max(existing.max_connector_center_delta, abs(raw["median_signed_connector_x_delta"]))
    order = {"high": 0, "medium": 1, "ambiguous": 2}
    return sorted(by_source.values(), key=lambda item: (
        order.get(item.confidence, 3), -max(item.max_connector_gap, item.max_connector_center_delta),
        -len(item.implicated_pairs), item.source_path,
    ))


def save_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    temp.replace(path)


def write_report(workspace: Path, report: dict, queue: list[QueueEntry]) -> None:
    save_json(workspace / "reports/alignment_report.json", report)
    save_json(workspace / "repair_queue.json", {"schema": "custodian.operator_modular_alignment_repair.queue.v1", "entries": [asdict(item) for item in queue]})
    counts = {status: sum(item.status == status for item in queue) for status in ("fixed", "pending", "editing", "unresolved", "skipped", "resolved_by_partner")}
    cards = []
    pairs_by_id = {item["id"]: item for item in report.get("pairs", [])}
    for item in queue:
        runtime_rows = "".join(f"<li>{html.escape(path)}</li>" for path in item.runtime_paths)
        pair_rows = "".join(f"<li>{html.escape(pair)}</li>" for pair in item.implicated_pairs[:12])
        preview = next((pairs_by_id.get(pair) for pair in item.implicated_pairs if pairs_by_id.get(pair, {}).get("review")), None)
        preview_html = ""
        if preview:
            preview_html = (
                f'<a href="{html.escape(preview["gif"])}"><img src="{html.escape(preview["review"])}" '
                f'alt="combined alignment review"></a>'
            )
        cards.append(f"""
<article class="{html.escape(item.status)}">
  <h2>{html.escape(item.layer.upper())} · {html.escape(item.action)} · {html.escape(item.direction.upper())}</h2>
  <strong>{html.escape(item.status.upper())} / {html.escape(item.confidence.upper())}</strong>
  <p><b>Runtime Truth</b><br>source status: {html.escape(item.resolution)}<br>
  roundtrip: {'PASS' if item.roundtrip_pass else 'FAIL / NOT PROVEN'}<br>
  editable source: <code>{html.escape(item.source_path)}</code><br>
  previous source: <code>{html.escape(item.selected_source_path or 'none')}</code></p>
  <p>{html.escape(item.provenance_note)}</p>
  <p>bad frames: {html.escape(', '.join(map(str, item.flagged_frames)))} · max gap {item.max_connector_gap:.1f}px · max center {item.max_connector_center_delta:.1f}px</p>
  {preview_html}
  <details><summary>Runtime sheets</summary><ul>{runtime_rows}</ul></details>
  <details><summary>Implicated pairs</summary><ul>{pair_rows}</ul></details>
</article>""")
    document = f"""<!doctype html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="3">
<title>Modular Alignment Repair</title><style>
body{{background:#12151b;color:#e7e2d5;font:15px system-ui;margin:32px;max-width:1200px}} code{{color:#b9dcff}}
.summary{{position:sticky;top:0;background:#202630;padding:18px;border:1px solid #596777;z-index:2}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(390px,1fr));gap:16px;margin-top:18px}}
article{{background:#1b2028;border-left:6px solid #c15454;padding:16px}} article.fixed,article.resolved_by_partner{{border-color:#5db66f}}
article.ambiguous{{border-color:#ca9b42}} img{{image-rendering:pixelated;max-width:100%}} li{{margin:6px 0}}
</style></head><body><h1>MODULAR ALIGNMENT REPAIR</h1>
<section class="summary"><b>{counts['fixed'] + counts['resolved_by_partner']} / {len(queue)} fixed</b> · {counts['pending']} pending · {counts['editing']} editing · {counts['unresolved']} unresolved · {counts['skipped']} skipped<br>
Runtime sheets {report['runtime_sheets']} · pairings {report['pairings']} · pair frames {report['pair_frames']} · flagged pairings {report['flagged_pairings']}</section>
<main class="grid">{''.join(cards)}</main></body></html>"""
    workspace.mkdir(parents=True, exist_ok=True)
    (workspace / "index.html").write_text(document, encoding="utf-8")


def resolve_aseprite(explicit: Path | None) -> Path:
    candidate = explicit or (Path(os.environ["ASEPRITE_BIN"]) if os.environ.get("ASEPRITE_BIN") else None)
    if candidate is None:
        found = shutil.which("aseprite")
        candidate = Path(found) if found else None
    if candidate is None or not candidate.exists():
        raise RuntimeError("Aseprite not found. Pass --aseprite PATH or set ASEPRITE_BIN.")
    return candidate.resolve()


def launch_editor(aseprite: Path, source: Path, input_fn: Callable[[str], str] = input) -> None:
    started = time.monotonic()
    process = subprocess.Popen([str(aseprite), str(source)])
    process.wait()
    if time.monotonic() - started < 2.0:
        input_fn("Aseprite returned immediately; finish editing/close the document, then press Enter: ")


def validate_entry_source(entry: QueueEntry) -> None:
    validate_sheet_contract(
        Path(entry.source_path), entry.source_frame_count,
        entry.source_frame_width, entry.source_frame_height,
    )


def run_builder(repo_root: Path) -> None:
    subprocess.run(
        [sys.executable, str(BUILDER_PATH), "--strict", "--remove-superseded"],
        cwd=repo_root, check=True,
    )


def merge_prior_state(queue: list[QueueEntry], workspace: Path) -> None:
    state_path = workspace / "state.json"
    if not state_path.exists():
        return
    prior = json.loads(state_path.read_text(encoding="utf-8"))
    by_id = {item["id"]: item for item in prior.get("entries", [])}
    for entry in queue:
        old = by_id.get(entry.id)
        if not old:
            continue
        old_hash = old.get("source_hash")
        current_hash = file_sha256(Path(entry.source_path)) if Path(entry.source_path).exists() else None
        if old.get("status") in {"fixed", "resolved_by_partner"} and old_hash == current_hash:
            entry.status = old["status"]
            entry.source_hash = old_hash
        elif old.get("status") in {"skipped", "unresolved"}:
            entry.status = old["status"]


def persist_state(workspace: Path, queue: list[QueueEntry], current_id: str | None = None) -> None:
    save_json(workspace / "state.json", {
        "schema": "custodian.operator_modular_alignment_repair.state.v1",
        "current_id": current_id, "entries": [asdict(item) for item in queue],
    })


def reconcile_suspicions(
    report: dict,
    reconciler: SourceReconciler,
    *,
    dry_run: bool,
) -> dict[str, EditableSourceRecord]:
    """Reconcile every current suspicion, keyed by resolved runtime path."""
    records: dict[str, EditableSourceRecord] = {}
    for suspicion in report["suspicions"]:
        runtime = Path(suspicion["runtime_path"])
        try:
            record = reconciler.reconcile(runtime, dry_run=dry_run)
        except Exception as exc:
            identity = CHECKER.parse_modular_png_name(runtime)
            semantic = "|".join((identity["part"], identity["variant"], identity["anim_id"], identity["direction"]))
            record = EditableSourceRecord(
                semantic, str(runtime), None, [], None, "unresolved", "", None, None,
                None, f"MATERIALIZATION_FAILED: {exc}", [], [],
            )
        records[runtime_record_key(runtime)] = record
    return records


def merge_live_queue(
    active_queue: list[QueueEntry],
    prior_queue: list[QueueEntry],
    *,
    just_edited_source: str | None = None,
) -> list[QueueEntry]:
    """Merge a freshly computed active queue with the prior live queue.

    New active suspects enter pending. Active entries override prior
    fixed/resolved status. Skipped and unresolved statuses survive while the
    source is still active, except the just-edited item reopens pending.
    Prior entries that disappeared resolve as fixed/skipped when appropriate,
    otherwise resolved_by_partner.
    """
    active_keys = {entry.source_path for entry in active_queue}
    prior_by_key: dict[str, QueueEntry] = {}
    for item in prior_queue:
        prior_by_key.setdefault(item.source_path, item)

    for entry in active_queue:
        prior = prior_by_key.get(entry.source_path)
        if prior is None:
            entry.status = "pending"
            continue
        if entry.source_path == just_edited_source:
            entry.status = "pending"
        elif prior.status == "skipped":
            entry.status = "skipped"
        elif prior.status == "unresolved":
            entry.status = "unresolved"
        else:
            entry.status = "pending"

    historical: list[QueueEntry] = []
    for path, prior in prior_by_key.items():
        if path in active_keys:
            continue
        if path == just_edited_source:
            prior.status = "fixed"
        elif prior.status not in {"fixed", "skipped"}:
            prior.status = "resolved_by_partner"
        historical.append(prior)

    return active_queue + historical


def refresh_live_queue(
    args: argparse.Namespace,
    reconciler: SourceReconciler,
    prior_queue: list[QueueEntry],
    just_edited_source: str | None = None,
) -> tuple[dict, list[QueueEntry]]:
    report = analyze(
        args.runtime_root,
        args.selector,
        args.gap_threshold,
        args.center_threshold,
    )
    records = reconcile_suspicions(report, reconciler, dry_run=False)
    active = build_queue(report, records, args.repo_root)
    merged = merge_live_queue(
        active,
        prior_queue,
        just_edited_source=just_edited_source,
    )
    return report, merged


def interactive_loop(
    args: argparse.Namespace,
    report: dict,
    queue: list[QueueEntry],
    reconciler: SourceReconciler,
    *,
    editor_runner: Callable[[Path, Path], None] = launch_editor,
    builder_runner: Callable[[Path], None] = run_builder,
    input_fn: Callable[[str], str] = input,
) -> None:
    aseprite = resolve_aseprite(args.aseprite)
    while True:
        entry = next(
            (item for item in queue if item.status == "pending"),
            None,
        )
        if entry is None:
            break
        source = Path(entry.source_path)
        if not source.exists() or not entry.roundtrip_pass:
            entry.status = "unresolved"
            persist_state(args.workspace, queue, entry.id)
            continue
        if not args.no_backup:
            reconciler.backup_before_edit(source)
        before = file_sha256(source)
        entry.status = "editing"
        entry.source_hash = before
        persist_state(args.workspace, queue, entry.id)
        write_report(args.workspace, report, queue)
        print(f"[PENDING] {entry.confidence.upper()} {entry.layer} / {entry.action} / {entry.direction}")
        print(f"  bad frames: {','.join(map(str, entry.flagged_frames))}")
        print(f"  opening canonical editable source: {source}")
        editor_runner(aseprite, source)
        after = file_sha256(source)
        if after == before:
            choice = (input_fn("File was not modified. [r] reopen [s] skip [q] save and quit: ") or "r").lower()
            if choice == "q":
                entry.status = "pending"
                persist_state(args.workspace, queue, entry.id)
                return
            if choice == "s":
                entry.status = "skipped"
                persist_state(args.workspace, queue)
            else:
                entry.status = "pending"
            continue
        try:
            validate_entry_source(entry)
        except ValueError as exc:
            entry.status = "unresolved"
            persist_state(args.workspace, queue, entry.id)
            print(f"STOP: {exc}")
            return
        builder_runner(args.repo_root)
        refreshed_report, refreshed_queue = refresh_live_queue(
            args,
            reconciler,
            queue,
            just_edited_source=entry.source_path,
        )
        queue[:] = refreshed_queue
        report = refreshed_report
        refreshed_entry = next(
            (item for item in queue if item.source_path == entry.source_path),
            None,
        )
        if refreshed_entry is None or refreshed_entry.status in {"fixed", "resolved_by_partner"}:
            print("PASS — corrected asset now fits all tested connector combinations")
            persist_state(args.workspace, queue)
            write_report(args.workspace, report, queue)
            continue
        refreshed_entry.status = "unresolved"
        persist_state(args.workspace, queue, refreshed_entry.id)
        write_report(args.workspace, report, queue)
        choice = (input_fn("Still outside connector thresholds. [r] reopen [n] next [s] skip [q] save and quit: ") or "r").lower()
        if choice == "q":
            return
        if choice == "s":
            refreshed_entry.status = "skipped"
        elif choice == "n":
            refreshed_entry.status = "unresolved"
        else:
            refreshed_entry.status = "pending"
    fixed = sum(1 for item in queue if item.status in {"fixed", "resolved_by_partner"})
    unresolved = sum(1 for item in queue if item.status == "unresolved")
    skipped = sum(1 for item in queue if item.status == "skipped")
    print(f"Queue drained: {fixed} fixed, {unresolved} unresolved, {skipped} skipped")


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    args.repo_root = args.repo_root.expanduser().resolve()
    args.runtime_root = args.runtime_root.expanduser().resolve()
    args.source_root = args.source_root.expanduser().resolve()
    args.workspace = args.workspace.expanduser().resolve()
    if args.all_assets:
        args.selector = "all"
    report = analyze(
        args.runtime_root, args.selector, args.gap_threshold, args.center_threshold,
        None if args.dry_run else args.workspace,
    )
    print("Modular Operator Alignment Repair\n---------------------------------")
    print(f"Runtime sheets: {report['runtime_sheets']}")
    print(f"Pairs checked: {report['pairings']}")
    print(f"Pair frames checked: {report['pair_frames']}")
    print(f"Bad pairs: {report['flagged_pairings']}")

    reconciler = SourceReconciler(
        repo_root=args.repo_root, source_root=args.source_root,
        module_root=args.runtime_root, workspace=args.workspace,
    )
    records = reconcile_suspicions(
        report, reconciler, dry_run=args.dry_run or args.report_only
    )
    queue = build_queue(report, records, args.repo_root)
    if args.resume:
        merge_prior_state(queue, args.workspace)
    print(f"Suspect source sheets: {len(queue)}")
    if args.dry_run:
        print(f"Builder: {sys.executable} {BUILDER_PATH} --strict --remove-superseded")
        try:
            print(f"Aseprite: {resolve_aseprite(args.aseprite)}")
        except RuntimeError as exc:
            print(f"Aseprite: unavailable ({exc})")
        for index, entry in enumerate(queue, 1):
            print(f"  {index}. {entry.confidence.upper()} {entry.source_path}")
        return 0
    write_report(args.workspace, report, queue)
    persist_state(args.workspace, queue)
    print(f"Report: {args.workspace / 'index.html'}")
    if not args.no_open:
        webbrowser.open((args.workspace / "index.html").as_uri())
    if args.report_only or args.reconcile_only:
        return 0
    try:
        interactive_loop(args, report, queue, reconciler)
    except KeyboardInterrupt:
        persist_state(args.workspace, queue)
        print("\nState saved; resume with --resume")
        return 130
    subprocess.run(["godot", "--headless", "--path", str(REPO_ROOT / "custodian"), "--import", "--quit"], check=True)
    subprocess.run([
        "godot", "--headless", "--path", str(REPO_ROOT / "custodian"),
        "--script", "res://tools/pipelines/build_operator_animation_resources.gd",
    ], check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
