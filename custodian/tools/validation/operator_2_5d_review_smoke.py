#!/usr/bin/env python3
"""Fast invariants for 2.5D review state, family derivation, and sandbox bundles."""
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from dataclasses import replace
from pathlib import Path
from types import SimpleNamespace

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))
import operator_2_5d_review as review_module
import operator_2_5d_timing_authority as timing_contract
from operator_2_5d_review import (Operator2DReview, human_review_evidence_sha, human_review_is_valid,
                                  human_review_passes, qa_state, sha256_file)
from animation_preview import Preview, ReviewSequence, SemanticIdentity, TimelineClip
from ui.service import WorkbenchService
from ui.state import AnimationRecord, AnimationSelection


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
approval_sha = human_review_evidence_sha(**human_evidence)
canonical_approval = {
    "status": "APPROVED",
    "provenance": {
        "kind": "workbench_explicit_user",
        "reviewer": "human-user",
        "control": "polish-human-approved",
    },
    "evidence_sha256": approval_sha,
}
assert human_review_is_valid("NEEDS_HUMAN_REVIEW", {"status": "REQUIRED"}, approval_sha)
assert not human_review_passes("NEEDS_HUMAN_REVIEW", {"status": "NOT_REQUIRED"}, approval_sha)
assert not human_review_is_valid("NEEDS_HUMAN_REVIEW", {"status": "APPROVED"}, approval_sha)
assert not human_review_is_valid("NEEDS_HUMAN_REVIEW", {**canonical_approval, "evidence_sha256": "forged"}, approval_sha)
assert not human_review_is_valid("NEEDS_HUMAN_REVIEW", {**canonical_approval,
    "provenance": {**canonical_approval["provenance"], "reviewer": "caller"}}, approval_sha)
assert human_review_passes("NEEDS_HUMAN_REVIEW", canonical_approval, approval_sha)
assert not human_review_passes("RED", canonical_approval, approval_sha)
assert not human_review_is_valid("RED", canonical_approval, approval_sha)
for status in ("GREEN", "YELLOW"):
    assert human_review_is_valid(status, {"status": "NOT_REQUIRED"}, approval_sha)
    assert human_review_passes(status, {"status": "NOT_REQUIRED"}, approval_sha)
    assert not human_review_is_valid(status, canonical_approval, approval_sha)

