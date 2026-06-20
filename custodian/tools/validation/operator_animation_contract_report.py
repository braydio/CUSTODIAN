#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = Path(__file__).resolve().parent / "contracts/operator_modular_core.json"
DEFAULT_SOURCE_ROOT = PROJECT_ROOT / "content/sprites/operator/new_operator/modular"
DEFAULT_RUNTIME_ROOT = PROJECT_ROOT / "content/sprites/operator/runtime"

DIRECTIONS = {"s", "se", "e", "ne", "n", "nw", "w", "sw"}
LAYER_ALIASES = {
    "modular_body_lower": "lower_body",
    "modular_body_upper": "upper_body",
    "modular_combined_body": "combined_body",
    "modular_lower_body": "lower_body",
    "modular_ranged_weapon": "ranged_weapon",
    "modular_sidearm": "sidearm",
    "modular_upper_body": "upper_body",
    "modular_upper_fx": "upper_fx",
    "modular_wardrobe_cape": "wardrobe_cape",
    "body": "combined_body",
    "fx": "upper_fx",
    "weapon": "sidearm",
}
VALID_LAYERS = {
    "lower_body",
    "upper_body",
    "upper_fx",
    "wardrobe_cape",
    "sidearm",
    "ranged_weapon",
    "combined_body",
}
VALID_LOADOUTS = {"unarmed", "sidearm", "ranged_2h", "full"}
KNOWN_ACTION_ALIASES = {
    "idle": "idle_01",
    "walk": "walk_01",
    "run": "run_01",
    "stance": "stance_01",
    "aim": "aim_01",
}


@dataclass(frozen=True)
class ExpectedAsset:
    group: str
    label: str
    layer: str
    loadout: str
    action: str
    direction: str
    required: bool
    frame_size: int
    frames: Any = None
    pattern: str = "any"

    @property
    def key(self) -> tuple[str, str, str, str]:
        return (self.layer, self.loadout, self.action, self.direction)


@dataclass
class Asset:
    path: str
    origin: str
    layer: str | None
    loadout: str | None
    action: str | None
    direction: str | None
    frames: int | None
    frame_size: int | None
    width: int | None = None
    height: int | None = None
    issues: list[str] = field(default_factory=list)

    @property
    def key(self) -> tuple[str, str, str, str] | None:
        if not (self.layer and self.loadout and self.action and self.direction):
            return None
        return (self.layer, self.loadout, self.action, self.direction)


def main() -> int:
    parser = argparse.ArgumentParser(description="Report modular Operator animation coverage against a contract.")
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true", dest="json_output")
    parser.add_argument("--owner", default="operator")
    parser.add_argument("--source-root", type=Path, default=DEFAULT_SOURCE_ROOT)
    parser.add_argument("--runtime-root", type=Path, default=DEFAULT_RUNTIME_ROOT)
    args = parser.parse_args()

    contract = json.loads(args.contract.read_text(encoding="utf-8"))
    expected = expand_contract(contract)
    assets = scan_assets(args.source_root, args.runtime_root, owner=args.owner)
    report = build_report(contract, expected, assets)

    if args.json_output:
        print(json.dumps(report, indent=2))
    else:
        print_text_report(report)

    if args.strict and (
        report["summary"]["missing_required"] > 0
        or report["summary"]["suspicious_required_assets"] > 0
    ):
        return 1
    return 0


def expand_contract(contract: dict[str, Any]) -> list[ExpectedAsset]:
    default_dirs = contract.get("directions", sorted(DIRECTIONS))
    default_frame_size = int(contract.get("frame_size", 96))
    out: list[ExpectedAsset] = []
    for group in contract.get("groups", []):
        group_required = bool(group.get("required", False))
        group_id = str(group["id"])
        label = str(group.get("label", group_id))
        for entry in group.get("entries", []):
            directions = entry.get("directions", default_dirs)
            if directions == "all":
                directions = default_dirs
            required = bool(entry.get("required", group_required))
            for direction in directions:
                out.append(
                    ExpectedAsset(
                        group=group_id,
                        label=label,
                        layer=str(entry["layer"]),
                        loadout=str(entry["loadout"]),
                        action=str(entry["action"]),
                        direction=str(direction),
                        required=required,
                        frame_size=int(entry.get("frame_size", default_frame_size)),
                        frames=entry.get("frames"),
                        pattern=str(entry.get("pattern", "any")),
                    )
                )
    return out


