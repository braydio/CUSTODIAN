"""Tests for the candidate-only Operator 3D intake, the bounded stager, and the Workbench 3D projection.

Dependency-free (unittest). Run from the repository root:
  python3 -I custodian/tools/validation/test_operator_3d_candidate_intake.py -v

Fixtures are synthetic 160x160 RGBA stages built from the real operator.v1.json contract. Negative
cases mutate a per-test copy in a temporary directory; the checkout and the live staged frames are
never written.
"""
import contextlib
import copy
import hashlib
import io
import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[3]
OPERATOR = REPO / "custodian/tools/operator"
CHARACTER3D = REPO / "custodian/tools/character3d"
CONTRACT = CHARACTER3D / "contracts/operator.v1.json"
sys.path.insert(0, str(OPERATOR))
sys.path.insert(0, str(CHARACTER3D / "stage"))

import operator_3d_candidate_intake as intake  # noqa: E402
import operator_stage  # noqa: E402
import animation_workbench  # noqa: E402
from ui.service import WorkbenchService  # noqa: E402
from ui.state import AnimationSelection  # noqa: E402

DIRS = list(intake.RENDER_DIRECTIONS)
ACTIONS = ("walking", "running")
EXPECTED_PIVOT = {"walking": [50, 107], "running": [62, 108]}
EXPECTED_SESSION = {"walking": ("unarmed", "locomotion", "walk_01"), "running": ("unarmed", "locomotion", "run_01")}
STAGE_RELATIVE = intake.STAGE_RELATIVE
WORKBENCH_RELATIVE = intake.WORKBENCH_RELATIVE
TEMPLATE = None


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _frame(action_index: int, direction_index: int, frame: int) -> Image.Image:
    """Distinct RGBA content per action, direction and frame; visible area stays inside the clearance."""
    image = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    ImageDraw.Draw(image).rectangle(
        (40 + direction_index, 20, 120, 140),
        fill=(10 * direction_index + frame % 200, 60 + action_index * 40, 90 + frame % 100, 255),
    )
    return image


def _write_stage(repo: Path, contract: dict) -> Path:
    stage = repo / STAGE_RELATIVE
    (stage / "meta").mkdir(parents=True, exist_ok=True)
    for action_index, action in enumerate(ACTIONS):
        spec = contract["actions"][action]
        count = spec["frame_count"]
        cells = {}
        for direction_index, direction in enumerate(DIRS):
            folder = stage / "frames80" / action / direction
            folder.mkdir(parents=True, exist_ok=True)
            for frame in range(count):
                path = folder / f"{frame:04d}.png"
                _frame(action_index, direction_index, frame).save(path)
                cells[f"{direction}/{frame:04d}"] = _sha(path)
        meta = {
            "schema": intake.PREVIEW_ACTION_SCHEMA, "action": action, "scale_px_per_m": 80,
            "frame_size": [160, 160], "viewport_class": "Standard", "pivot": spec["root_px"],
            "directions": DIRS, "frame_count": count, "fps_authored_sampling": 24, "loop": spec["loop"],
            "source_sha256": contract["source"]["motions"][action]["sha256"], "source_canvas": spec["source_canvas"],
            "flags": [], "approval_state": "candidate_unapproved", "frames_dir": f"frames80/{action}",
            "cell_sha256": cells,
        }
        (stage / "meta" / f"{action}.json").write_text(json.dumps(meta, indent=1) + "\n")
    manifest = {"schema": intake.PREVIEW_MANIFEST_SCHEMA, "staged_frames": 320, "actions": list(ACTIONS),
                "note": "fixture"}
    (stage / "MANIFEST.json").write_text(json.dumps(manifest, indent=1) + "\n")
    return stage


def setUpModule():
    global TEMPLATE
    contract = json.loads(CONTRACT.read_text())
    root = Path(tempfile.mkdtemp(prefix="op3d-template-"))
    repo = root / "repo"
    (repo / WORKBENCH_RELATIVE).mkdir(parents=True)
    _write_stage(repo, contract)
    (repo / "custodian/tools/character3d/contracts").mkdir(parents=True)
    shutil.copy(CONTRACT, repo / "custodian/tools/character3d/contracts/operator.v1.json")
    TEMPLATE = root


