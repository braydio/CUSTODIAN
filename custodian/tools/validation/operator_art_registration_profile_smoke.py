#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))
sys.path.insert(0, str(ROOT / "custodian/tools/art"))

import animation_workbench_model as model
from art_agent.registration_profile import load_profile, weighted_median
from art_agent.source_models import NormalizationPlan
from art_agent.source_service import SourceArtService


def main() -> int:
    profile = load_profile()
    registration = profile["registration"]
    assert registration["anchor"] == [48, 84]
    assert registration["guide"]["horizontal"]["hips"] == 58
    assert profile["profile"]["enforcement"]["artistic"] is False
    assert weighted_median([{"ratio": 2.0, "weight": 1.0, "frame": 1, "segment": "a"},
                            {"ratio": 1.0, "weight": 2.0, "frame": 2, "segment": "b"}]) == 1.0
    guide_script = (ROOT / "custodian/tools/aseprite/operator_anchor_guides.lua").read_text()
    render_bridge = (ROOT / "custodian/tools/aseprite/operator_live_bridge/art_agent_ops.lua").read_text()
    assert "__ART_GUIDE_OPERATOR_REGISTRATION" in guide_script and "registration.guide.horizontal" in guide_script
    assert "layer.isEditable = false" in guide_script and "image:clone()" in guide_script
    assert "__ART_GUIDE_" in render_bridge and "local function internal(layer)" in render_bridge
    assert "48, 84" not in guide_script and "hips = 58" not in guide_script
    assert "operator_art_profile.json" in guide_script and "sprite:newCel(layer, frame_index" in guide_script
    assert "sprite:deleteLayer(layer)" in guide_script

    old_plan = {
        "schema": "custodian.operator_art_normalization_plan.v1", "source_sha256": "a" * 64,
        "frame_count": 1, "source_cell_width": 96, "source_cell_height": 96,
        "target_width": 96, "target_height": 96, "shared_union_bbox": [1, 2, 90, 91],
        "global_scale": 1, "prepared_width": 768, "prepared_height": 768,
        "destination_x": 0, "destination_y": 0, "anchor": "feet", "method": "crisp",
        "registrations": [{"frame": 1, "dx": 0, "dy": 0}],
    }
    migrated = NormalizationPlan.from_json(old_plan)
    assert migrated.mode == "contain" and not migrated.profile_sha256

    with tempfile.TemporaryDirectory(prefix="operator-registration-profile-") as temporary:
        temp = Path(temporary)
        source_root = temp / "inbox"; source_root.mkdir()
        source = source_root / "synthetic.png"
        image = Image.new("RGBA", (768, 768), (0, 0, 0, 0)); draw = ImageDraw.Draw(image)
        draw.ellipse((300, 40, 468, 210), fill=(20, 20, 25, 255))
        draw.rectangle((250, 210, 518, 470), fill=(40, 40, 45, 255))
        draw.rectangle((270, 450, 350, 650), fill=(60, 50, 45, 255))
        draw.rectangle((420, 450, 500, 650), fill=(60, 50, 45, 255)); image.save(source)
        service = SourceArtService(root=temp / "sessions", allowed_source_roots=(source_root,),
                                   handoff_root=temp / "handoff", canonical_root=temp / "canonical")
        session_path = service.start(source_path=source, frames=1, target_size=96)
        service.analyze(session_path)
        try:
            service.plan_normalization(session_path, mode="operator_profile")
        except model.WorkbenchError as error:
            assert "PROFILE_LANDMARKS_INSUFFICIENT" in str(error)
        else:
            raise AssertionError("profile planning silently accepted missing landmarks")
        lm = [
            {"frame": 1, "name": "head_center", "x": 384, "y": 125, "semantic_side": "center", "confidence": 1.0, "provenance": "human", "approved": True},
            {"frame": 1, "name": "hip_center", "x": 384, "y": 397, "semantic_side": "center", "confidence": 1.0, "provenance": "human", "approved": True},
            {"frame": 1, "name": "toe_near", "x": 310, "y": 650, "semantic_side": "near", "confidence": 1.0, "provenance": "human", "approved": True},
            {"frame": 1, "name": "toe_far", "x": 460, "y": 650, "semantic_side": "far", "confidence": 1.0, "provenance": "human", "approved": True},
        ]
        service.set_source_landmarks(session_path, lm)
        assert service.validate_source_landmarks(session_path)["valid"]
        service.render_source(session_path)
        plan = service.plan_normalization(session_path, mode="operator_profile")
        assert plan["mode"] == "operator_profile"
        assert sum(item["accepted"] for item in plan["scale_observations"]) == 1
        assert plan["registrations"] == [{"frame": 1, "dx": 0, "dy": 0}]
        outputs = service.convert(session_path)
        command = service.production_command(session_path)
        assert command["executes"] is False
        output_path = Path(command["output"]); output_path.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run([sys.executable, str(ROOT / "custodian/tools/art/custodian_pixelart_converter.py"),
                        str(source), str(output_path), "--sheet", "--frames", "1", "--source-cell", "768x768",
                        "--size", "96", "--choose", "1", "--force", "--normalization-plan",
                        str(session_path.parent / "normalization_plan.json")], check=True, capture_output=True, text=True)
        with Image.open(outputs["candidates"]["crisp"]) as internal, Image.open(output_path) as external:
            assert internal.convert("RGBA").tobytes() == external.convert("RGBA").tobytes()
        proof = service.verify_production(session_path)
        assert proof["verified"] and proof["method"] == "crisp"
        report = service.source_registration_report(session_path)
        assert report["profile_sha256"] == profile["sha256"]
        assert report["frames"][0]["transformed_landmarks"]["hip_center"]

        unsafe = source_root / "unsafe.png"
        with Image.open(source) as base:
            unsafe_image = base.convert("RGBA")
        ImageDraw.Draw(unsafe_image).point((0, 0), fill=(255, 255, 255, 255)); unsafe_image.save(unsafe)
        unsafe_session = service.start(source_path=unsafe, frames=1, target_size=96); service.analyze(unsafe_session)
        unsafe_lm = [dict(item, y=(345 if item["name"] == "hip_center" else item["y"])) for item in lm]
        service.set_source_landmarks(unsafe_session, unsafe_lm)
        try:
            service.plan_normalization(unsafe_session, mode="operator_profile")
        except model.WorkbenchError as error:
            assert "PROFILE_REGISTRATION_CLIPS" in str(error)
        else:
            raise AssertionError("profile scale silently shrank to accommodate peripheral alpha")

        try:
            service.set_source_landmarks(session_path, [dict(item, x=900) if item["name"] == "head_center" else item for item in lm])
        except model.WorkbenchError:
            pass
        else:
            raise AssertionError("out-of-cell source landmark was accepted")

    print("PASS operator_art_registration_profile_smoke: profile authority, v1 compatibility, source landmarks, shared scale, plan replay, crisp proof")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
