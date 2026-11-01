#!/usr/bin/env python3
"""Create deterministic 2.5D/runtime/3D Operator iteration comparisons.

This helper assembles existing PNG sources and renderer outputs. It does not
render animation, infer timing correspondence, or alter source assets.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


APPROVED_REL = Path("custodian/asset_drop/source_work/operator/operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png")
APPROVED_SHA = "d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3"
LOCK_REL = Path("custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/operator_2_5d_design_lock_v1_source.png")
LOCK_SHA = "41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b"
DIRECTIONS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
POSTURE_PROJECTED = {"N": "e", "NE": "e", "E": "e", "SE": "e",
                     "S": "e", "SW": "w", "W": "w", "NW": "w"}
SAMPLES = (1, 132, 263)
BG = (25, 27, 31, 255)
PANEL = (35, 38, 43, 255)
TEXT = (235, 237, 240, 255)
MUTED = (174, 180, 188, 255)


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def require_png(path: Path, expected_sha: str | None = None) -> Image.Image:
    if not path.is_file():
        raise RuntimeError(f"REQUIRED_IMAGE_MISSING:{path}")
    head = path.read_bytes()[:256]
    if head.startswith(b"version https://git-lfs.github.com/spec/v1"):
        raise RuntimeError(f"REQUIRED_IMAGE_IS_UNHYDRATED_LFS_POINTER:{path}")
    digest = sha(path)
    if expected_sha and digest != expected_sha:
        raise RuntimeError(f"REQUIRED_IMAGE_SHA_MISMATCH:{path}:{digest}:{expected_sha}")
    try:
        im = Image.open(path)
        im.load()
    except Exception as exc:
        raise RuntimeError(f"REQUIRED_IMAGE_DECODE_FAILED:{path}:{exc}") from exc
    if im.mode != "RGBA":
        raise RuntimeError(f"REQUIRED_IMAGE_NOT_RGBA:{path}:{im.mode}")
    return im


def runtime_path(repo: Path, resource: str) -> Path:
    if not resource.startswith("res://"):
        raise RuntimeError("RUNTIME_RESOURCE_PATH_NOT_RES:" + resource)
    rel = Path(resource.removeprefix("res://"))
    path = repo / rel
    if not path.is_file():
        path = repo / "custodian" / rel
    require_png(path)
    return path


def frame(path: Path, item: dict, index: int) -> Image.Image:
    im = require_png(path)
    w, h = item["frame_size"]
    count = item["frames"]
    if im.size != (w * count, h):
        raise RuntimeError(f"RUNTIME_SHEET_GEOMETRY_MISMATCH:{path}:{im.size}:{(w*count, h)}")
    if index < 0 or index >= count:
        raise RuntimeError(f"RUNTIME_FRAME_INDEX_INVALID:{path}:{index}:{count}")
    return im.crop((index * w, 0, (index + 1) * w, h))


def text(draw, xy, value, fill=TEXT, font=None):
    draw.text(xy, value, fill=fill, font=font)


def canvas(width, height):
    im = Image.new("RGBA", (width, height), BG)
    return im, ImageDraw.Draw(im)


def center_paste(dst, src, box, size=None):
    x0, y0, x1, y1 = box
    if size is None:
        size = src.size
    source = src if src.size == size else src.resize(size, Image.Resampling.NEAREST)
    x = x0 + (x1 - x0 - size[0]) // 2
    y = y0 + (y1 - y0 - size[1]) // 2
    dst.alpha_composite(source, (x, y))


def fit_paste(dst, src, box):
    x0, y0, x1, y1 = box
    scale = min((x1 - x0) / src.width, (y1 - y0) / src.height)
    size = (max(1, round(src.width * scale)), max(1, round(src.height * scale)))
    fitted = src.resize(size, Image.Resampling.NEAREST)
    dst.alpha_composite(fitted, (x0 + (x1 - x0 - size[0]) // 2,
                                 y0 + (y1 - y0 - size[1]) // 2))


def approved_cell(sheet: Image.Image, direction_index: int, frame_index: int) -> Image.Image:
    return sheet.crop((frame_index * 128, direction_index * 128,
                       (frame_index + 1) * 128, (direction_index + 1) * 128))


def runtime_composite(repo, manifest, identity, direction, index, choose_full_body=False):
    entry = manifest["animations"].get(identity)
    if not entry:
        return None, {"identity": identity, "status": "missing_identity"}
    layers = entry["layers"]
    if choose_full_body and "full_body" in layers:
        layer_order = ["full_body"]
    else:
        layer_order = [l for l in ("lower_body", "upper_body") if l in layers]
        if not layer_order and "full_body" in layers:
            layer_order = ["full_body"]
    if not layer_order:
        return None, {"identity": identity, "status": "missing_renderable_layers"}
    rendered = None
    used = []
    frames = []
    for layer in layer_order:
        record = layers[layer]
        path = runtime_path(repo, record["path"])
        idx = min(index, record["frames"] - 1)
        cel = frame(path, record, idx)
        if rendered is None:
            rendered = Image.new("RGBA", cel.size, (0, 0, 0, 0))
        if cel.size != rendered.size:
            raise RuntimeError(f"RUNTIME_LAYER_SIZE_DIFFER:{identity}:{layer}")
        rendered.alpha_composite(cel)
        used.append({"layer": layer, "path": path.relative_to(repo).as_posix(),
                     "sha256": sha(path), "frames": record["frames"],
                     "selected_frame_zero_based": idx,
                     "source_frame_size": record["frame_size"]})
        frames.append(record["frames"])
    return rendered, {"identity": identity, "requested_direction": direction,
                      "authored_direction": entry["direction"], "direction_status": "authored",
                      "composition_order_back_to_front": layer_order, "layers": used,
                      "frame_index_zero_based": index, "frames_per_layer": frames,
                      "fps": entry.get("timing", {}).get("fps"),
                      "loop": entry.get("timing", {}).get("loop")}


def build_runtime_sheet(repo, manifest, out_path):
    cell = 120
    margin = 12
    row_h = 176
    width = 8 * (cell + 8) + 230
    height = 72 + 8 * row_h + 82 + 8 * 140
    im, draw = canvas(width, height)
    records = {"selected_posture_idle": [], "separate_locomotion_idle_family": []}
    text(draw, (12, 10), "ACTUAL CURRENT RUNTIME IDLE · unarmed/posture/idle_relaxed_01", font=None)
    text(draw, (12, 32), "Eight requested headings project to authored E/W; five frame pairs, lower then upper. Display only: native 96px cell.", MUTED)
    y_start = 60
    for row, direction in enumerate(DIRECTIONS):
        source_dir = POSTURE_PROJECTED[direction]
        identity = f"unarmed/posture/idle_relaxed_01/{source_dir}"
        y = y_start + row * row_h
        text(draw, (12, y + 7), f"{direction} → {source_dir.upper()} ({'authored' if direction == source_dir.upper() else 'projected'})")
        entry = manifest["animations"].get(identity)
        if not entry:
            raise RuntimeError("POSTURE_IDLE_IDENTITY_MISSING:" + identity)
        count = entry["layers"]["lower_body"]["frames"]
        if count != 5 or entry["layers"].get("upper_body", {}).get("frames") != 5:
            raise RuntimeError("POSTURE_IDLE_EXPECTED_FIVE_LAYER_FRAMES:" + identity)
        for i in range(count):
            sprite, rec = runtime_composite(repo, manifest, identity, direction, i)
            x0 = 120 + i * (cell + 8)
            draw.rectangle((x0, y + 25, x0 + cell, y + 25 + cell), fill=PANEL)
            center_paste(im, sprite, (x0, y + 25, x0 + cell, y + 25 + cell), (cell, cell))
            text(draw, (x0 + 42, y + 150), f"f{i+1}", MUTED)
            records["selected_posture_idle"].append({"requested_direction": direction,
                "selected_identity": identity, "fallback": direction != source_dir.upper(), **rec})

    y2 = y_start + 8 * row_h + 12
    text(draw, (12, y2), "SEPARATE LOCOMOTION IDLE FAMILY · unarmed/locomotion/idle_01 (not the selected relaxed posture)")
    text(draw, (12, y2 + 21), "One central source frame per authored heading; full_body where present, otherwise available modular layers only.", MUTED)
    y2 += 48
    for row, direction in enumerate(DIRECTIONS):
        key = direction.lower()
        identity = f"unarmed/locomotion/idle_01/{key}"
        sprite, rec = runtime_composite(repo, manifest, identity, direction, 2, choose_full_body=True)
        y = y2 + row * 140
        text(draw, (12, y + 54), f"{direction}: {rec.get('composition_back_to_front', rec.get('composition_order_back_to_front', []))}", MUTED)
        draw.rectangle((120, y + 10, 120 + cell, y + 10 + cell), fill=PANEL)
        if sprite is not None:
            fit_paste(im, sprite, (120, y + 10, 120 + cell, y + 10 + cell))
        rec["selected_alternative_family"] = "unarmed/locomotion/idle_01"
        records["separate_locomotion_idle_family"].append(rec)
    im.save(out_path)
    return records


def make_contact_sheets(repo, args):
    out = args.output_dir
    out.mkdir(parents=True, exist_ok=True)
    approved_path = repo / APPROVED_REL
    approved = require_png(approved_path, APPROVED_SHA)
    if approved.size != (1920, 1024):
        raise RuntimeError(f"APPROVED_IDLE_DIMENSIONS_MISMATCH:{approved.size}")
    if len(DIRECTIONS) * 15 * 128 != approved.width * 8 or approved.height != 8 * 128:
        raise RuntimeError("APPROVED_IDLE_GRID_MISMATCH")
    # Byte-copy the authoritative source sheet: output pixels and encoding unchanged.
    approved_out = out / "approved_128_idle_8dir_15f_contact_sheet.png"
    shutil.copyfile(approved_path, approved_out)
    if sha(approved_out) != APPROVED_SHA:
        raise RuntimeError("APPROVED_SOURCE_COPY_CHANGED")
    lock_path = repo / LOCK_REL
    lock = require_png(lock_path, LOCK_SHA)
    lock_out = out / "approved_design_lock_reference.png"
    shutil.copyfile(lock_path, lock_out)

    runtime_manifest_path = repo / "custodian/content/sprites/operator/runtime/operator_runtime_manifest.generated.json"
    runtime_manifest = json.loads(runtime_manifest_path.read_text())
    runtime_records = build_runtime_sheet(repo, runtime_manifest, out / "runtime_idle_actual_contact_sheet.png")

    # Main 8-direction comparison. Approved 15-frame source and 264-frame
    # experimental motion have no temporal correspondence; this is a pose sample.
    col_w, cell_size, row_h = 250, 128, 188
    comp, draw = canvas(84 + 4 * col_w, 68 + 8 * row_h)
    titles = (("APPROVED 128px", "center source frame 8/15"),
              ("CURRENT RUNTIME 96px", "posture E/W display projection"),
              (args.previous_label.upper(), "neutral idle sample 132"),
              (args.candidate_label.upper(), "neutral idle sample 132"))
    text(draw, (12, 10), "REPRESENTATIVE POSE COMPARISON · juxtaposition only; timing correspondence is unknown")
    for ci, title in enumerate(titles):
        text(draw, (76 + ci * col_w, 31), title[0], MUTED)
        text(draw, (76 + ci * col_w, 45), title[1], MUTED)
    for di, direction in enumerate(DIRECTIONS):
        y = 68 + di * row_h
        text(draw, (12, y + 78), direction)
        x_positions = [76 + ci * col_w for ci in range(4)]
        cells = [approved_cell(approved, di, 7)]
        source_dir = POSTURE_PROJECTED[direction]
        runtime_id = f"unarmed/posture/idle_relaxed_01/{source_dir}"
        runtime_entry = runtime_manifest["animations"][runtime_id]
        runtime_frame_index = 2
        runtime_sprite, runtime_rec = runtime_composite(repo, runtime_manifest, runtime_id, direction, runtime_frame_index)
        cells.append(runtime_sprite.resize((128, 128), Image.Resampling.NEAREST))
        for root in (args.previous_eightdir_root, args.candidate_root / "v003_8dir"):
            source = root / direction / "0132.png"
            cells.append(require_png(source))
        for ci, cell in enumerate(cells):
            box = (x_positions[ci], y + 24, x_positions[ci] + cell_size, y + 24 + cell_size)
            draw.rectangle((box[0] - 3, box[1] - 3, box[2] + 3, box[3] + 3), fill=PANEL)
            center_paste(comp, cell, box, (cell_size, cell_size))
        text(draw, (x_positions[1], y + 158), f"{runtime_id.split('/')[-1]}/{source_dir.upper()} actual source", MUTED)
    comp.save(out / "operator_v003_8dir_reference_comparison.png")

    # Per-pose V002/V003 paired sheet at the four requested headings.
    dirs = ("S", "SE", "SW", "E")
    pose, draw = canvas(560, 42 + len(dirs) * len(SAMPLES) * 156)
    text(draw, (12, 10), "V002 VS V003 · fixed camera/root/scale · sample indices, not 2.5D frame matches")
    y = 42
    pose_records = []
    for direction in dirs:
        for sample in SAMPLES:
            text(draw, (12, y + 56), f"{direction} · {sample}")
            for col, root in enumerate((args.previous_root / "final_128", args.candidate_root / "native128")):
                source = root / direction / f"{sample:04d}.png"
                im = require_png(source)
                x = 125 + col * 200
                center_paste(pose, im, (x, y + 12, x + 128, y + 140), (128, 128))
                text(draw, (x + 2, y + 142), args.previous_label if col == 0 else args.candidate_label, MUTED)
                pose_records.append({"direction": direction, "sample_index": sample,
                                     "variant": args.previous_label if col == 0 else args.candidate_label,
                                     "path": source.as_posix(), "sha256": sha(source)})
            y += 156
    pose.save(out / "operator_v003_pose_comparison.png")

    # ROI zooms from the same native 128 full-body source renders; nearest only.
    detail, draw = canvas(1000, 615)
    text(draw, (12, 10), "UPPER-BODY DETAIL · hood · collar · pauldrons · chest · waist · 3× nearest display enlargement")
    regions = {"S": (24, 15, 104, 76), "E": (35, 17, 91, 78)}
    x_positions = (135, 565)
    y = 45
    for direction, rect in regions.items():
        text(draw, (12, y + 100), direction)
        for col, root in enumerate((args.previous_root / "final_128", args.candidate_root / "native128")):
            src = require_png(root / direction / "0132.png")
            crop = src.crop(rect).resize(((rect[2]-rect[0])*3, (rect[3]-rect[1])*3), Image.Resampling.NEAREST)
            x = x_positions[col]
            detail.alpha_composite(crop, (x, y))
            text(draw, (x, y + crop.height + 4), args.previous_label if col == 0 else args.candidate_label, MUTED)
        y += 280
    detail.save(out / "operator_v003_upper_body_detail.png")

    sharp, draw = canvas(860, 42 + len(dirs) * len(SAMPLES) * 164)
    text(draw, (12, 10), "NATIVE 128 VS INDEPENDENT 512→128 · pixelart --choose 1 once per independent 512px render")
    y = 42
    sharp_records = []
    for direction in dirs:
        for sample in SAMPLES:
            text(draw, (12, y + 48), f"{direction} · {sample}")
            for col, base in enumerate((args.candidate_root / "native128", args.candidate_root / "reduced512")):
                source = base / direction / f"{sample:04d}.png"
                cel = require_png(source)
                x = 155 + col * 220
                center_paste(sharp, cel, (x, y + 5, x + 128, y + 133), (128, 128))
                text(draw, (x, y + 136), "native 128" if col == 0 else "512 reduced once", MUTED)
                sharp_records.append({"direction": direction, "sample_index": sample,
                                      "path": source.as_posix(), "sha256": sha(source),
                                      "variant": "native128" if col == 0 else "reduced512_choose1"})
            y += 164
    sharp.save(out / "operator_v003_native128_vs_reduced512.png")

    adjacent, draw = canvas(980, 48 + 6 * 184)
    text(draw, (12, 10), "SHORT MOTION CHECKS · adjacent neutral-idle and retargeted running-action frame neighborhoods")
    adjacent_records = []
    row = 0
    checks = (("neutral_idle", (131, 132, 133), "pose overlay"),
              ("running", (5, 6, 7), "source running action"),
              ("running", (15, 16, 17), "source running action"))
    for family, indices, label in checks:
        for direction in ("S", "E"):
            y = 48 + row * 184
            text(draw, (12, y + 58), f"{family} · {direction} · {label}")
            for col, sample in enumerate(indices):
                path = args.adjacent_root / family / direction / f"{sample:04d}.png"
                cell = require_png(path)
                x = 260 + col * 180
                center_paste(adjacent, cell, (x, y + 12, x + 128, y + 140), (128, 128))
                text(draw, (x + 42, y + 144), str(sample), MUTED)
                adjacent_records.append({"family": family, "direction": direction,
                                         "sample_index": sample, "path": path.as_posix(),
                                         "sha256": sha(path), "source_action_label": label})
            row += 1
    adjacent.save(out / "operator_v003_adjacent_motion_qa.png")

    # Reproducibility inputs and image hashes.
    repo_commit = __import__("subprocess").check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip()
    selector = repo / "custodian/game/actors/operator/animations/operator_animation_selector.gd"
    posture_code = repo / "custodian/game/actors/operator/presentation/unarmed_posture_presentation.gd"
    operator_code = repo / "custodian/game/actors/operator/operator.gd"
    source_records = {
        "approved_128_idle": {"path": APPROVED_REL.as_posix(), "sha256": sha(approved_path),
                               "dimensions": list(approved.size), "directions": list(DIRECTIONS),
                               "frames_per_direction": 15, "cell_px": [128,128], "root_px": [64,106],
                               "fps": "unknown; no timing invented"},
        "approved_design_lock": {"path": LOCK_REL.as_posix(), "sha256": sha(lock_path),
                                 "dimensions": list(lock.size)},
        "runtime_manifest": {"path": runtime_manifest_path.relative_to(repo).as_posix(),
                             "sha256": sha(runtime_manifest_path), "schema": runtime_manifest.get("schema"),
                             "repo_generation_commit": repo_commit},
        "runtime_selector_sources": [{"path": p.relative_to(repo).as_posix(), "sha256": sha(p)}
                                      for p in (selector, posture_code, operator_code)],
    }
    outputs = {}
    for p in sorted(out.glob("*.png")):
        outputs[p.name] = {"sha256": sha(p), "dimensions": list(Image.open(p).size), "bytes": p.stat().st_size}
    manifest = {
        "schema": "custodian.operator_3d_iteration_reference_comparison.v1",
        "candidate_state": "candidate_unapproved",
        "reference_sources": source_records,
        "runtime_actual_idle": {
            "selected_semantic": "unarmed/posture/idle_relaxed_01",
            "current_runtime_source_generation": repo_commit,
            "presentation_layers_back_to_front": ["lower_body", "upper_body"],
            "projection_policy_source": "unarmed_posture_presentation.gd::authored_sector",
            "requested_to_authored_direction": POSTURE_PROJECTED,
            "source_fps": 8,
            "frames_per_layer": 5,
            "records": runtime_records,
            "separate_locomotion_family": "unarmed/locomotion/idle_01; shown in distinct labeled section",
        },
        "candidate_versions": {"previous_label": args.previous_label,
                               "previous_blend_sha256": sha(args.previous_blend),
                               "candidate_label": args.candidate_label,
                               "candidate_blend_sha256": sha(args.candidate_blend)},
        "samples": {"experimental_neutral_idle_indices": list(SAMPLES),
                    "sample_names": ["beginning", "middle", "end"],
                    "timing_correspondence_to_approved_15f_idle": "none established"},
        "render_settings": {"renderer": "Blender animation compiler blender_neutral_idle_proof.py",
                            "directions": list(DIRECTIONS), "camera": {"resolution": [128,128],
                                "elevation_degrees":45,"pixels_per_meter":50,"orthographic_scale":2.56,
                                "root_pixel":[64,106],"fixed_scale":1.2287417600294088,
                                "independent_no_mirroring":True},
                            "native_sizes": [128,512],
                            "reduction": "tools/custodian_aliases.sh pixelart --pixel-source --size 128 --choose 1; one conversion invocation per 512 render",
                            "display_enlargement": "nearest-neighbor; does not alter source pixels"},
        "pose_comparison_records": pose_records,
        "sharpness_comparison_records": sharp_records,
        "adjacent_motion_records": adjacent_records,
        "generated_outputs": outputs,
    }
    (out / "comparison_manifest.v1.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(json.dumps({"result":"built", "output_dir":str(out), "outputs":list(outputs),
                      "manifest":str(out / "comparison_manifest.v1.json"),
                      "runtime_posture_east_west_fallbacks":sum(1 for d in DIRECTIONS if POSTURE_PROJECTED[d] != d.lower())},sort_keys=True))


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--repo-root", type=Path, required=True)
    p.add_argument("--previous-label", default="V002")
    p.add_argument("--candidate-label", default="V003")
    p.add_argument("--previous-root", type=Path, required=True, help="V2 proof root containing final_128/")
    p.add_argument("--previous-eightdir-root", type=Path, required=True, help="Matching-camera V2 eight-direction frame root")
    p.add_argument("--candidate-root", type=Path, required=True, help="Candidate proof root containing native128/, reduced512/ and v003_8dir/")
    p.add_argument("--adjacent-root", type=Path, required=True, help="Adjacent-frame output root with neutral_idle/ and running/ dirs")
    p.add_argument("--previous-blend", type=Path, required=True)
    p.add_argument("--candidate-blend", type=Path, required=True)
    p.add_argument("--output-dir", type=Path, required=True)
    args = p.parse_args()
    make_contact_sheets(args.repo_root.resolve(), args)


if __name__ == "__main__":
    main()