def scan_assets(source_root: Path, runtime_root: Path, *, owner: str) -> list[Asset]:
    assets: list[Asset] = []
    if source_root.exists():
        for path in sorted(source_root.rglob("*.png")):
            assets.append(parse_asset(path, source_root, "source", owner))
    module_root = runtime_root / "modules/new_operator"
    if module_root.exists():
        for path in sorted(module_root.rglob("*.png")):
            assets.append(parse_asset(path, runtime_root, "runtime_module", owner))
    actions_root = runtime_root / "actions"
    if actions_root.exists():
        for path in sorted(actions_root.rglob("*.png")):
            assets.append(parse_asset(path, runtime_root, "action_runtime", owner))
    mark_superseded_siblings(assets)
    return assets


def parse_asset(path: Path, root: Path, origin: str, owner: str) -> Asset:
    rel = path.relative_to(root).as_posix()
    asset = Asset(rel, origin, None, None, None, None, None, None)
    if path.name.endswith(".import"):
        asset.issues.append("unexpected .import sidecar in PNG scan")
        return asset
    parts = path.stem.split("__")
    if len(parts) < 6 or parts[0] != owner:
        asset.issues.append("noncanonical or non-operator filename")
        inspect_image(path, asset)
        return asset

    try:
        direction = parts[-3]
        frames = int(parts[-2].removesuffix("f"))
        frame_size = int(re.sub(r"\D.*$", "", parts[-1]))
    except ValueError:
        asset.issues.append("cannot parse direction/frame metadata")
        inspect_image(path, asset)
        return asset

    raw_layer = parts[1]
    layer = LAYER_ALIASES.get(raw_layer)
    if raw_layer == "modular_upper_body" and len(parts) >= 7 and parts[2] == "weapon" and parts[3] == "ranged_2h":
        layer = "ranged_weapon"
        loadout = "ranged_2h"
        action = "stance_01"
    elif raw_layer == "body" and len(parts) >= 7 and parts[2] == "full":
        layer = "combined_body"
        loadout = "full"
        action = parts[3]
    elif raw_layer == "fx" and len(parts) >= 7 and parts[2] == "full":
        layer = "upper_fx"
        loadout = "full"
        action = parts[3]
    elif raw_layer == "body":
        layer = "combined_body"
        loadout = parts[2]
        action = "__".join(parts[3:-3])
    elif raw_layer == "fx":
        layer = "upper_fx"
        loadout = parts[2]
        action = "__".join(parts[3:-3])
    elif raw_layer == "weapon" and len(parts) >= 7 and parts[2] == "sidearm_pistol":
        layer = "sidearm"
        loadout = "sidearm"
        action = "__".join(parts[3:-3])
    else:
        if layer is None:
            asset.issues.append(f"unknown modular layer: {raw_layer}")
            layer = raw_layer
        if len(parts) < 7:
            asset.issues.append("missing loadout/action tokens")
            loadout = None
            action = None
        else:
            token_a = parts[2]
            token_b = "__".join(parts[3:-3])
            if token_a in VALID_LOADOUTS and token_b:
                loadout = token_a
                action = token_b
            elif token_b in VALID_LOADOUTS:
                loadout = token_b
                action = KNOWN_ACTION_ALIASES.get(token_a, token_a)
            else:
                loadout = "unarmed"
                action = KNOWN_ACTION_ALIASES.get(token_b or token_a, token_b or token_a)

    asset.layer = layer
    asset.loadout = loadout
    asset.action = action
    asset.direction = direction
    asset.frames = frames
    asset.frame_size = frame_size

    if direction not in DIRECTIONS:
        asset.issues.append(f"unsupported direction: {direction}")
    if layer not in VALID_LAYERS:
        asset.issues.append(f"unknown normalized layer: {layer}")
    if loadout and loadout not in VALID_LOADOUTS:
        asset.issues.append(f"unknown loadout: {loadout}")
    if frame_size != 96:
        asset.issues.append(f"wrong frame size in filename: {frame_size}")
    inspect_image(path, asset)
    return asset


