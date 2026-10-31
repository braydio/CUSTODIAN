#!/usr/bin/env python3
"""Synthetic safety and pinned-source replay for the Grunt raster workflow."""
from __future__ import annotations

import copy
import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[3]
PIPELINE_DIR = REPO / "custodian/tools/iteration/raster_pipeline"
sys.path.insert(0, str(PIPELINE_DIR))
import raster_pipeline as raster  # noqa: E402

PLAN_PATH = REPO / "custodian/tools/iteration/grunt_candidate_ab/grunt_raster_plan.json"
SOURCE = REPO / "custodian/asset_drop/source_work/enemies/grunt_cutout_candidate_v1/raider_humanoid_cutout_turnaround_parts_v1_source.png"
BASELINE_DIR = REPO / "custodian/tools/iteration/grunt_candidate_ab/generated"


def _assert_blocked(callback, label: str) -> None:
    try:
        callback()
    except (raster.RasterError, OSError, ValueError, KeyError, json.JSONDecodeError):
        return
    raise AssertionError(f"negative control unexpectedly passed: {label}")


def _synthetic(root: Path, base_plan: dict) -> dict:
    source = root / "synthetic.png"
    image = Image.new("RGBA", (80, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for x0 in (2, 21, 40, 59):
        for y in range(4, 44):
            for x in range(x0, x0 + 12):
                draw.point((x, y), (min(255, 40 + x * 2), min(255, 55 + y * 4), (x * 9 + y * 3) % 240, 255))
        draw.point((x0 + 5, 5), (255, 255, 255, 255))
    image.save(source)
    plan = copy.deepcopy(base_plan)
    plan["source"] = {"path": source.relative_to(REPO).as_posix(), "sha256": hashlib.sha256(source.read_bytes()).hexdigest()}
    plan["views"] = {
        code: {"label": label, "roi": [x, 0, 14, 48]}
        for code, label, x in (("s", "front fixture", 0), ("n", "back fixture", 19), ("e", "right fixture", 38), ("w", "left fixture", 57))
    }
    return plan


def main() -> int:
    ai = REPO / ".ai"
    ai.mkdir(exist_ok=True)
    pinned_before = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    baseline_hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in BASELINE_DIR.glob("candidate_*.png")}
    baseline_hashes["preview_manifest.json"] = hashlib.sha256((BASELINE_DIR / "preview_manifest.json").read_bytes()).hexdigest()
    plan = json.loads(PLAN_PATH.read_text())
    review_root = ai / "grunt-candidate-raster-workflow-v1"
    review_root.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="grunt-raster-smoke-", dir=review_root) as temp:
        temp_root = Path(temp)
        synthetic_plan = _synthetic(temp_root, plan)
        synthetic_plan_path = temp_root / "synthetic_plan.json"
        synthetic_plan_path.write_text(json.dumps(synthetic_plan))
        synthetic_out = temp_root / "synthetic_out"
        one = raster.build(synthetic_plan_path, synthetic_out)
        first_report = (synthetic_out / "raster_report.json").read_bytes()
        two = raster.build(synthetic_plan_path, synthetic_out)
        assert (synthetic_out / "raster_report.json").read_bytes() == first_report
        assert one["plan_sha256"] == two["plan_sha256"]
        assert (synthetic_out / "contact_sheet_72px.png").is_file()
        assert len(list(synthetic_out.glob("*/*.png"))) == 36
        for direction in ("s", "n", "e", "w"):
            for height in ("64", "72", "80"):
                variants = one["outputs"][direction]["candidates"][height]
                assert set(variants) == {"crisp", "balanced", "clustered"}
                assert all(row["contact_error_px"] == 0 for row in variants.values())
                assert all(row["qa"]["alpha_bounds"] is not None for row in variants.values())
                assert all(row["qa"]["size"] == [96, 96] for row in variants.values())
                assert all(row["foot_registration"]["contact_pixels_in_cell"] for row in variants.values())
                assert all(row["foot_registration"]["actor_ground_residual_px"] == 0.5 for row in variants.values())
                assert all(row["foot_registration"]["ground_severity"] == "within_declared_tolerance" for row in variants.values())
                assert all("coordinates_in_cell" in row["silhouette_drift"] for row in variants.values())
        method_images = [Image.open(synthetic_out / mode / "candidate_s_72px.png").convert("RGBA").tobytes() for mode in ("crisp", "balanced", "clustered")]
        assert len(set(method_images)) == 3, "converter modes must remain genuinely distinct"

        # Exact-coordinate cleanup approval only writes a copy and audit.
        candidate = synthetic_out / "crisp" / "candidate_s_72px.png"
        original = candidate.read_bytes()
        image = Image.open(candidate).convert("RGBA")
        x, y = image.getchannel("A").getbbox()[0:2]
        before = list(image.getpixel((x, y)))
        after = [before[0], before[1], before[2], 0]
        approval = {
            "schema": "custodian.raster_cleanup_approval.v1", "reviewed_by": "synthetic-smoke",
            "candidate_path": candidate.relative_to(REPO).as_posix(),
            "candidate_sha256": hashlib.sha256(original).hexdigest(),
            "edits": [{"x": x, "y": y, "before": before, "after": after}],
        }
        approval_path = temp_root / "cleanup_approval.json"
        approval_path.write_text(json.dumps(approval))
        audit = raster.apply_cleanup(approval_path, synthetic_out)
        assert audit["changed_pixels"] == 1 and candidate.read_bytes() == original
        cleaned = REPO / audit["cleaned_path"]
        assert cleaned.is_file() and hashlib.sha256(original).hexdigest() == audit["reversible_source_sha256"]

        wrong_hash = copy.deepcopy(approval)
        wrong_hash["candidate_sha256"] = "0" * 64
        approval_path.write_text(json.dumps(wrong_hash))
        _assert_blocked(lambda: raster.apply_cleanup(approval_path, synthetic_out), "stale cleanup hash")

        # Malformed bounds, altered source identity, and empty source all fail closed.
        bad_roi = copy.deepcopy(synthetic_plan)
        bad_roi["views"]["e"]["roi"] = [79, 0, 10, 10]
        _assert_blocked(lambda: raster.validate_plan(bad_roi, temp_root / "synthetic.png", synthetic_out), "out-of-range ROI")
        bad_hash = copy.deepcopy(synthetic_plan)
        bad_hash["source"]["sha256"] = "0" * 64
        _assert_blocked(lambda: raster.validate_plan(bad_hash, temp_root / "synthetic.png", synthetic_out), "source hash mismatch")
        bad_size = copy.deepcopy(synthetic_plan)
        bad_size["target"]["body_heights"] = [96]
        _assert_blocked(lambda: raster.validate_plan(bad_size, temp_root / "synthetic.png", synthetic_out), "invalid body height")
        blank_path = temp_root / "blank.png"
        Image.new("RGBA", (80, 48), (0, 0, 0, 0)).save(blank_path)
        blank_plan = copy.deepcopy(synthetic_plan)
        blank_plan["source"]["path"] = blank_path.relative_to(REPO).as_posix()
        blank_plan["source"]["sha256"] = hashlib.sha256(blank_path.read_bytes()).hexdigest()
        blank_plan_path = temp_root / "blank_plan.json"
        blank_plan_path.write_text(json.dumps(blank_plan))
        _assert_blocked(lambda: raster.build(blank_plan_path, temp_root / "blank_out"), "empty alpha image")
        _assert_blocked(lambda: raster.validate_plan(synthetic_plan, temp_root / "synthetic.png", temp_root / "synthetic.png"), "source/output collision")
        _assert_blocked(lambda: raster.build(PLAN_PATH, REPO / "custodian/content/sprites/raster-negative"), "output traversal into runtime sprites")
        symlink_out = temp_root / "symlink_out"
        symlink_out.mkdir()
        (symlink_out / "crisp").symlink_to(SOURCE.parent, target_is_directory=True)
        source_before_symlink_case = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
        _assert_blocked(lambda: raster.build(PLAN_PATH, symlink_out), "symlink redirection outside review workspace")
        assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == source_before_symlink_case

        # Full-size real source replay twice, entirely in ignored scratch.
        real_out = temp_root / "real_out"
        real_first = raster.build(PLAN_PATH, real_out)
        real_report = (real_out / "raster_report.json").read_bytes()
        real_second = raster.build(PLAN_PATH, real_out)
        assert (real_out / "raster_report.json").read_bytes() == real_report
        assert real_first["source"]["sha256"] == pinned_before == real_second["source"]["sha256"]
        assert (real_out / "contact_sheet_72px.png").is_file()
        assert len(list(real_out.glob("*/*.png"))) == 36

        # Exact-byte fallback is used only for an absent/unhydrated LFS source.
        lfs_pointer = temp_root / "unhydrated_source.png"
        lfs_pointer.write_text("version https://git-lfs.github.com/spec/v1\noid sha256:" + pinned_before + "\nsize " + str(SOURCE.stat().st_size) + "\n")
        fallback_plan = copy.deepcopy(plan)
        fallback_plan["source"]["path"] = lfs_pointer.relative_to(REPO).as_posix()
        fallback_plan["source"]["fallback"] = {
            "zip": "custodian_grunt_runtime_ab_v1_1.zip",
            "member": SOURCE.relative_to(REPO).as_posix(),
        }
        fallback_plan_path = temp_root / "fallback_plan.json"
        fallback_plan_path.write_text(json.dumps(fallback_plan))
        fallback_out = temp_root / "fallback_out"
        fallback_result = raster.build(fallback_plan_path, fallback_out)
        assert fallback_result["source"]["sha256"] == pinned_before
        fallback_copy = fallback_out / "verified_source_fallback" / SOURCE.name
        assert hashlib.sha256(fallback_copy.read_bytes()).hexdigest() == pinned_before
        bad_fallback_plan = copy.deepcopy(fallback_plan)
        bad_fallback_plan["source"]["sha256"] = "0" * 64
        bad_fallback_path = temp_root / "bad_fallback_plan.json"
        bad_fallback_path.write_text(json.dumps(bad_fallback_plan))
        bad_fallback_out = temp_root / "bad_fallback_out"
        _assert_blocked(lambda: raster.build(bad_fallback_path, bad_fallback_out), "fallback source hash mismatch")
        assert not (bad_fallback_out / "verified_source_fallback").exists()

    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == pinned_before
    after_baseline_hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in BASELINE_DIR.glob("candidate_*.png")}
    after_baseline_hashes["preview_manifest.json"] = hashlib.sha256((BASELINE_DIR / "preview_manifest.json").read_bytes()).hexdigest()
    assert after_baseline_hashes == baseline_hashes
    print("[PASS] synthetic and hydrated-source raster plans, determinism, cleanup gating, and safety controls")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
