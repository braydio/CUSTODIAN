#!/usr/bin/env python3
"""Generate the C2b runtime animation and compatibility consumer inventory."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CUSTODIAN = ROOT / "custodian"
MANIFEST = CUSTODIAN / "content/sprites/operator/runtime/operator_runtime_manifest.generated.json"
REACHABILITY = CUSTODIAN / "content/data/operator/operator_animation_reachability.json"
OPERATOR_DIR = CUSTODIAN / "game/actors/operator"
GAME = CUSTODIAN / "game"
OUTPUT = ROOT / "reports/operator/operator_runtime_consumer_disposition.json"
COMPATIBILITY = (
    "operator_runtime_frames.tres",
    "operator_weapon_frames.tres",
    "operator_melee_overlay_frames.tres",
    "operator_ranged_fx_frames.tres",
    "operator_modular_lower_body_frames.tres",
    "operator_modular_upper_body_frames.tres",
    "operator_modular_sidearm_frames.tres",
    "operator_modular_upper_fx_frames.tres",
    "operator_modular_cape_frames.tres",
    "operator_modular_head_frames.tres",
    "operator_animation_catalog_frames.tres",
)
HARD_ORPHANS = {
    "melee_1h/attack/critical_execution_01",
    "melee_1h/attack/fast_attack_chain_01",
    "ranged_2h/attack/fast_01",
    "ranged_2h/attack/fast_02",
    "ranged_2h/attack/fast_03",
    "sidearm/cosmetic/fx_01",
    "melee_1h/cosmetic/melee_1h",
}

PREVIOUSLY_STALE = {
    "melee_1h/locomotion/walk_01": "DORMANT",
    "melee_1h_heavy/attack/fast_01": "DORMANT",
    "melee_1h_heavy/attack/fast_02": "DORMANT",
    "melee_1h_heavy/attack/fast_03": "DORMANT",
    "ranged_2h/cosmetic/aim_01": "DORMANT",
    "ranged_2h/cosmetic/fire_01": "DORMANT",
    "sidearm/cosmetic/fire_sidearm_01": "DORMANT",
    "unarmed/cosmetic/critical_hitspark_01": "DORMANT",
    "unarmed/interaction/field_patch_use_01": "DORMANT",
    "unarmed/transition/dodge_charge_meter_01": "DORMANT",
    "unarmed/posture/dodge_charge_ready_01": "DORMANT",
    "unarmed/transition/dodge_charge_release_01": "DORMANT",
    "unarmed/transition/dodge_chain_release_01": "DORMANT",
    "melee_1h/attack/critical_execution_01": "DORMANT",
    "melee_1h/attack/fast_attack_chain_01": "DORMANT",
    "melee_1h/cosmetic/melee_1h": "DORMANT",
    "ranged_2h/attack/fast_01": "DORMANT",
    "ranged_2h/attack/fast_02": "DORMANT",
    "ranged_2h/attack/fast_03": "DORMANT",
    "sidearm/cosmetic/fx_01": "DORMANT",
    "unarmed/attack/fast_recovery_01": "SUPERSEDED",
    "unarmed/attack/fast_strike_01": "SUPERSEDED",
    "unarmed/attack/fast_windup_01": "SUPERSEDED",
    "shared/posture/stance_01": "SUPERSEDED",
}


def _classification_index(payload: dict) -> dict[tuple[str, str, str, str], dict]:
    index: dict[tuple[str, str, str, str], dict] = {}
    for entry in payload.get("entries", []):
        base = (entry.get("profile", ""), entry.get("group", ""), entry.get("action", ""))
        index[(*base, str(entry.get("layer", "")))] = entry
    return index


def _source_path(runtime_path: str) -> str:
    return runtime_path.replace("/runtime/animations/", "/source/animations/")


def _game_sources() -> list[tuple[str, str]]:
    result = []
    for path in GAME.rglob("*"):
        if path.is_file() and path.suffix in {".gd", ".tscn"}:
            try:
                result.append((path.relative_to(ROOT).as_posix(), path.read_text(errors="ignore")))
            except OSError:
                continue
    return result


def build_report() -> dict:
    manifest = json.loads(MANIFEST.read_text())
    classifications = _classification_index(json.loads(REACHABILITY.read_text()))
    sources = _game_sources()
    rows = []
    for identity, animation in sorted(manifest.get("animations", {}).items()):
        base = (animation.get("profile", ""), animation.get("group", ""), animation.get("action", ""))
        family = "/".join(base)
        for layer, spec in sorted(animation.get("layers", {}).items()):
            status_entry = classifications.get((*base, layer)) or classifications.get((*base, ""))
            status = str(status_entry.get("status", "UNCLASSIFIED")) if status_entry else "UNCLASSIFIED"
            runtime = str(spec.get("path", ""))
            source = _source_path(runtime)
            exact_identity = f"{identity}/{layer}"
            consumers = [path for path, text in sources if exact_identity in text or runtime in text]
            consumer_resolution = "literal-reference"
            if not consumers and status == "LIVE":
                consumers = ["custodian/game/actors/operator/operator.gd"]
                consumer_resolution = "dynamic-identity-selection"
            if status == "LIVE":
                disposition = "KEEP_LIVE"
            elif status == "SUPERSEDED":
                disposition = "REMOVE_ORPHAN" if family in HARD_ORPHANS else "REMOVE_SUPERSEDED"
            elif status == "ALTERNATE_LAYER":
                disposition = "KEEP_ALTERNATE_LAYER"
            elif status.startswith("DORMANT"):
                disposition = "PRESERVE_DORMANT"
            else:
                disposition = "UNCLASSIFIED"
            rows.append({
                "identity": identity,
                "family": family,
                "layer": layer,
                "direction": animation.get("direction", ""),
                "source_path": source,
                "source_exists": (CUSTODIAN / source.removeprefix("res://")).exists(),
                "runtime_path": runtime,
                "classification_before": PREVIOUSLY_STALE.get(family, status),
                "classification_after": status,
                "classification_reason": status_entry.get("reason", "") if status_entry else "",
                "discovered_consumers": consumers,
                "consumer_resolution": consumer_resolution if consumers else "no-live-consumer-found",
                "disposition": disposition,
            })

    compatibility = []
    resource_sources = []
    for path in GAME.rglob("*"):
        if path.is_file() and path.suffix in {".gd", ".tscn", ".tres"}:
            try:
                resource_sources.append((path.relative_to(ROOT).as_posix(), path.read_text(errors="ignore")))
            except OSError:
                continue
    for name in COMPATIBILITY:
        resource_file = OPERATOR_DIR / name
        resource_path = f"res://game/actors/operator/{name}"
        refs = [rel for rel, text in resource_sources if resource_path in text]
        tools = []
        for tool_path in (CUSTODIAN / "tools").rglob("*"):
            if tool_path.is_file() and tool_path.suffix in {".py", ".gd", ".sh", ".json"}:
                try:
                    if name in tool_path.read_text(errors="ignore"):
                        tools.append(tool_path.relative_to(ROOT).as_posix())
                except OSError:
                    continue
        disposition = "REMOVED_NO_GAMEPLAY_CONSUMER" if not resource_file.exists() else "REMOVE_NO_GAMEPLAY_CONSUMER"
        compatibility.append({
            "resource": f"res://game/actors/operator/{name}",
            "exists": resource_file.exists(),
            "game_references": refs,
            "tool_references": sorted(set(tools)),
            "disposition": disposition,
        })
    current_identities = {row["identity"] + "/" + row["layer"] for row in rows}
    if OUTPUT.exists():
        previous = json.loads(OUTPUT.read_text())
        for row in previous.get("canonical_layers", []):
            if row.get("disposition") not in {"REMOVE_ORPHAN", "REMOVE_SUPERSEDED"}:
                continue
            key = str(row.get("identity", "")) + "/" + str(row.get("layer", ""))
            if key in current_identities:
                continue
            retained = dict(row)
            retained["archived"] = True
            retained["classification_before"] = PREVIOUSLY_STALE.get(
                str(retained.get("family", "")), retained.get("classification_before", "")
            )
            retained["source_exists"] = (CUSTODIAN / str(retained.get("source_path", "")).removeprefix("res://")).exists()
            source_path = str(retained.get("source_path", ""))
            retained["source_archive_path"] = source_path.replace(
                "content/sprites/operator/source/animations/",
                "content/sprites/operator/source/legacy/c2b_runtime_retirement/",
            )
            retained["source_archive_exists"] = (
                CUSTODIAN / retained["source_archive_path"].removeprefix("res://")
            ).exists()
            retained["runtime_exists"] = (CUSTODIAN / str(retained.get("runtime_path", "")).removeprefix("res://")).exists()
            rows.append(retained)

    return {
        "schema": "custodian.operator_runtime_consumer_disposition.v1",
        "source_authorities": [
            "custodian/content/sprites/operator/runtime/operator_runtime_manifest.generated.json",
            "custodian/content/data/operator/operator_animation_reachability.json",
        ],
        "canonical_layer_identity_count": len(rows),
        "active_canonical_layer_identity_count": len(current_identities),
        "compatibility_resource_count": len(compatibility),
        "canonical_layers": rows,
        "compatibility_resources": compatibility,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    rendered = json.dumps(build_report(), indent=2, sort_keys=True) + "\n"
    if args.check:
        if not args.output.exists() or args.output.read_text() != rendered:
            print(f"stale Operator runtime consumer report: {args.output}")
            return 1
        print("Operator runtime consumer report: current")
        return 0
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered)
    print(f"wrote {args.output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
