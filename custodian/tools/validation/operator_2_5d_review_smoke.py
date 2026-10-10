#!/usr/bin/env python3
"""Fast invariants for 2.5D review state, family derivation, and sandbox bundles."""
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))
from operator_2_5d_review import Operator2DReview, human_review_evidence_sha, qa_state, sha256_file
from animation_preview import Preview, ReviewSequence, SemanticIdentity, TimelineClip
from ui.service import WorkbenchService
from ui.state import AnimationSelection


assert qa_state({"status": "RED", "findings": []}) == "RED"
assert qa_state({"status": "NEEDS_HUMAN_REVIEW", "findings": [{"severity": "major"}]}) == "NEEDS_HUMAN_REVIEW"
assert qa_state({"status": "YELLOW", "findings": [{"severity": "advisory"}]}) == "YELLOW"
assert qa_state({"status": "GREEN", "findings": []}) == "GREEN"
assert qa_state({"status": "GREEN", "findings": [{"severity": "unrecognized"}]}) == "RED"
assert qa_state({"status": "UNKNOWN", "findings": []}) == "RED"
assert qa_state({"status": "YELLOW", "findings": []}) == "YELLOW"
human_evidence = dict(identity="operator_2_5d_128:u/posture/idle/ne", manifest_sha256="m",
    document_sha256="d", frame_sha256=["f"], profile_sha256="p", reference_sha256="r",
    frames=1, frame_size=[128, 128], durations=[0.125], findings_sha256="q")
assert human_review_evidence_sha(**human_evidence) != human_review_evidence_sha(**{**human_evidence, "findings_sha256":"changed"})
assert human_review_evidence_sha(**human_evidence) != human_review_evidence_sha(**{**human_evidence, "durations":[0.25]})

