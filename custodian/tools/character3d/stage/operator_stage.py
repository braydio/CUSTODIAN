"""Stage the validated cleaned frames into the CUSTODIAN ignored preview folder for the Godot preview.

Output (git-ignored): custodian/.ai/operator_3d_animation_preview/
  frames80/<action>/<dir>/NNNN.png   viewport cells (160x160 or 192x192), placed with
                                      destination = source + target_pivot - source_pivot
  frames50/<action>/<dir>/NNNN.png   Running and Walking at 50 px/m (128x128, pivot 64,106)
  meta/<action>.json, meta/<scale>.json, MANIFEST.json

Inputs: reports/PREVIEW_FRAME_MANIFEST.json (validated cleaned frames), REVIEW_VIEWPORT_REPORT.json,
measure_*_objectfix metadata (loop flag), and the batch INPUT_MANIFEST (source hashes).
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

DIRS = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
COUNTS = {"running": 15, "walking": 25, "alert": 96, "casual_walk": 100, "dead": 71, "run_03": 19, "runfast": 11,
          "skill_01": 26, "skill_03": 39, "triple_combo_attack": 104, "unsteady_walk": 71}
FPS = 24


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def loop_of(probe: Path, action: str) -> bool:
    f = sorted((probe / "reports").glob(f"measure_{action}_objectfix_c*_80.json"))[0]
    return bool(json.loads(f.read_text())["loop"])


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--probe", required=True, type=Path, help="operator_running_scale_probe_v1 workspace")
    ap.add_argument("--batch", required=True, type=Path, help="operator_sprite_batch_v1 workspace (source hashes)")
    ap.add_argument("--repo", required=True, type=Path, help="repository root that receives custodian/.ai output")
    args = ap.parse_args(argv)
    PROBE, BATCH = args.probe, args.batch
    STAGE = args.repo / "custodian/.ai/operator_3d_animation_preview"
    man = json.loads((PROBE / "reports/PREVIEW_FRAME_MANIFEST.json").read_text())
    rep = json.loads((PROBE / "reports/REVIEW_VIEWPORT_REPORT.json").read_text())["actions"]
    inputs = json.loads((BATCH / "reports/INPUT_MANIFEST.json").read_text())["inputs"]
    by_key = {(f["action"], f["direction"], f["frame"]): f for f in man["frames"]}
    assert len(by_key) == sum(COUNTS.values()) * 8, "manifest is not complete"
    frame_count = 0
    meta_out = {}
    for action, n in COUNTS.items():
        v = rep[action]
        canvas = v["source_canvas"]
        spx, spy = v["source_pivot"]
        tx, ty = v["target_pivot"]
        vw, vh = v["viewport"]
        dx, dy = tx - spx, ty - spy
        cell_hashes = {}
        for d in DIRS:
            out_dir = STAGE / "frames80" / action / d
            out_dir.mkdir(parents=True, exist_ok=True)
            for k in range(n):
                rec = by_key[(action, d, k)]
                src = Image.open(rec["clean_path"]).convert("RGBA")
                cell = Image.new("RGBA", (vw, vh), (0, 0, 0, 0))
                cell.paste(src, (dx, dy))
                back = cell.crop((dx, dy, dx + canvas, dy + canvas))
                if back.tobytes() != src.tobytes():
                    raise SystemExit(f"{action} {d}/{k}: staging changed pixels")
                arr = np.array(cell)
                if (arr[arr[:, :, 3] == 0][:, :3] != 0).any():
                    raise SystemExit(f"{action} {d}/{k}: staged transparent RGB nonzero")
                path = out_dir / f"{k:04d}.png"
                cell.save(path)
                cell_hashes[f"{d}/{k:04d}"] = sha(path)
                frame_count += 1
        src_key = action if action in inputs else None
        meta_out[action] = {
            "schema": "custodian.operator_3d_preview_action.v1", "action": action, "scale_px_per_m": 80,
            "frame_size": [vw, vh], "viewport_class": v["viewport_class"], "pivot": [tx, ty],
            "directions": DIRS, "frame_count": n, "fps_authored_sampling": FPS, "loop": loop_of(PROBE, action),
            "source_sha256": inputs[src_key]["sha256"] if src_key else None,
            "source_canvas": canvas, "flags": v["flags"], "approval_state": "candidate_unapproved",
            "frames_dir": f"frames80/{action}", "cell_sha256": cell_hashes,
        }
        (STAGE / "meta").mkdir(parents=True, exist_ok=True)
        (STAGE / "meta" / f"{action}.json").write_text(json.dumps(meta_out[action], indent=1) + "\n")
        print(f"staged {action:20} {vw}x{vh} pivot ({tx},{ty}) loop={meta_out[action]['loop']} frames {n*8}")

    # 50 px/m comparison set: Running and Walking at native 128x128, pivot (64,106), no placement shift.
    for action in ("running", "walking"):
        n = COUNTS[action]
        cell_hashes = {}
        for d in DIRS:
            out_dir = STAGE / "frames50" / action / d
            out_dir.mkdir(parents=True, exist_ok=True)
            for k in range(n):
                src_path = PROBE / f"output/clean_objectfix/c128_50/{action}/{d}/frame_{k:02d}.png"
                if not src_path.is_file():
                    raise SystemExit(f"missing 50 px/m clean frame {src_path}")
                src = Image.open(src_path).convert("RGBA")
                if src.size != (128, 128):
                    raise SystemExit(f"50 px/m frame {src_path} is {src.size}")
                path = out_dir / f"{k:04d}.png"
                src.save(path)
                cell_hashes[f"{d}/{k:04d}"] = sha(path)
                frame_count += 1
        m = {"schema": "custodian.operator_3d_preview_action.v1", "action": action, "scale_px_per_m": 50,
             "frame_size": [128, 128], "viewport_class": "native_128", "pivot": [64, 106], "directions": DIRS,
             "frame_count": n, "fps_authored_sampling": FPS, "loop": loop_of(PROBE, action),
             "source_sha256": inputs[action]["sha256"], "flags": [], "approval_state": "candidate_unapproved",
             "frames_dir": f"frames50/{action}", "cell_sha256": cell_hashes}
        (STAGE / "meta" / f"{action}_50ppm.json").write_text(json.dumps(m, indent=1) + "\n")
        print(f"staged {action} 50 px/m 128x128 frames {n*8}")

    manifest = {"schema": "custodian.operator_3d_preview_manifest.v1", "staged_frames": frame_count,
                "expected_80ppm": sum(COUNTS.values()) * 8, "expected_50ppm": (COUNTS["running"] + COUNTS["walking"]) * 8,
                "source_manifest": str(PROBE / "reports/PREVIEW_FRAME_MANIFEST.json"),
                "actions": sorted(meta_out), "note": "ignored preview staging; not production assets"}
    (STAGE / "MANIFEST.json").write_text(json.dumps(manifest, indent=1) + "\n")
    print("STAGED", frame_count, "frames ->", STAGE)


if __name__ == "__main__":
    main()