def tearDownModule():
    if TEMPLATE is not None:
        shutil.rmtree(TEMPLATE, ignore_errors=True)


class Fixture(unittest.TestCase):
    """A fresh copy of the synthetic repository per test."""

    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix="op3d-case-"))
        self.repo = self.root / "repo"
        shutil.copytree(TEMPLATE / "repo", self.repo)
        self.stage = self.repo / STAGE_RELATIVE
        self.workbench = self.repo / WORKBENCH_RELATIVE

    def tearDown(self):
        shutil.rmtree(self.root, ignore_errors=True)

    def run_intake(self, operation, actions=ACTIONS):
        return getattr(intake, operation)(CONTRACT, self.stage, self.workbench, list(actions))

    def candidate_path(self, action, direction):
        profile, group, name = EXPECTED_SESSION[action]
        return self.workbench / "operator_3d_80" / profile / group / name / direction.lower() / "candidate.json"

    def meta_path(self, action):
        return self.stage / "meta" / f"{action}.json"

    def load_meta(self, action):
        return json.loads(self.meta_path(action).read_text())

    def save_meta(self, action, meta):
        self.meta_path(action).write_text(json.dumps(meta, indent=1) + "\n")

    def rewrite_frame(self, action, direction, frame, image):
        """Replace one staged frame and keep the stage receipt hash consistent, so only that check fails."""
        path = self.stage / "frames80" / action / direction / f"{frame:04d}.png"
        image.save(path)
        meta = self.load_meta(action)
        meta["cell_sha256"][f"{direction}/{frame:04d}"] = _sha(path)
        self.save_meta(action, meta)


