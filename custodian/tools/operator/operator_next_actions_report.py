#!/usr/bin/env python3
"""Join modular visual-fit evidence to the Operator production contract.

This is an offline review helper. It writes generated artifacts beside a
modular_combo_check.py manifest and never participates in runtime authority.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from types import ModuleType
from typing import Any, Iterable


GROUP_WEIGHTS = {
    "core_locomotion": 1000,
    "fast_attack": 950,
    "defense": 650,
    "dodge": 575,
    "field_patch": 525,
    "sidearm_actions": 500,
    "ranged_2h_stance": 475,
    "future_ranged_fire": 350,
    "optional_layers": 100,
}

RUNTIME_CONSUMERS = [
    "custodian/game/actors/operator/operator_runtime_frames.tres",
    "custodian/game/actors/operator/operator_weapon_frames.tres",
    "custodian/game/actors/operator/operator_melee_overlay_frames.tres",
    "custodian/game/actors/operator/operator_ranged_fx_frames.tres",
    "custodian/game/actors/operator/operator_modular_lower_body_frames.tres",
    "custodian/game/actors/operator/operator_modular_upper_body_frames.tres",
    "custodian/game/actors/operator/operator_modular_sidearm_frames.tres",
    "custodian/game/actors/operator/operator_modular_upper_fx_frames.tres",
    "custodian/game/actors/operator/operator_modular_cape_frames.tres",
]

LAYER_TOKENS = {
    "lower_body": "modular_lower_body",
    "upper_body": "modular_upper_body",
    "upper_fx": "modular_upper_fx",
    "wardrobe_cape": "modular_wardrobe_cape",
    "sidearm": "modular_sidearm",
    "ranged_weapon": "modular_ranged_weapon",
    "combined_body": "body",
}

SOURCE_FOLDER_BY_GROUP = {
    "core_locomotion": None,
    "fast_attack": "fast_attack",
    "defense": "block",
    "dodge": "dodge",
    "field_patch": "actions/field_patch",
    "sidearm_actions": "sidearm",
    "ranged_2h_stance": "ranged",
    "future_ranged_fire": "ranged",
    "optional_layers": "fast_attack",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate prioritized Operator animation implementation recommendations."
    )
    parser.add_argument("--combo-manifest", type=Path, required=True)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--contract", type=Path, default=None)
    parser.add_argument("--fit-gap-threshold", type=int, default=3)
    parser.add_argument("--fit-center-threshold", type=int, default=5)
    parser.add_argument("--max-actions", type=int, default=20)
    return parser.parse_args()


def load_contract_reporter(repo_root: Path) -> ModuleType:
    path = repo_root / "custodian/tools/validation/operator_animation_contract_report.py"
    spec = importlib.util.spec_from_file_location("custodian_operator_contract_report", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load contract reporter: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def repo_path(path: Path, repo_root: Path) -> str:
    resolved = path.expanduser().resolve()
    try:
        return resolved.relative_to(repo_root).as_posix()
    except ValueError:
        return resolved.as_posix()


def git_commit(repo_root: Path) -> str:
    completed = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )
    return completed.stdout.strip() if completed.returncode == 0 else "unknown"


def expected_frame_count(value: Any) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, dict):
        return int(value.get("min", value.get("max", 1)))
    return 1


def semantic_key(item: Any) -> tuple[str, str, str, str]:
    if hasattr(item, "key"):
        return tuple(item.key)
    return (str(item["layer"]), str(item["loadout"]), str(item["action"]), str(item["direction"]))


def asset_absolute(asset: Any, source_root: Path, runtime_root: Path) -> Path:
    root = source_root if asset.origin == "source" else runtime_root
    return (root / asset.path).resolve()


def replace_direction_and_frames(path: Path, direction: str, frames: int, frame_size: int) -> Path:
    name = re.sub(
        r"__(s|se|e|ne|n|nw|w|sw)__\d+f__\d+(?=\.png$)",
        f"__{direction}__{frames}f__{frame_size}",
        path.name,
        flags=re.IGNORECASE,
    )
    return path.with_name(name)


def fallback_source_path(item: Any, source_root: Path) -> Path:
    group = str(item.group)
    action = str(item.action)
    folder = SOURCE_FOLDER_BY_GROUP.get(group)
    if group == "core_locomotion":
        folder = action.split("_", 1)[0]
    parent = source_root / (folder or action)
    layer = LAYER_TOKENS.get(str(item.layer), str(item.layer))
    frames = expected_frame_count(item.frames)
    if str(item.layer) == "combined_body":
        name = f"operator__body__{item.loadout}__{action}__{item.direction}__{frames}f__{item.frame_size}.png"
    else:
        name = f"operator__{layer}__{item.loadout}__{action}__{item.direction}__{frames}f__{item.frame_size}.png"
    return parent / name


def expected_source_paths(
    item: Any,
    assets_by_key: dict[tuple[str, str, str, str], list[Any]],
    source_assets_by_identity: dict[tuple[str, str, str], list[Any]],
    source_root: Path,
    runtime_root: Path,
) -> list[Path]:
    exact = [
        asset_absolute(asset, source_root, runtime_root)
        for asset in assets_by_key.get(semantic_key(item), [])
        if asset.origin == "source"
    ]
    if exact:
        return exact
    siblings = source_assets_by_identity.get((item.layer, item.loadout, item.action), [])
    if siblings:
        sibling = asset_absolute(siblings[0], source_root, runtime_root)
        return [replace_direction_and_frames(sibling, item.direction, expected_frame_count(item.frames), item.frame_size)]
    return [fallback_source_path(item, source_root)]


def expected_runtime_paths(item: Any, runtime_root: Path) -> list[Path]:
    layer = str(item.layer)
    action = str(item.action)
    loadout = str(item.loadout)
    direction = str(item.direction)
    frames = expected_frame_count(item.frames)
    frame_size = int(item.frame_size)
    token = LAYER_TOKENS.get(layer, layer)
    if layer == "combined_body":
        filename = f"operator__body__{loadout}__{action}__{direction}__{frames}f__{frame_size}.png"
    else:
        filename = f"operator__{token}__{loadout}__{action}__{direction}__{frames}f__{frame_size}.png"

    module_root = runtime_root / "modules/new_operator"
    if action in {"idle_01", "walk_01", "run_01"}:
        path = module_root / layer / "locomotion" / action / filename
    elif item.group == "fast_attack":
        path = module_root / layer / "actions/unarmed/fast_attack" / action / filename
    elif layer == "sidearm":
        path = module_root / layer / "actions" / action / filename
    else:
        path = module_root / layer / "actions" / loadout / action / filename
    paths = [path]

    if item.group == "fast_attack" and layer in {"lower_body", "upper_body", "upper_fx"}:
        action_layer = "overlay" if layer == "upper_fx" else "body"
        action_name = f"operator__{action_layer}__unarmed__{action}__{direction}__{frames}f__{frame_size}.png"
        paths.append(runtime_root / "actions/unarmed/fast_attack" / action_layer / action_name)
    return paths


def priority_for(score: int) -> str:
    if score >= 1800:
        return "P0"
    if score >= 1000:
        return "P1"
    if score >= 600:
        return "P2"
    return "P3"


def report_commands(group_id: str) -> tuple[list[str], list[str]]:
    implementation = [
        "python custodian/tools/pipelines/build_operator_modular_runtime.py --remove-superseded",
        "python custodian/tools/validation/operator_animation_contract_report.py",
        "python custodian/tools/validation/operator_modular_pipeline_smoke.py",
    ]
    smoke = "operator_modular_fast_attack_smoke.gd" if group_id == "fast_attack" else "operator_modular_layers_smoke.gd"
    validation = [
        "python custodian/tools/validation/operator_animation_contract_report.py --strict",
        "python custodian/tools/validation/operator_modular_pipeline_smoke.py",
        f"cd custodian && godot --headless --script tools/validation/{smoke}",
    ]
    return implementation, validation


def build_actions(
    manifest: dict[str, Any],
    contract: dict[str, Any],
    expected: list[Any],
    assets: list[Any],
    contract_report: dict[str, Any],
    repo_root: Path,
    source_root: Path,
    runtime_root: Path,
    gap_threshold: int,
    center_threshold: int,
) -> list[dict[str, Any]]:
    expected_by_group_dir: dict[tuple[str, str], list[Any]] = defaultdict(list)
    expected_by_action_dir: dict[tuple[str, str], list[Any]] = defaultdict(list)
    group_labels: dict[str, str] = {}
    group_required: dict[str, bool] = {}
    for group in contract.get("groups", []):
        group_labels[str(group["id"])] = str(group.get("label", group["id"]))
        group_required[str(group["id"])] = bool(group.get("required", False))
    for item in expected:
        expected_by_group_dir[(item.group, item.direction)].append(item)
        expected_by_action_dir[(item.action, item.direction)].append(item)

    assets_by_key: dict[tuple[str, str, str, str], list[Any]] = defaultdict(list)
    source_assets_by_identity: dict[tuple[str, str, str], list[Any]] = defaultdict(list)
    for asset in assets:
        if asset.key is None:
            continue
        assets_by_key[tuple(asset.key)].append(asset)
        if asset.origin == "source":
            source_assets_by_identity[(asset.layer, asset.loadout, asset.action)].append(asset)

    state: dict[tuple[str, str], dict[str, Any]] = defaultdict(
        lambda: {
            "record_ids": set(),
            "flagged_frames": set(),
            "max_gap": 0.0,
            "max_center": 0.0,
            "missing_required": 0,
            "missing_optional": 0,
            "source_runtime_missing": 0,
            "suspicious": 0,
            "fit_issue": False,
            "shared_lower": False,
        }
    )

    for record in manifest.get("records", []):
        direction = str(record.get("direction", ""))
        actions = {str(record.get("lower_anim", ""))}
        actions.update(str(value) for value in record.get("chain_phases", []))
        upper_anim = str(record.get("upper_anim", ""))
        actions.update(part.strip() for part in upper_anim.split("→") if part.strip())
        matching_groups = {
            (item.group, item.direction)
            for action in actions
            for item in expected_by_action_dir.get((action, direction), [])
        }
        if not matching_groups:
            continue
        fit_rows = record.get("fit_debug", [])
        flagged = []
        max_gap = 0.0
        max_center = 0.0
        for row in fit_rows:
            gap = row.get("vertical_gap_px")
            center = row.get("horizontal_center_delta_px")
            gap_abs = abs(float(gap)) if gap is not None else 0.0
            center_abs = abs(float(center)) if center is not None else 0.0
            max_gap = max(max_gap, gap_abs)
            max_center = max(max_center, center_abs)
            if gap_abs >= gap_threshold or center_abs >= center_threshold:
                flagged.append(int(row.get("frame", 0)))
        for key in matching_groups:
            item_state = state[key]
            item_state["record_ids"].add(str(record.get("id", "unknown")))
            item_state["max_gap"] = max(item_state["max_gap"], max_gap)
            item_state["max_center"] = max(item_state["max_center"], max_center)
            for frame in flagged:
                item_state["flagged_frames"].add((str(record.get("id", "unknown")), frame))
            item_state["fit_issue"] = item_state["fit_issue"] or bool(flagged)
            if key[0] == "core_locomotion" and str(record.get("pair_mode", "")) == "action_fanout":
                item_state["shared_lower"] = True

    for field, counter in [
        ("missing_required_assets", "missing_required"),
        ("missing_optional_assets", "missing_optional"),
    ]:
        for item in contract_report.get(field, []):
            state[(str(item["group"]), str(item["direction"]))][counter] += 1

    for item in contract_report.get("source_exists_but_runtime_missing", []):
        for expected_item in expected_by_action_dir.get((str(item["action"]), str(item["direction"])), []):
            if expected_item.layer == item["layer"] and expected_item.loadout == item["loadout"]:
                state[(expected_item.group, expected_item.direction)]["source_runtime_missing"] += 1

    for suspicious in contract_report.get("suspicious_assets", []):
        asset = suspicious.get("asset", {})
        for expected_item in expected_by_action_dir.get((str(asset.get("action", "")), str(asset.get("direction", ""))), []):
            if expected_item.layer == asset.get("layer") and expected_item.loadout == asset.get("loadout"):
                state[(expected_item.group, expected_item.direction)]["suspicious"] += 1

    actions: list[dict[str, Any]] = []
    for key, item_state in state.items():
        group_id, direction = key
        has_signal = (
            item_state["fit_issue"]
            or item_state["missing_required"]
            or item_state["missing_optional"]
            or item_state["source_runtime_missing"]
            or item_state["suspicious"]
        )
        if not has_signal:
            continue
        group_items = expected_by_group_dir.get(key, [])
        score = GROUP_WEIGHTS.get(group_id, 100)
        score += item_state["missing_required"] * 400
        score += len(item_state["record_ids"]) * 70
        score += len(item_state["flagged_frames"]) * 25
        score += int(round(item_state["max_gap"] * 10))
        score += int(round(item_state["max_center"] * 6))
        score += 180 if item_state["shared_lower"] else 0
        score += item_state["source_runtime_missing"] * 375

        sources: list[dict[str, Any]] = []
        runtime_paths: set[str] = set()
        for expected_item in group_items:
            for path in expected_source_paths(
                expected_item, assets_by_key, source_assets_by_identity, source_root, runtime_root
            ):
                source_record = {
                    "repo_path": repo_path(path, repo_root),
                    "absolute_path": str(path.resolve()),
                    "exists": path.exists(),
                    "layer": expected_item.layer,
                    "loadout": expected_item.loadout,
                    "action": expected_item.action,
                    "direction": expected_item.direction,
                }
                if source_record not in sources:
                    sources.append(source_record)
            for path in expected_runtime_paths(expected_item, runtime_root):
                runtime_paths.add(repo_path(path, repo_root))

        reasons = []
        if item_state["missing_required"]:
            reasons.append(f"{item_state['missing_required']} required contract assets are missing")
        if item_state["missing_optional"]:
            reasons.append(f"{item_state['missing_optional']} grouped optional assets are missing")
        if item_state["source_runtime_missing"]:
            reasons.append(f"{item_state['source_runtime_missing']} source assets have no generated runtime counterpart")
        if item_state["fit_issue"]:
            reasons.append(
                f"{len(item_state['flagged_frames'])} fit frames exceed gap/center thresholds "
                f"(max gap {item_state['max_gap']:.1f}px, center delta {item_state['max_center']:.1f}px)"
            )
        if item_state["shared_lower"]:
            reasons.append("a shared locomotion lower body affects multiple upper-action combinations")
        if item_state["suspicious"]:
            reasons.append(f"{item_state['suspicious']} matching assets have suspicious metadata")

        implementation, validation = report_commands(group_id)
        label = group_labels.get(group_id, group_id.replace("_", " ").title())
        actions.append(
            {
                "priority": "",
                "score": score,
                "title": f"Finalize {label} — {direction.upper()}",
                "group": group_id,
                "group_label": label,
                "production_required": group_required.get(group_id, False),
                "reason": "; ".join(reasons),
                "reasons": reasons,
                "affected_directions": [direction],
                "affected_actions": sorted({item.action for item in group_items}),
                "other_phase_sheets": [source["repo_path"] for source in sources],
                "source_files": sources,
                "expected_runtime_paths": sorted(runtime_paths),
                "dependent_combinations": len(item_state["record_ids"]),
                "dependent_combination_ids": sorted(item_state["record_ids"]),
                "flagged_frame_count": len(item_state["flagged_frames"]),
                "maximum_seam_gap_px": item_state["max_gap"],
                "maximum_horizontal_center_delta_px": item_state["max_center"],
                "implementation_commands": implementation,
                "validation_commands": validation,
                "runtime_registration_consumers": RUNTIME_CONSUMERS,
                "acceptance_criteria": [
                    f"Review and approve every {direction.upper()} sheet in the grouped production unit together.",
                    f"All reviewed frames remain below {gap_threshold}px seam-gap and {center_threshold}px center-delta thresholds, or carry an explicit visual exception.",
                    "The production contract reports no new required gaps or suspicious metadata for this group.",
                    "Generated runtime outputs exist at the listed destinations and focused playback validation passes.",
                ],
            }
        )

    actions.sort(key=lambda item: (-int(item["score"]), item["group"], item["affected_directions"]))
    for rank, action in enumerate(actions, 1):
        action["rank"] = rank
        action["priority"] = priority_for(int(action["score"]))
    return actions


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# Operator Modular Next Actions",
        "",
        "> Generated artifact—not project authority. Production priority comes from "
        "`operator_modular_core.json`; visual evidence comes from the combo-check manifest.",
        "",
        f"Generated: `{report['generated_at_utc']}`  ",
        f"Commit: `{report['commit_sha']}`  ",
        f"Recommendations: `{len(report['actions'])}`",
        "",
    ]
    if not report["actions"]:
        lines.append("No actionable contract, drift, metadata, or fit findings were found.")
    for action in report["actions"]:
        lines.extend(
            [
                f"## {action['rank']}. {action['priority']} — {action['title']}",
                "",
                f"Score: **{action['score']}**",
                "",
                action["reason"],
                "",
                "Source approval unit:",
                "",
            ]
        )
        lines.extend(f"- `{source['repo_path']}`" for source in action["source_files"])
        lines.extend(["", "Expected runtime outputs:", ""])
        lines.extend(f"- `{runtime}`" for runtime in action["expected_runtime_paths"])
        lines.extend(["", "Implementation:", "", "```bash"])
        lines.extend(action["implementation_commands"])
        lines.extend(["```", "", "Validation:", "", "```bash"])
        lines.extend(action["validation_commands"])
        lines.extend(["```", "", "Acceptance:", ""])
        lines.extend(f"- {criterion}" for criterion in action["acceptance_criteria"])
        lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.expanduser().resolve()
    manifest_path = args.combo_manifest.expanduser().resolve()
    if not manifest_path.exists():
        print(f"ERROR: combo manifest does not exist: {manifest_path}", file=sys.stderr)
        return 2
    if args.max_actions <= 0:
        print("ERROR: --max-actions must be positive", file=sys.stderr)
        return 2

    reporter = load_contract_reporter(repo_root)
    contract_path = (
        args.contract.expanduser().resolve()
        if args.contract is not None
        else repo_root / "custodian/tools/validation/contracts/operator_modular_core.json"
    )
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    expected = reporter.expand_contract(contract)
    source_root = repo_root / "custodian/content/sprites/operator/new_operator/modular"
    runtime_root = repo_root / "custodian/content/sprites/operator/runtime"
    assets = reporter.scan_assets(source_root, runtime_root, owner="operator")
    contract_report = reporter.build_report(contract, expected, assets)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    actions = build_actions(
        manifest,
        contract,
        expected,
        assets,
        contract_report,
        repo_root,
        source_root,
        runtime_root,
        args.fit_gap_threshold,
        args.fit_center_threshold,
    )[: args.max_actions]
    for rank, action in enumerate(actions, 1):
        action["rank"] = rank

    report = {
        "schema": "custodian.operator_modular_next_actions.v1",
        "notice": "Generated artifact—not project authority.",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "commit_sha": git_commit(repo_root),
        "repo_root": str(repo_root),
        "combo_manifest": {
            "repo_path": repo_path(manifest_path, repo_root),
            "absolute_path": str(manifest_path),
            "schema": manifest.get("schema", "unknown"),
        },
        "contract": repo_path(contract_path, repo_root),
        "thresholds": {
            "fit_gap_px": args.fit_gap_threshold,
            "fit_center_px": args.fit_center_threshold,
        },
        "contract_summary": contract_report.get("summary", {}),
        "actions": actions,
    }

    reports_dir = manifest_path.parent
    reports_dir.mkdir(parents=True, exist_ok=True)
    json_path = reports_dir / "next_actions.json"
    markdown_path = reports_dir / "NEXT_ACTIONS.md"
    json_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    write_markdown(report, markdown_path)
    print(f"next actions: {len(actions)}")
    print(f"json: {json_path}")
    print(f"markdown: {markdown_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