def inspect_image(path: Path, asset: Asset) -> None:
    try:
        with Image.open(path) as image:
            asset.width, asset.height = image.size
    except Exception as exc:
        asset.issues.append(f"cannot inspect image: {exc}")
        return
    if asset.frames and asset.frame_size:
        expected_width = asset.frames * asset.frame_size
        if asset.width != expected_width or asset.height != asset.frame_size:
            asset.issues.append(
                f"declared {asset.frames}x{asset.frame_size}px expects {expected_width}x{asset.frame_size}, got {asset.width}x{asset.height}"
            )
        if asset.width and asset.frame_size and asset.width % asset.frame_size == 0:
            implied = asset.width // asset.frame_size
            if implied != asset.frames:
                asset.issues.append(f"filename declares {asset.frames} frames but width implies {implied}")


def mark_superseded_siblings(assets: list[Asset]) -> None:
    by_identity: dict[tuple[str, str, str, str, str, str], list[Asset]] = {}
    for asset in assets:
        if asset.key is None:
            continue
        directory = str(Path(asset.path).parent)
        identity = (*asset.key, asset.origin, directory)
        by_identity.setdefault(identity, []).append(asset)
    for siblings in by_identity.values():
        variants = {(a.frames, a.frame_size) for a in siblings}
        if len(variants) <= 1:
            continue
        for asset in siblings:
            asset.issues.append("possible superseded sibling with same semantic identity and different frame count/size")


def build_report(contract: dict[str, Any], expected: list[ExpectedAsset], assets: list[Asset]) -> dict[str, Any]:
    expected_by_key: dict[tuple[str, str, str, str], list[ExpectedAsset]] = {}
    for item in expected:
        expected_by_key.setdefault(item.key, []).append(item)
    expected_identities = {(item.layer, item.loadout, item.action) for item in expected}

    assets_by_key: dict[tuple[str, str, str, str], list[Asset]] = {}
    malformed: list[Asset] = []
    for asset in assets:
        if asset.key is None:
            malformed.append(asset)
        else:
            assets_by_key.setdefault(asset.key, []).append(asset)

    ok_required: list[dict[str, Any]] = []
    missing_required: list[ExpectedAsset] = []
    missing_optional: list[ExpectedAsset] = []
    suspicious: list[dict[str, Any]] = []
    suspicious_required = 0

    for item in expected:
        matches = [asset for asset in assets_by_key.get(item.key, []) if frames_match(item.frames, asset.frames) and asset.frame_size == item.frame_size]
        suspicious_matches = [asset for asset in assets_by_key.get(item.key, []) if asset.issues]
        if matches:
            if item.required:
                ok_required.append({"expected": expected_dict(item), "paths": [a.path for a in matches]})
        else:
            (missing_required if item.required else missing_optional).append(item)
        if item.required and suspicious_matches:
            suspicious_required += len(suspicious_matches)

    for asset in assets:
        issues = list(asset.issues)
        if (
            asset.key
            and asset.action
            and asset.key not in expected_by_key
            and (asset.layer, asset.loadout, asset.action) not in expected_identities
        ):
            issues.append(f"unknown action not present in contract: {asset.action}")
        if issues:
            suspicious.append({"asset": asset_dict(asset), "issues": issues})

    source_keys = {asset.key for asset in assets if asset.origin == "source" and asset.key is not None}
    runtime_keys = {asset.key for asset in assets if asset.origin in {"runtime_module", "action_runtime"} and asset.key is not None}
    source_no_runtime = sorted(source_keys - runtime_keys)
    runtime_no_source = sorted(runtime_keys - source_keys)
    extra_keys = sorted(key for key in assets_by_key if key not in expected_by_key)

    report = {
        "schema": "custodian.operator_animation_contract_report.v1",
        "contract": contract.get("schema", "unknown"),
        "owner": contract.get("owner", "operator"),
        "summary": {
            "expected": len(expected),
            "required_expected": sum(1 for item in expected if item.required),
            "assets_scanned": len(assets),
            "ok_required": len(ok_required),
            "missing_required": len(missing_required),
            "missing_optional": len(missing_optional),
            "suspicious_assets": len(suspicious),
            "suspicious_required_assets": suspicious_required,
            "extra_uncontracted_keys": len(extra_keys),
            "source_exists_runtime_missing": len(source_no_runtime),
            "runtime_exists_source_missing": len(runtime_no_source),
        },
        "ok_required_assets": ok_required,
        "missing_required_assets": [expected_dict(item) for item in missing_required],
        "missing_optional_assets": [expected_dict(item) for item in missing_optional],
        "suspicious_assets": suspicious,
        "extra_uncontracted_assets": [key_dict(key, assets_by_key[key]) for key in extra_keys],
        "source_exists_but_runtime_missing": [semantic_dict(key) for key in source_no_runtime],
        "runtime_exists_but_source_missing": [semantic_dict(key) for key in runtime_no_source],
        "suggested_next_production_batch": suggested_batch(missing_required),
    }
    return report


