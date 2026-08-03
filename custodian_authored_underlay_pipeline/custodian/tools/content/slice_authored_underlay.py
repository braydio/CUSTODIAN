#!/usr/bin/env python3
# Slice a large authored underlay master into Godot-ready runtime plates.
# Outputs PNG plates, deterministic manifest, runtime scene, preview scene,
# and a build report. Keep the source master outside the Godot project.

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import sys
import tempfile
from typing import Any, Iterable

from PIL import Image

SCHEMA = "custodian.authored_underlay_plate_manifest.v1"
DEFAULT_LOADER = "res://game/world/presentation/authored_underlay_plate_loader.gd"


class PipelineError(RuntimeError):
    pass


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def atomic_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", newline="\n",
        dir=path.parent, delete=False
    ) as handle:
        handle.write(text)
        temp_name = handle.name
    os.replace(temp_name, path)


def atomic_write_json(path: Path, value: dict[str, Any]) -> None:
    atomic_write_text(path, json.dumps(value, indent=2) + "\n")


def atomic_save_png(image: Image.Image, path: Path, compress_level: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        suffix=".png", dir=path.parent, delete=False
    ) as handle:
        temp_path = Path(handle.name)
    try:
        image.save(
            temp_path, format="PNG",
            optimize=False, compress_level=compress_level
        )
        os.replace(temp_path, path)
    finally:
        temp_path.unlink(missing_ok=True)


def normalize_res_relative(value: str, label: str) -> str:
    value = value.replace("\\", "/").strip()
    if value.startswith("res://"):
        value = value[6:]
    value = value.lstrip("/")
    if not value or value.startswith("../") or "/../" in value:
        raise PipelineError(f"{label} must remain inside the Godot root: {value}")
    return value


def res_path(relative_path: str) -> str:
    return "res://" + relative_path.replace("\\", "/").lstrip("/")


def recorded_source_path(path: Path, repo_root: Path) -> str:
    try:
        return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def is_fully_transparent(image: Image.Image) -> bool:
    if image.mode != "RGBA":
        return False
    return image.getchannel("A").getextrema() == (0, 0)


def rect2(values: Iterable[float]) -> str:
    x, y, w, h = values
    return f"Rect2({x:.6f}, {y:.6f}, {w:.6f}, {h:.6f})"


def vector2(x: float, y: float) -> str:
    return f"Vector2({x:.6f}, {y:.6f})"


def verify_plate_core(
    source: Image.Image,
    plate_path: Path,
    source_core_rect: list[int],
    texture_core_rect: list[int],
) -> None:
    sx, sy, sw, sh = source_core_rect
    tx, ty, tw, th = texture_core_rect
    if (sw, sh) != (tw, th):
        raise PipelineError(f"Core size mismatch: {plate_path}")
    expected = source.crop((sx, sy, sx + sw, sy + sh))
    with Image.open(plate_path) as plate_image:
        actual = plate_image.convert(source.mode).crop((tx, ty, tx + tw, ty + th))
    if expected.tobytes() != actual.tobytes():
        raise PipelineError(f"Core pixel verification failed: {plate_path}")


def runtime_scene_text(
    root_name: str,
    manifest_path: str,
    loader_path: str,
    streaming: bool,
    preload_margin: float,
    unload_margin: float,
    max_loads: int,
) -> str:
    return f"""[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="{loader_path}" id="1_loader"]

[node name="{root_name}" type="Node2D"]
script = ExtResource("1_loader")
manifest_path = "{manifest_path}"
streaming_enabled = {"true" if streaming else "false"}
preload_margin_world = {preload_margin:.6f}
unload_margin_world = {unload_margin:.6f}
max_loads_per_tick = {max_loads}

[node name="PlateRoot" type="Node2D" parent="."]
"""


