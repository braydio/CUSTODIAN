#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))

from art_agent.registration_profile import load_active_authoring_profile, load_profile
from art_agent.service import ArtAgentService
import animation_workbench_model as workbench_model
from canonical_visual_contract import DIRECTIONS, REFERENCE, build, sha256


def main() -> int:
    first = build()
    second = build()
    assert first == second, "measurement/evidence generation is not deterministic"
    assert first["sources"]["design"]["sha256"] == "41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b"
    assert first["sources"]["first_animation"]["sha256"] == "d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3"
    assert first["sources"]["design"]["size"] == [2048, 256]
    assert first["sources"]["first_animation"]["size"] == [1920, 1024]
    assert first["sources"]["first_animation"]["fps"] is None
    assert first["registration"]["status"] == "accepted"
    assert first["registration"]["anchor"] == [64, 106]
    assert first["registration"]["shadow_origin"] == [64, 107]
    assert first["registration"]["ground_y"] == 107
    assert first["action_envelope"]["status"] == "not_asserted"
    assert first["action_envelope"]["universal_action_envelope"] == "not_asserted"
    assert first["pixel_cleanup"]["status"] == "accepted_no_cleanup"
    assert first["pixel_cleanup"]["normalized_reference_mutated"] is False
    assert first["palette"]["cleanup_status"] == "accepted_no_cleanup"
    proxy_scan = first["action_envelope"]["legacy_proxy_scan"]
    assert proxy_scan["status"] == "proxy_overflow_found"
    fast_chain = proxy_scan["categories"]["fast_chain_extension"]
    assert fast_chain["candidate_8px_margin_overflow_frames"] > 0
    assert fast_chain["candidate_canvas_overflow_frames"] > 0
    assert fast_chain["largest_alpha_bbox"]["candidate_root_translated_bbox"][2] > 120
    assert list(first["normalized_reference"]["directions"]) == list(DIRECTIONS)
    for direction in DIRECTIONS:
        ref = REFERENCE.parent / "directions" / f"{direction}.png"
        assert ref.is_file() and sha256(ref) == first["normalized_reference"]["directions"][direction]["sha256"]

    legacy = load_profile(profile_id="legacy_96")
    assert legacy["profile_id"] == "legacy_96" and legacy["registration"]["frame_size"] == [96, 96]
    assert legacy["sha256"] == "3197bb8880acd1ded1ea09985905cf6a5c57568f8e899284ceb48759bc1ceeb5"
    active = load_active_authoring_profile()
    assert active["profile_id"] == "operator_2_5d_128"
    assert active["registration"]["frame_size"] == [128, 128]
    assert active["registration"]["status"] == "accepted"
    assert active["profile"]["status"] == "accepted"
    assert active["profile"]["universal_action_envelope"] == "not_asserted"
    assert active["sha256"] == first["profile"]["sha256"]
    assert workbench_model.DEFAULT_PROFILE_ID == "operator_2_5d_128"
    assert workbench_model.DEFAULT_FRAME_SIZE == (128, 128)
    assert ArtAgentService().registration_profile(profile_id="operator_2_5d_128")["profile_id"] == "operator_2_5d_128"
    assert {"left_foot_contact", "right_foot_contact", "projected_world_root", "shadow_origin"}.issubset(
        set(json.loads((ROOT / "custodian/content/data/operator/authoring/operator_landmark_schema.json").read_text())["names"])
    )
    assert set(first["calibration_candidates"]) == set(DIRECTIONS)
    family_manifest = json.loads((ROOT / "custodian/asset_drop/source_work/operator/operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_manifest.json").read_text())
    assert family_manifest["authority_status"] == "accepted_first_canonical_animation_source"
    assert family_manifest["semantic_identity"] == {"owner": "operator", "animation_profile": "unarmed", "action_group": "posture", "action": "idle_relaxed_01", "layer": "full_body"}
    assert family_manifest["fps"] is None and family_manifest["timing_status"] == "unknown_non_blocking"
    assert family_manifest["canonical_reference_sha256"] == sha256(REFERENCE)
    assert family_manifest["registration_profile_sha256"] == active["sha256"]

    profile_path = ROOT / "custodian/content/data/operator/authoring/operator_art_profile.json"
    registry = json.loads(profile_path.read_text())
    assert registry["schema"] == "custodian.operator_art_profile.v3"
    assert registry["profiles"]["legacy_96"]["registration"] == legacy["registration"]
    assert registry["canonical_visual_reference"]["sha256"] == sha256(REFERENCE)
    assert registry["canonical_visual_reference"]["status"] == "accepted"
    assert registry["canonical_visual_reference"]["profile_sha256"] == active["sha256"]
    guide_script = (ROOT / "custodian/tools/aseprite/operator_anchor_guides.lua").read_text()
    assert "profile.active_authoring_profile" in guide_script
    assert "cell_width, cell_height = registration.frame_size" in guide_script
    assert "__ART_GUIDE_OPERATOR_REGISTRATION_" in guide_script

    # The original single-profile documents remain readable through the registry loader.
    with tempfile.TemporaryDirectory(prefix="operator-profile-backward-read-") as td:
        legacy_doc = dict(registry["profiles"]["legacy_96"])
        legacy_doc.pop("profile_sha256", None)
        legacy_doc["schema"] = "custodian.operator_art_profile.v2"
        legacy_doc_path = Path(td) / "profile-v2.json"
        legacy_doc_path.write_text(json.dumps(legacy_doc))
        assert load_profile(legacy_doc_path)["registration"]["frame_size"] == [96, 96]
        legacy_doc["schema"] = "custodian.operator_art_profile.v1"
        legacy_doc_path.write_text(json.dumps(legacy_doc))
        assert load_profile(legacy_doc_path)["registration"]["frame_size"] == [96, 96]

    print(json.dumps({"status": "ok", "normalized_reference_sha256": sha256(REFERENCE), "legacy_profile_sha256": legacy["sha256"], "active_profile_status": active["registration"]["status"]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
