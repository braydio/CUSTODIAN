"""Stage cleaned Pursuit Frame 3D candidate frames for the debug playable preview.

Reads the cleaned 80 px/m renders from the Pursuit Frame proof workspace and writes
registered candidate viewports under custodian/.ai/pursuit_frame_3d_preview/ (gitignored).
Frames are pure crops and pads at native density: no resampling, no mirroring, no
per-frame recentering. One root pixel per viewport class is shared by every action,
direction and frame.

Hard checks per frame:
- no alpha is cropped away (alpha sum before and after placement must match);
- no visible pixel lies within CLEARANCE_PX of the viewport edge;
- transparent pixels carry zero RGB.

Usage:
  python3 -I custodian/tools/debug/pursuit_frame_3d_stage.py \
      --workspace ~/Projects/.operator-3d-animation-proof/pursuit_frame_3d_v1
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

PPM = 80
CLEARANCE_PX = 4
DIRECTIONS = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
ACTIONS = [
    "running", "walking", "alert", "agree_gesture", "casual_walk", "arise",
    "attack", "behit_flyup", "skill_01", "skill_03", "triple_combo_attack",
]
# Source canvas for each action: 256 px renders, or 512 px renders for the six edge-clipped actions.
SOURCE_CANVAS = {a: "c256_80" for a in ACTIONS}
for a in ["arise", "attack", "behit_flyup", "skill_01", "skill_03", "triple_combo_attack"]:
    SOURCE_CANVAS[a] = "c512_80"
# Smallest-first viewport classes. Root pixel is shared by every action in the class.
CLASSES = [
    {"id": "standard_256x256", "width": 256, "height": 256, "root": [128, 180]},
    {"id": "extended_256x320", "width": 256, "height": 320, "root": [128, 216]},
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def place(src: Image.Image, src_root, cls):
    """Crop or pad src so src_root lands on cls root. Pixel-exact, no resampling."""
    dx = src_root[0] - cls["root"][0]
    dy = src_root[1] - cls["root"][1]
    box = (dx, dy, dx + cls["width"], dy + cls["height"])
    out = src.crop(box)  # PIL pads outside the source with transparent black
    arr = np.array(out)
    arr[arr[:, :, 3] == 0, :3] = 0
    return Image.fromarray(arr, "RGBA")


def clearance_ok(img: Image.Image) -> bool:
    alpha = np.array(img)[:, :, 3]
    c = CLEARANCE_PX
    ring = np.concatenate([alpha[:c].ravel(), alpha[-c:].ravel(), alpha[:, :c].ravel(), alpha[:, -c:].ravel()])
    return not (ring > 0).any()


def choose_class(src_frames, src_root):
    """Smallest class where every frame of the action fits with clearance and no alpha is lost."""
    for cls in CLASSES:
        ok = True
        for img in src_frames:
            placed = place(img, src_root, cls)
            src_alpha = int(np.array(img)[:, :, 3].sum())
            if int(np.array(placed)[:, :, 3].sum()) != src_alpha or not clearance_ok(placed):
                ok = False
                break
        if ok:
            return cls
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--workspace", required=True)
    ap.add_argument("--out", default="custodian/.ai/pursuit_frame_3d_preview")
    args = ap.parse_args()
    ws = Path(args.workspace).expanduser()
    out = Path(args.out)
    frames_root = out / "frames"
    manifest = {
        "schema": "custodian.pursuit_frame_3d_preview.v1",
        "status": "candidate_preview_not_production",
        "pixels_per_meter_render": PPM,
        "clearance_px": CLEARANCE_PX,
        "directions": DIRECTIONS,
        "mirroring": False,
        "classes": CLASSES,
        "actions": {},
        "source_hashes": {},
    }
    for action in ACTIONS:
        canvas = SOURCE_CANVAS[action]
        meta = json.loads((ws / "reports" / f"measure_{action}_{canvas}.json").read_text())
        src_root = [int(v) for v in meta["camera"]["root_pixel"]]
        src_dir = ws / "output" / "clean" / canvas / action
        frame_count = meta["sample_count"]
        # Load every frame of the action across all 8 directions for the class decision.
        loaded = {d: [Image.open(src_dir / d / f"frame_{i:02d}.png").convert("RGBA") for i in range(frame_count)] for d in DIRECTIONS}
        flat = [img for d in DIRECTIONS for img in loaded[d]]
        cls = choose_class(flat, src_root)
        if cls is None:
            raise SystemExit(f"{action}: no supported viewport fits with clearance")
        for d in DIRECTIONS:
            for i, img in enumerate(loaded[d]):
                placed = place(img, src_root, cls)
                dst = frames_root / cls["id"] / action / d / f"frame_{i:02d}.png"
                dst.parent.mkdir(parents=True, exist_ok=True)
                placed.save(dst)
        manifest["source_hashes"][action] = {
            "canvas": canvas,
            "measure_meta_sha256": sha256(ws / "reports" / f"measure_{action}_{canvas}.json"),
        }
        manifest["actions"][action] = {
            "viewport": cls["id"],
            "root_px": cls["root"],
            "source_root_px": src_root,
            "source_canvas": canvas,
            "frame_count": frame_count,
            "authored_frame_range": meta["authored_frame_range"],
            "authored_duration_s": meta["authored_duration_s"],
            "sampling_target_fps": meta["sampling_target_fps"],
            "sample_count": meta["sample_count"],
            "loop": meta["loop"],
        }
        print(f"{action:20s} {cls['id']:18s} frames={frame_count}")
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1) + "\n")
    print("wrote", out / "manifest.json")


if __name__ == "__main__":
    main()
