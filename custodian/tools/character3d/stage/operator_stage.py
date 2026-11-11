"""Stage the validated cleaned frames into the CUSTODIAN ignored preview folder for the Godot preview.

Output (git-ignored): custodian/.ai/operator_3d_animation_preview/
  frames80/<action>/<dir>/NNNN.png   viewport cells (160x160 or 192x192), placed with
                                      destination = source + target_pivot - source_pivot
  frames50/<action>/<dir>/NNNN.png   Running and Walking at 50 px/m (128x128, pivot 64,106)
  meta/<action>.json, meta/<scale>.json, MANIFEST.json
  receipts/<actions>.json            per-invocation receipt: selected actions, frame counts, output hashes

Inputs: reports/PREVIEW_FRAME_MANIFEST.json (validated cleaned frames), REVIEW_VIEWPORT_REPORT.json,
measure_*_objectfix metadata (loop flag), and the batch INPUT_MANIFEST (source hashes).

Bounded staging: --actions restricts output to the named actions; every other staged action is left
untouched. All requested actions and their source frames are validated before any output is written.
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
PPM50_ACTIONS = ("running", "walking")
RECEIPT_SCHEMA = "custodian.operator_3d_stage_receipt.v1"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def loop_of(probe: Path, action: str) -> bool:
    f = sorted((probe / "reports").glob(f"measure_{action}_objectfix_c*_80.json"))[0]
    return bool(json.loads(f.read_text())["loop"])


def select_actions(requested: list[str] | None) -> tuple[str, ...]:
    """Return the actions to stage, failing before any output is touched on a bad request."""
    if not requested:
        return tuple(COUNTS)
    unknown = sorted(set(requested) - set(COUNTS))
    if unknown:
        raise SystemExit(f"unknown --actions {unknown}; known: {sorted(COUNTS)}")
    if len(set(requested)) != len(requested):
        raise SystemExit(f"duplicate --actions entries: {requested}")
    return tuple(requested)


def ppm50_source(probe: Path, action: str, direction: str, index: int) -> Path:
    return probe / f"output/clean_objectfix/c128_50/{action}/{direction}/frame_{index:02d}.png"


def validate_sources(probe: Path, man: dict, rep: dict, inputs: dict, actions: tuple[str, ...], skip_50: bool) -> dict:
    """Check every selected action's source frames exist and are complete. Writes nothing."""
    by_key = {(f["action"], f["direction"], f["frame"]): f for f in man["frames"]}
    if len(by_key) != len(man["frames"]):
        raise SystemExit("source PREVIEW_FRAME_MANIFEST.json contains duplicate action/direction/frame rows")
    for action in actions:
        if action not in rep:
            raise SystemExit(f"REVIEW_VIEWPORT_REPORT.json has no entry for selected action {action}")
        if action not in inputs:
            raise SystemExit(f"INPUT_MANIFEST.json has no source hash for selected action {action}")
    missing = [(a, d, k) for a in actions for d in DIRS for k in range(COUNTS[a]) if (a, d, k) not in by_key]
    if missing:
        raise SystemExit(f"source manifest lacks {len(missing)} selected frames; first {missing[0]}")
    for a in actions:
        for d in DIRS:
            for k in range(COUNTS[a]):
                if not Path(by_key[(a, d, k)]["clean_path"]).is_file():
                    raise SystemExit(f"missing clean frame for {a} {d}/{k}: {by_key[(a, d, k)]['clean_path']}")
    if not skip_50:
        for a in actions:
            if a not in PPM50_ACTIONS:
                continue
            for d in DIRS:
                for k in range(COUNTS[a]):
                    path = ppm50_source(probe, a, d, k)
                    if not path.is_file():
                        raise SystemExit(f"missing 50 px/m clean frame {path}")
    return by_key


