#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from PIL import Image, ImageDraw


REPO_ROOT = Path(__file__).resolve().parents[3]
OPERATOR_TOOLS = REPO_ROOT / "custodian/tools/operator"
sys.path.insert(0, str(OPERATOR_TOOLS))

import modular_alignment_repair as repair
import operator_asset_reconciliation as reconciliation


def sheet(path: Path, frames: int = 2, size: int = 96, *, x_offset: int = 0, seam: bool = True) -> None:
    image = Image.new("RGBA", (frames * size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for frame in range(frames):
        left = frame * size + 42 + x_offset
        if "lower_body" in path.name:
            draw.rectangle((left, 48, left + 11, 79), fill=(80, 160, 220, 255))
        else:
            bottom = 48 if seam else 35
            draw.rectangle((left, 18, left + 11, bottom - 1), fill=(220, 150, 80, 255))
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


class AlignmentRepairSmoke(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="operator-alignment-repair-smoke-")
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        self.module = self.root / "runtime/animations"
        self.workspace = self.root / ".ai"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def runtime(self, layer: str = "upper_body", action: str = "run_01", size: int = 96, profile: str = "unarmed", group: str = "locomotion") -> Path:
        path = self.module / profile / group / action / f"operator__{layer}__{profile}__{group}__{action}__e__2f__{size}.png"
        sheet(path, size=size)
        return path

    def source_path(self, layer: str = "upper_body", action: str = "run_01", size: int = 96) -> Path:
        directory = self.source / "unarmed" / "locomotion" / action
        path = directory / f"operator__{layer}__unarmed__locomotion__{action}__e__2f__{size}.png"
        sheet(path, size=size)
        return path

    def reconciler(self, build_one=None) -> reconciliation.SourceReconciler:
        return reconciliation.SourceReconciler(
            repo_root=self.root, source_root=self.source, module_root=self.module,
            archive_root=self.root / "archive", workspace=self.workspace, build_one=build_one,
        )

    def suspicion(self, runtime: Path, layer: str = "upper", action: str = "run_01", direction: str = "e") -> dict:
        return {
            "runtime_path": str(runtime), "layer": layer, "action": action, "direction": direction,
            "confidence": "high", "flagged_frames": [0, 1], "implicated_pairs": ["pair-a"],
            "median_signed_vertical_gap": 4, "median_signed_connector_x_delta": 6,
        }

    def report(self, suspicions: list) -> dict:
        return {
            "runtime_sheets": 0, "lower_sheets": 0, "upper_sheets": 0,
            "pairings": 0, "pair_frames": 0, "flagged_pairings": 0,
            "missing": [], "pairs": [], "findings": [], "suspicions": suspicions,
        }

    def test_existing_roundtrip_match(self) -> None:
        runtime = self.runtime()
        source = self.source_path()
        record = self.reconciler().reconcile(runtime)
        self.assertEqual(record.resolution, "existing_roundtrip_match")
        self.assertEqual((self.root / record.editable_path).resolve(), source.resolve())
        self.assertFalse(record.quarantined_paths)

    def test_missing_source_promotes_runtime_and_roundtrips(self) -> None:
        runtime = self.runtime()
        record = self.reconciler().reconcile(runtime)
        self.assertEqual(record.resolution, "promoted_from_runtime")
        editable = self.root / record.editable_path
        self.assertTrue(editable.exists())
        self.assertEqual(reconciliation.pixel_sha256(editable), reconciliation.pixel_sha256(runtime))

    def test_stale_source_is_backed_up_and_quarantined(self) -> None:
        runtime = self.runtime()
        stale = self.source_path()
        sheet(stale, x_offset=7)
        record = self.reconciler().reconcile(runtime)
        self.assertEqual(record.resolution, "promoted_from_runtime")
        self.assertTrue(record.backup_paths)
        self.assertTrue(record.quarantined_paths)
        self.assertEqual(reconciliation.pixel_sha256(self.root / record.editable_path), reconciliation.pixel_sha256(runtime))

    def test_runtime_96_wins_over_128_source_and_archive(self) -> None:
        runtime = self.runtime()
        old = self.source_path(size=128)
        archive = self.root / "archive" / runtime.name
        sheet(archive, x_offset=9)
        record = self.reconciler().reconcile(runtime)
        editable = self.root / record.editable_path
        with Image.open(editable) as image:
            self.assertEqual(image.size, (192, 96))
        self.assertEqual(record.resolution, "promoted_from_runtime")
        self.assertIsNotNone(record.archive_candidate)
        self.assertNotEqual(reconciliation.pixel_sha256(archive), reconciliation.pixel_sha256(runtime))

    def test_materialization_failure_restores_stale_source(self) -> None:
        runtime = self.runtime()
        stale = self.source_path()
        sheet(stale, x_offset=8)

        def corrupt(_source, output, identity):
            sheet(output, frames=identity.frames, size=identity.frame_width, x_offset=20)

        with self.assertRaises(reconciliation.MaterializationError):
            self.reconciler(corrupt).reconcile(runtime)
        self.assertTrue(stale.exists())

    def test_connector_metric_ignores_extended_arm_bbox(self) -> None:
        lower = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        upper = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        ImageDraw.Draw(lower).rectangle((43, 48, 53, 80), fill="white")
        draw = ImageDraw.Draw(upper)
        draw.rectangle((43, 20, 53, 47), fill="white")
        draw.rectangle((5, 25, 42, 27), fill="white")
        metrics = repair.connector_debug(lower, upper)
        self.assertLess(abs(metrics["connector_center_delta_px"]), 1)
        self.assertGreater(metrics["connector_overlap_px"], 0)

    def test_connector_ignores_narrow_appendage_below_waist(self) -> None:
        lower = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        upper = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        draw = ImageDraw.Draw(lower)
        draw.rectangle((43, 48, 53, 80), fill="white")
        draw.rectangle((30, 55, 33, 70), fill="white")
        ImageDraw.Draw(upper).rectangle((43, 20, 53, 47), fill="white")
        metrics = repair.connector_debug(lower, upper)
        self.assertEqual(metrics["connector_lower_span"], [43, 53])
        self.assertEqual(metrics["connector_vertical_gap_px"], 0)

    def test_connector_reports_true_seam_gap(self) -> None:
        lower = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        upper = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
        ImageDraw.Draw(lower).rectangle((43, 48, 53, 80), fill="white")
        ImageDraw.Draw(upper).rectangle((43, 20, 53, 40), fill="white")
        metrics = repair.connector_debug(lower, upper)
        self.assertGreaterEqual(metrics["connector_vertical_gap_px"], 3)

    def test_queue_deduplicates_editable_source_deterministically(self) -> None:
        runtime = self.runtime()
        source = self.source_path()
        identity = "upper_body|unarmed|run_01|e"
        record = reconciliation.EditableSourceRecord(
            identity, str(runtime), str(source), [str(source)], str(source),
            "existing_roundtrip_match", "same", "same", "same", None, "matched", [], [],
        )
        suspicion = {
            "runtime_path": str(runtime), "layer": "upper", "action": "run_01", "direction": "e",
            "confidence": "high", "flagged_frames": [0, 1], "implicated_pairs": ["a", "b"],
            "median_signed_vertical_gap": 4, "median_signed_connector_x_delta": 6,
        }
        queue = repair.build_queue({"suspicions": [suspicion, suspicion]}, {repair.runtime_record_key(runtime): record})
        self.assertEqual(len(queue), 1)
        self.assertEqual(queue[0].implicated_pairs, ["a", "b"])
        self.assertEqual(Path(queue[0].source_path).resolve(), source.resolve())
        self.assertTrue(queue[0].roundtrip_pass)

    def test_v2_queue_uses_runtime_path_provenance_key(self) -> None:
        runtime = self.runtime()
        source = self.source_path()
        record = reconciliation.EditableSourceRecord(
            "upper_body|unarmed|run_01|e", str(runtime), str(source), [str(source)], str(source),
            "promoted_from_runtime", "same", "same", "same", None, "runtime promoted source", [], [],
        )
        suspicion = self.suspicion(runtime)
        by_semantic = {"upper_body|unarmed|run_01|e": record}
        by_path = {repair.runtime_record_key(runtime): record}
        semantic_queue = repair.build_queue({"suspicions": [suspicion]}, by_semantic)
        path_queue = repair.build_queue({"suspicions": [suspicion]}, by_path)
        self.assertEqual(Path(semantic_queue[0].source_path).resolve(), runtime.resolve())
        self.assertEqual(Path(path_queue[0].source_path).resolve(), source.resolve())
        self.assertEqual(path_queue[0].resolution, "promoted_from_runtime")
        self.assertTrue(path_queue[0].roundtrip_pass)

    def test_v2_pairing_never_crosses_animation_profile(self) -> None:
        lower_unarmed = self.runtime("lower_body", "run_01")
        upper_unarmed = self.runtime("upper_body", "run_01")
        lower_melee = self.runtime("lower_body", "run_01", profile="melee_1h")
        upper_melee = self.runtime("upper_body", "run_01", profile="melee_1h")
        jobs, missing = repair.find_exact_v2_pair_jobs(
            [repair._sheet(lower_unarmed), repair._sheet(lower_melee)],
            [repair._sheet(upper_unarmed), repair._sheet(upper_melee)],
        )
        self.assertEqual(missing, [])
        self.assertEqual(len(jobs), 2)
        for job in jobs:
            self.assertEqual(
                repair.v2_pair_key(job.lower.source_path),
                repair.v2_pair_key(job.upper.source_path),
            )

    def test_v2_pairing_never_crosses_action_group(self) -> None:
        lower_locomotion = self.runtime("lower_body", "run_01")
        upper_attack = self.runtime("upper_body", "run_01", group="attack")
        jobs, missing = repair.find_exact_v2_pair_jobs(
            [repair._sheet(lower_locomotion)], [repair._sheet(upper_attack)]
        )
        self.assertEqual(jobs, [])
        self.assertEqual(len(missing), 2)
        lower_run = self.runtime("lower_body", "run_01")
        upper_walk = self.runtime("upper_body", "walk_01")
        jobs_same_group, missing_same_group = repair.find_exact_v2_pair_jobs(
            [repair._sheet(lower_run)], [repair._sheet(upper_walk)]
        )
        self.assertEqual(jobs_same_group, [])
        self.assertEqual(len(missing_same_group), 2)

    def test_dimension_validation_stops_resized_sheet(self) -> None:
        path = self.source_path()
        sheet(path, size=64)
        with self.assertRaises(ValueError):
            reconciliation.validate_sheet_contract(path, 2, 96, 96)

    def test_resume_invalidates_externally_changed_pass(self) -> None:
        source = self.source_path()
        entry = repair.QueueEntry(
            "id", str(source), [], "upper", "e", "run_01", "high", [], [], 0, 0,
        )
        old_hash = reconciliation.file_sha256(source)
        repair.save_json(self.workspace / "state.json", {"entries": [{"id": "id", "status": "fixed", "source_hash": old_hash}]})
        sheet(source, x_offset=2)
        repair.merge_prior_state([entry], self.workspace)
        self.assertEqual(entry.status, "pending")

    def test_suspicion_consensus_distinguishes_bad_upper_and_ambiguity(self) -> None:
        lower_a = str(self.runtime("lower_body", "run_01"))
        lower_b = str(self.runtime("lower_body", "walk_01"))
        upper = str(self.runtime("upper_body", "run_01"))
        good_upper = str(self.runtime("upper_body", "walk_01"))
        findings = [
            repair.FrameFinding(f"pair-{index}", 0, lower, upper, 0, 8, 3, 1, 0, 0, True)
            for index, lower in enumerate((lower_a, lower_b))
        ]
        findings.extend(
            repair.FrameFinding(f"good-{index}", 0, lower, good_upper, 0, 0, 10, 1, 0, 0, False)
            for index, lower in enumerate((lower_a, lower_b))
        )
        suspects = {item.runtime_path: item for item in repair.score_suspicions(findings)}
        self.assertEqual(suspects[upper].confidence, "high")
        lone = repair.score_suspicions([findings[0]])
        self.assertTrue(all(item.confidence == "ambiguous" for item in lone))

    def test_unchanged_editor_close_can_skip_without_building(self) -> None:
        source = self.source_path()
        runtime = self.runtime()
        entry = repair.QueueEntry(
            "id", str(source), [str(runtime)], "upper", "e", "run_01", "high",
            [0], ["pair"], 4, 6, roundtrip_pass=True,
            source_frame_count=2, source_frame_width=96, source_frame_height=96,
        )
        args = SimpleNamespace(
            aseprite=Path("/bin/true"), workspace=self.workspace, repo_root=self.root,
            runtime_root=self.module, selector="all", gap_threshold=3, center_threshold=5,
            no_backup=True,
        )
        builds = []
        repair.interactive_loop(
            args, {"runtime_sheets": 0, "pairings": 0, "pair_frames": 0, "flagged_pairings": 0, "pairs": []},
            [entry], self.reconciler(), editor_runner=lambda _a, _s: None,
            builder_runner=lambda root: builds.append(root), input_fn=lambda _prompt: "s",
        )
        self.assertEqual(entry.status, "skipped")
        self.assertFalse(builds)

    def test_changed_save_rebuilds_and_advances_on_pass(self) -> None:
        source = self.source_path()
        runtime = self.runtime()
        entry = repair.QueueEntry(
            "id", str(source), [str(runtime)], "upper", "e", "run_01", "high",
            [0], ["pair"], 4, 6, roundtrip_pass=True,
            source_frame_count=2, source_frame_width=96, source_frame_height=96,
        )
        args = SimpleNamespace(
            aseprite=Path("/bin/true"), workspace=self.workspace, repo_root=self.root,
            runtime_root=self.module, selector="all", gap_threshold=3, center_threshold=5,
            no_backup=True,
        )
        builds = []
        original_analyze = repair.analyze
        try:
            repair.analyze = lambda *_args, **_kwargs: {
                "runtime_sheets": 0, "pairings": 0, "pair_frames": 0,
                "flagged_pairings": 0, "pairs": [], "suspicions": [], "findings": [], "missing": [],
            }
            def edit(_aseprite, path):
                sheet(path, x_offset=1)
            repair.interactive_loop(
                args, repair.analyze(), [entry], self.reconciler(), editor_runner=edit,
                builder_runner=lambda root: builds.append(root), input_fn=lambda _prompt: "r",
            )
        finally:
            repair.analyze = original_analyze
        self.assertEqual(entry.status, "fixed")
        self.assertEqual(builds, [self.root])

    def test_live_queue_adds_new_suspect_after_refresh(self) -> None:
        runtime_a = self.runtime()
        source_a = self.source_path()
        runtime_b = self.runtime("lower_body", "walk_01")
        source_b = self.source_path("lower_body", "walk_01")
        prior = repair.QueueEntry(
            "upper_body|unarmed|run_01|e", str(source_a), [str(runtime_a)], "upper", "e", "run_01",
            "high", [0], ["pair-a"], 4, 6, status="fixed",
            source_frame_count=2, source_frame_width=96, source_frame_height=96,
        )
        args = SimpleNamespace(
            runtime_root=self.module, selector="all", gap_threshold=3,
            center_threshold=5, repo_root=self.root,
        )
        report = self.report([
            self.suspicion(runtime_a),
            self.suspicion(runtime_b, layer="lower", action="walk_01"),
        ])
        original_analyze = repair.analyze
        try:
            repair.analyze = lambda *_args, **_kwargs: report
            _fresh_report, refreshed = repair.refresh_live_queue(args, self.reconciler(), [prior])
        finally:
            repair.analyze = original_analyze
        self.assertEqual(len(refreshed), 2)
        new_entry = next(item for item in refreshed if item.id != prior.id)
        self.assertEqual(Path(new_entry.source_path).resolve(), source_b.resolve())
        self.assertEqual(new_entry.status, "pending")

    def test_live_queue_marks_disappeared_partner_resolved(self) -> None:
        source = self.source_path()
        runtime = self.runtime()
        prior = repair.QueueEntry(
            "upper_body|unarmed|run_01|e", str(source), [str(runtime)], "upper", "e", "run_01",
            "high", [0], ["pair-a"], 4, 6, status="unresolved",
            source_frame_count=2, source_frame_width=96, source_frame_height=96,
        )
        args = SimpleNamespace(
            runtime_root=self.module, selector="all", gap_threshold=3,
            center_threshold=5, repo_root=self.root,
        )
        original_analyze = repair.analyze
        try:
            repair.analyze = lambda *_args, **_kwargs: self.report([])
            _fresh_report, refreshed = repair.refresh_live_queue(args, self.reconciler(), [prior])
        finally:
            repair.analyze = original_analyze
        self.assertEqual(len(refreshed), 1)
        self.assertEqual(refreshed[0].status, "resolved_by_partner")

    def test_run_builder_uses_strict_mode(self) -> None:
        calls = []
        original_run = repair.subprocess.run
        try:
            repair.subprocess.run = lambda *args, **_kwargs: calls.append(args) or SimpleNamespace()
            repair.run_builder(self.root)
        finally:
            repair.subprocess.run = original_run
        self.assertEqual(len(calls), 1)
        command = calls[0][0]
        self.assertEqual(command[0], sys.executable)
        self.assertIn("--strict", command)
        self.assertIn("--remove-superseded", command)


if __name__ == "__main__":
    unittest.main(verbosity=2)