def preview_scene_text(
    root_name: str,
    plates: list[dict[str, Any]],
    z_index: int,
    filter_mode: str,
) -> str:
    filter_value = {
        "nearest": 1,
        "linear": 2,
        "nearest_mipmaps": 3,
        "linear_mipmaps": 4,
    }[filter_mode]
    lines = [f"[gd_scene load_steps={len(plates) + 1} format=3]", ""]
    for index, plate in enumerate(plates, 1):
        ext_id = f"tex_{index:04d}"
        plate["_ext_id"] = ext_id
        lines.append(
            f'[ext_resource type="Texture2D" path="{plate["res_path"]}" id="{ext_id}"]'
        )
    lines += ["", f'[node name="{root_name}" type="Node2D"]', f"z_index = {z_index}", ""]
    for plate in plates:
        world = plate["world_rect"]
        core = plate["texture_core_rect"]
        lines += [
            f'[node name="Plate_{plate["id"]}" type="Sprite2D" parent="."]',
            f'texture = ExtResource("{plate["_ext_id"]}")',
            "centered = false",
            "region_enabled = true",
            f"region_rect = {rect2(core)}",
            f"position = {vector2(world[0], world[1])}",
            f'scale = {vector2(plate["world_units_per_pixel"], plate["world_units_per_pixel"])}',
            f"texture_filter = {filter_value}",
            "z_index = 0",
            "",
        ]
        del plate["_ext_id"]
    return "\n".join(lines).rstrip() + "\n"