with tempfile.TemporaryDirectory(prefix="operator_2d_review_") as raw:
    root = Path(raw)
    frame = root / "frame.png"
    Image.new("RGBA", (128, 128), (17, 34, 51, 255)).save(frame)
    selection = SimpleNamespace(profile="operator", group="posture", action="idle", direction="ne",
        art_generation="operator_2_5d_128", authoring_identity="operator_2_5d_128:operator/posture/idle/ne")
    class Service:
        def workspace(self, _selection): return root / "workbench"
    owner = Operator2DReview(service=Service(), repo_root=root, workspace_root=root / "workbench")
    sandbox_owner = Operator2DReview(service=Service(), repo_root=ROOT, workspace_root=root / "workbench")
    sandbox_owner.preview_root = root / "runtime_preview"
    digest = sha256_file(frame)
    receipt = {"receipt_sha256": "receipt", "authoring_identity": selection.authoring_identity,
        "authority": {"frame_sha256": [digest], "frame_paths": [str(frame)], "durations": [0.125]}}
    request = owner.make_sandbox_request(selection, receipt, [frame])
    bundle = owner.preview_root / request["request_id"]
    saved_request = json.loads((bundle / "request.json").read_text())
    assert saved_request["request_sha256"] == request["request_sha256"]
    assert sha256_file(bundle / saved_request["frames"][0]["path"]) == digest
    assert request["durations"] == [0.125] and request["frame_size"] == [128, 128]
    godot = shutil.which("godot")
    if godot:
        sandbox = sandbox_owner.run_sandbox(selection, receipt)
        assert sandbox["status"] == "PASSED" and sandbox["production_unchanged"]
        request_path = Path(sandbox["request_path"])
        sandbox_bundle = request_path.parent
        original_request_text = request_path.read_text()
        scene = "res://scenes/debug/operator_2_5d_review_sandbox.tscn"
        command = [godot, "--headless", "--path", str(ROOT / "custodian"), "--scene", scene,
                   "--", "--request", str(request_path)]
        result = json.loads(Path(sandbox["result_path"]).read_text())
        assert result["presentation"] == "PASSED"
        assert result["frame_size"] == [128, 128] and result["frame_count"] == 1
        assert result["body_owner"] == 1 and result["visible_body_owners"] == [1] and result["shadow_present"]
        assert result["sprite_visible"] and result["frames_reference_same"] and result["selected_texture_size"] == [128, 128]
        assert result["presented_pixel_sha256"] == saved_request["frames"][0]["pixel_sha256"]
        assert result["operator_position"] == [0.0, 0.0] and result["operator_scale"] == [1.0, 1.0]
        assert result["sprite_position"] == [0.0, -18.0] and result["sprite_scale"] == [1.0, 1.0]
        assert result["shadow_position"] == [0.0, 13.0] and result["camera_zoom"] == [3.0, 3.0]
        altered_request = json.loads(original_request_text)
        altered_request["durations"] = [0.25]
        request_path.write_text(json.dumps(altered_request))
        refused_request = subprocess.run(command, capture_output=True, text=True, timeout=90, check=False)
        result = json.loads(Path(sandbox["result_path"]).read_text())
        assert refused_request.returncode != 0 and "request hash mismatch" in result.get("error", "")
        request_path.write_text(original_request_text)
    # A frame mutation invalidates the exact request's per-frame content authority.
    tamper_bundle = sandbox_bundle if godot else bundle
    (tamper_bundle / saved_request["frames"][0]["path"]).write_bytes(b"tampered")
    assert sha256_file(tamper_bundle / saved_request["frames"][0]["path"]) != saved_request["frames"][0]["sha256"]
    if godot:
        refused = subprocess.run(command, capture_output=True, text=True, timeout=90, check=False)
        result = json.loads((sandbox_bundle / "result.json").read_text())
        assert refused.returncode != 0 and "frame hash mismatch" in result.get("error", "")

    good = SimpleNamespace(selection=selection, coverage="CANONICAL_2_5D", workflow_status="LIVE", stale=False)
    missing_selection = SimpleNamespace(**{**selection.__dict__, "direction": "e",
        "authoring_identity": "operator_2_5d_128:operator/posture/idle/e"})
    missing = SimpleNamespace(selection=missing_selection, coverage="MISSING", workflow_status="DORMANT", stale=False)
    owner.current_receipt = lambda current: {"runtime_verified": current.direction == "ne", "receipt_sha256": "r"} if current.direction == "ne" else None
    family = owner.family((good, missing), profile="operator", group="posture", action="idle")
    assert len(family["cells"]) == 2 and not family["complete"]
    assert family["cells"][0]["runtime_verified"] is False or family["cells"][1]["runtime_verified"] is False

    # Mixed v1/v2 sequences must choose legacy runtime and exact 2.5D Workbench
    # frames by generation, even when the caller's default source is runtime.
    runtime_frame = root / "runtime.png"
    Image.new("RGBA", (96, 96), (255, 0, 0, 255)).save(runtime_frame)
    workbench_frame = root / "workbench.png"
    Image.new("RGBA", (128, 128), (0, 255, 0, 255)).save(workbench_frame)
    legacy_selection = AnimationSelection("unarmed", "locomotion", "idle_01", "e")
    two_d_selection = AnimationSelection("unarmed", "posture", "idle_relaxed_01", "e", art_generation="operator_2_5d_128")
    class FakeProvider:
        def load(self, identity, source):
            return Preview(identity, source, (Image.open(runtime_frame).convert("RGBA"),), (96, 96), "runtime", (str(runtime_frame),))
    class FakeArt:
        def render(self, _session): return {"frames": [str(workbench_frame)]}
    service = object.__new__(WorkbenchService)
    service.preview_provider = FakeProvider()
    service.browser_records = lambda **_kwargs: (
        SimpleNamespace(selection=legacy_selection, frames=1),
        SimpleNamespace(selection=two_d_selection, frames=1),
    )
    service.polish_attach = lambda _selection: root / "session.json"
    service._polish = lambda _selection: SimpleNamespace(service=FakeArt())
    mixed = ReviewSequence("mixed", [
        TimelineClip("unarmed", "locomotion", "idle_01", "e"),
        TimelineClip("unarmed", "posture", "idle_relaxed_01", "e", art_generation="operator_2_5d_128"),
    ])
    frames = service.flatten_sequence(mixed, "runtime")
    assert frames[0][2].getpixel((0, 0)) == (255, 0, 0, 255)
    assert frames[1][2].getpixel((0, 0)) == (0, 255, 0, 255)

print("operator_2_5d_review_smoke: PASS")
