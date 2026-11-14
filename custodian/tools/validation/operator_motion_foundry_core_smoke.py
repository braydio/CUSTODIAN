#!/usr/bin/env python3
"""Deterministic MF1 fixture and fail-closed input/output controls."""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "tools/operator/motion_foundry"
sys.path.insert(0, str(ROOT / "tools/operator"))
from motion_foundry.motion import interpolate  # noqa: E402


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def run(command: list[str], expect: int = 0) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(command, cwd=ROOT.parents[0], text=True, capture_output=True)
    if result.returncode != expect:
        raise AssertionError(f"command exit {result.returncode}, wanted {expect}: {result.stdout}\n{result.stderr}")
    return result


def main() -> int:
    if interpolate([{"frame": 0, "offset": [0, 0]}, {"frame": 2, "offset": [-1, 1]}], 1) != (-1, 1):
        raise AssertionError("signed half-away interpolation failed")
    if interpolate([{"frame": 0, "offset": [0, 0]}, {"frame": 2, "offset": [1, -1]}], 1) != (1, -1):
        raise AssertionError("positive half-away interpolation failed")
    protected = [ROOT / "content", ROOT / "asset_drop/source_work/operator/operator_2_5d_design_reference/operator_2_5d_design_lock_v1_source.png"]
    before = {str(p): _tree_hash(p) for p in protected}
    with tempfile.TemporaryDirectory(prefix="motion-foundry-smoke-") as temp:
        base = Path(temp)
        source = base / "source"
        source.mkdir()
        colors = {"torso": (18, 48, 88, 255), "arm_near": (220, 120, 30, 255), "foot_near": (50, 180, 70, 255)}
        boxes = {"torso": (57, 50, 71, 92), "arm_near": (48, 58, 60, 76), "foot_near": (56, 99, 66, 106)}
        parts = []
        for index, part_id in enumerate(colors):
            im = Image.new("RGBA", (128, 128))
            ImageDraw.Draw(im).rectangle(boxes[part_id], fill=colors[part_id])
            path = source / f"{part_id}.png"
            im.save(path, optimize=False, compress_level=9)
            parts.append({"id": part_id, "source": path.name, "sha256": digest(path),
                          "pivot": [61, 106] if part_id == "foot_near" else [64, 70],
                          "parent": None if part_id == "torso" else "torso",
                          "draw_order": (10, 20, 30)[index], "movable": part_id != "torso"})
        rig = {"schema": "custodian.motion_foundry.rig.v1", "rig_id": "operator_south_fixture", "owner": "operator",
               "art_generation": "operator_2_5d_128", "direction": "s", "frame_size": [128, 128],
               "root": [64, 106], "ground": [64, 107],
               "reference_profile_sha256": "05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761", "parts": parts}
        keys = [{"frame": 0, "offset": [0, 0]}, {"frame": 7, "offset": [0, -2]}, {"frame": 14, "offset": [0, 0]}]
        motion = {"schema": "custodian.motion_foundry.motion.v1", "motion_id": "neutral_idle_south_fixture",
                  "rig_id": rig["rig_id"], "profile": "unarmed", "group": "posture", "action": "idle_relaxed_01",
                  "direction": "s", "frame_count": 15, "fps": None, "loop": True,
                  "interpolation": "linear_integer_half_away_from_zero",
                  "tracks": [{"part": part_id, "keys": keys if part_id == "arm_near" else [{"frame": 0, "offset": [0, 0]}, {"frame": 14, "offset": [0, 0]}]}
                             for part_id in colors],
                  "contacts": [{"part": "foot_near", "frames": list(range(15)), "point": [61, 106]}]}
        rig_path, motion_path = base / "rig.json", base / "motion.json"
        write_json(rig_path, rig)
        write_json(motion_path, motion)
        outputs = [base / "one" / ".ai" / "operator_motion_foundry", base / "two" / ".ai" / "operator_motion_foundry"]
        plans, renders = [], []
        for output in outputs:
            args = [sys.executable, "-m", "motion_foundry.cli"]
            env = dict(os.environ, PYTHONPATH=str(ROOT / "tools/operator"))
            common = ["--rig", str(rig_path), "--motion", str(motion_path), "--source-root", str(source), "--output-root", str(output)]
            plans.append(subprocess.run(args + ["plan"] + common, cwd=ROOT.parent, env=env, text=True, capture_output=True, check=True).stdout)
            rendered = subprocess.run(args + ["render"] + common + ["--write"], cwd=ROOT.parent, env=env, text=True, capture_output=True)
            if rendered.returncode:
                raise AssertionError(f"render failed: {rendered.stdout}\n{rendered.stderr}")
            renders.append(subprocess.run(args + ["check"] + common, cwd=ROOT.parent, env=env, text=True, capture_output=True, check=True).stdout)
        a, b = [json.loads(value) for value in renders]
        if plans[0] != plans[1] or a["candidate_sha256"] != b["candidate_sha256"] or a["receipt_sha256"] != b["receipt_sha256"]:
            raise AssertionError("separate output roots are not byte-deterministic")
        run_record = json.loads((outputs[0] / "runs" / a["job_id"] / "report.json").read_text())
        if run_record["geometry"] != [1920, 128] or run_record["status"] != "candidate" or run_record["publication_authorized"]:
            raise AssertionError("fixture output contract mismatch")
        strip_path = next((outputs[0] / "runs" / a["job_id"] / "candidate").glob("*.png"))
        strip = Image.open(strip_path)
        if strip.mode != "RGBA" or strip.size != (1920, 128):
            raise AssertionError("fixture strip geometry/mode mismatch")

        def rejects(rig_value: dict, motion_value: dict, *, source_root: Path = source, render: bool = False) -> None:
            bad_rig_path, bad_motion_path = base / "probe-rig.json", base / "probe-motion.json"
            write_json(bad_rig_path, rig_value)
            write_json(bad_motion_path, motion_value)
            command = [sys.executable, "-m", "motion_foundry.cli", "render" if render else "plan"]
            if render:
                command += ["--write"]
            command += ["--rig", str(bad_rig_path), "--motion", str(bad_motion_path), "--source-root", str(source_root)]
            if render:
                command += ["--output-root", str(base / "failed" / ".ai" / "operator_motion_foundry")]
            failed = subprocess.run(command, cwd=ROOT.parent, env=dict(os.environ, PYTHONPATH=str(ROOT / "tools/operator")), capture_output=True)
            if failed.returncode == 0:
                raise AssertionError(f"negative control was accepted: {failed.stdout!r}")
            if render and (base / "failed" / ".ai").exists():
                raise AssertionError("failed candidate render wrote output")

        def copy_json(value: dict) -> dict:
            return json.loads(json.dumps(value))

        bad = copy_json(rig); bad["direction"] = "bad"; rejects(bad, motion)
        bad = copy_json(rig); bad["reference_profile_sha256"] = "0" * 64; rejects(bad, motion)
        bad = copy_json(rig); bad["parts"][1]["id"] = bad["parts"][0]["id"]; rejects(bad, motion)
        bad = copy_json(rig); bad["parts"][1]["draw_order"] = bad["parts"][0]["draw_order"]; rejects(bad, motion)
        bad = copy_json(rig); bad["parts"][1]["parent"] = "foot_near"; bad["parts"][2]["parent"] = "arm_near"; rejects(bad, motion)
        bad = copy_json(motion); bad["direction"] = "n"; rejects(rig, bad)
        bad = copy_json(motion); bad["tracks"][1]["keys"][1]["frame"] = 14; rejects(rig, bad)
        bad = copy_json(motion); bad["tracks"][0]["keys"][0]["offset"] = [1, 0]; rejects(rig, bad)
        bad = copy_json(motion); bad["tracks"][0]["part"] = "unknown"; rejects(rig, bad)
        bad = copy_json(motion); bad["tracks"][1]["keys"][0]["offset"] = [0, 0]
        bad["tracks"][1]["keys"][1]["offset"] = [0, 0]
        bad["contacts"][0]["point"] = [60, 106]; rejects(rig, bad, render=True)
        bad = copy_json(motion); bad["tracks"][1]["keys"] = [{"frame": 0, "offset": [-100, 0]}, {"frame": 14, "offset": [-100, 0]}]
        rejects(rig, bad, render=True)
        # A valid rig digest cannot make a wrong source canvas acceptable.
        wrong_canvas = base / "wrong-canvas"; shutil.copytree(source, wrong_canvas)
        wrong_image = Image.new("RGBA", (127, 128), (18, 48, 88, 255)); wrong_image.save(wrong_canvas / "torso.png")
        bad = copy_json(rig); bad["parts"][0]["sha256"] = digest(wrong_canvas / "torso.png")
        rejects(bad, motion, source_root=wrong_canvas)

        command = [sys.executable, "-m", "motion_foundry.cli", "render", "--write", "--rig", str(rig_path), "--motion", str(motion_path),
                   "--source-root", str(source), "--output-root", str(outputs[0])]
        strip_path.write_bytes(b"tampered candidate")
        if subprocess.run(command, cwd=ROOT.parent, env=dict(os.environ, PYTHONPATH=str(ROOT / "tools/operator")), capture_output=True).returncode == 0:
            raise AssertionError("tampered repeated output was overwritten")
        # Wrong source hash and symlink escape are rejected before any candidate writes.
        bad_rig = dict(rig)
        bad_rig["parts"] = [dict(part) for part in rig["parts"]]
        bad_rig["parts"][0]["sha256"] = "0" * 64
        bad_path = base / "bad-rig.json"
        write_json(bad_path, bad_rig)
        probe = [sys.executable, "-m", "motion_foundry.cli", "plan", "--rig", str(bad_path), "--motion", str(motion_path), "--source-root", str(source)]
        if subprocess.run(probe, cwd=ROOT.parent, env=dict(os.environ, PYTHONPATH=str(ROOT / "tools/operator")), capture_output=True).returncode == 0:
            raise AssertionError("wrong source SHA accepted")
        outside = base / "outside.png"
        shutil.copy2(source / "torso.png", outside)
        (source / "escape.png").symlink_to(outside)
        symlink_rig = dict(rig)
        symlink_rig["parts"] = [dict(part) for part in rig["parts"]]
        symlink_rig["parts"][0].update(source="escape.png", sha256=digest(outside))
        write_json(bad_path, symlink_rig)
        if subprocess.run(probe, cwd=ROOT.parent, env=dict(os.environ, PYTHONPATH=str(ROOT / "tools/operator")), capture_output=True).returncode == 0:
            raise AssertionError("symlink escape accepted")
    after = {str(p): _tree_hash(p) for p in protected}
    if before != after:
        raise AssertionError("protected canonical art/reference changed")
    print("PASS operator_motion_foundry_core_smoke")
    print("PASS separate-root determinism, 15x128 RGBA fixture, signed interpolation, hash/symlink rejection, protected paths unchanged")
    return 0


def _tree_hash(path: Path) -> str:
    if path.is_file():
        return digest(path)
    h = hashlib.sha256()
    for child in sorted(path.rglob("*")):
        if child.is_file():
            h.update(child.relative_to(path).as_posix().encode())
            h.update(bytes.fromhex(digest(child)))
    return h.hexdigest()


if __name__ == "__main__":
    raise SystemExit(main())
