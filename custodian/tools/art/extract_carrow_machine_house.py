#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ALPHA_CUTOFF = 16
COMPONENT_MIN_AREA = 100

REPO_ROOT = Path(__file__).resolve().parents[3]

DEFAULT_SOURCE_DIR = (
    REPO_ROOT / "custodian" / "asset_drop" / "source_work" / "district_transfer_frame"
)

DEFAULT_OUTPUT_DIR = (
    REPO_ROOT
    / "custodian"
    / "asset_drop"
    / "production_prep"
    / "carrow_machine_house_extract"
)


# ---------------------------------------------------------------------------
# Source filename aliases
# ---------------------------------------------------------------------------

SOURCE_NAMES = {
    "floor": [
        "carrow_machine_house_floor_v1_32.png",
    ],
    "wall": [
        "carrow_machine_house_wall_v1_32.png",
    ],
    "props": [
        "carrow_machine_house_service_props_v1_256x192.png",
        "carrow_machine_house_service_props_v1.png",
    ],
}


# ---------------------------------------------------------------------------
# Semantic prop definitions
#
# Props are identified spatially, not by connected-component enumeration order.
# ---------------------------------------------------------------------------

PROP_LAYOUT = [
    # row 1
    ("parts_locker", 0, 0, (64, 96)),
    ("service_cabinet", 0, 1, (96, 64)),
    ("workbench", 0, 2, (128, 96)),
    ("tool_board", 0, 3, (96, 64)),
    # row 2
    ("maintenance_cart", 1, 0, (96, 96)),
    ("power_cabinet", 1, 1, (64, 96)),
    ("conduit_junction", 1, 2, (64, 64)),
    ("replacement_modules", 1, 3, (64, 96)),
]


@dataclass
class Component:
    bbox: tuple[int, int, int, int]
    area: int

    @property
    def x(self) -> int:
        return self.bbox[0]

    @property
    def y(self) -> int:
        return self.bbox[1]

    @property
    def width(self) -> int:
        return self.bbox[2] - self.bbox[0]

    @property
    def height(self) -> int:
        return self.bbox[3] - self.bbox[1]

    @property
    def center_x(self) -> float:
        return (self.bbox[0] + self.bbox[2]) / 2.0

    @property
    def center_y(self) -> float:
        return (self.bbox[1] + self.bbox[3]) / 2.0


def find_source(source_dir: Path, aliases: list[str]) -> Path:
    for name in aliases:
        candidate = source_dir / name
        if candidate.exists():
            return candidate

    raise FileNotFoundError(
        "Could not find any of:\n  " + "\n  ".join(str(source_dir / n) for n in aliases)
    )


def sha256(path: Path) -> str:
    h = hashlib.sha256()

    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)

    return h.hexdigest()


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def remove_low_alpha(image: Image.Image) -> Image.Image:
    """
    Remove generator matte at alpha <= cutoff while retaining all other
    alpha values.
    """
    arr = np.array(image, dtype=np.uint8)

    alpha = arr[:, :, 3]
    alpha[alpha <= ALPHA_CUTOFF] = 0
    arr[:, :, 3] = alpha

    return Image.fromarray(arr, "RGBA")


def detect_components(image: Image.Image) -> list[Component]:
    """
    Detect alpha-connected logical sprites.
    """
    alpha = np.array(image.getchannel("A"))
    mask = alpha > ALPHA_CUTOFF

    labels, count = ndimage.label(mask)
    slices = ndimage.find_objects(labels)

    components: list[Component] = []

    for label_id, sl in enumerate(slices, start=1):
        if sl is None:
            continue

        ys, xs = sl

        area = int(np.count_nonzero(labels[sl] == label_id))

        if area < COMPONENT_MIN_AREA:
            continue

        components.append(
            Component(
                bbox=(
                    int(xs.start),
                    int(ys.start),
                    int(xs.stop),
                    int(ys.stop),
                ),
                area=area,
            )
        )

    return components


def crop_component(
    image: Image.Image,
    component: Component,
    padding: int = 0,
) -> Image.Image:
    x1, y1, x2, y2 = component.bbox

    x1 = max(0, x1 - padding)
    y1 = max(0, y1 - padding)
    x2 = min(image.width, x2 + padding)
    y2 = min(image.height, y2 + padding)

    return image.crop((x1, y1, x2, y2))


