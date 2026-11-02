#!/usr/bin/env python3
"""Guard the retired compatibility SpriteFrames generation path."""
from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CUSTODIAN = ROOT / "custodian"
OPERATOR = CUSTODIAN / "game/actors/operator"
MANIFEST = CUSTODIAN / "tools/validation/validation_manifest.json"
REPORT = ROOT / "reports/operator/operator_runtime_consumer_disposition.json"
RETIRED = {
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
}


def main() -> int:
    failures: list[str] = []
    updater = CUSTODIAN / "tools/pipelines/update_operator_compatibility_resources.py"
    if updater.exists():
        failures.append("retired compatibility resource updater exists")

    active_pipeline_files = [
        CUSTODIAN / "tools/operator/animation_workbench.py",
        CUSTODIAN / "tools/operator/operator_ingest.sh",
        CUSTODIAN / "tools/pipelines/reload_assets.py",
        CUSTODIAN / "tools/pipelines/ingest_runtime.gd",
    ]
    if any("update_operator_compatibility_resources.py" in path.read_text(encoding="utf-8", errors="ignore")
           for path in active_pipeline_files):
        failures.append("active Operator pipeline still invokes the retired updater")

    for name in sorted(RETIRED):
        if (OPERATOR / name).exists():
            failures.append(f"retired compatibility resource remains: {name}")
    scene = (OPERATOR / "operator.tscn").read_text(encoding="utf-8")
    if any(f"res://game/actors/operator/{name}" in scene for name in RETIRED):
        failures.append("Operator scene still references a retired compatibility resource")
    if ('[node name="PrimaryWeaponSprite"' not in scene
            or 'sprite_frames = ExtResource("39_canonical_runtime_frames")' not in scene):
        failures.append("PrimaryWeaponSprite no longer binds the canonical runtime database")
    if "RangedFxOverlaySprite" in scene:
        failures.append("retired ranged FX overlay node remains in the Operator scene")
    actor = (OPERATOR / "operator.gd").read_text(encoding="utf-8")
    if "primary_weapon_frames_resource" in actor:
        failures.append("Operator retains the removed compatibility frame fallback export")
    if "primary_weapon_sprite.sprite_frames = OPERATOR_RUNTIME_FRAMES" not in actor:
        failures.append("PrimaryWeaponSprite fallback is not the canonical runtime database")
    if "if _is_using_ranged_2h_primary():" not in actor:
        failures.append("two-handed ranged compatibility fallback has no explicit cutover guard")
    sidearm = (OPERATOR / "sidearm_pistol_definition.tres").read_text(encoding="utf-8")
    if "content/sprites/operator/runtime/operator_runtime_frames.tres" not in sidearm:
        failures.append("sidearm definition does not reference the canonical runtime database")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    owners = {
        path
        for entry in manifest.get("tests", [])
        for path in entry.get("owners", [])
    }
    missing_owners = sorted(
        f"custodian/game/actors/operator/{name}"
        for name in RETIRED
        if f"custodian/game/actors/operator/{name}" not in owners
    )
    if missing_owners:
        failures.append("validation manifest does not own retired resources: " + ", ".join(missing_owners))

    report = json.loads(REPORT.read_text(encoding="utf-8"))
    compatibility = report.get("compatibility_resources", [])
    if len(compatibility) != len(RETIRED):
        failures.append(f"consumer report accounts for {len(compatibility)} compatibility resources")
    if any(row.get("exists") for row in compatibility):
        failures.append("consumer report says a retired compatibility resource still exists")
    layers = report.get("canonical_layers", [])
    archived = [row for row in layers if row.get("archived")]
    if not archived:
        failures.append("consumer report has no archived source/runtime dispositions")
    if any(not row.get("source_archive_exists") or row.get("runtime_exists") for row in archived):
        failures.append("archived canonical layers must retain source provenance and have no runtime publication")
    active = [row for row in layers if not row.get("archived")]
    if any(row.get("disposition") == "UNCLASSIFIED" for row in active):
        failures.append("active runtime layers include unclassified rows")

    runtime_frames = CUSTODIAN / "content/sprites/operator/runtime/operator_runtime_frames.tres"
    if not runtime_frames.exists():
        failures.append("canonical Operator runtime SpriteFrames resource is missing")
    elif any(f"/source/legacy/c2b_runtime_retirement/" in line for line in runtime_frames.read_text(errors="ignore").splitlines()):
        failures.append("canonical SpriteFrames still references retired runtime art")

    if failures:
        for failure in failures:
            print(f"FAIL {failure}")
        return 1
    print("PASS compatibility resources: updater retired; all 11 resources removed after canonical cutover")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
