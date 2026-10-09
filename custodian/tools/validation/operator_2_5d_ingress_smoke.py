#!/usr/bin/env python3
"""Focused target binding, generation isolation, and package-resume checks."""
from __future__ import annotations

import json
import shutil
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS / "operator"))
sys.path.insert(0, str(TOOLS / "pipelines"))

import animation_workbench_model as workbench_model
import animation_workbench
import operator_animation_targets
import operator_asset_schema as schema
from art_agent.source_models import SOURCE_SESSION_SCHEMA, SourceSession, SourceGeometry
from art_agent.source_service import SourceArtService
from operator_2_5d_ingress import IngressError, Operator2DIngress
from ui.state import AnimationSelection


REPO = Path(__file__).resolve().parents[3]


def main() -> None:
    # V1 source-session evidence stays readable and serializes with its old shape.
    legacy = SourceSession.create(session_id="legacy", created_utc="now", source_original="x",
                                  source_sha256="0" * 64, geometry=SourceGeometry(1, 1, 1, 8, 8),
                                  target_width=96, target_height=96)
    assert legacy.schema == SOURCE_SESSION_SCHEMA and "target_binding" not in legacy.to_json()
    assert SourceSession.from_json(legacy.to_json()).target_binding is None

    with tempfile.TemporaryDirectory(prefix="operator_2_5d_ingress_") as temporary:
        root = Path(temporary)
        custodian = root / "custodian"
        source_root = custodian / "content/sprites/operator/source"
        weapon_root = custodian / "content/sprites/weapons"
        workspace_root = root / ".ai/operator_animation_workbench"
        source_root.mkdir(parents=True)
        weapon_root.mkdir(parents=True)

        key = schema.OperatorAssetKey("operator", "full_body", "unarmed", "locomotion",
                                      "walk_01", "n", 15, 96, 96)
        legacy_path = custodian / schema.canonical_source_path(key)
        legacy_path.parent.mkdir(parents=True, exist_ok=True)
        Image.new("RGBA", (15 * 96, 96), (0, 0, 0, 0)).save(legacy_path)
        runtime = custodian / schema.canonical_runtime_path(key)
        runtime.parent.mkdir(parents=True, exist_ok=True)
        runtime.write_bytes(b"legacy runtime counterpart")
        plan = workbench_model.build_creation_plan(
            "unarmed", "locomotion", "walk_01", "n", 15, (128, 128),
            repo_root=root, source_root=source_root, weapon_root=weapon_root,
            art_generation="operator_2_5d_128",
        )
        assert plan.status == "READY", plan.collisions
        assert "operator_2_5d_128" in plan.layers[0]["source_path"]
        assert plan.art_generation == "operator_2_5d_128"
        if shutil.which("aseprite"):
            created, created_workspace = animation_workbench.create_animation(
                "unarmed", "new_ingress_01", "ne", group="locomotion", frames=15,
                frame_size=(128, 128), fps=8.0, loop=True, template="full_body",
                root=root / "workbench", repo_root=root, source_root=source_root,
                weapon_root=weapon_root, art_generation="operator_2_5d_128",
            )
            assert created_workspace == root / "workbench/operator_2_5d_128/unarmed/locomotion/new_ingress_01/ne"
            assert created["creation"]["authoring_identity"] == "operator_2_5d_128:unarmed/locomotion/new_ingress_01/ne"
        else:
            print("SKIP 2.5D NEW WORKBENCH integration: aseprite executable unavailable")
        target_key = schema.OperatorAssetKey("operator", "full_body", "unarmed", "locomotion",
                                             "walk_01", "n", 15, 128, 128)
        same_generation = custodian / schema.canonical_source_path(
            target_key, art_generation="operator_2_5d_128")
        same_generation.parent.mkdir(parents=True, exist_ok=True)
        Image.new("RGBA", (15 * 128, 128), (0, 0, 0, 0)).save(same_generation)
        collided = workbench_model.build_creation_plan(
            "unarmed", "locomotion", "walk_01", "n", 15, (128, 128),
            repo_root=root, source_root=source_root, weapon_root=weapon_root,
            art_generation="operator_2_5d_128",
        )
        assert collided.status == "COLLISION"
        protected_manifest = root / "blocked-workbench/workbench.json"
        protected_manifest.parent.mkdir(parents=True)
        protected_manifest.write_text(json.dumps({"creation": {"art_generation": "operator_2_5d_128"}}))
        try:
            animation_workbench.publish(protected_manifest)
        except workbench_model.WorkbenchError as error:
            assert "publication is disabled" in str(error)
        else:
            raise AssertionError("2.5D Workbench reached the legacy publisher")

        inbox = root / "asset_drop/inbox/operator_2_5d"
        inbox.mkdir(parents=True)
        allowed = (inbox,)
        source_service = SourceArtService(root=root / "sessions", allowed_source_roots=allowed,
                                          canonical_root=REPO / "custodian", handoff_root=root / "handoff")
        ingress = Operator2DIngress(REPO, source=source_service, workspace_root=workspace_root)
        proof_source = inbox / "proof.png"
        bad_source = inbox / "bad-geometry.png"
        bad_image = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        ImageDraw.Draw(bad_image).rectangle((4, 2, 11, 13), fill=(80, 100, 120, 255))
        bad_image.save(bad_source)
        proof_image = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        ImageDraw.Draw(proof_image).rectangle((48, 24, 79, 101), fill=(80, 100, 120, 255))
        proof_image.save(proof_source)
        proof_session = source_service.start(source_path=proof_source, frames=1, target_size=128)
        profile_hash, reference_hash = operator_animation_targets._profile_hashes(REPO)
        binding_1f = {
            "art_generation": "operator_2_5d_128", "profile": "unarmed", "group": "locomotion",
            "action": "walk_01", "direction": "n", "layer": "full_body",
            "authoring_identity": "operator_2_5d_128:unarmed/locomotion/walk_01/n",
            "canonical_profile_sha256": profile_hash, "normalized_reference_sha256": reference_hash,
            "frames": 1, "frame_size": [128, 128],
        }
        bad_session = source_service.start(source_path=bad_source, frames=1, target_size=128)
        source_service.bind_target(bad_session, binding_1f)
        source_service.analyze(bad_session)
        try:
            source_service.plan_normalization(bad_session, mode="operator_profile")
        except workbench_model.WorkbenchError as error:
            assert "source cells must already be 128x128" in str(error)
        else:
            raise AssertionError("2.5D profile inferred scale without target scale landmarks")
        source_service.bind_target(proof_session, {
            **binding_1f,
        })
        source_service.set_source_landmarks(proof_session, [
            {"frame": 1, "name": "head_center", "x": 8, "y": 4, "semantic_side": "center",
             "confidence": 1.0, "provenance": "human"},
            {"frame": 1, "name": "hip_center", "x": 8, "y": 12, "semantic_side": "center",
             "confidence": 1.0, "provenance": "human"},
        ])
        source_service.analyze(proof_session)
        source_service.plan_normalization(proof_session, mode="operator_profile")
        command = source_service.production_command(proof_session)["command"]
        assert command[command.index("--size") + 1] == "128"
        source_service.convert(proof_session)
        proof_root = Path(source_service.status(proof_session)["root"])
        (proof_root / "production").mkdir(parents=True, exist_ok=True)
        (proof_root / "candidates/crisp.png").replace(proof_root / "production/crisp.png")
        assert source_service.verify_production(proof_session)["verified"] is True
        with Image.open(proof_root / "production/crisp.png") as normalized:
            assert normalized.size == (128, 128)
        stale_custodian = root / "stale-authority/custodian"
        authority_path = stale_custodian / "content/data/operator/authoring/operator_art_profile.json"
        authority_path.parent.mkdir(parents=True)
        authority_path.write_bytes((REPO / "custodian/content/data/operator/authoring/operator_art_profile.json").read_bytes())
        stale_service = SourceArtService(root=root / "stale-sessions", allowed_source_roots=allowed,
                                         canonical_root=stale_custodian)
        stale_binding = {"art_generation": "operator_2_5d_128", "profile": "unarmed", "group": "locomotion",
                         "action": "walk_01", "direction": "n", "layer": "full_body",
                         "authoring_identity": "operator_2_5d_128:unarmed/locomotion/walk_01/n",
                         "canonical_profile_sha256": profile_hash, "normalized_reference_sha256": reference_hash,
                         "frames": 1, "frame_size": [128, 128]}
        stale_session = stale_service.start(source_path=proof_source, frames=1, target_size=128)
        stale_service.bind_target(stale_session, stale_binding)
        authority = json.loads(authority_path.read_text())
        authority["profiles"]["operator_2_5d_128"]["profile_sha256"] = "0" * 64
        authority_path.write_text(json.dumps(authority))
        try:
            stale_service.status(stale_session)
        except Exception as error:
            assert "authority is stale" in str(error)
        else:
            raise AssertionError("changed 2.5D profile authority was accepted")
        authority_path.write_bytes((REPO / "custodian/content/data/operator/authoring/operator_art_profile.json").read_bytes())
        stale_reference_session = stale_service.start(source_path=proof_source, frames=1, target_size=128)
        stale_service.bind_target(stale_reference_session, stale_binding)
        authority = json.loads(authority_path.read_text())
        authority["canonical_visual_reference"]["sha256"] = "1" * 64
        authority_path.write_text(json.dumps(authority))
        try:
            stale_service.status(stale_reference_session)
        except Exception as error:
            assert "authority is stale" in str(error)
        else:
            raise AssertionError("changed normalized reference authority was accepted")
        plan_payload = operator_animation_targets.load_plan(ingress.plan_path)
        family = next(item for item in operator_animation_targets.target_families(plan_payload)
                      if item.profile == "unarmed" and item.action == "idle_relaxed_01")
        selections = [AnimationSelection(family.profile, family.group, family.action, direction,
                                         art_generation=family.generation)
                      for direction in family.directions]
        files = {}
        for direction in family.directions:
            path = inbox / f"{direction}.png"
            sheet = Image.new("RGBA", (15 * 128, 128), (0, 0, 0, 0))
            for frame in range(15):
                ImageDraw.Draw(sheet).rectangle((frame * 128 + 48, 24, frame * 128 + 79, 101),
                                                fill=(80, 100, 120, 255))
            sheet.save(path)
            files[direction] = path
        package_path = ingress.create_package(selections, source_paths=files)
        session_path = ingress.start_cell(package_path, "n", columns=15)
        session = source_service.status(session_path)
        assert session["schema"] == "custodian.operator_art_source_session.v2"
        assert session["target_binding"]["direction"] == "n"
        assert session["target_binding"]["frame_size"] == [128, 128]
        assert ingress.start_cell(package_path, "n", columns=15) == session_path
        if shutil.which("aseprite"):
            alias_home = root / "pixelart-alias-home"
            alias_project = alias_home / "Projects/CUSTODIAN"
            alias_project.parent.mkdir(parents=True)
            alias_project.symlink_to(REPO, target_is_directory=True)
            imported = ingress.process_cell(package_path, "ne", execution_env={"HOME": str(alias_home)})
            assert imported["terminal_state"] == "EDITABLE_WORKBENCH"
            assert imported["handoff"]
            imported_manifest = json.loads((Path(imported["workbench"]) / "workbench.json").read_text())
            assert imported_manifest["creation"]["authoring_identity"] == \
                f"operator_2_5d_128:unarmed/{family.group}/idle_relaxed_01/ne", imported_manifest["creation"]
            assert imported_manifest["creation"]["import_sources"]["full_body"]
            resumed_handoff = source_service.handoff(
                imported["source_session"], destination_name=Path(imported["handoff"]).name,
                art_generation="operator_2_5d_128",
            )
            assert resumed_handoff["operation"] == "REUSE"
        ingress.record_blocked(package_path, "n", "fixture blocked before production proof")
        try:
            ingress.validate_package(package_path)
        except IngressError as error:
            assert "not terminal" in str(error)
        else:
            raise AssertionError("package with pending directions incorrectly completed")
        files["nw"].write_bytes(b"changed source")
        try:
            ingress.start_cell(package_path, "nw", columns=15)
        except IngressError as error:
            assert "changed after package creation" in str(error)
        else:
            raise AssertionError("changed package source was reused")
        package = json.loads(package_path.read_text())
        for direction, cell in package["cells"].items():
            if cell["terminal_state"] not in {"EDITABLE_WORKBENCH", "BLOCKED"}:
                ingress.record_blocked(package_path, direction, "fixture cell intentionally deferred")
        terminal = ingress.validate_package(package_path)
        assert terminal["complete"] is True
        assert sum(cell["terminal_state"] == "EDITABLE_WORKBENCH" for cell in terminal["cells"].values()) == (1 if shutil.which("aseprite") else 0)
        assert runtime.read_bytes() == b"legacy runtime counterpart"

    print("PASS operator_2_5d_ingress_smoke: generation-scoped collision, v1/v2 session binding, explicit 8-direction mapping, resume and stale-source refusal")


if __name__ == "__main__":
    main()
