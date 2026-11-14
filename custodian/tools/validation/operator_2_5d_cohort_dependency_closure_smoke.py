#!/usr/bin/env python3
"""Focused deterministic and fail-closed tests for the WB25 closure report."""
from __future__ import annotations

import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/validation"))
import operator_2_5d_cohort_dependency_closure as closure


def main() -> None:
    workspace = closure._workspace_default(ROOT)
    first = closure.build_report(ROOT, workspace)
    second = closure.build_report(ROOT, workspace)
    assert first == second
    assert first["schema"] == "custodian.operator_2_5d_cohort_dependency_closure.v1"
    assert first["candidate"]["id"] == "unarmed_neutral_motion_v1"
    assert first["candidate"]["family_count"] == 7
    assert first["candidate"]["direction_slots"] == 56
    families = first["candidate"]["families"]
    assert [len(f["directions"]) for f in families] == [8] * 7
    assert all(f["required_layers"] == ["full_body"] for f in families)
    assert all(f["effective_review"]["verified_directions"] == 0 for f in families)
    assert all(f["effective_review"]["receipts"] == 0 for f in families)
    assert families[0]["frame_contract"] == {
        "frames": 15, "frame_size": [128, 128], "loop": True, "fps": None,
        "timing_status": "unknown_non_blocking",
    }
    assert all(f["frame_contract"]["frames"] is None and f["frame_contract"]["loop"] is None
               and f["frame_contract"]["fps"] is None for f in families[1:])

    workspace_evidence = first["evidence_availability"]["authoring_workspace"]
    if workspace_evidence["status"] == "AVAILABLE":
        assert workspace_evidence["editable_idle_directions"] == 8
        assert workspace_evidence["effective_receipts"] == 0
        idle = workspace_evidence["idle_relaxed_01"]
        assert all(item["manifest_status"] == "PRESENT" and item["saved_document_status"] == "PRESENT" for item in idle)
        assert all(item["frames"] == 15 and item["preview_fps"] == 8.0 and item["timing_authority"] is False for item in idle)
        assert all(item["source_strip_hash_matches_correction"] for item in idle)
        assert all(item["source_session_hash_matches_correction"] for item in idle)
    else:
        assert workspace_evidence["editable_idle_directions"] is None
        assert workspace_evidence["effective_receipts"] is None

    controls = first["negative_controls"]
    assert all(control["pass"] for control in controls.values())
    assert first["release_status"] == "NOT_RELEASE_ELIGIBLE"
    assert all(edge["classification"] in {"OPEN", "UNKNOWN"} for edge in first["edges"])
    assert all(closure._edge_evidence_resolves(ROOT, edge["evidence"]) for edge in first["edges"])
    locomotion = first["edges"][2:6]
    assert all(isinstance(edge["evidence"], list) for edge in locomotion)
    assert all(any(ref["symbol"].endswith("_update_animation") for ref in edge["evidence"])
               for edge in locomotion)
    assert not closure._edge_evidence_resolves(ROOT, [{
        "path": "custodian/game/actors/operator/operator.gd",
        "symbol": "operator._sync_animation_from_state",
    }])
    assert not closure._edge_evidence_resolves(ROOT, {"status": "UNKNOWN", "reason": ""})
    assert first["presentation_owners"]["posture"]["required_layers"] == ["lower_body", "upper_body"]
    assert first["presentation_owners"]["posture"]["candidate_layers"] == ["full_body"]
    assert first["presentation_owners"]["selector"]["generation_neutral"] is True
    assert len(first["investigation"]["source_evidence_sha256"]) >= 10

    with tempfile.TemporaryDirectory(prefix="operator_2_5d_closure_missing_") as raw:
        absent = closure._workspace_evidence(ROOT, Path(raw) / "missing")
        assert absent["status"] == "UNAVAILABLE"
        assert absent["editable_idle_directions"] is None
        assert absent["effective_receipts"] is None
        unavailable = closure.build_report(ROOT, Path(raw) / "missing")
        assert unavailable["candidate"]["families"][0]["authoring"]["workspace_count"] is None
        assert unavailable["candidate"]["families"][0]["effective_review"]["verified_directions"] is None

    print("operator_2_5d_cohort_dependency_closure_smoke: PASS")


if __name__ == "__main__":
    main()