class CandidateIntakeTests(Fixture):
    def test_walking_registers_eight_directional_sessions(self):
        report = self.run_intake("apply", ["walking"])
        self.assertEqual(report["directional_sessions"], 8)
        self.assertEqual(report["imported_animations"], 1)
        for direction in DIRS:
            self.assertTrue(self.candidate_path("walking", direction).is_file(), direction)

    def test_running_registers_eight_directional_sessions(self):
        report = self.run_intake("apply", ["running"])
        self.assertEqual(report["directional_sessions"], 8)
        for direction in DIRS:
            self.assertTrue(self.candidate_path("running", direction).is_file(), direction)

    def test_both_actions_validate_320_frames_and_16_sessions(self):
        report = self.run_intake("apply")
        self.assertEqual(report["directional_sessions"], 16)
        self.assertEqual(report["validated_frames"], 320)

    def test_frame_counts_dimensions_and_pivots_match_source(self):
        self.run_intake("apply")
        for action in ACTIONS:
            count = self.load_meta(action)["frame_count"]
            for direction in DIRS:
                data = json.loads(self.candidate_path(action, direction).read_text())
                self.assertEqual(data["frames"]["count"], count, (action, direction))
                self.assertEqual((data["frames"]["width"], data["frames"]["height"]), (160, 160))
                self.assertEqual(data["frames"]["pivot"], EXPECTED_PIVOT[action])
                self.assertEqual(len(data["frames"]["items"]), count)

    def test_direction_conversion_is_explicit_and_lowercase(self):
        self.run_intake("apply")
        self.assertEqual(intake.WORKBENCH_DIRECTIONS["SW"], "sw")
        self.assertEqual(intake.WORKBENCH_DIRECTIONS["NE"], "ne")
        for direction in DIRS:
            self.assertTrue(self.candidate_path("walking", intake.WORKBENCH_DIRECTIONS[direction]).is_file())

    def test_sessions_reference_only_their_own_render_direction(self):
        self.run_intake("apply")
        for direction in DIRS:
            data = json.loads(self.candidate_path("walking", direction).read_text())
            self.assertEqual(data["source"]["render_direction"], direction)
            for item in data["frames"]["items"]:
                self.assertEqual(item["render_direction"], direction)
                self.assertTrue(item["path"].startswith(f"frames80/walking/{direction}/"), item["path"])

    def test_candidate_manifest_records_provenance_and_stays_unpublished(self):
        self.run_intake("apply")
        data = json.loads(self.candidate_path("running", "N").read_text())
        contract = json.loads(CONTRACT.read_text())
        self.assertEqual(data["schema"], intake.CANDIDATE_SCHEMA)
        self.assertEqual(data["generation"], "operator_3d_80")
        self.assertEqual(data["identity"], {"profile": "unarmed", "group": "locomotion", "action": "run_01",
                                            "direction": "n", "layer": "full_body"})
        self.assertEqual(data["source"]["master_sha256"], intake.EXPECTED_MASTER_SHA256)
        self.assertEqual(data["source"]["motion_sha256"], contract["source"]["motions"]["running"]["sha256"])
        self.assertEqual(data["source"]["contract_sha256"], _sha(CONTRACT))
        self.assertIs(data["timing_authority"], False)
        self.assertIs(data["runtime_published"], False)
        self.assertEqual(data["approval_state"], "candidate_unapproved")
        self.assertEqual(data["provisional_preview_fps"], 24)

    def test_frame_hashes_match_the_staged_pixels(self):
        self.run_intake("apply")
        data = json.loads(self.candidate_path("walking", "E").read_text())
        for item in data["frames"]["items"]:
            self.assertEqual(_sha(self.stage / item["path"]), item["sha256"])

    def test_repeated_identical_apply_is_a_no_op(self):
        self.run_intake("apply")
        before = {path: (path.read_bytes(), path.stat().st_mtime_ns) for path in self.workbench.rglob("candidate.json")}
        report = self.run_intake("apply")
        self.assertEqual(report["written"], 0)
        self.assertEqual({row["status"] for row in report["sessions"]}, {"UNCHANGED"})
        after = {path: (path.read_bytes(), path.stat().st_mtime_ns) for path in self.workbench.rglob("candidate.json")}
        self.assertEqual(before, after)

    def test_verify_passes_after_apply_and_fails_when_a_session_is_removed(self):
        self.run_intake("apply")
        self.assertTrue(self.run_intake("verify")["ok"])
        self.candidate_path("walking", "S").unlink()
        report = self.run_intake("verify")
        self.assertFalse(report["ok"])
        self.assertIn("MISSING", {row["status"] for row in report["sessions"]})

    def test_changed_source_motion_hash_fails_closed(self):
        meta = self.load_meta("walking")
        meta["source_sha256"] = "0" * 64
        self.save_meta("walking", meta)
        with self.assertRaisesRegex(intake.IntakeError, "source motion SHA-256"):
            self.run_intake("plan")
        self.assertFalse(self.workbench.joinpath("operator_3d_80").exists())

    def test_changed_frame_bytes_fail_closed(self):
        path = self.stage / "frames80/running/SE/0003.png"
        Image.new("RGBA", (160, 160), (255, 0, 0, 255)).save(path)
        with self.assertRaisesRegex(intake.IntakeError, "SHA-256 does not match"):
            self.run_intake("apply")
        self.assertFalse(self.workbench.joinpath("operator_3d_80").exists())

    def test_missing_frame_fails(self):
        (self.stage / "frames80/walking/S/0007.png").unlink()
        with self.assertRaisesRegex(intake.IntakeError, "missing or unexpected|missing"):
            self.run_intake("plan")

    def test_extra_frame_fails(self):
        shutil.copy(self.stage / "frames80/walking/S/0000.png", self.stage / "frames80/walking/S/0099.png")
        with self.assertRaisesRegex(intake.IntakeError, "missing, duplicated or extra"):
            self.run_intake("plan")

    def test_noncontiguous_frame_index_fails(self):
        folder = self.stage / "frames80/walking/S"
        (folder / "0004.png").rename(folder / "0040.png")
        with self.assertRaisesRegex(intake.IntakeError, "missing, duplicated or extra"):
            self.run_intake("plan")

    def test_incomplete_receipt_index_fails(self):
        meta = self.load_meta("walking")
        del meta["cell_sha256"]["NE/0002"]
        self.save_meta("walking", meta)
        with self.assertRaisesRegex(intake.IntakeError, "frame index set is wrong"):
            self.run_intake("plan")

    def test_wrong_dimensions_fail(self):
        self.rewrite_frame("walking", "W", 1, Image.new("RGBA", (128, 128), (1, 2, 3, 255)))
        with self.assertRaisesRegex(intake.IntakeError, "expected RGBA"):
            self.run_intake("plan")

    def test_non_rgba_frame_fails(self):
        self.rewrite_frame("walking", "W", 1, Image.new("RGB", (160, 160), (1, 2, 3)))
        with self.assertRaisesRegex(intake.IntakeError, "expected RGBA"):
            self.run_intake("plan")

    def test_alpha_outside_clearance_fails(self):
        image = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
        ImageDraw.Draw(image).rectangle((0, 20, 60, 140), fill=(9, 9, 9, 255))
        self.rewrite_frame("running", "NW", 2, image)
        with self.assertRaisesRegex(intake.IntakeError, "clearance"):
            self.run_intake("plan")

    def test_symlinked_direction_folder_fails(self):
        outside = self.root / "outside"
        shutil.copytree(self.stage / "frames80/walking/S", outside)
        folder = self.stage / "frames80/walking/S"
        shutil.rmtree(folder)
        os.symlink(outside, folder, target_is_directory=True)
        with self.assertRaisesRegex(intake.IntakeError, "symbolic link"):
            self.run_intake("plan")

    def test_symlinked_frame_file_fails(self):
        outside = self.root / "frame.png"
        shutil.copy(self.stage / "frames80/walking/S/0000.png", outside)
        target = self.stage / "frames80/walking/S/0000.png"
        target.unlink()
        os.symlink(outside, target)
        with self.assertRaisesRegex(intake.IntakeError, "symbolic link"):
            self.run_intake("plan")

    def test_unmapped_action_is_rejected_without_guessing(self):
        with self.assertRaisesRegex(intake.IntakeError, "no explicit semantic mapping"):
            self.run_intake("plan", ["alert"])

    def test_duplicate_requested_actions_are_rejected(self):
        with self.assertRaisesRegex(intake.IntakeError, "duplicate"):
            self.run_intake("plan", ["walking", "walking"])

    def test_failed_import_leaves_existing_sessions_unchanged(self):
        self.run_intake("apply", ["walking"])
        before = {path: path.read_bytes() for path in self.workbench.rglob("candidate.json")}
        self.rewrite_frame("running", "E", 0, Image.new("RGBA", (160, 160), (5, 5, 5, 255)))
        meta = self.load_meta("running")
        meta["cell_sha256"]["E/0000"] = "f" * 64
        self.save_meta("running", meta)
        with self.assertRaises(intake.IntakeError):
            self.run_intake("apply")
        after = {path: path.read_bytes() for path in self.workbench.rglob("candidate.json")}
        self.assertEqual(before, after)
        self.assertFalse(self.candidate_path("running", "N").exists())
        self.assertEqual([p for p in self.workbench.iterdir() if p.name.startswith(".operator_3d_candidate_tmp")], [])

    def test_failure_during_promotion_rolls_back_every_new_session(self):
        real_replace = os.replace
        calls = {"count": 0}

        def failing_replace(source, target):
            calls["count"] += 1
            if calls["count"] == 5:
                raise OSError("simulated disk failure")
            return real_replace(source, target)

        with mock.patch.object(intake.os, "replace", side_effect=failing_replace):
            with self.assertRaisesRegex(intake.IntakeError, "rolled back"):
                self.run_intake("apply")
        self.assertEqual(list(self.workbench.rglob("candidate.json")), [])
        self.assertFalse(self.workbench.joinpath("operator_3d_80").exists())
        self.assertEqual([p for p in self.workbench.iterdir() if p.name.startswith(".operator_3d_candidate_tmp")], [])

    def test_existing_session_with_different_content_is_preserved(self):
        self.run_intake("apply", ["walking"])
        path = self.candidate_path("walking", "S")
        path.write_text('{"schema": "other"}\n')
        with self.assertRaisesRegex(intake.IntakeError, "refusing replacement"):
            self.run_intake("apply", ["walking"])
        self.assertEqual(path.read_text(), '{"schema": "other"}\n')

    def test_plan_is_read_only(self):
        self.run_intake("plan")
        self.assertFalse(self.workbench.joinpath("operator_3d_80").exists())

    def test_cli_plan_and_apply_return_exit_codes(self):
        argv = ["--contract", str(CONTRACT), "--stage-root", str(self.stage),
                "--workbench-root", str(self.workbench), "--actions", "walking", "running"]
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(intake.main(["--plan", *argv]), 0)
            self.assertEqual(intake.main(["--apply", *argv]), 0)
            self.assertEqual(intake.main(["--verify", *argv]), 0)
            self.candidate_path("running", "NE").unlink()
            self.assertEqual(intake.main(["--verify", *argv]), 1)