with tempfile.TemporaryDirectory(prefix="operator_2d_current_receipt_") as raw:
    root = Path(raw)
    workbench = root / "workbench"
    workbench.mkdir()
    manifest = workbench / "workbench.json"
    document = workbench / "workbench.aseprite"
    manifest.write_text(json.dumps({"timeline": {"fps": 8.0, "preview_fps": 8.0,
        "workspace_clock_frames": 1, "durations": [1.0], "loop": True, "timing_authority": True}}))
    document.write_bytes(b"fixture physical document")
    reference = root / "reference.png"
    Image.new("RGBA", (128, 128), (1, 2, 3, 255)).save(reference)
    reference_sha = sha256_file(reference)
    profile_path = root / "custodian/content/data/operator/authoring/operator_art_profile.json"
    profile_path.parent.mkdir(parents=True)
    profile_path.write_text(json.dumps({
        "active_authoring_profile": "operator_2_5d_128",
        "profiles": {"operator_2_5d_128": {"profile_sha256": "profile-sha"}},
        "canonical_visual_reference": {"sha256": reference_sha, "path": "reference.png"},
    }))
    plan_path = root / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"
    plan_path.parent.mkdir(parents=True)
    plan_path.write_text(json.dumps({"schema": "custodian.operator_animation_implementation_plan.v2",
        "items": [{"id": "fixture", "rank": 1, "priority": "P0", "state": "complete",
            "art_generation": "operator_2_5d_128", "canonical_profile_id": "operator_2_5d_128",
            "profile": "unarmed", "group": "posture", "action": "idle_relaxed_01",
            "directions": ["n", "ne", "e", "se", "s", "sw", "w", "nw"],
            "requested_directions": ["n", "ne", "e", "se", "s", "sw", "w", "nw"],
            "required_layers": ["full_body"]}]}))
    art_root = root / ".ai/operator_art_agent/render"
    art_root.mkdir(parents=True)
    frame_path = art_root / "frame.png"
    Image.new("RGBA", (128, 128), (17, 34, 51, 255)).save(frame_path)
    selection = SimpleNamespace(profile="unarmed", group="posture", action="idle_relaxed_01", direction="ne",
        art_generation="operator_2_5d_128", authoring_identity="operator_2_5d_128:unarmed/posture/idle_relaxed_01/ne")
    qa_findings = [{"severity": "major", "code": "fixture-major"}]
    qa = {"schema": "custodian.operator_art_qa.v2", "status": "NEEDS_HUMAN_REVIEW", "findings": qa_findings}

    class ReceiptArt:
        aseprite = "fixture-aseprite"
        def inspect_polish_contract(self, _session): return {"valid": True, "art_generation": "operator_2_5d_128"}

    class ReceiptService:
        aseprite = "fixture-aseprite"
        def workspace(self, _selection): return workbench
        def polish_attach(self, _selection): return workbench
        def _polish(self, _selection): return SimpleNamespace(service=ReceiptArt())
        def polish_analyze(self, _session): return {"qa": qa}

    receipt_owner = Operator2DReview(service=ReceiptService(), repo_root=root, workspace_root=workbench)
    physical_contract = {"width": 128, "height": 128, "frames": 1, "durations": [0.125]}
    import animation_workbench
    saved_contract = animation_workbench.inspect_saved_document_contract
    animation_workbench.inspect_saved_document_contract = lambda *_args: physical_contract

    last_approval = {}
    def current_receipt_for(human, *, timing_authority=True, decision=True):
        manifest.write_text(json.dumps({"timeline": {"fps": 8.0, "preview_fps": 8.0,
            "workspace_clock_frames": 1, "document_frames": 1, "clock_owner": "full_body",
            "durations": [1.0], "loop": True,
            "frame_durations_ms": [125.0], "timing_authority": timing_authority},
            "identity": {"profile": "unarmed", "group": "posture", "action": "idle_relaxed_01", "direction": "ne"}}))
        authority = {
            "workbench_manifest_sha256": sha256_file(manifest),
            "workbench_document_sha256": sha256_file(document),
            "render_sha256": "render-sha",
            "frame_sha256": [sha256_file(frame_path)],
            "frame_paths": [str(frame_path.resolve())],
            "canonical_profile_sha256": "profile-sha",
            "normalized_reference_sha256": reference_sha,
            "frames": 1,
            "frame_size": [128, 128],
            "durations": [0.125],
        }
        decision_path = timing_contract.decision_path(
            receipt_owner.receipt_root, selection)
        decision_path.parent.mkdir(parents=True, exist_ok=True)
        if decision and timing_authority:
            params = {"fps": 8.0, "loop": True, "durations": [1.0]}
            decision_record = {"schema": timing_contract.SCHEMA,
                "authoring_identity": selection.authoring_identity,
                "action": "workbench_explicit_timing_confirmation", "parameters": params,
                "provenance": {"kind": "workbench_explicit_user", "control": "timing-preview-confirm",
                    "confirmed_utc": "2026-10-11T00:00:00+00:00"},
                "parameter_sha256": timing_contract.parameter_digest(**params),
                "bindings": {"manifest_sha256": sha256_file(manifest),
                    "document_sha256": sha256_file(document), "plan_sha256": sha256_file(plan_path),
                    "profile_sha256": "profile-sha", "reference_sha256": reference_sha,
                    "physical": {"frames": 1, "width": 128, "height": 128, "durations": [0.125]}}}
            decision_record["record_sha256"] = timing_contract.sha256_bytes(timing_contract.canonical_json(decision_record))
            decision_path.write_text(json.dumps(decision_record))
        else:
            decision_path.unlink(missing_ok=True)
        authority["timing_decision_sha256"] = ""
        if decision and timing_authority:
            authority["timing_decision_sha256"] = decision_record["record_sha256"]
        qa_record = {"status": "NEEDS_HUMAN_REVIEW",
            "findings_sha256": hashlib.sha256(json.dumps(qa_findings, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest(),
            "findings": qa_findings}
        human_digest = human_review_evidence_sha(identity=selection.authoring_identity,
            manifest_sha256=authority["workbench_manifest_sha256"], document_sha256=authority["workbench_document_sha256"],
            frame_sha256=authority["frame_sha256"], profile_sha256="profile-sha", reference_sha256=reference_sha,
            frames=1, frame_size=[128, 128], durations=[0.125], findings_sha256=qa_record["findings_sha256"])
        approval_record = receipt_owner._approval_record(human_digest)
        last_approval["record"] = approval_record
        if human == "AUTO_APPROVAL":
            human = approval_record
        evidence = hashlib.sha256(json.dumps({"identity": selection.authoring_identity, "authority": authority,
            "qa": qa_record, "human_review": human}, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()
        request_base = {"schema": "custodian.operator_2_5d_sandbox_request.v1", "request_id": "receipt-fixture",
            "authoring_identity": selection.authoring_identity, "evidence_sha256": evidence,
            "frame_size": [128, 128], "durations": [0.125],
            "frames": [{"path": "frame_000.png", "sha256": sha256_file(frame_path),
                        "pixel_sha256": hashlib.sha256(Image.open(frame_path).convert("RGBA").tobytes()).hexdigest()}]}
        request_payload = json.dumps(request_base, separators=(",", ":"), ensure_ascii=False)
        request_sha = hashlib.sha256(request_payload.encode()).hexdigest()
        bundle = receipt_owner.preview_root / "receipt-fixture"
        bundle.mkdir(parents=True, exist_ok=True)
        (bundle / "frame_000.png").write_bytes(frame_path.read_bytes())
        request = {**request_base, "payload_json": request_payload, "request_sha256": request_sha}
        request_path = bundle / "request.json"
        request_path.write_text(json.dumps(request))
        result_path = bundle / "result.json"
        result_path.write_text(json.dumps({"request_sha256": request_sha, "presentation": "PASSED"}))
        sandbox = {"status": "PASSED", "request_sha256": request_sha,
            "result_sha256": sha256_file(result_path), "result_path": str(result_path.resolve()),
            "request_path": str(request_path.resolve()), "production_unchanged": True,
            "production_before": {}, "production_after": {}}
        receipt = {"schema": "custodian.operator_2_5d_review_receipt.v1",
            "authoring_identity": selection.authoring_identity, "session_path": str(workbench.resolve()),
            "authority": authority, "qa": qa_record, "human_review": human, "sandbox": sandbox,
            "runtime_verified": False, "evidence_sha256": evidence}
        receipt["receipt_sha256"] = hashlib.sha256(json.dumps(receipt, sort_keys=True,
            separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()
        receipt_path = receipt_owner._receipt_path(selection)
        receipt_path.parent.mkdir(parents=True, exist_ok=True)
        receipt_path.write_text(json.dumps(receipt))
        return receipt_owner.current_receipt(selection)

    # Run the required real renderer pass before receipt/family controls. The
    # receipt controls below use isolated persisted fixtures to test review
    # derivation; these fixtures cannot replace this actual Godot result.
    sandbox_owner = Operator2DReview(service=ReceiptService(), repo_root=ROOT, workspace_root=workbench)
    sandbox_owner.preview_root = root / "renderer_preflight"
    renderer_receipt = {"receipt_sha256": "renderer-prerequisite",
        "authoring_identity": selection.authoring_identity,
        "authority": {"frame_sha256": [sha256_file(frame_path)],
            "frame_paths": [str(frame_path)], "durations": [0.125]}}
    godot = shutil.which("godot")
    assert godot, "R0-02 requires the real Godot sandbox executable"
    renderer_result = sandbox_owner.run_sandbox(selection, renderer_receipt, godot=godot)
    assert renderer_result["status"] == "PASSED" and renderer_result["production_unchanged"]

    try:
        assert current_receipt_for({"status": "REQUIRED"})["runtime_verified"] is False
        assert current_receipt_for({"status": "NOT_REQUIRED"}) is None
        assert current_receipt_for("AUTO_APPROVAL")["runtime_verified"] is True
        # Passing QA, human approval, and sandbox proof cannot turn the physical
        # 8 FPS preview default into approved timing authority.
        assert current_receipt_for("AUTO_APPROVAL", timing_authority=False) is None
        assert current_receipt_for("AUTO_APPROVAL", timing_authority=True)["runtime_verified"] is True
        assert current_receipt_for("AUTO_APPROVAL", timing_authority=True, decision=False) is None
        # Family completion consumes the same effective leaf receipt gate. A
        # fully covered family cannot advance while its current timing proof is
        # non-authoritative, even with the positive QA/human/sandbox fixture.
        family_owner = Operator2DReview(service=ReceiptService(), repo_root=ROOT, workspace_root=workbench)
        family_owner.current_receipt = lambda _selection: current_receipt_for(
            "AUTO_APPROVAL", timing_authority=False)
        family_records = [SimpleNamespace(
            selection=SimpleNamespace(profile="unarmed", group="posture", action="idle_relaxed_01",
                direction=direction, art_generation="operator_2_5d_128",
                authoring_identity=f"operator_2_5d_128:unarmed/posture/idle_relaxed_01/{direction}"),
            coverage_status="CANONICAL_2_5D", workflow_status="EDITABLE_WORKBENCH",
            stale_reference=False, layers=("full_body",))
            for direction in ("n", "ne", "e", "se", "s", "sw", "w", "nw")]
        family = family_owner.family(family_records, profile="unarmed", group="posture",
                                     action="idle_relaxed_01")
        assert family["complete"] is False
        assert all(not cell["runtime_verified"] for cell in family["cells"])
        current_approval = last_approval["record"]
        assert current_receipt_for({**current_approval, "provenance": {"kind": "forged"}}) is None
        assert current_receipt_for({**current_approval, "evidence_sha256": "stale"}) is None
        assert current_receipt_for({"status": "APPROVED", "provenance": current_approval["provenance"],
            "evidence_sha256": approval_sha}) is None
    finally:
        animation_workbench.inspect_saved_document_contract = saved_contract

with tempfile.TemporaryDirectory(prefix="operator_2d_timing_decision_") as raw:
    root = Path(raw)
    ref = root / "reference.png"
    Image.new("RGBA", (128, 128), (1, 2, 3, 255)).save(ref)
    ref_sha = sha256_file(ref)
    profile_path = root / "custodian/content/data/operator/authoring/operator_art_profile.json"
    profile_path.parent.mkdir(parents=True)
    profile_path.write_text(json.dumps({"active_authoring_profile": "operator_2_5d_128",
        "profiles": {"operator_2_5d_128": {"profile_sha256": "profile-sha"}},
        "canonical_visual_reference": {"sha256": ref_sha, "path": "reference.png"}}))
    plan_path = root / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"
    plan_path.parent.mkdir(parents=True)
    plan_path.write_text(json.dumps({"schema": "custodian.operator_animation_implementation_plan.v2",
        "items": [{"id": "fixture", "rank": 1, "priority": "P0", "state": "complete",
            "art_generation": "operator_2_5d_128", "canonical_profile_id": "operator_2_5d_128",
            "profile": "unarmed", "group": "posture", "action": "idle_relaxed_01",
            "directions": ["n", "ne", "e", "se", "s", "sw", "w", "nw"],
            "requested_directions": ["n", "ne", "e", "se", "s", "sw", "w", "nw"],
            "required_layers": ["full_body"]}]}))
    selection = AnimationSelection("unarmed", "posture", "idle_relaxed_01", "ne", art_generation="operator_2_5d_128")
    workspace = root / ".ai/operator_animation_workbench/operator_2_5d_128/unarmed/posture/idle_relaxed_01/ne"
    workspace.mkdir(parents=True)
    manifest_path, document_path = workspace / "workbench.json", workspace / "workbench.aseprite"
    manifest_path.write_text(json.dumps({"identity": {"profile": "unarmed", "group": "posture",
        "action": "idle_relaxed_01", "direction": "ne"}, "canvas": {"width": 128, "height": 128},
        "timeline": {"preview_fps": 8, "workspace_clock_frames": 3, "document_frames": 3,
                     "clock_owner": "full_body", "timing_authority": False}}))
    document_path.write_bytes(b"saved physical fixture")

    class TimingBackend:
        durations = [0.125, 0.25, 0.125]
        def inspect_saved_document_contract(self, *_args):
            return {"frames": 3, "width": 128, "height": 128, "durations": list(self.durations)}

    timing_backend = TimingBackend()
    timing_service = WorkbenchService(repo_root=root, workspace_root=root / ".ai/operator_animation_workbench",
                                      workbench_api=timing_backend)
    # A manifest Boolean alone cannot create an effective decision.
    manifest = json.loads(manifest_path.read_text())
    manifest["timeline"]["timing_authority"] = True
    manifest_path.write_text(json.dumps(manifest))
    assert timing_service.timing_approval_status(selection)["status"] == "PREVIEW TIMING"
    assert not hasattr(timing_service, "_confirm_timing_decision_from_ui")
    preview = timing_service._preview_timing_decision_from_ui(selection, fps_text="8", loop_text="loop",
        durations_text="1, 2, 1")
    assert preview["status"] == "PREVIEW TIMING" and preview["frame_durations_ms"] == [125.0, 250.0, 125.0]
    prepared = timing_service._consume_timing_decision_preview(selection, preview_token=preview["token"])
    assert prepared["params"]["frame_durations_ms"] == [125.0, 250.0, 125.0]
    assert timing_service.timing_approval_status(selection)["status"] == "PREVIEW TIMING"
    decision_path = timing_contract.decision_path(
        root / ".ai/operator_animation_workbench/review_receipts/operator_2_5d_128", selection)
    assert not decision_path.exists(), "generic service preview/consume calls must not persist approval"
    try:
        timing_service._consume_timing_decision_preview(selection, preview_token=preview["token"])
    except ValueError:
        pass
    else:
        raise AssertionError("one-use Workbench timing preview was reusable")
    # A saved-input change also expires a preview before any UI writer can run.
    stale_preview = timing_service._preview_timing_decision_from_ui(selection, fps_text="8", loop_text="loop",
        durations_text="1, 2, 1")
    document_path.write_bytes(b"mutated saved physical fixture")
    assert timing_service.timing_approval_status(selection)["status"] == "PREVIEW TIMING"
    try:
        timing_service._consume_timing_decision_preview(selection, preview_token=stale_preview["token"])
    except ValueError:
        pass
    else:
        raise AssertionError("changed Workbench bytes retained a consumable timing preview")

with tempfile.TemporaryDirectory(prefix="operator_2d_review_") as raw:
    root = Path(raw)
    frame = root / "frame.png"
    Image.new("RGBA", (128, 128), (17, 34, 51, 255)).save(frame)
    selection = SimpleNamespace(profile="operator", group="posture", action="idle", direction="ne",
        art_generation="operator_2_5d_128", authoring_identity="operator_2_5d_128:operator/posture/idle/ne")
    class Service:
        def workspace(self, _selection): return root / "workbench"
    owner = Operator2DReview(service=Service(), repo_root=root, workspace_root=root / "workbench")
    try:
        owner.inspect(selection, human_disposition={"status": "NOT_REQUIRED"})
        raise AssertionError("the removed free-form disposition seam must reject legacy callers")
    except TypeError:
        pass

    class ReviewFlow:
        instances = []
        def __init__(self, **_kwargs):
            self.calls = []
            self.instances.append(self)
        def inspect(self, _selection, *, sandbox_result=None):
            self.calls.append(("inspect", sandbox_result))
            if sandbox_result:
                return {"qa": {"status": "NEEDS_HUMAN_REVIEW"}, "human_review": {"status": "APPROVED"},
                        "sandbox": sandbox_result, "runtime_verified": True}
            return {"qa": {"status": "NEEDS_HUMAN_REVIEW"}, "human_review": {"status": "REQUIRED"},
                    "sandbox": {"status": "NOT_RUN"}, "runtime_verified": False}
        def _approve_human_review(self, _selection):
            self.calls.append(("approve", None))
            return {"qa": {"status": "NEEDS_HUMAN_REVIEW"}, "human_review": {"status": "APPROVED"},
                    "sandbox": {"status": "NOT_RUN"}, "runtime_verified": False}
        def run_sandbox(self, _selection, _receipt):
            self.calls.append(("sandbox", None))
            return {"status": "PASSED", "request_sha256": "request", "result_sha256": "result"}

    real_review_owner = review_module.Operator2DReview
    review_module.Operator2DReview = ReviewFlow
    flow_service = SimpleNamespace(repo_root=root, workspace_root=root / "workbench")
    try:
        waiting = WorkbenchService.review_and_sandbox(flow_service, selection, human_approved=False)
        assert not waiting["runtime_verified"] and ReviewFlow.instances[-1].calls == [("inspect", None)]
        verified = WorkbenchService.review_and_sandbox(flow_service, selection, human_approved=True)
        assert verified["runtime_verified"]
        assert [name for name, _ in ReviewFlow.instances[-1].calls] == ["inspect", "approve", "sandbox", "inspect"]
    finally:
        review_module.Operator2DReview = real_review_owner
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

    stalled_godot = root / "stalled-godot"
    stalled_godot.write_text(f"#!{sys.executable}\nimport time\ntime.sleep(5)\n")
    stalled_godot.chmod(0o755)
    timeout_receipt = {**receipt, "receipt_sha256": "bounded-timeout-control"}
    timed_out = sandbox_owner.run_sandbox(selection, timeout_receipt,
        godot=str(stalled_godot), timeout_sec=0.05)
    assert timed_out["status"] == "FAILED" and timed_out["timed_out"] is True
    assert timed_out["timeout_sec"] == 0.05
    assert "timed out after 0.05s" in timed_out["result"]["error"]

    import operator_animation_targets
    plan = operator_animation_targets.load_plan(ROOT / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json")
    projected = operator_animation_targets.project_targets(plan, repo_root=ROOT, workspace_root=root / "live-workspace")
    family_records = tuple(record for record in projected if (
        record.selection.profile, record.selection.group, record.selection.action
    ) == ("unarmed", "posture", "idle_relaxed_01"))
    assert len(family_records) == 8 and all(isinstance(record, AnimationRecord) for record in family_records)
    integrated = WorkbenchService(repo_root=ROOT, workspace_root=root / "live-workspace")
    integrated.browser_records = lambda **_kwargs: family_records
    live_family = integrated.review_family("unarmed", "posture", "idle_relaxed_01")
    assert len(live_family["cells"]) == 8 and not live_family["complete"]
    assert live_family["required_directions"] == ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
    assert all(cell["missing_layers"] == [] for cell in live_family["cells"])

    live_owner = Operator2DReview(service=integrated, repo_root=ROOT, workspace_root=root / "live-workspace")
    live_owner.current_receipt = lambda current: {"runtime_verified": True, "receipt_sha256": "r"}
    assert live_owner.family(family_records, profile="unarmed", group="posture", action="idle_relaxed_01")["complete"]
    assert not live_owner.family(family_records[:-1], profile="unarmed", group="posture", action="idle_relaxed_01")["complete"]
    missing_layer = (*family_records[:-1], replace(family_records[-1], layers=()))
    assert not live_owner.family(missing_layer, profile="unarmed", group="posture", action="idle_relaxed_01")["complete"]
    missing_layer = (*family_records[:-1], replace(family_records[-1], layers=()))
    assert not live_owner.family(missing_layer, profile="unarmed", group="posture", action="idle_relaxed_01")["complete"]
    stale_records = (*family_records[:-1], replace(family_records[-1], stale_reference=True))
    assert not live_owner.family(stale_records, profile="unarmed", group="posture", action="idle_relaxed_01")["complete"]
    live_owner.current_receipt = lambda _current: {"runtime_verified": False, "receipt_sha256": "forged"}
    assert not live_owner.family(family_records, profile="unarmed", group="posture", action="idle_relaxed_01")["complete"]

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