def parse_manifest(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise PipelineError(f"Cannot read manifest {path}: {exc}") from exc
    if not isinstance(value, dict) or value.get("schema") != SCHEMA:
        raise PipelineError(f"Unsupported manifest: {path}")
    return value


def verify_existing(
    manifest_path: Path,
    godot_root: Path,
    source_override: Path | None,
) -> None:
    manifest = parse_manifest(manifest_path)
    source_record = manifest["source"]
    source_path = source_override or Path(source_record["path"])
    if not source_path.is_absolute():
        source_path = godot_root.parent / source_path
    if not source_path.exists():
        raise PipelineError(f"Source master not found: {source_path}")
    if sha256_file(source_path) != source_record["sha256"]:
        raise PipelineError("Source master SHA-256 changed.")
    Image.MAX_IMAGE_PIXELS = None
    with Image.open(source_path) as opened:
        source = opened.convert(source_record["mode"])
        source.load()
    if list(source.size) != source_record["size_px"]:
        raise PipelineError("Source dimensions changed.")
    for plate in manifest["plates"]:
        path = godot_root / str(plate["res_path"]).removeprefix("res://")
        if not path.exists():
            raise PipelineError(f"Missing plate: {path}")
        if sha256_file(path) != plate["sha256"]:
            raise PipelineError(f"Plate hash changed: {path}")
        verify_plate_core(
            source, path,
            plate["source_core_rect"],
            plate["texture_core_rect"],
        )
    print(f"Verified {len(manifest['plates'])} plate cores.")


def apply_defaults(args: argparse.Namespace) -> None:
    base = f"content/backgrounds/authored_underlays/{args.asset_id}"
    args.output_res_dir = args.output_res_dir or f"{base}/plates"
    args.manifest_res_path = args.manifest_res_path or f"{base}/{args.asset_id}.plates.json"
    args.runtime_scene_res_path = args.runtime_scene_res_path or (
        f"game/world/presentation/generated/{args.asset_id}_underlay_runtime.tscn"
    )
    args.preview_scene_res_path = args.preview_scene_res_path or (
        f"scenes/debug/generated/{args.asset_id}_underlay_preview.tscn"
    )


def build(args: argparse.Namespace) -> dict[str, Any]:
    repo_root = Path(args.repo_root).resolve()
    godot_root = Path(args.godot_root)
    if not godot_root.is_absolute():
        godot_root = (repo_root / godot_root).resolve()
    source_path = Path(args.source)
    if not source_path.is_absolute():
        source_path = (repo_root / source_path).resolve()

    if not source_path.exists():
        raise PipelineError(f"Source master missing: {source_path}")
    if not godot_root.exists():
        raise PipelineError(f"Godot root missing: {godot_root}")
    if not (godot_root / "project.godot").exists() and not args.allow_no_project:
        raise PipelineError(f"project.godot not found under {godot_root}")
    if args.plate_size < 256:
        raise PipelineError("--plate-size must be >= 256")
    if args.bleed < 0 or args.bleed * 2 >= args.plate_size:
        raise PipelineError("--bleed must be >= 0 and less than half plate size")
    if args.world_units_per_pixel <= 0:
        raise PipelineError("--world-units-per-pixel must be positive")
    if args.unload_margin_world < args.preload_margin_world:
        raise PipelineError("Unload margin must be >= preload margin")
    if not 0 <= args.compress_level <= 9:
        raise PipelineError("PNG compress level must be 0..9")

    out_rel = normalize_res_relative(args.output_res_dir, "--output-res-dir")
    manifest_rel = normalize_res_relative(args.manifest_res_path, "--manifest-res-path")
    runtime_rel = normalize_res_relative(args.runtime_scene_res_path, "--runtime-scene-res-path")
    preview_rel = normalize_res_relative(args.preview_scene_res_path, "--preview-scene-res-path")
    out_dir = godot_root / out_rel
    manifest_file = godot_root / manifest_rel
    runtime_file = godot_root / runtime_rel
    preview_file = godot_root / preview_rel
    out_dir.mkdir(parents=True, exist_ok=True)

    Image.MAX_IMAGE_PIXELS = None
    with Image.open(source_path) as opened:
        source = opened.convert("RGBA" if opened.mode not in ("RGB", "RGBA") else opened.mode)
        source.load()

    width, height = source.size
    columns = math.ceil(width / args.plate_size)
    rows = math.ceil(height / args.plate_size)
    plates: list[dict[str, Any]] = []
    omitted: list[list[int]] = []
    expected_names: set[str] = set()

    for row in range(rows):
        for column in range(columns):
            x = column * args.plate_size
            y = row * args.plate_size
            core_w = min(args.plate_size, width - x)
            core_h = min(args.plate_size, height - y)
            core = source.crop((x, y, x + core_w, y + core_h))
            if args.omit_fully_transparent and is_fully_transparent(core):
                omitted.append([column, row])
                continue

            left = max(0, x - args.bleed)
            top = max(0, y - args.bleed)
            right = min(width, x + core_w + args.bleed)
            bottom = min(height, y + core_h + args.bleed)
            plate_image = source.crop((left, top, right, bottom))
            texture_core = [x - left, y - top, core_w, core_h]

            filename = f"{args.asset_id}__p_{column:03d}_{row:03d}.png"
            expected_names.add(filename)
            plate_file = out_dir / filename
            atomic_save_png(plate_image, plate_file, args.compress_level)

            world_x = args.world_origin_x + x * args.world_units_per_pixel
            world_y = args.world_origin_y + y * args.world_units_per_pixel
            plate = {
                "id": f"{column:03d}_{row:03d}",
                "grid": [column, row],
                "res_path": res_path((Path(out_rel) / filename).as_posix()),
                "source_core_rect": [x, y, core_w, core_h],
                "texture_core_rect": texture_core,
                "texture_size_px": list(plate_image.size),
                "world_rect": [
                    world_x, world_y,
                    core_w * args.world_units_per_pixel,
                    core_h * args.world_units_per_pixel,
                ],
                "world_units_per_pixel": args.world_units_per_pixel,
                "sha256": sha256_file(plate_file),
            }
            plates.append(plate)
            if not args.skip_pixel_verification:
                verify_plate_core(source, plate_file, plate["source_core_rect"], texture_core)

    if args.clean:
        for stale in out_dir.glob(f"{args.asset_id}__p_*.png"):
            if stale.name not in expected_names:
                stale.unlink()

    master_world_rect = [
        args.world_origin_x,
        args.world_origin_y,
        width * args.world_units_per_pixel,
        height * args.world_units_per_pixel,
    ]
    manifest = {
        "schema": SCHEMA,
        "asset_id": args.asset_id,
        "generated_by": "slice_authored_underlay.py",
        "source": {
            "path": recorded_source_path(source_path, repo_root),
            "size_px": [width, height],
            "mode": source.mode,
            "sha256": sha256_file(source_path),
            "runtime_authority": False,
        },
        "layout": {
            "plate_core_size_px": args.plate_size,
            "bleed_px": args.bleed,
            "grid_columns": columns,
            "grid_rows": rows,
            "world_origin": [args.world_origin_x, args.world_origin_y],
            "world_units_per_pixel": args.world_units_per_pixel,
            "master_world_rect": master_world_rect,
            "z_index": args.z_index,
            "texture_filter": args.texture_filter,
            "omit_fully_transparent": args.omit_fully_transparent,
            "omitted_empty_core_grid": omitted,
        },
        "runtime": {
            "manifest_res_path": res_path(manifest_rel),
            "runtime_scene_res_path": res_path(runtime_rel),
            "preview_scene_res_path": res_path(preview_rel),
            "loader_script_res_path": args.loader_res_path,
            "streaming_enabled": args.streaming_enabled,
            "preload_margin_world": args.preload_margin_world,
            "unload_margin_world": args.unload_margin_world,
            "max_loads_per_tick": args.max_loads_per_tick,
        },
        "plate_count": len(plates),
        "plates": plates,
    }
    atomic_write_json(manifest_file, manifest)
    atomic_write_text(
        runtime_file,
        runtime_scene_text(
            args.root_node_name,
            res_path(manifest_rel),
            args.loader_res_path,
            args.streaming_enabled,
            args.preload_margin_world,
            args.unload_margin_world,
            args.max_loads_per_tick,
        ),
    )
    atomic_write_text(
        preview_file,
        preview_scene_text(
            args.root_node_name + "Preview",
            plates,
            args.z_index,
            args.texture_filter,
        ),
    )
    report = {
        "asset_id": args.asset_id,
        "source_size_px": [width, height],
        "grid": [columns, rows],
        "plate_count": len(plates),
        "omitted_empty_plate_count": len(omitted),
        "plate_core_size_px": args.plate_size,
        "bleed_px": args.bleed,
        "manifest": res_path(manifest_rel),
        "runtime_scene": res_path(runtime_rel),
        "preview_scene": res_path(preview_rel),
        "master_world_rect": master_world_rect,
    }
    atomic_write_json(manifest_file.with_suffix(".build-report.json"), report)
    print(json.dumps(report, indent=2))
    return manifest


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Build Godot authored-underlay plates.")
    p.add_argument("--source", required=True)
    p.add_argument("--repo-root", default=".")
    p.add_argument("--godot-root", default="custodian")
    p.add_argument("--asset-id", required=True)
    p.add_argument("--output-res-dir")
    p.add_argument("--manifest-res-path")
    p.add_argument("--runtime-scene-res-path")
    p.add_argument("--preview-scene-res-path")
    p.add_argument("--loader-res-path", default=DEFAULT_LOADER)
    p.add_argument("--root-node-name", default="AuthoredUnderlayPlateSet")
    p.add_argument("--plate-size", type=int, default=2048)
    p.add_argument("--bleed", type=int, default=16)
    p.add_argument("--world-origin-x", type=float, default=0.0)
    p.add_argument("--world-origin-y", type=float, default=0.0)
    p.add_argument("--world-units-per-pixel", type=float, default=1.0)
    p.add_argument("--z-index", type=int, default=-120)
    p.add_argument(
        "--texture-filter",
        choices=("nearest", "linear", "nearest_mipmaps", "linear_mipmaps"),
        default="linear_mipmaps",
    )
    p.add_argument("--compress-level", type=int, default=6)
    p.add_argument("--preload-margin-world", type=float, default=768.0)
    p.add_argument("--unload-margin-world", type=float, default=1536.0)
    p.add_argument("--max-loads-per-tick", type=int, default=2)
    p.add_argument(
        "--streaming-enabled",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    p.add_argument(
        "--omit-fully-transparent",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    p.add_argument("--clean", action=argparse.BooleanOptionalAction, default=False)
    p.add_argument("--skip-pixel-verification", action="store_true")
    p.add_argument("--allow-no-project", action="store_true")
    p.add_argument("--verify-only", action="store_true")
    p.add_argument("--verify-manifest")
    return p


def main() -> int:
    args = parser().parse_args()
    apply_defaults(args)
    try:
        if args.verify_only:
            if not args.verify_manifest:
                raise PipelineError("--verify-only requires --verify-manifest")
            repo_root = Path(args.repo_root).resolve()
            godot_root = Path(args.godot_root)
            if not godot_root.is_absolute():
                godot_root = (repo_root / godot_root).resolve()
            source = Path(args.source)
            if not source.is_absolute():
                source = (repo_root / source).resolve()
            verify_existing(Path(args.verify_manifest), godot_root, source)
        else:
            build(args)
    except PipelineError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