class BoundedStagerTests(unittest.TestCase):
    """operator_stage.py --actions / --skip-50ppm against a tiny synthetic probe and batch."""

    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix="op3d-stage-"))
        self.probe = self.root / "probe"
        self.batch = self.root / "batch"
        self.repo = self.root / "repo"
        self.counts = {"walking": 2, "running": 2}
        self._build_inputs()
        self.patch = mock.patch.object(operator_stage, "COUNTS", self.counts)
        self.patch.start()

    def tearDown(self):
        self.patch.stop()
        shutil.rmtree(self.root, ignore_errors=True)

    def _build_inputs(self):
        (self.probe / "reports").mkdir(parents=True)
        (self.batch / "reports").mkdir(parents=True)
        rows, actions, inputs = [], {}, {}
        for index, action in enumerate(ACTIONS):
            actions[action] = {"source_canvas": 256, "source_pivot": [128, 128], "target_pivot": EXPECTED_PIVOT[action],
                               "viewport": [160, 160], "viewport_class": "Standard", "flags": []}
            (self.probe / f"reports/measure_{action}_objectfix_c256_80.json").write_text(json.dumps({"loop": True}))
            inputs[action] = {"sha256": hashlib.sha256(action.encode()).hexdigest()}
            for direction in DIRS:
                for frame in range(self.counts[action]):
                    clean = self.probe / f"clean/{action}/{direction}/{frame}.png"
                    clean.parent.mkdir(parents=True, exist_ok=True)
                    image = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
                    ImageDraw.Draw(image).rectangle((120, 120, 140, 140), fill=(index * 90, 40 + frame, 200, 255))
                    image.save(clean)
                    rows.append({"action": action, "direction": direction, "frame": frame, "clean_path": str(clean)})
                    small = self.probe / f"output/clean_objectfix/c128_50/{action}/{direction}/frame_{frame:02d}.png"
                    small.parent.mkdir(parents=True, exist_ok=True)
                    Image.new("RGBA", (128, 128), (0, 0, 0, 0)).save(small)
        (self.probe / "reports/PREVIEW_FRAME_MANIFEST.json").write_text(json.dumps({"frames": rows}))
        (self.probe / "reports/REVIEW_VIEWPORT_REPORT.json").write_text(json.dumps({"actions": actions}))
        (self.batch / "reports/INPUT_MANIFEST.json").write_text(json.dumps({"inputs": inputs}))

    def stage(self, *extra):
        return operator_stage.main(["--probe", str(self.probe), "--batch", str(self.batch),
                                    "--repo", str(self.repo), *extra])

    def stage_root(self):
        return self.repo / STAGE_RELATIVE

    def test_unknown_action_fails_before_any_output(self):
        with self.assertRaises(SystemExit):
            self.stage("--actions", "walking", "dance")
        self.assertFalse(self.stage_root().exists())

    def test_duplicate_action_fails_before_any_output(self):
        with self.assertRaises(SystemExit):
            self.stage("--actions", "walking", "walking")
        self.assertFalse(self.stage_root().exists())

    def test_bounded_run_stages_only_selected_actions_and_preserves_others(self):
        self.stage("--actions", "walking", "--skip-50ppm")
        walking_meta = (self.stage_root() / "meta/walking.json").read_bytes()
        self.assertFalse((self.stage_root() / "meta/running.json").exists())
        self.stage("--actions", "running", "--skip-50ppm")
        self.assertEqual((self.stage_root() / "meta/walking.json").read_bytes(), walking_meta)
        manifest = json.loads((self.stage_root() / "MANIFEST.json").read_text())
        self.assertEqual(manifest["actions"], ["running", "walking"])
        self.assertEqual(manifest["staged_frames"], 2 * 8 * 2)

    def test_receipt_lists_actions_frames_and_output_hashes(self):
        self.stage("--actions", "walking", "--skip-50ppm")
        receipt = json.loads((self.stage_root() / "receipts/walking.json").read_text())
        self.assertEqual(receipt["schema"], operator_stage.RECEIPT_SCHEMA)
        self.assertEqual(receipt["actions"], ["walking"])
        self.assertEqual(receipt["expected_frames"], 2 * 8)
        self.assertEqual(receipt["staged_frames"], 2 * 8)
        self.assertEqual(receipt["outputs"]["meta/walking.json"], _sha(self.stage_root() / "meta/walking.json"))

    def test_skip_50ppm_controls_the_comparison_set(self):
        self.stage("--actions", "walking", "--skip-50ppm")
        self.assertFalse((self.stage_root() / "meta/walking_50ppm.json").exists())
        self.stage("--actions", "walking")
        self.assertTrue((self.stage_root() / "meta/walking_50ppm.json").is_file())

    def test_staged_pixels_match_the_clean_frame_placement_rule(self):
        self.stage("--actions", "walking", "--skip-50ppm")
        staged = Image.open(self.stage_root() / "frames80/walking/S/0000.png")
        self.assertEqual(staged.size, (160, 160))
        # Clean content at (120..140) on a 256 canvas moves by target_pivot - source_pivot = (-78, -21).
        self.assertEqual(staged.getbbox(), (120 - 78, 120 - 21, 141 - 78, 141 - 21))