def frames_match(expected: Any, actual: int | None) -> bool:
    if expected is None or actual is None:
        return True
    if isinstance(expected, int):
        return actual == expected
    if isinstance(expected, dict):
        return int(expected.get("min", actual)) <= actual <= int(expected.get("max", actual))
    return True


def expected_dict(item: ExpectedAsset) -> dict[str, Any]:
    return asdict(item)


def asset_dict(asset: Asset) -> dict[str, Any]:
    return asdict(asset)


def semantic_dict(key: tuple[str, str, str, str]) -> dict[str, str]:
    layer, loadout, action, direction = key
    return {"layer": layer, "loadout": loadout, "action": action, "direction": direction}


def key_dict(key: tuple[str, str, str, str], assets: list[Asset]) -> dict[str, Any]:
    return {**semantic_dict(key), "paths": [asset.path for asset in assets]}


def suggested_batch(missing: list[ExpectedAsset]) -> list[dict[str, Any]]:
    grouped: dict[tuple[str, str], dict[str, Any]] = {}
    for item in missing:
        key = (item.group, item.action)
        row = grouped.setdefault(key, {"group": item.group, "action": item.action, "items": []})
        row["items"].append(
            {
                "layer": item.layer,
                "loadout": item.loadout,
                "direction": item.direction,
                "frame_size": item.frame_size,
                "frames": item.frames,
            }
        )
    return list(grouped.values())[:12]


def print_text_report(report: dict[str, Any]) -> None:
    print("Operator Animation Contract Report")
    print("==================================")
    for key, value in report["summary"].items():
        print(f"{key}: {value}")
    print_section("OK required assets", [fmt_ok(item) for item in report["ok_required_assets"]], limit=40)
    print_section("Missing required assets", [fmt_expected(item) for item in report["missing_required_assets"]], limit=80)
    print_section("Missing optional assets", [fmt_expected(item) for item in report["missing_optional_assets"]], limit=60)
    print_section("Suspicious assets", [fmt_suspicious(item) for item in report["suspicious_assets"]], limit=80)
    print_section("Extra/uncontracted assets", [fmt_extra(item) for item in report["extra_uncontracted_assets"]], limit=60)
    print_section("Source exists but runtime module missing", [fmt_semantic(item) for item in report["source_exists_but_runtime_missing"]], limit=60)
    print_section("Runtime exists but source missing", [fmt_semantic(item) for item in report["runtime_exists_but_source_missing"]], limit=60)
    batch_lines = []
    for batch in report["suggested_next_production_batch"]:
        dirs = ",".join(sorted({item["direction"] for item in batch["items"]}))
        layers = ",".join(sorted({item["layer"] for item in batch["items"]}))
        batch_lines.append(f"{batch['group']} / {batch['action']}: {layers} [{dirs}]")
    print_section("Suggested next production batch", batch_lines, limit=20)


def print_section(title: str, lines: list[str], *, limit: int) -> None:
    print()
    print(title)
    print("-" * len(title))
    if not lines:
        print("(none)")
        return
    for line in lines[:limit]:
        print(f"- {line}")
    if len(lines) > limit:
        print(f"... and {len(lines) - limit} more")


def fmt_expected(item: dict[str, Any]) -> str:
    return f"{item['group']} {item['layer']}/{item['loadout']}/{item['action']}/{item['direction']} frames={item['frames']}"


def fmt_ok(item: dict[str, Any]) -> str:
    exp = item["expected"]
    return f"{exp['layer']}/{exp['loadout']}/{exp['action']}/{exp['direction']} -> {', '.join(item['paths'][:2])}"


def fmt_suspicious(item: dict[str, Any]) -> str:
    asset = item["asset"]
    return f"{asset['path']}: {'; '.join(item['issues'])}"


def fmt_extra(item: dict[str, Any]) -> str:
    return f"{fmt_semantic(item)} -> {', '.join(item['paths'][:2])}"


def fmt_semantic(item: dict[str, str]) -> str:
    return f"{item['layer']}/{item['loadout']}/{item['action']}/{item['direction']}"


if __name__ == "__main__":
    raise SystemExit(main())