def fit_to_canvas(
    sprite: Image.Image,
    target_size: tuple[int, int],
    *,
    hard_alpha: bool = True,
) -> Image.Image:
    """
    Downsample once with Lanczos, preserving aspect ratio.
    Center result on transparent runtime canvas.
    """
    target_w, target_h = target_size

    src = sprite.copy()

    src.thumbnail(
        (target_w, target_h),
        Image.Resampling.LANCZOS,
    )

    if hard_alpha:
        arr = np.array(src)
        arr[:, :, 3] = np.where(
            arr[:, :, 3] > ALPHA_CUTOFF,
            255,
            0,
        ).astype(np.uint8)

        src = Image.fromarray(arr, "RGBA")

    canvas = Image.new(
        "RGBA",
        (target_w, target_h),
        (0, 0, 0, 0),
    )

    x = (target_w - src.width) // 2
    y = (target_h - src.height) // 2

    canvas.alpha_composite(src, (x, y))

    return canvas


def cluster_rows(
    components: list[Component],
    expected_rows: int,
) -> list[list[Component]]:
    """
    Divide components into spatial rows from center-Y.
    """
    ordered = sorted(components, key=lambda c: c.center_y)

    centers = np.array(
        [c.center_y for c in ordered],
        dtype=float,
    )

    # Find the largest gaps between Y centers.
    gaps = np.diff(centers)

    cut_count = expected_rows - 1

    if cut_count <= 0:
        return [sorted(ordered, key=lambda c: c.center_x)]

    cut_indexes = set(int(i) for i in np.argsort(gaps)[-cut_count:])

    rows: list[list[Component]] = []
    current: list[Component] = []

    for i, component in enumerate(ordered):
        current.append(component)

        if i in cut_indexes:
            rows.append(sorted(current, key=lambda c: c.center_x))
            current = []

    if current:
        rows.append(sorted(current, key=lambda c: c.center_x))

    rows.sort(key=lambda row: sum(c.center_y for c in row) / len(row))

    return rows


# ---------------------------------------------------------------------------
# FLOOR
# ---------------------------------------------------------------------------


def extract_floor(
    source: Path,
    output_root: Path,
    manifest: dict,
) -> list[Path]:
    image = remove_low_alpha(load_rgba(source))
    components = detect_components(image)

    if len(components) != 64:
        raise RuntimeError(
            f"Expected exactly 64 floor components, " f"found {len(components)}"
        )

    # The generated source is a true 8x8 logical layout.
    rows = cluster_rows(components, 8)

    if any(len(row) != 8 for row in rows):
        raise RuntimeError("Floor components did not resolve into 8 rows of 8.")

    native_dir = output_root / "floor" / "native_extract"
    runtime_dir = output_root / "floor" / "runtime_32"

    native_dir.mkdir(parents=True, exist_ok=True)
    runtime_dir.mkdir(parents=True, exist_ok=True)

    outputs: list[Path] = []

    for row_index, row in enumerate(rows, start=1):
        for col_index, component in enumerate(row, start=1):
            logical = f"r{row_index:02d}_c{col_index:02d}"

            native_name = f"floor_carrow_{logical}__native.png"
            runtime_name = f"floor_carrow_{logical}_32.png"

            sprite = crop_component(
                image,
                component,
                padding=0,
            )

            native_path = native_dir / native_name
            runtime_path = runtime_dir / runtime_name

            sprite.save(native_path)

            runtime = fit_to_canvas(
                sprite,
                (32, 32),
                hard_alpha=True,
            )
            runtime.save(runtime_path)

            manifest["outputs"].append(
                {
                    "family": "floor",
                    "logical_id": logical,
                    "source_bbox": list(component.bbox),
                    "native_size": list(sprite.size),
                    "runtime_size": [32, 32],
                    "native_path": str(native_path.relative_to(REPO_ROOT)),
                    "runtime_path": str(runtime_path.relative_to(REPO_ROOT)),
                    "sha256": sha256(runtime_path),
                }
            )

            outputs.append(runtime_path)

    return outputs


# ---------------------------------------------------------------------------
# PROPS
# ---------------------------------------------------------------------------


