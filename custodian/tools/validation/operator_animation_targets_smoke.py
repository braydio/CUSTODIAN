#!/usr/bin/env python3
"""Generation-aware target, coverage, path, and identity smoke checks."""
from __future__ import annotations

import copy
import json
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OPERATOR = ROOT / "custodian/tools/operator"
sys.path.insert(0, str(OPERATOR))
sys.path.insert(0, str(ROOT / "custodian/tools/pipelines"))

import operator_animation_targets as targets
import operator_asset_schema as schema
from ui.state import AnimationRecord, AnimationSelection


PLAN = ROOT / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"
AUDIT = ROOT / "reports/operator_presentation/operator_2_5d_coverage.json"
PROFILE = ROOT / "custodian/content/data/operator/authoring/operator_art_profile.json"


def main() -> None:
    plan = targets.load_plan(PLAN)
    families = targets.target_families(plan)
    assert len(families) == 69
    assert sum(len(family.directions) for family in families) == 552
    first = families[0]
    assert first.key == ("operator_2_5d_128", "unarmed", "posture", "idle_relaxed_01")
    assert first.source_sha256 == "d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3"
    assert first.frame_contract["frames"] == 15
    assert first.frame_contract["fps"] is None
    assert sum(family.migration_verdict == "missing_canonical_2_5d" for family in families) == 68
    assert plan["audit_summary"]["legacy_production_reachable_families"] == 69
    assert plan["audit_summary"]["remaining_baseline_direction_animation_strips"] == 544

    key = schema.OperatorAssetKey("operator", "full_body", "unarmed", "posture", "idle_relaxed_01", "n", 15, 128, 128)
    legacy_path = schema.canonical_source_path(key)
    canonical_path = schema.canonical_source_path(key, art_generation="operator_2_5d_128")
    assert legacy_path.as_posix() == "content/sprites/operator/source/animations/unarmed/posture/idle_relaxed_01/operator__full_body__unarmed__posture__idle_relaxed_01__n__15f__128.png"
    assert canonical_path.as_posix() == "content/sprites/operator/source/generations/operator_2_5d_128/animations/unarmed/posture/idle_relaxed_01/operator__full_body__unarmed__posture__idle_relaxed_01__n__15f__128.png"
    legacy_selection = AnimationSelection("unarmed", "posture", "idle_relaxed_01", "n")
    target_selection = AnimationSelection("unarmed", "posture", "idle_relaxed_01", "n", art_generation="operator_2_5d_128")
    assert legacy_selection.identity == target_selection.identity
    assert legacy_selection.authoring_identity != target_selection.authoring_identity

    with tempfile.TemporaryDirectory(prefix="operator_animation_targets_") as raw:
        repo = Path(raw)
        audit_copy = repo / "reports/operator_presentation/operator_2_5d_coverage.json"
        profile_copy = repo / "custodian/content/data/operator/authoring/operator_art_profile.json"
        audit_copy.parent.mkdir(parents=True, exist_ok=True)
        profile_copy.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(AUDIT, audit_copy)
        shutil.copy2(PROFILE, profile_copy)
        projected_selection = AnimationSelection("melee_1h", "attack", "fast_01", "n")
        legacy_rows = (
            AnimationRecord(projected_selection, 10, ("full_body",)),
            AnimationRecord(AnimationSelection("shared", "locomotion", "idle_01", "s"), 4, ("full_body",)),
        )
        # One local canonical direction proves the same projection detects future ingested pixels.
        key = schema.OperatorAssetKey("operator", "full_body", "melee_1h", "attack", "fast_01", "n", 10, 128, 128)
        path = repo / "custodian" / schema.canonical_source_path(key, art_generation="operator_2_5d_128")
        path.parent.mkdir(parents=True)
        path.touch()
        records = targets.project_targets(plan, repo_root=repo, workspace_root=repo / ".ai/workbench", legacy_records=legacy_rows)
        by_id = {record.selection.authoring_identity: record for record in records}
        fallback = by_id["operator_2_5d_128:shared/locomotion/idle_01/s"]
        assert fallback.coverage_status == "LEGACY_FALLBACK" and not fallback.canonical_complete
        projected = by_id["operator_2_5d_128:melee_1h/attack/fast_01/ne"]
        assert projected.coverage_status == "PROJECTED" and not projected.canonical_complete
        canonical = by_id["operator_2_5d_128:melee_1h/attack/fast_01/n"]
        assert canonical.coverage_status == "CANONICAL_2_5D" and canonical.canonical_complete
        accepted = by_id["operator_2_5d_128:unarmed/posture/idle_relaxed_01/n"]
        assert accepted.coverage_status == "CANONICAL_2_5D" and accepted.workflow_status == "INTAKE"

        stale_plan = copy.deepcopy(plan)
        row = next(item for item in stale_plan["items"] if item.get("migration_verdict") == "canonical_2_5d")
        row["normalized_reference_sha256"] = "0" * 64
        stale = targets.project_targets(stale_plan, repo_root=repo, workspace_root=repo / ".ai/workbench")
        stale_accepted = next(item for item in stale if item.selection.action == "idle_relaxed_01")
        assert stale_accepted.stale_reference and stale_accepted.workflow_status == "STALE_REFERENCE"

    print("operator_animation_targets_smoke ok")


if __name__ == "__main__":
    main()