def write_manifest(stage: Path, probe: Path) -> dict:
    """Recompute the stage manifest from the metadata on disk, so bounded runs never drop other actions."""
    metas80, metas50 = {}, {}
    for path in sorted((stage / "meta").glob("*.json")):
        if path.name == "MANIFEST.json":
            continue
        data = json.loads(path.read_text())
        (metas50 if data.get("scale_px_per_m") == 50 else metas80)[data["action"]] = data
    manifest = {
        "schema": "custodian.operator_3d_preview_manifest.v1",
        "staged_frames": sum(len(m["cell_sha256"]) for m in (*metas80.values(), *metas50.values())),
        "expected_80ppm": sum(COUNTS.values()) * 8,
        "expected_50ppm": (COUNTS["running"] + COUNTS["walking"]) * 8,
        "source_manifest": str(probe / "reports/PREVIEW_FRAME_MANIFEST.json"),
        "actions": sorted(metas80),
        "note": "ignored preview staging; not production assets",
    }
    (stage / "MANIFEST.json").write_text(json.dumps(manifest, indent=1) + "\n")
    return manifest


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--probe", required=True, type=Path, help="operator_running_scale_probe_v1 workspace")
    ap.add_argument("--batch", required=True, type=Path, help="operator_sprite_batch_v1 workspace (source hashes)")
    ap.add_argument("--repo", required=True, type=Path, help="repository root that receives custodian/.ai output")
    ap.add_argument("--actions", nargs="+", metavar="ACTION", help="stage only these actions (default: all known)")
    ap.add_argument("--skip-50ppm", action="store_true", help="do not stage the 50 px/m comparison set")
    args = ap.parse_args(argv)
    PROBE, BATCH = args.probe, args.batch
    STAGE = args.repo / "custodian/.ai/operator_3d_animation_preview"
    actions = select_actions(args.actions)
    man = json.loads((PROBE / "reports/PREVIEW_FRAME_MANIFEST.json").read_text())
    rep = json.loads((PROBE / "reports/REVIEW_VIEWPORT_REPORT.json").read_text())["actions"]
    inputs = json.loads((BATCH / "reports/INPUT_MANIFEST.json").read_text())["inputs"]
    by_key = validate_sources(PROBE, man, rep, inputs, actions, args.skip_50ppm)
    frame_count = 0
    meta_out = {}
    outputs = {}
    for action in actions:
        n = COUNTS[action]
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
        meta_path = STAGE / "meta" / f"{action}.json"
        meta_path.write_text(json.dumps(meta_out[action], indent=1) + "\n")
        outputs[f"meta/{action}.json"] = sha(meta_path)
        print(f"staged {action:20} {vw}x{vh} pivot ({tx},{ty}) loop={meta_out[action]['loop']} frames {n*8}")

    # 50 px/m comparison set: Running and Walking at native 128x128, pivot (64,106), no placement shift.
    if not args.skip_50ppm:
        for action in (a for a in actions if a in PPM50_ACTIONS):
            n = COUNTS[action]
            cell_hashes = {}
            for d in DIRS:
                out_dir = STAGE / "frames50" / action / d
                out_dir.mkdir(parents=True, exist_ok=True)
                for k in range(n):
                    src_path = ppm50_source(PROBE, action, d, k)
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
            meta_path = STAGE / "meta" / f"{action}_50ppm.json"
            meta_path.write_text(json.dumps(m, indent=1) + "\n")
            outputs[f"meta/{action}_50ppm.json"] = sha(meta_path)
            print(f"staged {action} 50 px/m 128x128 frames {n*8}")

    manifest = write_manifest(STAGE, PROBE)
    outputs["MANIFEST.json"] = sha(STAGE / "MANIFEST.json")
    expected = sum(COUNTS[a] * 8 for a in actions)
    if not args.skip_50ppm:
        expected += sum(COUNTS[a] * 8 for a in actions if a in PPM50_ACTIONS)
    receipt = {
        "schema": RECEIPT_SCHEMA, "actions": list(actions), "skip_50ppm": args.skip_50ppm,
        "expected_frames": expected, "staged_frames": frame_count,
        "sources": {
            "PREVIEW_FRAME_MANIFEST.json": sha(PROBE / "reports/PREVIEW_FRAME_MANIFEST.json"),
            "REVIEW_VIEWPORT_REPORT.json": sha(PROBE / "reports/REVIEW_VIEWPORT_REPORT.json"),
            "INPUT_MANIFEST.json": sha(BATCH / "reports/INPUT_MANIFEST.json"),
        },
        "source_sha256": {a: inputs[a]["sha256"] for a in actions if a in inputs},
        "outputs": outputs,
        "stage_manifest_actions": manifest["actions"],
    }
    receipt_dir = STAGE / "receipts"
    receipt_dir.mkdir(parents=True, exist_ok=True)
    (receipt_dir / ("+".join(sorted(actions)) + ".json")).write_text(json.dumps(receipt, indent=1, sort_keys=True) + "\n")
    print("STAGED", frame_count, "frames ->", STAGE)


if __name__ == "__main__":
    main()
