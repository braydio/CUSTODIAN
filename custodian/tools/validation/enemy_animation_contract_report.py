#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = Path(__file__).resolve().parent / "contracts/enemy_animation_base.json"
DEFAULT_ENEMY_ROOT = PROJECT_ROOT / "content/sprites/enemies"

_FILENAME_RE = re.compile(
    r"^(?P<enemy_id>enemy_[a-z0-9_]+)"
    r"__(?P<layer>[a-z0-9_]+)"
    r"__(?P<action_group>[a-z0-9_]+)"
    r"__(?P<action>[a-z0-9_]+)"
    r"__(?P<direction>s|se|e|ne|n|nw|w|sw)"
    r"__(?P<frames>[1-9][0-9]*)f"
    r"__(?P<frame_size>[1-9][0-9]*(?:x[1-9][0-9]*)?)\.png$"
)


@dataclass(frozen=True)
class EnemyAnimationAsset:
    enemy_id: str
    layer: str
    action_group: str
    action: str
    direction: str
    frames: int
    frame_width: int
    frame_height: int
    path: str

    @property
    def semantic_key(self) -> str:
        return "/".join((self.layer, self.action_group, self.action, self.direction))


def _parse_frame_size(token: str) -> tuple[int, int]:
    if "x" not in token:
        size = int(token)
        return size, size
    width, height = token.split("x", 1)
    return int(width), int(height)


def parse_asset(path: Path, enemy_root: Path) -> EnemyAnimationAsset | None:
    match = _FILENAME_RE.fullmatch(path.name)
    if not match:
        return None
    width, height = _parse_frame_size(match.group("frame_size"))
    return EnemyAnimationAsset(
        enemy_id=match.group("enemy_id"),
        layer=match.group("layer"),
        action_group=match.group("action_group"),
        action=match.group("action"),
        direction=match.group("direction"),
        frames=int(match.group("frames")),
        frame_width=width,
        frame_height=height,
        path=path.relative_to(PROJECT_ROOT).as_posix(),
    )


def scan_enemy(enemy_id: str, enemy_root: Path) -> tuple[list[EnemyAnimationAsset], list[str]]:
    runtime_root = enemy_root / enemy_id / "runtime"
    if not runtime_root.is_dir():
        return [], [f"missing runtime directory: {runtime_root.relative_to(PROJECT_ROOT).as_posix()}"]

    assets: list[EnemyAnimationAsset] = []
    invalid_names: list[str] = []
    for path in sorted(runtime_root.rglob("*.png")):
        parsed = parse_asset(path, enemy_root)
        if parsed is None:
            invalid_names.append(path.relative_to(PROJECT_ROOT).as_posix())
            continue
        if parsed.enemy_id != enemy_id:
            invalid_names.append(path.relative_to(PROJECT_ROOT).as_posix())
            continue
        assets.append(parsed)
    return assets, invalid_names


def _matching_assets(assets: list[EnemyAnimationAsset], capability: dict) -> tuple[list[EnemyAnimationAsset], list[EnemyAnimationAsset]]:
    candidates = [
        asset
        for asset in assets
        if asset.layer == capability["layer"]
        and asset.action_group in capability["action_groups"]
        and asset.action in capability["actions"]
    ]
    min_frames = int(capability.get("min_frames", 1))
    valid = [asset for asset in candidates if asset.frames >= min_frames]
    return candidates, valid


def _capability_result(assets: list[EnemyAnimationAsset], capability: dict) -> dict:
    candidates, valid = _matching_assets(assets, capability)
    min_directions = int(capability.get("min_direction_count", 1))
    directions = sorted({asset.direction for asset in valid})
    return {
        "id": capability["id"],
        "satisfied": len(directions) >= min_directions,
        "required_layer": capability["layer"],
        "accepted_groups": capability["action_groups"],
        "accepted_actions": capability["actions"],
        "min_direction_count": min_directions,
        "min_frames": int(capability.get("min_frames", 1)),
        "directions_present": directions,
        "matches": [asdict(asset) for asset in valid],
        "under_frame_minimum": [asdict(asset) for asset in candidates if asset not in valid],
    }


def _duplicates(assets: list[EnemyAnimationAsset]) -> list[dict]:
    by_key: dict[str, list[EnemyAnimationAsset]] = {}
    for asset in assets:
        by_key.setdefault(asset.semantic_key, []).append(asset)
    return [
        {"semantic_key": key, "paths": [asset.path for asset in matches]}
        for key, matches in sorted(by_key.items())
        if len(matches) > 1
    ]


def build_enemy_report(enemy_id: str, contract: dict, enemy_root: Path) -> dict:
    assets, invalid_names = scan_enemy(enemy_id, enemy_root)
    base = contract["base_humanoid"]
    required = [_capability_result(assets, capability) for capability in base["required"]]
    optional = [_capability_result(assets, capability) for capability in base.get("optional", [])]
    missing_required = [entry["id"] for entry in required if not entry["satisfied"]]
    missing_optional = [entry["id"] for entry in optional if not entry["satisfied"]]
    duplicates = _duplicates(assets)
    return {
        "enemy_id": enemy_id,
        "summary": {
            "runtime_assets": len(assets),
            "required_capabilities": len(required),
            "required_satisfied": len(required) - len(missing_required),
            "missing_required": len(missing_required),
            "optional_capabilities": len(optional),
            "optional_satisfied": len(optional) - len(missing_optional),
            "invalid_names": len(invalid_names),
            "duplicate_semantic_assets": len(duplicates),
        },
        "missing_required": missing_required,
        "missing_optional": missing_optional,
        "required": required,
        "optional": optional,
        "invalid_names": invalid_names,
        "duplicate_semantic_assets": duplicates,
    }


def build_report(contract: dict, enemy_ids: list[str], enemy_root: Path) -> dict:
    reports = [build_enemy_report(enemy_id, contract, enemy_root) for enemy_id in enemy_ids]
    return {
        "schema": "custodian.enemy_animation_contract_report.v1",
        "contract_schema": contract["schema"],
        "enemies": reports,
        "summary": {
            "enemies_checked": len(reports),
            "enemies_missing_required": sum(1 for report in reports if report["summary"]["missing_required"]),
            "missing_required_capabilities": sum(report["summary"]["missing_required"] for report in reports),
            "invalid_names": sum(report["summary"]["invalid_names"] for report in reports),
            "duplicate_semantic_assets": sum(report["summary"]["duplicate_semantic_assets"] for report in reports),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate enemy runtime animation assets against the base enemy animation contract.")
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--enemy-root", type=Path, default=DEFAULT_ENEMY_ROOT)
    parser.add_argument("--enemy-id", action="append", dest="enemy_ids", help="Enemy id to check. Repeat for multiple enemies.")
    parser.add_argument("--strict", action="store_true", help="Fail when required animation capabilities are missing.")
    parser.add_argument("--strict-names", action="store_true", help="Also fail on malformed runtime PNG names or duplicate semantic assets.")
    parser.add_argument("--json", action="store_true", help="Print the full report instead of only the summary.")
    args = parser.parse_args()

    contract = json.loads(args.contract.read_text())
    enemy_ids = args.enemy_ids or list(contract.get("default_enforced_enemies", []))
    if not enemy_ids:
        parser.error("no enemy ids supplied and contract has no default_enforced_enemies")

    report = build_report(contract, enemy_ids, args.enemy_root)
    print(json.dumps(report if args.json else report["summary"], indent=2))

    if args.strict and report["summary"]["missing_required_capabilities"]:
        return 1
    if args.strict_names and (report["summary"]["invalid_names"] or report["summary"]["duplicate_semantic_assets"]):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