def extract_props(
    source: Path,
    output_root: Path,
    manifest: dict,
) -> list[Path]:
    image = remove_low_alpha(load_rgba(source))
    components = detect_components(image)

    if len(components) != 8:
        raise RuntimeError(
            f"Expected exactly 8 service-prop components, " f"found {len(components)}"
        )

    rows = cluster_rows(components, 2)

    if len(rows) != 2:
        raise RuntimeError(f"Expected two prop rows, found {len(rows)}")

    if any(len(row) != 4 for row in rows):
        raise RuntimeError("Expected four props in each row.")

    native_dir = output_root / "props" / "native_extract"
    runtime_dir = output_root / "props" / "runtime"

    native_dir.mkdir(parents=True, exist_ok=True)
    runtime_dir.mkdir(parents=True, exist_ok=True)

    outputs: list[Path] = []

    for name, row_idx, col_idx, runtime_size in PROP_LAYOUT:
        component = rows[row_idx][col_idx]

        sprite = crop_component(
            image,
            component,
            padding=2,
        )

        native_path = native_dir / f"props_carrow_{name}__native.png"
        runtime_path = runtime_dir / f"props_carrow_{name}.png"

        sprite.save(native_path)

        runtime = fit_to_canvas(
            sprite,
            runtime_size,
            hard_alpha=True,
        )
        runtime.save(runtime_path)

        manifest["outputs"].append(
            {
                "family": "props",
                "logical_id": name,
                "source_bbox": list(component.bbox),
                "native_size": list(sprite.size),
                "runtime_size": list(runtime_size),
                "native_path": str(native_path.relative_to(REPO_ROOT)),
                "runtime_path": str(runtime_path.relative_to(REPO_ROOT)),
                "sha256": sha256(runtime_path),
            }
        )

        outputs.append(runtime_path)

    return outputs


# ---------------------------------------------------------------------------
# WALL / ARCHITECTURE
# ---------------------------------------------------------------------------


def extract_walls(
    source: Path,
    output_root: Path,
    manifest: dict,
) -> list[Path]:
    image = remove_low_alpha(load_rgba(source))
    components = detect_components(image)

    if len(components) != 49:
        raise RuntimeError(
            f"Expected 49 wall/architecture components, " f"found {len(components)}"
        )

    # Wall pieces have intentionally irregular widths and footprints.
    # Preserve source geometry first. Do NOT crush all pieces into 32x32.
    #
    # The image resolves naturally into six visual rows.
    rows = cluster_rows(components, 6)

    native_dir = output_root / "walls" / "native_extract"
    preview_dir = output_root / "walls" / "runtime_preview_50pct"

    native_dir.mkdir(parents=True, exist_ok=True)
    preview_dir.mkdir(parents=True, exist_ok=True)

    outputs: list[Path] = []

    item_index = 1

    for row_index, row in enumerate(rows, start=1):
        for col_index, component in enumerate(row, start=1):
            logical = f"wall_carrow_" f"r{row_index:02d}_c{col_index:02d}"

            sprite = crop_component(
                image,
                component,
                padding=1,
            )

            native_path = native_dir / f"{logical}__native.png"

            sprite.save(native_path)

            # Review derivative only.
            #
            # We preserve architecture proportions rather than arbitrarily
            # forcing multi-cell facade pieces onto 32x32 canvases.
            preview_size = (
                max(1, round(sprite.width * 0.5)),
                max(1, round(sprite.height * 0.5)),
            )

            preview = sprite.resize(
                preview_size,
                Image.Resampling.LANCZOS,
            )

            arr = np.array(preview)

            arr[:, :, 3] = np.where(
                arr[:, :, 3] > ALPHA_CUTOFF,
                255,
                0,
            ).astype(np.uint8)

            preview = Image.fromarray(arr, "RGBA")

            preview_path = preview_dir / f"{logical}__50pct.png"

            preview.save(preview_path)

            manifest["outputs"].append(
                {
                    "family": "walls",
                    "index": item_index,
                    "logical_id": logical,
                    "source_bbox": list(component.bbox),
                    "native_size": list(sprite.size),
                    "preview_size": list(preview.size),
                    "native_path": str(native_path.relative_to(REPO_ROOT)),
                    "preview_path": str(preview_path.relative_to(REPO_ROOT)),
                    "sha256": sha256(preview_path),
                }
            )

            outputs.append(preview_path)
            item_index += 1

    return outputs


