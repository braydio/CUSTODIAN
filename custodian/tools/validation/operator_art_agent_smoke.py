#!/usr/bin/env python3
"""Headless safety and editing smoke for Operator Art Agent V1."""
from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OPERATOR_TOOLS = ROOT / "custodian/tools/operator"
sys.path.insert(0, str(OPERATOR_TOOLS))

import animation_workbench as workbench  # noqa: E402
import animation_workbench_model as model  # noqa: E402
from art_agent.service import ArtAgentService  # noqa: E402


def tree_hashes(root: Path) -> dict[str, str]:
    if not root.exists():
        return {}
    return {
        str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


def expect_error(fragment: str, callback) -> None:
    try:
        callback()
    except Exception as error:
        assert fragment in str(error), (fragment, error)
    else:
        raise AssertionError(f"expected failure containing {fragment!r}")


def read_json(path: Path) -> dict:
    return json.loads(path.read_text())


def write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload, indent=2) + "\n")


def aseprite_main() -> None:
    protected_roots = (
        ROOT / "custodian/content/sprites/operator/source/animations",
        ROOT / "custodian/content/sprites/operator/runtime/animations",
        ROOT / "custodian/game/actors/operator",
    )
    before_production = {str(path): tree_hashes(path) for path in protected_roots}
    aseprite = workbench.resolve_aseprite()
    if aseprite is None:
        print("SKIP operator_art_agent_smoke: Aseprite executable unavailable")
        return

    with tempfile.TemporaryDirectory() as temp_dir:
        temp = Path(temp_dir)
        service = ArtAgentService(
            art_root=temp / "art",
            workspace_root=temp / "workbench",
            aseprite=aseprite,
        )
        session_path = service.start_session(
            profile="melee_1h",
            group="locomotion",
            action="run_01",
            direction="e",
            weapon="vigil_pattern_dagger",
        )
        session = service.load_session(session_path)
        workbench_path = Path(session.workbench_path)
        manifest_path = Path(session.workbench_manifest)
        baseline_backup = session_path.parent / "backups/000000_baseline.aseprite"
        assert session_path.exists() and baseline_backup.exists()
        assert session.expected_workbench_sha256 == model.file_sha256(workbench_path)
        # Production CLI deliberately cannot accept injected roots; tests use the
        # service constructor so an agent cannot turn those test seams into path escapes.

        inspection = service.inspect(session_path)
        assert inspection["frames"] == 6
        assert {layer["name"] for layer in inspection["layers"]} >= {
            "lower_body", "upper_body", "weapon__vigil_pattern_dagger"
        }

        original_bytes = workbench_path.read_bytes()
        paint = service.apply_operation(
            session_path,
            {
                "type": "paint_pixels", "frame": 1, "layer": "lower_body",
                "pixels": [{"x": 2, "y": 2, "rgba": [255, 0, 255, 255]}],
            },
        )
        assert paint["response"]["changed_pixels"] == 1
        assert Path(paint["backup"]).exists()
        assert (session_path.parent / "operations.jsonl").exists()

        service.apply_operation(
            session_path,
            {
                "type": "erase_pixels", "frame": 1, "layer": "lower_body",
                "pixels": [{"x": 2, "y": 2}],
            },
        )
        service.apply_operation(
            session_path,
            {
                "type": "stroke", "frame": 1, "layer": "lower_body",
                "rgba": [20, 40, 60, 255],
                "brush": {"shape": "square", "size": 1},
                "points": [[4, 4], [7, 5]],
            },
        )
        service.apply_operation(
            session_path,
            {
                "type": "copy_region", "layer": "lower_body",
                "source_frame": 1, "destination_frame": 2,
                "source_rect": [4, 4, 4, 2], "destination": [10, 10],
            },
        )
        move = service.apply_operation(
            session_path,
            {
                "type": "move_region", "frame": 2, "layer": "lower_body",
                "rect": [10, 10, 4, 2], "dx": 2, "dy": 1,
            },
        )
        pre_move = Path(move["backup"]).read_bytes()
        undone = service.undo_last(session_path)
        assert undone["undone_operation"] == move["operation_id"]
        assert workbench_path.read_bytes() == pre_move

        rendered = service.render(session_path)
        assert len(rendered["frames"]) == 6
        for key in ("strip", "contact_sheet", "diff", "before_after"):
            assert Path(rendered[key]).exists()
        with Image.open(rendered["strip"]) as strip:
            assert strip.size == (96 * 6, 96)
        with Image.open(rendered["contact_sheet"]) as sheet:
            assert sheet.mode == "RGBA"

        stable_bytes = workbench_path.read_bytes()
        stable_sha = model.file_sha256(workbench_path)
        expect_error(
            "reference layers cannot be mutated",
            lambda: service.apply_operation(
                session_path,
                {"type": "paint_pixels", "frame": 1, "layer": "__REFERENCE_SESSION_BASELINE",
                 "pixels": [{"x": 1, "y": 1, "rgba": [1, 2, 3, 255]}]},
            ),
        )
        assert workbench_path.read_bytes() == stable_bytes
        expect_error(
            "outside legal binding rectangle",
            lambda: service.apply_operation(
                session_path,
                {"type": "paint_pixels", "frame": 1, "layer": "lower_body",
                 "pixels": [{"x": -1, "y": 0, "rgba": [1, 2, 3, 255]}]},
            ),
        )
        assert model.file_sha256(workbench_path) == stable_sha

        manifest = read_json(manifest_path)
        saved_manifest = json.loads(json.dumps(manifest))
        manifest["layers"][0]["workspace_contract"]["frame_size"] = [64, 64]
        write_json(manifest_path, manifest)
        expect_error(
            "cel image dimensions differ from binding contract",
            lambda: service.apply_operation(
                session_path,
                {"type": "paint_pixels", "frame": 1, "layer": "lower_body",
                 "pixels": [{"x": 70, "y": 20, "rgba": [1, 2, 3, 255]}]},
            ),
        )
        write_json(manifest_path, saved_manifest)

        external_backup = workbench_path.read_bytes()
        workbench_path.write_bytes(external_backup + b"external")
        expect_error(
            "WORKBENCH CHANGED OUTSIDE ART AGENT SESSION",
            lambda: service.apply_operation(
                session_path,
                {"type": "paint_pixels", "frame": 1, "layer": "lower_body",
                 "pixels": [{"x": 1, "y": 1, "rgba": [1, 2, 3, 255]}]},
            ),
        )
        workbench_path.write_bytes(external_backup)

        manifest = read_json(manifest_path)
        manifest["pending_migration"] = {"operation": "add"}
        write_json(manifest_path, manifest)
        expect_error(
            "PENDING FRAME MIGRATIONS",
            lambda: service.apply_operation(
                session_path,
                {"type": "paint_pixels", "frame": 1, "layer": "lower_body",
                 "pixels": [{"x": 1, "y": 1, "rgba": [1, 2, 3, 255]}]},
            ),
        )
        manifest["pending_migration"] = None
        write_json(manifest_path, manifest)

        # Final real semantic acceptance: mutate the real six-frame Vigil session,
        # render the diff, then restore the exact pre-edit Aseprite bytes.
        pre_acceptance = workbench_path.read_bytes()
        acceptance = service.apply_operation(
            session_path,
            {"type": "paint_pixels", "frame": 2, "layer": "lower_body",
             "pixels": [{"x": 0, "y": 0, "rgba": [225, 151, 17, 255]}]},
        )
        service.render(session_path)
        service.undo_last(session_path)
        assert workbench_path.read_bytes() == pre_acceptance
        assert Path(acceptance["backup"]).read_bytes() == pre_acceptance

        # The initial baseline remains recoverable and was never published.
        assert baseline_backup.read_bytes() == original_bytes

    after_production = {str(path): tree_hashes(path) for path in protected_roots}
    assert before_production == after_production, "production Operator assets changed"
    print(
        "PASS operator_art_agent_smoke: session, inspect/render, pixel operations, "
        "rollback guards, exact undo, and production immutability"
    )


if __name__ == "__main__":
    if "--aseprite-child" in sys.argv:
        aseprite_main()
    else:
        subprocess.run([sys.executable, str(Path(__file__).with_name("operator_art_agent_service_smoke.py"))], check=True)
        subprocess.run([sys.executable, str(Path(__file__).with_name("operator_art_agent_semantic_smoke.py"))], check=True)
        subprocess.run([sys.executable, str(Path(__file__).with_name("operator_art_agent_mcp_smoke.py"))], check=True)
        if workbench.resolve_aseprite() is None:
            print("SKIP real Aseprite integration: executable unavailable")
        else:
            aseprite_main()
        print("PASS operator_art_agent_smoke: V2 aggregate")
