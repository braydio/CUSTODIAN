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
from art_agent.service import ArtAgentService


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
        assert "--expected-normalization-plan-sha256" in command["command"]
        output_path = Path(command["output"]); output_path.parent.mkdir(parents=True, exist_ok=True)
        approved_digest = service.load(session_path)[0].approved_normalization_plan_sha256
        subprocess.run([sys.executable, str(ROOT / "custodian/tools/art/custodian_pixelart_converter.py"),
                        str(source), str(output_path), "--sheet", "--frames", "1", "--source-cell", "768x768",
                        "--size", "96", "--choose", "1", "--force", "--normalization-plan",
                        str(session_path.parent / "normalization_plan.json"), "--expected-normalization-plan-sha256",
                        approved_digest], check=True, capture_output=True, text=True)
        with Image.open(outputs["candidates"]["crisp"]) as internal, Image.open(output_path) as external:
            assert internal.convert("RGBA").tobytes() == external.convert("RGBA").tobytes()
        proof = service.verify_production(session_path)
        assert proof["verified"] and proof["method"] == "crisp"
        report = service.source_registration_report(session_path)
        assert report["profile_sha256"] == profile["sha256"]
        assert report["frames"][0]["transformed_landmarks"]["hip_center"]

        plan_path = session_path.parent / "normalization_plan.json"
        approved_digest = service.load(session_path)[0].approved_normalization_plan_sha256
        original_plan = json.loads(plan_path.read_text())
        tampered = dict(original_plan, destination_x=original_plan["destination_x"] + 1)
        plan_path.write_text(json.dumps(tampered))
        try:
            service.verify_production(session_path)
        except model.WorkbenchError as error:
            assert "changed after approval" in str(error)
        else:
            raise AssertionError("source verification accepted an in-bounds plan mutation")
        for label, operation in (
            ("source registration report", lambda: service.source_registration_report(session_path)),
            ("review", lambda: service.review(session_path)),
        ):
            try:
                operation()
            except model.WorkbenchError as error:
                assert "changed after approval" in str(error), (label, error)
            else:
                raise AssertionError(f"{label} accepted an in-bounds plan mutation")
        tampered_session, _, session_json = service.load(session_path)
        tampered_session.state = "REVIEWED"
        service.save(session_json, tampered_session)
        try:
            service.handoff(session_path, destination_name="operator_idle_e.png", dry_run=True)
        except model.WorkbenchError as error:
            assert "changed after approval" in str(error)
        else:
            raise AssertionError("handoff accepted an in-bounds plan mutation")
        try:
            subprocess.run([sys.executable, str(ROOT / "custodian/tools/art/custodian_pixelart_converter.py"),
                            str(source), str(output_path), "--sheet", "--frames", "1", "--source-cell", "768x768",
                            "--size", "96", "--choose", "1", "--force", "--normalization-plan", str(plan_path),
                            "--expected-normalization-plan-sha256", approved_digest],
                           check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError as error:
            assert "does not match approved digest" in error.stderr
        else:
            raise AssertionError("converter accepted an in-bounds plan mutation")
        service.plan_normalization(session_path, mode="operator_profile")
        service.set_frame_registration(session_path, frame=1, dx=1, dy=0)
        assert service.load(session_path)[0].approved_normalization_plan_sha256 != approved_digest
        assert not (session_path.parent / "production/verification.json").exists()

        # Workbench reports use current 96x96 coordinates as registered canvas evidence,
        # with scale and pose residuals remaining advisory.
        wb_root = temp / "workbench-report"; (wb_root / "previews").mkdir(parents=True)
        wb_service = ArtAgentService(art_root=temp / "wb-art", workspace_root=temp / "wb-workspace")
        manifest = {"canvas": {"width": 96, "height": 96}}
        wb_service._checked_session = lambda _path: (None, manifest, wb_root)
        wb_service.get_metrics = lambda _path: {"frames": [{"alpha_bbox": [20, 10, 70, 90], "bottom_y": 90}]}
        wb_service.get_landmarks = lambda _path: [
            {"frame": 1, "name": "head_center", "x": 48, "y": 20, "confidence": 1.0, "status": "CURRENT"},
            {"frame": 1, "name": "hip_center", "x": 49, "y": 59, "confidence": 1.0, "status": "CURRENT"},
        ]
        wb_report = wb_service.registration_report(Path("fixture"))
        assert wb_report["profile_sha256"] == profile["sha256"]
        assert wb_report["frame_size"] == [96, 96]
        assert wb_report["coordinate_space"] == "registered_workbench_canvas"
        assert wb_report["anchor_context"]["coordinate"] == registration["anchor"]
        assert wb_report["source_session_scale_normalization_applied"] is False
        assert wb_report["frames"][0]["transformed_landmarks"]["head_center"] == [48.0, 20.0]
        assert wb_report["frames"][0]["advisory_residuals"]["hip_center"]
        assert wb_report["scale_observations"] and all(x["status"] == "advisory" for x in wb_report["scale_observations"])

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

    print("PASS operator_art_registration_profile_smoke: profile authority, v1 compatibility, trusted plan digest, crisp replay, advisory workbench report")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