# ---------------------------------------------------------------------------
# REVIEW CONTACT SHEETS
# ---------------------------------------------------------------------------


def make_contact_sheet(
    images: list[Path],
    output: Path,
    *,
    columns: int,
    cell_size: tuple[int, int] = (160, 160),
) -> None:
    if not images:
        return

    cell_w, cell_h = cell_size

    rows = (len(images) + columns - 1) // columns

    canvas = Image.new(
        "RGBA",
        (columns * cell_w, rows * cell_h),
        (20, 20, 20, 255),
    )

    draw = ImageDraw.Draw(canvas)

    for index, path in enumerate(images):
        image = Image.open(path).convert("RGBA")

        thumb = image.copy()
        thumb.thumbnail(
            (cell_w - 16, cell_h - 30),
            Image.Resampling.NEAREST,
        )

        col = index % columns
        row = index // columns

        x0 = col * cell_w
        y0 = row * cell_h

        x = x0 + (cell_w - thumb.width) // 2
        y = y0 + 4

        canvas.alpha_composite(thumb, (x, y))

        draw.text(
            (x0 + 4, y0 + cell_h - 20),
            path.stem,
            fill=(220, 220, 220, 255),
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output)


def open_in_aseprite(paths: list[Path]) -> None:
    if not paths:
        return

    try:
        subprocess.Popen(
            ["aseprite", *map(str, paths)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        print(
            "Aseprite not found; extraction is complete, "
            "but review files were not opened."
        )


def main() -> int:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--source-dir",
        type=Path,
        default=DEFAULT_SOURCE_DIR,
    )

    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
    )

    parser.add_argument(
        "--review",
        action="store_true",
        help="Open generated contact sheets in Aseprite.",
    )

    args = parser.parse_args()

    source_dir = args.source_dir.resolve()
    output_dir = args.output_dir.resolve()

    floor_source = find_source(
        source_dir,
        SOURCE_NAMES["floor"],
    )
    wall_source = find_source(
        source_dir,
        SOURCE_NAMES["wall"],
    )
    props_source = find_source(
        source_dir,
        SOURCE_NAMES["props"],
    )

    manifest = {
        "schema": "custodian.carrow_machine_house_extract.v1",
        "alpha_cutoff": ALPHA_CUTOFF,
        "sources": {
            "floor": str(floor_source.relative_to(REPO_ROOT)),
            "walls": str(wall_source.relative_to(REPO_ROOT)),
            "props": str(props_source.relative_to(REPO_ROOT)),
        },
        "outputs": [],
    }

    print()
    print("Carrow Machine House extraction")
    print("--------------------------------")
    print(f"Source: {source_dir}")
    print(f"Output: {output_dir}")
    print()

    floor_outputs = extract_floor(
        floor_source,
        output_dir,
        manifest,
    )

    print(f"Floor: {len(floor_outputs)} extracted")

    wall_outputs = extract_walls(
        wall_source,
        output_dir,
        manifest,
    )

    print(f"Walls: {len(wall_outputs)} extracted")

    prop_outputs = extract_props(
        props_source,
        output_dir,
        manifest,
    )

    print(f"Props: {len(prop_outputs)} extracted")

    manifest_path = output_dir / "manifest.json"

    manifest_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    manifest_path.write_text(
        json.dumps(
            manifest,
            indent=2,
        )
        + "\n"
    )

    floor_contact = output_dir / "review" / "floor_runtime_contact.png"

    wall_contact = output_dir / "review" / "wall_extract_contact.png"

    props_contact = output_dir / "review" / "props_runtime_contact.png"

    make_contact_sheet(
        floor_outputs,
        floor_contact,
        columns=8,
        cell_size=(96, 96),
    )

    make_contact_sheet(
        wall_outputs,
        wall_contact,
        columns=6,
        cell_size=(220, 180),
    )

    make_contact_sheet(
        prop_outputs,
        props_contact,
        columns=4,
        cell_size=(180, 160),
    )

    print()
    print("Done.")
    print(f"Manifest: {manifest_path}")
    print()
    print("Review:")
    print(f"  {floor_contact}")
    print(f"  {wall_contact}")
    print(f"  {props_contact}")

    if args.review:
        open_in_aseprite(
            [
                floor_contact,
                wall_contact,
                props_contact,
            ]
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
