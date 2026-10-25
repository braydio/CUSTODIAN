#!/usr/bin/env python3
"""Focused read-only Asset Workbench REVIEW contract smoke."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import asyncio
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
ASSET_TOOLS = REPO / "tools/assets"
sys.path.insert(0, str(ASSET_TOOLS))

from asset_inspector import AssetInspection, FrameLayout
from asset_workbench.review import AssetReviewService, compare_frames, extract_frames, scale_frame_nearest, side_by_side_frames
from asset_workbench.service import AssetWorkbenchService


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def colored_frames() -> tuple[Image.Image, ...]:
    colors = ((230, 20, 30, 255), (20, 220, 40, 180), (30, 40, 230, 80), (250, 240, 30, 0))
    return tuple(Image.new("RGBA", (2, 2), color) for color in colors)


def check_layouts(root: Path) -> None:
    frames = colored_frames()
    cases = (
        ("copy", Image.new("RGBA", (2, 2)), FrameLayout.COPY, 1, None, None),
        ("horizontal", Image.new("RGBA", (8, 2)), FrameLayout.HORIZONTAL_STRIP, 4, None, None),
        ("vertical", Image.new("RGBA", (2, 8)), FrameLayout.VERTICAL_STRIP, 4, None, None),
        ("grid", Image.new("RGBA", (4, 4)), FrameLayout.GRID, 4, 2, 2),
    )
    for name, canvas, layout, count, columns, rows in cases:
        for index, frame in enumerate(frames[:count]):
            if layout is FrameLayout.HORIZONTAL_STRIP: origin = (index * 2, 0)
            elif layout is FrameLayout.VERTICAL_STRIP: origin = (0, index * 2)
            elif layout is FrameLayout.GRID: origin = ((index % 2) * 2, (index // 2) * 2)
            else: origin = (0, 0)
            canvas.alpha_composite(frame, origin)
        path = root / f"{name}.png"
        canvas.save(path)
        inspection = AssetInspection(path, *canvas.size, 2, 2, count, layout, columns, rows)
        result = extract_frames(path, inspection)
        check(len(result) == count, f"{name}: frame count changed")
        check(all(frame.size == (2, 2) and frame.mode == "RGBA" for frame in result), f"{name}: frame fidelity/mode changed")
        source_pixels = [canvas.crop((index * 2, 0, (index + 1) * 2, 2)).getpixel((0, 0)) if layout is FrameLayout.HORIZONTAL_STRIP
                         else canvas.crop((0, index * 2, 2, (index + 1) * 2)).getpixel((0, 0)) if layout is FrameLayout.VERTICAL_STRIP
                         else canvas.crop(((index % 2) * 2, (index // 2) * 2, (index % 2 + 1) * 2, (index // 2 + 1) * 2)).getpixel((0, 0)) if layout is FrameLayout.GRID
                         else canvas.getpixel((0, 0)) for index in range(count)]
        check([frame.getpixel((0, 0)) for frame in result] == source_pixels, f"{name}: frame order or RGBA changed")
    bad = AssetInspection(root / "bad.png", 6, 2, 2, 2, 0, FrameLayout.AMBIGUOUS)
    try:
        extract_frames(root / "bad.png", bad)
    except ValueError as error:
        check("ambiguous" in str(error), "ambiguous geometry diagnostic is unclear")
    else:
        raise AssertionError("ambiguous geometry was guessed")
    pointer = root / "pointer.png"
    pointer.write_text("version https://git-lfs.github.com/spec/v1\noid sha256:" + "a" * 64 + "\nsize 4\n")
    try:
        extract_frames(pointer, AssetInspection(pointer, 2, 2, 2, 2, 1, FrameLayout.COPY))
    except ValueError as error:
        check("LFS OBJECT NOT HYDRATED" in str(error), "LFS pointer diagnostic missing")
    else:
        raise AssertionError("LFS pointer reached image decoding")


def check_comparisons() -> None:
    left = Image.new("RGBA", (2, 2), (0, 0, 0, 0))
    right = left.copy()
    right.putpixel((1, 1), (255, 0, 0, 255))
    diff, warning, changed, bounds = compare_frames(left, right, "diff")
    check(warning is None and diff is not None and changed == 1 and bounds == (1, 1, 2, 2), "diff did not report pixel evidence")
    result, warning, *_ = compare_frames(left, Image.new("RGBA", (3, 2)), "overlay")
    check(result is None and warning and "equal frame dimensions" in warning, "mismatched dimensions were resampled or accepted")
    source = Image.new("RGBA", (2, 1), (20, 40, 60, 120))
    zoomed = scale_frame_nearest(source, 3)
    check(zoomed.size == (6, 3) and zoomed.getpixel((0, 0)) == source.getpixel((0, 0)) and zoomed.getpixel((5, 2)) == source.getpixel((1, 0)), "integer zoom interpolated or changed RGBA pixels")
    side = side_by_side_frames(Image.new("RGBA", (2, 3), (5, 20, 50, 80)), Image.new("RGBA", (4, 1), (80, 20, 5, 180)))
    check(side.size == (6, 3) and side.getpixel((2, 0)) == (80, 20, 5, 180), "side-by-side changed source dimensions or pixels")


def check_fixture_authorities(root: Path) -> None:
    family = {
        "schema": "custodian.asset_family.v2", "id": "review_static", "kind": "world_prop",
        "runtime": {"domain": "sprites/environment/props", "owner": "review_static"},
        "canvas": {"width": 4, "height": 3}, "direction_policy": "omni",
        "states": {"icon": {"layer": "body", "action_group": "still", "variant": "icon", "animation": False, "fps": 9, "frames": 1}},
    }
    family_path = root / "content/metadata/assets/families/review_static.asset.json"
    family_path.parent.mkdir(parents=True)
    family_path.write_text(json.dumps(family), encoding="utf-8")
    inbox = root / "asset_drop/inbox/review_static"
    inbox.mkdir(parents=True)
    pixels = Image.new("RGBA", (4, 3), (10, 50, 200, 120))
    staged = inbox / "review_static__body__still__icon__omni__1f__4x3.png"
    pixels.save(staged)
    # An unrelated unresolved file creates a global planner error but must not
    # hide the individually resolved selected source.
    Image.new("RGBA", (4, 3)).save(inbox / "unrelated.png")
    (inbox / "broken.png").write_bytes(b"not a PNG")
    (inbox / "lfs.png").write_text("version https://git-lfs.github.com/spec/v1\noid sha256:" + "b" * 64 + "\nsize 4\n")
    runtime_rel = "content/sprites/environment/props/review_static/runtime/review_static__body__still__icon__omni__1f__4x3.png"
    runtime = root / runtime_rel
    runtime.parent.mkdir(parents=True)
    pixels.save(runtime)
    digest = hashlib.sha256(runtime.read_bytes()).hexdigest()
    catalog_path = root / "catalog.json"
    catalog_path.write_text(json.dumps({"schema": "custodian.asset_catalog.v2", "families": {"review_static": {"assets": {
        "icon::omni": {"state_id": "icon", "direction": "omni", "semantic_identity": ["review_static", "world_prop", "body", "still", "icon", "omni"], "path": runtime_rel, "frames": 1, "frame_size": [4, 3], "sha256": digest, "provenance": "authored", "source_asset": None}
    }}}}), encoding="utf-8")
    result = AssetReviewService(root, catalog_path=catalog_path).representations("review_static", "icon")
    check(any(item.kind == "staged" and item.trusted for item in result.representations), "global plan error suppressed an individually resolved staged source")
    check(any("broken.png" in issue for issue in result.diagnostics), "malformed neighbor was not diagnosed")
    check(any("LFS OBJECT NOT HYDRATED" in issue and "lfs.png" in issue for issue in result.diagnostics), "staged LFS pointer was not diagnosed")
    runtime_item = next(item for item in result.representations if item.kind == "runtime")
    check(runtime_item.trusted and runtime_item.frame_count == 1, "valid catalog runtime was not trusted")
    runtime.write_bytes(runtime.read_bytes() + b"tamper")
    result = AssetReviewService(root, catalog_path=catalog_path).representations("review_static", "icon")
    runtime_item = next(item for item in result.representations if item.kind == "runtime")
    check(not runtime_item.trusted and any("SHA-256 mismatch" in issue for issue in runtime_item.diagnostics), "runtime hash mismatch was previewable")
    catalog = json.loads(catalog_path.read_text())
    entry = catalog["families"]["review_static"]["assets"]["icon::omni"]
    entry["sha256"] = hashlib.sha256(runtime.read_bytes()).hexdigest()
    entry["frames"] = 2
    catalog_path.write_text(json.dumps(catalog))
    result = AssetReviewService(root, catalog_path=catalog_path).representations("review_static", "icon")
    runtime_item = next(item for item in result.representations if item.kind == "runtime")
    check(not runtime_item.trusted and any("frame contract mismatch" in issue for issue in runtime_item.diagnostics), "runtime state frame contract mismatch was previewable")
    pointer_data = b"version https://git-lfs.github.com/spec/v1\noid sha256:" + b"c" * 64 + b"\nsize 4\n"
    runtime.write_bytes(pointer_data)
    entry["frames"] = 1
    entry["sha256"] = hashlib.sha256(pointer_data).hexdigest()
    catalog_path.write_text(json.dumps(catalog))
    result = AssetReviewService(root, catalog_path=catalog_path).representations("review_static", "icon")
    runtime_item = next(item for item in result.representations if item.kind == "runtime")
    check(not runtime_item.trusted and any("LFS OBJECT NOT HYDRATED" in issue for issue in runtime_item.diagnostics), "runtime LFS pointer reached Pillow or was trusted")


def check_baby_opossum() -> None:
    service = AssetReviewService()
    idle = service.representations("ambient_baby_opossum", "idle_south").representations
    check(len(idle) == 4 and all(item.frame_count == 4 and item.trusted for item in idle), "Baby Opossum idle_south 4-frame directions are incomplete/untrusted")
    check({item.provenance for item in idle} == {"authored", "mirrored"}, "authored and mirrored runtime provenance is missing")
    hold = service.representations("ambient_baby_opossum", "hide_hold").representations
    groom = service.representations("ambient_baby_opossum", "groom").representations
    check(len(hold) == 1 and hold[0].frame_count == 1 and hold[0].trusted, "Baby Opossum static hold contract failed")
    check(len(groom) == 1 and groom[0].frame_count == 6 and groom[0].fps == 8 and groom[0].trusted, "Baby Opossum 6-frame/FPS contract failed")
    for item in (*idle, *hold, *groom):
        with Image.open(item.source_path) as image:
            inspection = __import__("asset_inspector").inspect_png(item.source_path, item.frame_width, item.frame_height, item.layout.value, item.columns, item.rows)
            check(len(extract_frames(item.source_path, inspection)) == item.frame_count, f"real runtime frame extraction failed: {item.source_path}")


async def check_review_ui() -> None:
    try:
        from asset_workbench.app import AssetWorkbenchApp
        from textual_image.widget import AutoImage
    except ModuleNotFoundError as error:
        if error.name and error.name.startswith(("textual", "textual_image")):
            print("SKIP REVIEW Textual Pilot: optional raster UI dependencies are not installed")
            return
        raise
    app = AssetWorkbenchApp(service=AssetWorkbenchService(), review_service=AssetReviewService())
    async with app.run_test() as pilot:
        await pilot.pause()
        check(app.browser.select_state("ambient_baby_opossum", "idle_south"), "UI could not retain semantic selection for REVIEW")
        await pilot.click("#review-mode")
        await pilot.pause()
        check(app._review_mode and len(app._frames) == 4, "REVIEW UI did not load the selected four-frame state")
        check(app.query_one("#review-image", AutoImage).image is not None, "REVIEW UI did not render a native raster frame")
        check("Frame 1 / 4" in str(app.query_one("#frame-status").renderable), "REVIEW frame status is out of sync")
        app.query_one("#frame-select").value = "2"
        await pilot.pause()
        check(app._frame_index == 2, "filmstrip frame selection did not update the active frame")
        strip = app.query_one("#filmstrip-image")
        await pilot.click(strip, offset=(max(0, strip.size.width - 1), 1))
        await pilot.pause()
        check(app._frame_index == 3, "clicking the filmstrip did not select the corresponding frame")
        app.query_one("#zoom").value = "2"
        await pilot.pause()
        check(app.query_one("#review-image", AutoImage).image.size == (192, 192), "UI integer zoom did not preserve exact source-pixel replication")
        await pilot.click("#play")
        await pilot.pause(0.15)
        check(app._frame_index == 0, "UI playback did not advance at declared 8 FPS timing or loop after the last frame")
        await pilot.click("#play")
        await pilot.pause()


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="asset-workbench-review-") as temporary:
        root = Path(temporary)
        check_layouts(root)
        check_fixture_authorities(root / "fixture")
    check_comparisons()
    check_baby_opossum()
    asyncio.run(check_review_ui())
    print("PASS asset workbench REVIEW layouts, trust, LFS, comparisons, and Baby Opossum contracts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
