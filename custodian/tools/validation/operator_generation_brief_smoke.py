#!/usr/bin/env python3
"""Determinism, staleness, and ingress correlation checks for generation briefs."""
from __future__ import annotations

import json
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "custodian/tools/operator"), str(ROOT / "custodian/tools/operator/ui"),
                str(ROOT / "custodian/tools/pipelines")]

from operator_2_5d_ingress import IngressError, Operator2DIngress
from operator_generation_brief import export_generation_brief, validate_generation_brief
from ui.state import AnimationSelection


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="operator_generation_brief_") as raw:
        root = Path(raw) / "repo"
        plan_source = ROOT / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"
        profile_source = ROOT / "custodian/content/data/operator/authoring/operator_art_profile.json"
        reference_source = ROOT / "custodian/content/sprites/operator/reference/operator_2_5d"
        plan = root / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"
        profile = root / "custodian/content/data/operator/authoring/operator_art_profile.json"
        plan.parent.mkdir(parents=True)
        profile.parent.mkdir(parents=True)
        shutil.copy2(plan_source, plan)
        shutil.copy2(profile_source, profile)
        reference_root = root / "custodian/content/sprites/operator/reference/operator_2_5d"
        shutil.copytree(reference_source, reference_root)
        workspace = root / ".ai/operator_animation_workbench"
        idle = AnimationSelection("unarmed", "posture", "idle_relaxed_01", "ne", art_generation="operator_2_5d_128")
        first = export_generation_brief(root, workspace, idle)
        second = export_generation_brief(root, workspace, idle)
        assert first["brief_id"] == second["brief_id"]
        assert first["manifest_sha256"] == second["manifest_sha256"]
        manifest_path = first["path"] / "manifest.json"
        manifest = json.loads(manifest_path.read_text())
        assert manifest["frame_contract"] == {"frames": 15, "frame_size": [128, 128], "loop": True,
                                                "fps": None, "timing_status": "unknown_non_blocking"}
        assert manifest["readiness"] == "GENERATION_READY"
        assert manifest["unknown_authoring_fields"] == ["fps"]
        assert "references/directions/ne.png" in manifest["files"]
        assert "references/directions/n.png" in manifest["files"]
        assert "references/directions/e.png" in manifest["files"]
        assert "registration_guide.json" in manifest["files"]
        assert "registration_overlay.png" in manifest["files"] and "PROMPT.txt" in manifest["files"]
        validate_generation_brief(root, workspace, idle, first["brief_id"], first["manifest_sha256"])
        wrong_direction = AnimationSelection("unarmed", "posture", "idle_relaxed_01", "e", art_generation="operator_2_5d_128")
        try:
            validate_generation_brief(root, workspace, wrong_direction, first["brief_id"], first["manifest_sha256"])
            raise AssertionError("wrong direction brief was accepted")
        except ValueError:
            pass

        class SourcePathAdapter:
            @staticmethod
            def authorize_source_path(path): return Path(path).resolve()

        ingress = Operator2DIngress(root, source=SourcePathAdapter(), workspace_root=workspace)
        bound = ingress.target_binding(idle, brief_id=first["brief_id"], brief_sha256=first["manifest_sha256"])
        assert bound["generation_brief"] == {"brief_id": first["brief_id"], "manifest_sha256": first["manifest_sha256"]}
        returned_art = root / "returned_ne.png"
        returned_art.write_bytes(b"fixture PNG bytes")
        package_path = ingress.create_package([idle], source_paths={"ne": returned_art},
            brief_id=first["brief_id"], brief_sha256=first["manifest_sha256"])
        package = json.loads(package_path.read_text())
        assert package["targets"][0]["generation_brief"] == bound["generation_brief"]
        for invalid in ((first["brief_id"], "0" * 64), ("../escape", first["manifest_sha256"])):
            try:
                ingress.target_binding(idle, brief_id=invalid[0], brief_sha256=invalid[1])
                raise AssertionError("invalid brief correlation was accepted")
            except IngressError:
                pass
        # Existing unbriefed intake remains supported at the same authority seam.
        plain = ingress.target_binding(idle)
        assert "generation_brief" not in plain
        unbriefed_art = root / "unbriefed_ne.png"
        unbriefed_art.write_bytes(b"legacy-compatible unbriefed fixture")
        unbriefed_path = ingress.create_package([idle], source_paths={"ne": unbriefed_art})
        assert "generation_brief" not in json.loads(unbriefed_path.read_text())["targets"][0]

        prompt_path = first["path"] / "PROMPT.txt"
        prompt_bytes = prompt_path.read_bytes()
        prompt_path.write_bytes(prompt_bytes + b"tamper")
        try:
            validate_generation_brief(root, workspace, idle, first["brief_id"], first["manifest_sha256"])
            raise AssertionError("tampered prompt was accepted")
        except ValueError:
            pass
        prompt_path.write_bytes(prompt_bytes)

        unresolved = AnimationSelection("melee_1h", "attack", "fast_01", "n", art_generation="operator_2_5d_128")
        draft = export_generation_brief(root, workspace, unresolved)
        unresolved_manifest = json.loads((draft["path"] / "manifest.json").read_text())
        assert unresolved_manifest["frame_contract"]["frames"] is None
        assert unresolved_manifest["readiness"] == "PLANNING_ONLY"
        assert "frames" in unresolved_manifest["unknown_authoring_fields"]
        try:
            ingress.target_binding(unresolved)
            raise AssertionError("ingress accepted an unresolved physical frame count")
        except IngressError:
            pass

        before = plan.read_bytes()
        changed = json.loads(before)
        changed["items"][0]["rank"] = 7
        plan.write_text(json.dumps(changed))
        try:
            validate_generation_brief(root, workspace, idle, first["brief_id"], first["manifest_sha256"])
            raise AssertionError("stale plan brief was accepted")
        except ValueError:
            pass
        plan.write_bytes(before)

    print("operator_generation_brief_smoke: PASS")


if __name__ == "__main__":
    main()