class WorkbenchProjectionTests(Fixture):
    """Service-level projection, preview, and publication guards for operator_3d_80."""

    class FakeModel:
        class WorkbenchError(RuntimeError):
            pass

        @staticmethod
        def source_index(*_args, **_kwargs):
            return {}

    def service(self):
        return WorkbenchService(
            repo_root=self.repo, source_root=self.repo / "missing", weapon_root=self.repo / "missing",
            catalog_path=self.repo / "missing.json", workspace_root=self.workbench,
            model_api=self.FakeModel, workbench_api=animation_workbench,
        )

    def selection(self, action="walking", direction="s"):
        profile, group, name = EXPECTED_SESSION[action]
        return AnimationSelection(profile, group, name, direction, art_generation="operator_3d_80")

    def test_browser_shows_all_sixteen_directional_records(self):
        self.run_intake("apply")
        records = [r for r in self.service().discover_browser_records() if r.selection.art_generation == "operator_3d_80"]
        self.assertEqual(len(records), 16)
        self.assertEqual({r.coverage_status for r in records}, {"CANDIDATE_READY"})
        self.assertEqual({r.workflow_status for r in records}, {"IMPORTED_UNAPPROVED"})
        self.assertFalse(any(r.canonical_complete for r in records))
        self.assertIn("unapproved · not published", records[0].summary)

    def test_unregistered_directions_are_shown_as_missing_not_omitted(self):
        self.run_intake("apply", ["walking"])
        records = [r for r in self.service().discover_browser_records() if r.selection.art_generation == "operator_3d_80"]
        self.assertEqual(len(records), 16)
        missing = [r for r in records if r.coverage_status == "MISSING"]
        self.assertEqual(len(missing), 8)
        self.assertTrue(all(r.selection.action == "run_01" for r in missing))
        self.assertIn("MISSING", missing[0].summary)

    def test_session_is_read_only_and_names_no_aseprite_document(self):
        self.run_intake("apply")
        session = self.service().session(self.selection())
        self.assertEqual(session.workbench_state, "3D CANDIDATE / READ ONLY")
        self.assertEqual(session.contract_state, "CANDIDATE_UNAPPROVED")
        self.assertEqual(session.aseprite_path, "3D source / no Aseprite document")
        self.assertEqual(session.document_canvas, (160, 160))
        self.assertEqual(session.source_frames, 25)
        self.assertEqual(len(session.layers), 1)
        self.assertFalse(session.layers[0].publishing)

    def test_preview_loads_actual_staged_pixels_not_legacy_art(self):
        self.run_intake("apply")
        preview = self.service().preview(self.selection("running", "ne"), "candidate")
        self.assertEqual(preview.source, "candidate")
        self.assertEqual(preview.frame_size, (160, 160))
        self.assertEqual(len(preview.frames), 15)
        for index, frame in enumerate(preview.frames):
            self.assertEqual(frame.mode, "RGBA")
            staged = Image.open(self.stage / "frames80/running/NE" / f"{index:04d}.png")
            self.assertEqual(frame.tobytes(), staged.convert("RGBA").tobytes())
        self.assertTrue(all(path.startswith(str(self.stage)) for path in preview.paths))

    def test_preview_refuses_any_source_but_candidate_and_missing_sessions(self):
        self.run_intake("apply", ["walking"])
        with self.assertRaisesRegex(ValueError, "single source"):
            self.service().preview(self.selection(), "runtime")
        with self.assertRaisesRegex(ValueError, "no registered 3D candidate"):
            self.service().preview(self.selection("running", "n"), "candidate")

    def test_preview_fails_closed_when_a_staged_frame_changes(self):
        self.run_intake("apply")
        Image.new("RGBA", (160, 160), (7, 7, 7, 255)).save(self.stage / "frames80/walking/S/0001.png")
        with self.assertRaisesRegex(intake.IntakeError, "changed since registration"):
            self.service().preview(self.selection("walking", "s"), "candidate")

    def test_publication_is_disabled_for_candidates(self):
        self.run_intake("apply")
        view = self.service().publish_preview(self.selection())
        self.assertFalse(view.publish_enabled)
        self.assertIn("candidate-only", view.publish_block_reason)
        with self.assertRaisesRegex(Exception, "candidate-only"):
            self.service().publish(self.selection())

    def test_editing_and_migration_are_rejected_for_candidates(self):
        self.run_intake("apply")
        service = self.service()
        selection = self.selection()
        for call in (
            lambda: service.edit(selection),
            lambda: service.frame_preview(selection, "add", 1),
            lambda: service.frame_apply(selection, "add", 1),
            lambda: service.canvas_preview(selection, 128, 128),
            lambda: service.canvas_apply(selection, 128, 128),
            lambda: service.adopt_fx_layer(selection, "vfx"),
            lambda: service.copy_spritesheet(selection),
        ):
            with self.assertRaisesRegex(ValueError, "read-only"):
                call()

    def test_low_level_workbench_publish_rejects_candidate_sessions(self):
        self.run_intake("apply")
        manifest = self.candidate_path("walking", "S").parent / "workbench.json"
        with self.assertRaisesRegex(Exception, "candidate-only"):
            animation_workbench.publish(manifest)

    def test_validation_is_read_only_and_reports_frame_integrity(self):
        self.run_intake("apply")
        before = {path: path.read_bytes() for path in self.workbench.rglob("candidate.json")}
        lines = self.service().validate(self.selection(), False)
        self.assertTrue(any("validated 320 staged frames" in line for line in lines))
        self.assertEqual(before, {path: path.read_bytes() for path in self.workbench.rglob("candidate.json")})

    def test_legacy_and_2_5d_projection_shapes_are_unchanged(self):
        self.run_intake("apply")
        records = self.service().discover_browser_records()
        generations = {r.selection.art_generation for r in records}
        self.assertTrue(generations <= {"legacy_96", "operator_3d_80"}, generations)
        from operator_animation_targets import GENERATIONS
        self.assertEqual(GENERATIONS, {"legacy_96", "operator_2_5d_128"})


if __name__ == "__main__":
    unittest.main()
