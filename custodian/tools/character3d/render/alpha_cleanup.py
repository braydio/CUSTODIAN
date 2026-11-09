"""Derived-export alpha cleanup + validation for the Operator scale-probe workspace.

Raw renders are never modified. Each raw frame is copied to a derived path with RGB zeroed where alpha == 0.
Pixels with alpha > 0 are preserved exactly. Low-alpha pixels (1..7) that do not touch the main silhouette are
counted and reported, not deleted. Occupancy in all reports is measured from alpha, never RGB.

Usage:
  python3 -I scripts/alpha_cleanup.py --src output/measure/c256_80 --dst output/clean/c256_80 --report reports/_alpha_cleanup_c256.json
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image


def clean_array(arr):
    out = arr.copy()
    transparent = out[:, :, 3] == 0
    out[transparent, :3] = 0
    return out


def silhouette_mask(alpha):
    """Main silhouette = pixels with alpha >= 8, plus a 2px neighbourhood for antialiasing."""
    core = alpha >= 8
    grown = core.copy()
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            grown |= np.roll(np.roll(core, dy, axis=0), dx, axis=1)
    return grown


def process(src_path: Path, dst_path: Path):
    raw = np.array(Image.open(src_path).convert("RGBA"))
    cleaned = clean_array(raw)
    # Validation: alpha>0 pixels identical; transparent RGB zero; alpha channel untouched.
    nz = raw[:, :, 3] > 0
    if not np.array_equal(raw[nz], cleaned[nz]):
        raise SystemExit(f"{src_path}: visible pixels changed")
    if not np.array_equal(raw[:, :, 3], cleaned[:, :, 3]):
        raise SystemExit(f"{src_path}: alpha changed")
    if (cleaned[cleaned[:, :, 3] == 0][:, :3] != 0).any():
        raise SystemExit(f"{src_path}: transparent RGB not zero after cleanup")
    alpha = raw[:, :, 3]
    low = (alpha > 0) & (alpha < 8)
    sil = silhouette_mask(alpha)
    low_outside = int((low & ~sil).sum())
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(cleaned, "RGBA").save(dst_path)
    return {
        "transparent_px": int((alpha == 0).sum()),
        "transparent_px_with_rgb_before": int(((alpha == 0) & (raw[:, :, :3] != 0).any(axis=2)).sum()),
        "max_rgb_on_transparent_before": int(raw[:, :, :3][alpha == 0].max()) if (alpha == 0).any() else 0,
        "visible_px_preserved": int(nz.sum()),
        "low_alpha_px": int(low.sum()),
        "low_alpha_px_outside_silhouette": low_outside,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--dst", required=True)
    ap.add_argument("--report", required=True)
    args = ap.parse_args()
    src_root, dst_root = Path(args.src), Path(args.dst)
    summary = {"src": str(src_root), "dst": str(dst_root), "files": 0, "totals": {}, "per_action": {}}
    for f in sorted(src_root.rglob("frame_*.png")):
        rel = f.relative_to(src_root)
        stats = process(f, dst_root / rel)
        action = rel.parts[0]
        pa = summary["per_action"].setdefault(action, {"files": 0})
        pa["files"] += 1
        for k, v in stats.items():
            if k == "max_rgb_on_transparent_before":
                pa[k] = max(pa.get(k, 0), v)
            else:
                pa[k] = pa.get(k, 0) + v
        summary["files"] += 1
    summary["validation"] = "PASS: visible pixels identical; alpha identical; transparent RGB zero; raw sources untouched"
    Path(args.report).parent.mkdir(parents=True, exist_ok=True)
    Path(args.report).write_text(json.dumps(summary, indent=1) + "\n")
    print("ALPHA_CLEANUP", summary["files"], "files ->", dst_root)


if __name__ == "__main__":
    main()
