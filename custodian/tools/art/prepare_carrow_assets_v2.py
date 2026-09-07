#!/usr/bin/env python3
"""
CUSTODIAN
Carrow Yard / District Transfer Frame
Asset Pipeline V2 production-prep tool.

BOUNDARY:

    asset_drop/source_work/
            ↓
    THIS SCRIPT
            ↓
    asset_drop/production_prep/carrow_yard_v2/
            ↓ review
    Codex stages approved files into:
    asset_drop/inbox/<family>/
            ↓
    Asset Pipeline V2

This script NEVER writes directly into content/ runtime authority.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import subprocess
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ALPHA_CUTOFF = 16
COMPONENT_MIN_AREA = 100
WALL_SCALE = 0.5

REPO_ROOT = Path(__file__).resolve().parents[3]

DEFAULT_SOURCE_DIR = (
    REPO_ROOT
    / "custodian"
    / "asset_drop"
    / "source_work"
    / "district_transfer_frame"
)

DEFAULT_PREP_DIR = (
    REPO_ROOT
    / "custodian"
    / "asset_drop"
    / "production_prep"
    / "carrow_yard_v2"
)


# ============================================================================
# Source aliases
# ============================================================================

SOURCES = {
    "frame_body": [
        "district_transfer_frame_body_v1.png",
    ],
    "threshold": [
        "district_transfer_frame_threshold_v1.png",
    ],
    "contact_shadow": [
        "district_transfer_contact_shadow_v1.png",
        "district_transfer_frame_body_contact_shadow_v1.png",
    ],
    "aperture": [
        "district_transfer_frame_aperture_v1_8f.png",
    ],
    "boot": [
        "district_transfer_frame_boot_v1_6f.png",
        "district_transfer_frame_boot_v1_6f.png.png",
    ],
    "failure": [
        "district_transfer_frame_failure_v1_6f.png",
        "district_transfer_frame_failure_v1_6f_96x160.png.png",
    ],
    "emissive": [
        "district_transfer_frame_emissive_v1_4f.png",
        "district_transfer_frame_emmisive_v1_4f.png",
    ],
    "pedestal": [
        "district_transfer_pedestal_v1.png",
        "district_transfer_frame_pedestal_v1.png",
    ],
    "pedestal_screen": [
        "district_transfer_pedestal_screen_v1_4f.png",
        "district_transfer_frame_pedestal_screen_v1_4f.png",
    ],
    "route_plate": [
        "district_transfer_route_plate_v1.png",
        "district_transfer_route_plate_v1_96x32.png",
    ],
    "cable_pair": [
        "district_transfer_cable_feed_pair_v1.png",
        "district_transfer_cable_feed_pair_v1_192x128.png",
    ],
    "service_junction": [
        "district_transfer_service_junction_v1.png",
        "district_transfer_service_junction_v1_64x64.png",
    ],

    # Machine House
    "machine_entry": [
        "carrow_machine_house_entry_v1.png",
        "carrow_machine_house_entry_v1_192x128.png",
    ],
    "machine_floor": [
        "carrow_machine_house_floor_v1_32.png",
    ],
    "machine_wall": [
        "carrow_machine_house_wall_v1_32.png",
    ],
    "relay_bank": [
        "carrow_machine_house_relay_bank_v1.png",
        "carrow_machine_house_relay_bank_v1_160x96.png",
    ],
    "service_props": [
        "carrow_machine_house_service_props_v1.png",
        "carrow_machine_house_service_props_v1_256x192.png",
    ],
    "switchgear": [
        "carrow_machine_house_switchgear_v1.png",
        "carrow_machine_house_switchgear_v1_128x96.png",
    ],
}


# ============================================================================
# Semantic floor map
# ============================================================================

FLOOR_NAMES = [
    [
        "slab_plain_01",
        "slab_worn_01",
        "slab_cracked_01",
        "slab_cracked_02",
        "slab_oil_01",
        "slab_pocked_01",
        "slab_scuffed_01",
        "slab_oil_02",
    ],
    [
        "tread_01",
        "tread_worn_01",
        "tread_scuffed_01",
        "tread_hazard_left_01",
        "tread_hazard_right_01",
        "panel_bolted_01",
        "access_panel_01",
        "grate_horizontal_01",
    ],
    [
        "grate_horizontal_02",
        "grate_vertical_01",
        "grate_grid_01",
        "grate_honeycomb_01",
        "grate_slots_01",
        "grate_slots_02",
        "drain_square_01",
        "indicator_panel_01",
    ],
    [
        "conduit_horizontal_01",
        "conduit_vertical_01",
        "conduit_corner_01",
        "conduit_t_01",
        "conduit_cross_01",
        "conduit_clamp_horizontal_01",
        "conduit_indicator_vertical_01",
        "conduit_indicator_edge_01",
    ],
    [
        "edge_plain_01",
        "conduit_vertical_02",
        "conduit_corner_02",
        "conduit_t_02",
        "conduit_cross_02",
        "conduit_clamp_horizontal_02",
        "conduit_indicator_vertical_02",
        "conduit_indicator_edge_02",
    ],
    [
        "edge_vent_corner_01",
        "edge_vent_horizontal_01",
        "edge_vent_corner_02",
        "edge_vent_vertical_01",
        "edge_bevel_01",
        "drain_round_01",
        "access_panel_02",
        "hazard_diagonal_01",
    ],
    [
        "marking_line_01",
        "marking_cross_01",
        "marking_corner_01",
        "marking_bracket_01",
        "hazard_diagonal_02",
        "socket_small_01",
        "hatch_small_01",
        "slot_small_01",
    ],
    [
        "conduit_port_01",
        "conduit_vertical_clamp_01",
        "conduit_horizontal_clamp_01",
        "vent_square_01",
        "vent_triple_01",
        "indicator_quad_01",
        "brace_x_01",
        "service_panel_01",
    ],
]


# ============================================================================
# Wall semantic map
#
# This corresponds to the reviewed extraction ordering you just showed.
# The source r/c provenance is retained in handoff.json.
# ============================================================================

WALL_NAMES = {
    "r01_c01": "wall_run_panelled_long_01",
    "r01_c02": "wall_run_conduit_long_01",
    "r01_c03": "wall_run_panelled_medium_01",
    "r01_c04": "wall_run_breached_long_01",

    "r02_c01": "corner_block_01",
    "r02_c02": "corner_block_02",
    "r02_c03": "pillar_lit_01",
    "r02_c04": "pillar_plain_01",
    "r02_c05": "pillar_return_01",
    "r02_c06": "pillar_plain_02",
    "r02_c07": "pillar_plain_03",
    "r02_c08": "pillar_return_02",
    "r02_c09": "recess_vent_01",
    "r02_c10": "recess_vent_02",
    "r02_c11": "endcap_tall_01",

    "r03_c01": "doorframe_wide_01",
    "r03_c02": "doorframe_recessed_01",
    "r03_c03": "doorframe_narrow_01",
    "r03_c04": "post_narrow_01",
    "r03_c05": "wall_panel_medium_01",
    "r03_c06": "wall_panel_long_01",
    "r03_c07": "doorframe_wide_02",

    "r04_c01": "control_bay_01",
    "r04_c02": "machine_bay_01",
    "r04_c03": "conduit_bay_01",
    "r04_c04": "vent_pipe_bay_01",
    "r04_c05": "fan_bay_01",

    "r05_c01": "vent_wall_wide_01",
    "r05_c02": "vent_wall_medium_01",
    "r05_c03": "utility_panel_small_01",
    "r05_c04": "damaged_wall_light_01",
    "r05_c05": "breach_heavy_01",
    "r05_c06": "cracked_pillar_01",
    "r05_c07": "rounded_pillar_01",
    "r05_c08": "rubble_01",
    "r05_c09": "short_bridge_01",
    "r05_c10": "post_narrow_02",
    "r05_c11": "post_narrow_03",

    "r06_c01": "low_wall_long_01",
    "r06_c02": "low_wall_medium_01",
    "r06_c03": "low_wall_long_02",
    "r06_c04": "low_wall_short_01",
    "r06_c05": "low_wall_short_02",
    "r06_c06": "low_wall_endcap_01",
    "r06_c07": "low_wall_vent_01",
    "r06_c08": "bollard_lit_01",
    "r06_c09": "low_post_01",
    "r06_c10": "low_endcap_02",
    "r06_c11": "cap_small_01",
}


PROP_SPECS = [
    ("parts_locker", 0, 0, (64, 96)),
    ("service_cabinet", 0, 1, (96, 64)),
    ("workbench", 0, 2, (128, 96)),
    ("tool_board", 0, 3, (96, 64)),
    ("maintenance_cart", 1, 0, (96, 96)),
    ("power_cabinet", 1, 1, (64, 96)),
    ("conduit_junction", 1, 2, (64, 64)),
    ("replacement_modules", 1, 3, (64, 96)),
]


# ============================================================================
# Helpers
# ============================================================================

@dataclass
class Component:
    bbox: tuple[int, int, int, int]
    area: int

    @property
    def cx(self) -> float:
        return (self.bbox[0] + self.bbox[2]) / 2.0

    @property
    def cy(self) -> float:
        return (self.bbox[1] + self.bbox[3]) / 2.0


def find_source(root: Path, key: str) -> Path:
    for filename in SOURCES[key]:
        path = root / filename
        if path.exists():
            return path

    expected = "\n  ".join(SOURCES[key])

    raise FileNotFoundError(
        f"Missing source '{key}'. Tried:\n  {expected}"
    )


def sha256(path: Path) -> str:
    h = hashlib.sha256()

    with path.open("rb") as handle:
        for chunk in iter(
            lambda: handle.read(1024 * 1024),
            b"",
        ):
            h.update(chunk)

    return h.hexdigest()


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def zero_matte(image: Image.Image) -> Image.Image:
    arr = np.array(image, dtype=np.uint8).copy()

    alpha = arr[:, :, 3]
    alpha[alpha <= ALPHA_CUTOFF] = 0
    arr[:, :, 3] = alpha

    return Image.fromarray(arr, "RGBA")


def harden_alpha(image: Image.Image) -> Image.Image:
    arr = np.array(image, dtype=np.uint8).copy()

    arr[:, :, 3] = np.where(
        arr[:, :, 3] > ALPHA_CUTOFF,
        255,
        0,
    ).astype(np.uint8)

    return Image.fromarray(arr, "RGBA")


def alpha_bbox(image: Image.Image):
    alpha = np.array(image.getchannel("A"))
    ys, xs = np.nonzero(alpha > ALPHA_CUTOFF)

    if len(xs) == 0:
        return None

    return (
        int(xs.min()),
        int(ys.min()),
        int(xs.max()) + 1,
        int(ys.max()) + 1,
    )


def trim_alpha(image: Image.Image) -> Image.Image:
    bbox = alpha_bbox(image)

    if bbox is None:
        return image

    return image.crop(bbox)


def fit_canvas(
    image: Image.Image,
    size: tuple[int, int],
    *,
    hard_alpha: bool,
    bottom_align: bool = True,
) -> Image.Image:
    target_w, target_h = size

    image = trim_alpha(zero_matte(image))

    if image.width == 0 or image.height == 0:
        return Image.new(
            "RGBA",
            size,
            (0, 0, 0, 0),
        )

    scale = min(
        target_w / image.width,
        target_h / image.height,
    )

    width = max(1, round(image.width * scale))
    height = max(1, round(image.height * scale))

    image = image.resize(
        (width, height),
        Image.Resampling.LANCZOS,
    )

    image = zero_matte(image)

    if hard_alpha:
        image = harden_alpha(image)

    canvas = Image.new(
        "RGBA",
        size,
        (0, 0, 0, 0),
    )

    x = (target_w - width) // 2
    y = (
        target_h - height
        if bottom_align
        else (target_h - height) // 2
    )

    canvas.alpha_composite(image, (x, y))

    return canvas


def grid_cells(
    image: Image.Image,
    cols: int,
    rows: int,
) -> list[Image.Image]:
    cells = []

    for row in range(rows):
        y1 = round(row * image.height / rows)
        y2 = round((row + 1) * image.height / rows)

        for col in range(cols):
            x1 = round(col * image.width / cols)
            x2 = round((col + 1) * image.width / cols)

            cells.append(
                image.crop((x1, y1, x2, y2))
            )

    return cells


def registered_grid_strip(
    image: Image.Image,
    cols: int,
    rows: int,
    frame_size: tuple[int, int],
) -> Image.Image:
    """
    Important production fix:

    Find one shared crop box across all frames rather than trimming each
    independently. This prevents generated animation frames from drifting.
    """

    cells = [
        zero_matte(cell)
        for cell in grid_cells(image, cols, rows)
    ]

    boxes = [
        alpha_bbox(cell)
        for cell in cells
    ]

    boxes = [
        box
        for box in boxes
        if box is not None
    ]

    if not boxes:
        raise RuntimeError("Animation has no visible frames.")

    union = (
        min(b[0] for b in boxes),
        min(b[1] for b in boxes),
        max(b[2] for b in boxes),
        max(b[3] for b in boxes),
    )

    frame_w, frame_h = frame_size

    cropped = [
        cell.crop(union)
        for cell in cells
    ]

    max_w = union[2] - union[0]
    max_h = union[3] - union[1]

    scale = min(
        frame_w / max_w,
        frame_h / max_h,
    )

    scaled_w = max(1, round(max_w * scale))
    scaled_h = max(1, round(max_h * scale))

    frames = []

    for cell in cropped:
        cell = cell.resize(
            (scaled_w, scaled_h),
            Image.Resampling.LANCZOS,
        )

        cell = zero_matte(cell)

        canvas = Image.new(
            "RGBA",
            frame_size,
            (0, 0, 0, 0),
        )

        x = (frame_w - scaled_w) // 2
        y = (frame_h - scaled_h) // 2

        canvas.alpha_composite(cell, (x, y))

        frames.append(canvas)

    strip = Image.new(
        "RGBA",
        (frame_w * len(frames), frame_h),
        (0, 0, 0, 0),
    )

    for index, frame in enumerate(frames):
        strip.alpha_composite(
            frame,
            (index * frame_w, 0),
        )

    return strip


def detect_components(image: Image.Image):
    alpha = np.array(image.getchannel("A"))
    mask = alpha > ALPHA_CUTOFF

    labels, _ = ndimage.label(mask)
    slices = ndimage.find_objects(labels)

    components = []

    for label_index, sl in enumerate(
        slices,
        start=1,
    ):
        if sl is None:
            continue

        ys, xs = sl

        area = int(
            np.count_nonzero(
                labels[sl] == label_index
            )
        )

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


def cluster_rows(
    components: list[Component],
    expected_rows: int,
):
    ordered = sorted(
        components,
        key=lambda component: component.cy,
    )

    centers = np.array(
        [component.cy for component in ordered],
        dtype=float,
    )

    gap_count = expected_rows - 1

    if gap_count <= 0:
        return [
            sorted(
                ordered,
                key=lambda component: component.cx,
            )
        ]

    gaps = np.diff(centers)

    cuts = set(
        int(index)
        for index in np.argsort(gaps)[-gap_count:]
    )

    rows = []
    current = []

    for index, component in enumerate(ordered):
        current.append(component)

        if index in cuts:
            rows.append(
                sorted(
                    current,
                    key=lambda component: component.cx,
                )
            )
            current = []

    if current:
        rows.append(
            sorted(
                current,
                key=lambda component: component.cx,
            )
        )

    rows.sort(
        key=lambda row: sum(
            component.cy
            for component in row
        ) / len(row)
    )

    return rows


def pad_multiple_32(
    image: Image.Image,
) -> Image.Image:
    width = math.ceil(image.width / 32) * 32
    height = math.ceil(image.height / 32) * 32

    canvas = Image.new(
        "RGBA",
        (width, height),
        (0, 0, 0, 0),
    )

    # Wall pieces are grounded architecture.
    x = (width - image.width) // 2
    y = height - image.height

    canvas.alpha_composite(image, (x, y))

    return canvas


def save_state(
    family_dir: Path,
    state: str,
    image: Image.Image,
):
    family_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    path = family_dir / f"{state}.png"

    image.save(path)

    return path


# ============================================================================
# Family contract builders
# ============================================================================

def static_state(
    layer: str,
    group: str,
    variant: str,
    size: tuple[int, int],
    *,
    required: bool = True,
):
    return {
        "required": required,
        "layer": layer,
        "action_group": group,
        "variant": variant,
        "layout": "copy",
        "frame_width": size[0],
        "frame_height": size[1],
        "frames": 1,
    }


def animated_state(
    layer: str,
    group: str,
    variant: str,
    size: tuple[int, int],
    frames: int,
    fps: float,
):
    return {
        "required": True,
        "layer": layer,
        "action_group": group,
        "variant": variant,
        "layout": "horizontal_strip",
        "animation": True,
        "frames": frames,
        "fps": fps,
        "frame_width": size[0],
        "frame_height": size[1],
    }


def transfer_contract():
    states = {
        "body": static_state(
            "body", "structure", "body",
            (192, 256),
        ),
        "threshold": static_state(
            "body", "structure", "threshold",
            (160, 96),
        ),
        "contact_shadow": static_state(
            "fx", "structure", "contact_shadow",
            (192, 96),
        ),

        "aperture_loop": animated_state(
            "fx", "interaction", "aperture_loop",
            (96, 160), 8, 7,
        ),
        "boot": animated_state(
            "fx", "interaction", "boot",
            (96, 160), 6, 9,
        ),
        "failure": animated_state(
            "fx", "interaction", "failure",
            (96, 160), 6, 8,
        ),

        "emissive_dead": static_state(
            "fx", "state", "emissive_dead",
            (192, 256),
        ),
        "emissive_standby": static_state(
            "fx", "state", "emissive_standby",
            (192, 256),
        ),
        "emissive_acquiring": static_state(
            "fx", "state", "emissive_acquiring",
            (192, 256),
        ),
        "emissive_active": static_state(
            "fx", "state", "emissive_active",
            (192, 256),
        ),

        "pedestal": static_state(
            "body", "control", "pedestal",
            (64, 96),
        ),
        "pedestal_screen_off": static_state(
            "fx", "control", "screen_off",
            (32, 32),
        ),
        "pedestal_screen_ready": static_state(
            "fx", "control", "screen_ready",
            (32, 32),
        ),
        "pedestal_screen_acquiring": static_state(
            "fx", "control", "screen_acquiring",
            (32, 32),
        ),
        "pedestal_screen_active": static_state(
            "fx", "control", "screen_active",
            (32, 32),
        ),

        "route_plate": static_state(
            "body", "control", "route_plate",
            (96, 32),
        ),
        "service_junction": static_state(
            "body", "control", "service_junction",
            (64, 64),
        ),
        "cable_feed_left": static_state(
            "body", "dressing", "cable_feed_left",
            (96, 128),
        ),
        "cable_feed_right": static_state(
            "body", "dressing", "cable_feed_right",
            (96, 128),
        ),
    }

    return {
        "schema": "custodian.asset_family.v2",
        "id": "district_transfer_frame",
        "kind": "world_prop",
        "runtime": {
            "domain": "sprites/environment/structure",
            "owner": "district_transfer_frame",
            "template":
                "{domain}/{owner}/runtime/"
                "{layer}/{action_group}/{filename}",
            "filename_policy": "template",
            "filename_template":
                "{owner}__{layer}__{action_group}__"
                "{variant}__{direction}__{frames}f__"
                "{frame_width}x{frame_height}.png",
        },
        "canvas": {
            "width": 192,
            "height": 256,
        },
        "direction_policy": "omni",
        "auto_mirror": False,
        "states": states,
        "aliases": {},
        "consumers": [],
    }


def floor_contract():
    states = {}

    for row in FLOOR_NAMES:
        for name in row:
            states[name] = static_state(
                "body",
                "tile",
                name,
                (32, 32),
            )

    return {
        "schema": "custodian.asset_family.v2",
        "id": "carrow_machine_house_floor",
        "kind": "tile",
        "runtime": {
            "domain": "tiles/interiors/runtime",
            "owner": "carrow_machine_house_floor",
            "template": "{domain}/{filename}",
            "filename_policy": "template",
            "filename_template":
                "floor_carrow_{variant}_32.png",
        },
        "canvas": {
            "width": 32,
            "height": 32,
        },
        "direction_policy": "omni",
        "auto_mirror": False,
        "states": states,
        "aliases": {},
        "consumers": [],
    }


def wall_contract(
    sizes: dict[str, tuple[int, int]],
):
    states = {}

    for variant, size in sizes.items():
        states[variant] = static_state(
            "body",
            "structure",
            variant,
            size,
        )

    return {
        "schema": "custodian.asset_family.v2",
        "id": "carrow_machine_house_walls",
        "kind": "world_prop",
        "runtime": {
            "domain":
                "sprites/environment/structure/"
                "carrow_machine_house",
            "owner": "carrow_machine_house_walls",
            "template":
                "{domain}/runtime/walls/{filename}",
            "filename_policy": "template",
            "filename_template":
                "wall_carrow_{variant}.png",
        },
        "canvas": {
            "width": 32,
            "height": 32,
        },
        "direction_policy": "omni",
        "auto_mirror": False,
        "states": states,
        "aliases": {},
        "consumers": [],
    }


def props_contract(
    sizes: dict[str, tuple[int, int]],
):
    states = {}

    for variant, size in sizes.items():
        states[variant] = static_state(
            "body",
            "structure",
            variant,
            size,
        )

    return {
        "schema": "custodian.asset_family.v2",
        "id": "carrow_machine_house_props",
        "kind": "world_prop",
        "runtime": {
            "domain":
                "sprites/environment/structure/"
                "carrow_machine_house",
            "owner": "carrow_machine_house_props",
            "template":
                "{domain}/runtime/props/{filename}",
            "filename_policy": "template",
            "filename_template":
                "carrow_machine_house_{variant}.png",
        },
        "canvas": {
            "width": 64,
            "height": 96,
        },
        "direction_policy": "omni",
        "auto_mirror": False,
        "states": states,
        "aliases": {},
        "consumers": [],
    }


# ============================================================================
# Transfer Frame preparation
# ============================================================================

def prepare_transfer(
    source_dir: Path,
    family_dir: Path,
):
    produced = {}

    static_specs = {
        "body": (
            "frame_body",
            (192, 256),
            True,
        ),
        "threshold": (
            "threshold",
            (160, 96),
            True,
        ),
        "contact_shadow": (
            "contact_shadow",
            (192, 96),
            False,
        ),
        "pedestal": (
            "pedestal",
            (64, 96),
            True,
        ),
        "route_plate": (
            "route_plate",
            (96, 32),
            True,
        ),
        "service_junction": (
            "service_junction",
            (64, 64),
            True,
        ),
    }

    for state, (
        source_key,
        size,
        hard_alpha,
    ) in static_specs.items():

        source = find_source(
            source_dir,
            source_key,
        )

        output = fit_canvas(
            load_rgba(source),
            size,
            hard_alpha=hard_alpha,
            bottom_align=state != "contact_shadow",
        )

        path = save_state(
            family_dir,
            state,
            output,
        )

        produced[state] = path

    animation_specs = {
        "aperture_loop": (
            "aperture",
            4, 2,
            (96, 160),
        ),
        "boot": (
            "boot",
            3, 2,
            (96, 160),
        ),
        "failure": (
            "failure",
            6, 1,
            (96, 160),
        ),
    }

    for state, (
        source_key,
        cols,
        rows,
        frame_size,
    ) in animation_specs.items():

        source = find_source(
            source_dir,
            source_key,
        )

        strip = registered_grid_strip(
            load_rgba(source),
            cols,
            rows,
            frame_size,
        )

        path = save_state(
            family_dir,
            state,
            strip,
        )

        produced[state] = path

    # Emissive sheet: selectable machine states, NOT animation.
    emissive_source = load_rgba(
        find_source(
            source_dir,
            "emissive",
        )
    )

    emissive_cells = grid_cells(
        emissive_source,
        4,
        1,
    )

    emissive_states = [
        "emissive_dead",
        "emissive_standby",
        "emissive_acquiring",
        "emissive_active",
    ]

    for state, cell in zip(
        emissive_states,
        emissive_cells,
        strict=True,
    ):
        output = fit_canvas(
            cell,
            (192, 256),
            hard_alpha=False,
            bottom_align=True,
        )

        produced[state] = save_state(
            family_dir,
            state,
            output,
        )

    # Screen sheet: selectable display states, NOT animation.
    screen_source = load_rgba(
        find_source(
            source_dir,
            "pedestal_screen",
        )
    )

    screen_cells = grid_cells(
        screen_source,
        2,
        2,
    )

    screen_states = [
        "pedestal_screen_off",
        "pedestal_screen_ready",
        "pedestal_screen_acquiring",
        "pedestal_screen_active",
    ]

    for state, cell in zip(
        screen_states,
        screen_cells,
        strict=True,
    ):
        output = fit_canvas(
            cell,
            (32, 32),
            hard_alpha=False,
            bottom_align=False,
        )

        produced[state] = save_state(
            family_dir,
            state,
            output,
        )

    # Cable sheet: two distinct props, not animation.
    cable_source = load_rgba(
        find_source(
            source_dir,
            "cable_pair",
        )
    )

    cable_cells = grid_cells(
        cable_source,
        2,
        1,
    )

    for state, cell in zip(
        [
            "cable_feed_left",
            "cable_feed_right",
        ],
        cable_cells,
        strict=True,
    ):
        output = fit_canvas(
            cell,
            (96, 128),
            hard_alpha=True,
            bottom_align=True,
        )

        produced[state] = save_state(
            family_dir,
            state,
            output,
        )

    return produced


# ============================================================================
# Floor preparation
# ============================================================================

def prepare_floor(
    source_dir: Path,
    family_dir: Path,
):
    source = zero_matte(
        load_rgba(
            find_source(
                source_dir,
                "machine_floor",
            )
        )
    )

    components = detect_components(source)

    if len(components) != 64:
        raise RuntimeError(
            f"Expected 64 floor components, "
            f"found {len(components)}."
        )

    rows = cluster_rows(
        components,
        8,
    )

    if (
        len(rows) != 8
        or any(len(row) != 8 for row in rows)
    ):
        raise RuntimeError(
            "Floor did not resolve to 8x8."
        )

    produced = {}

    for row_index, row in enumerate(rows):
        for col_index, component in enumerate(row):
            state = FLOOR_NAMES[
                row_index
            ][col_index]

            sprite = crop_component(
                source,
                component,
            )

            sprite = fit_canvas(
                sprite,
                (32, 32),
                hard_alpha=True,
                bottom_align=False,
            )

            produced[state] = save_state(
                family_dir,
                state,
                sprite,
            )

    return produced


# ============================================================================
# Wall preparation
# ============================================================================

def prepare_walls(
    source_dir: Path,
    family_dir: Path,
):
    source = zero_matte(
        load_rgba(
            find_source(
                source_dir,
                "machine_wall",
            )
        )
    )

    components = detect_components(source)

    if len(components) != 49:
        raise RuntimeError(
            f"Expected 49 wall components, "
            f"found {len(components)}."
        )

    rows = cluster_rows(
        components,
        6,
    )

    expected_counts = [4, 11, 7, 5, 11, 11]

    if [
        len(row)
        for row in rows
    ] != expected_counts:
        raise RuntimeError(
            "Wall row topology changed. "
            f"Expected {expected_counts}, "
            f"found {[len(row) for row in rows]}."
        )

    produced = {}
    provenance = {}

    for row_index, row in enumerate(
        rows,
        start=1,
    ):
        for col_index, component in enumerate(
            row,
            start=1,
        ):
            source_id = (
                f"r{row_index:02d}_"
                f"c{col_index:02d}"
            )

            state = WALL_NAMES[source_id]

            sprite = crop_component(
                source,
                component,
                padding=1,
            )

            width = max(
                1,
                round(sprite.width * WALL_SCALE),
            )
            height = max(
                1,
                round(sprite.height * WALL_SCALE),
            )

            sprite = sprite.resize(
                (width, height),
                Image.Resampling.LANCZOS,
            )

            sprite = harden_alpha(
                zero_matte(sprite)
            )

            # Preserve the global 0.5x visual scale.
            # Only add transparent padding to 32px grid.
            sprite = pad_multiple_32(sprite)

            produced[state] = save_state(
                family_dir,
                state,
                sprite,
            )

            provenance[state] = {
                "source_id": source_id,
                "source_bbox": list(
                    component.bbox
                ),
                "runtime_size": list(
                    sprite.size
                ),
                "footprint_cells": [
                    sprite.width // 32,
                    sprite.height // 32,
                ],
            }

    return produced, provenance


# ============================================================================
# Machine House props
# ============================================================================

def prepare_props(
    source_dir: Path,
    family_dir: Path,
):
    produced = {}
    sizes = {}

    hero_specs = {
        "entry": (
            "machine_entry",
            (192, 128),
        ),
        "relay_bank": (
            "relay_bank",
            (160, 96),
        ),
        "switchgear": (
            "switchgear",
            (128, 96),
        ),
    }

    for state, (
        source_key,
        size,
    ) in hero_specs.items():

        source = load_rgba(
            find_source(
                source_dir,
                source_key,
            )
        )

        output = fit_canvas(
            source,
            size,
            hard_alpha=True,
            bottom_align=True,
        )

        produced[state] = save_state(
            family_dir,
            state,
            output,
        )

        sizes[state] = size

    source = zero_matte(
        load_rgba(
            find_source(
                source_dir,
                "service_props",
            )
        )
    )

    components = detect_components(source)

    if len(components) != 8:
        raise RuntimeError(
            f"Expected 8 service props, "
            f"found {len(components)}."
        )

    rows = cluster_rows(
        components,
        2,
    )

    if (
        len(rows) != 2
        or any(len(row) != 4 for row in rows)
    ):
        raise RuntimeError(
            "Service props did not resolve "
            "to 2 rows of 4."
        )

    for (
        state,
        row_index,
        col_index,
        size,
    ) in PROP_SPECS:

        component = rows[
            row_index
        ][col_index]

        sprite = crop_component(
            source,
            component,
            padding=2,
        )

        sprite = fit_canvas(
            sprite,
            size,
            hard_alpha=True,
            bottom_align=True,
        )

        produced[state] = save_state(
            family_dir,
            state,
            sprite,
        )

        sizes[state] = size

    return produced, sizes


# ============================================================================
# Review / manifest
# ============================================================================

def make_contact(
    paths: list[Path],
    destination: Path,
    columns: int = 5,
):
    if not paths:
        return

    cell_w = 240
    cell_h = 190

    rows = math.ceil(
        len(paths) / columns
    )

    canvas = Image.new(
        "RGB",
        (
            columns * cell_w,
            rows * cell_h,
        ),
        (22, 22, 24),
    )

    draw = ImageDraw.Draw(canvas)

    for index, path in enumerate(paths):
        image = load_rgba(path)

        thumb = image.copy()

        thumb.thumbnail(
            (
                cell_w - 20,
                cell_h - 42,
            ),
            Image.Resampling.NEAREST,
        )

        col = index % columns
        row = index // columns

        x0 = col * cell_w
        y0 = row * cell_h

        x = (
            x0
            + (cell_w - thumb.width) // 2
        )

        y = y0 + 5

        temp = Image.new(
            "RGBA",
            canvas.size,
            (0, 0, 0, 0),
        )

        temp.alpha_composite(
            thumb,
            (x, y),
        )

        canvas.paste(
            temp.convert("RGB"),
            mask=temp.getchannel("A"),
        )

        draw.text(
            (
                x0 + 6,
                y0 + cell_h - 28,
            ),
            path.stem,
            fill=(225, 225, 225),
        )

    destination.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    canvas.save(destination)


def write_json(
    path: Path,
    payload,
):
    path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    path.write_text(
        json.dumps(
            payload,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def record_family(
    family_id: str,
    files: dict[str, Path],
):
    return {
        "family": family_id,
        "inbox":
            f"custodian/asset_drop/inbox/"
            f"{family_id}",
        "files": {
            state: {
                "prep_path":
                    str(
                        path.relative_to(
                            REPO_ROOT
                        )
                    ),
                "inbox_name":
                    f"{state}.png",
                "sha256":
                    sha256(path),
                "size":
                    list(
                        load_rgba(path).size
                    ),
            }
            for state, path
            in sorted(files.items())
        },
    }


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--source-dir",
        type=Path,
        default=DEFAULT_SOURCE_DIR,
    )

    parser.add_argument(
        "--prep-dir",
        type=Path,
        default=DEFAULT_PREP_DIR,
    )

    parser.add_argument(
        "--review",
        action="store_true",
    )

    args = parser.parse_args()

    source_dir = args.source_dir.resolve()
    prep_dir = args.prep_dir.resolve()

    families_dir = prep_dir / "families"
    contracts_dir = prep_dir / "contracts"
    review_dir = prep_dir / "review"

    transfer_files = prepare_transfer(
        source_dir,
        families_dir
        / "district_transfer_frame",
    )

    floor_files = prepare_floor(
        source_dir,
        families_dir
        / "carrow_machine_house_floor",
    )

    wall_files, wall_provenance = (
        prepare_walls(
            source_dir,
            families_dir
            / "carrow_machine_house_walls",
        )
    )

    prop_files, prop_sizes = (
        prepare_props(
            source_dir,
            families_dir
            / "carrow_machine_house_props",
        )
    )

    wall_sizes = {
        state: load_rgba(path).size
        for state, path
        in wall_files.items()
    }

    contracts = {
        "district_transfer_frame":
            transfer_contract(),

        "carrow_machine_house_floor":
            floor_contract(),

        "carrow_machine_house_walls":
            wall_contract(
                wall_sizes
            ),

        "carrow_machine_house_props":
            props_contract(
                prop_sizes
            ),
    }

    for family_id, contract in contracts.items():
        write_json(
            contracts_dir
            / f"{family_id}.asset.json",
            contract,
        )

    handoff = {
        "schema":
            "custodian.carrow_asset_v2_handoff.v1",

        "source_root":
            str(
                source_dir.relative_to(
                    REPO_ROOT
                )
            ),

        "pipeline":
            "Asset Pipeline V2",

        "families": [
            record_family(
                "district_transfer_frame",
                transfer_files,
            ),
            record_family(
                "carrow_machine_house_floor",
                floor_files,
            ),
            record_family(
                "carrow_machine_house_walls",
                wall_files,
            ),
            record_family(
                "carrow_machine_house_props",
                prop_files,
            ),
        ],

        "wall_provenance":
            wall_provenance,
    }

    write_json(
        prep_dir / "handoff.json",
        handoff,
    )

    contact_paths = []

    for family_id, files in [
        (
            "district_transfer_frame",
            transfer_files,
        ),
        (
            "carrow_machine_house_floor",
            floor_files,
        ),
        (
            "carrow_machine_house_walls",
            wall_files,
        ),
        (
            "carrow_machine_house_props",
            prop_files,
        ),
    ]:
        contact = (
            review_dir
            / f"{family_id}_contact.png"
        )

        make_contact(
            list(files.values()),
            contact,
            columns=(
                8
                if family_id.endswith("floor")
                else 5
            ),
        )

        contact_paths.append(contact)

    print()
    print("Carrow Asset Pipeline V2 prep complete")
    print("-------------------------------------")
    print(f"Source: {source_dir}")
    print(f"Prep:   {prep_dir}")
    print()
    print("NO runtime files were written.")
    print("NO source masters were modified.")
    print()
    print(
        "Codex handoff:"
        f" {prep_dir / 'handoff.json'}"
    )
    print(
        "Suggested contracts:"
        f" {contracts_dir}"
    )

    if args.review:
        try:
            subprocess.Popen(
                [
                    "aseprite",
                    *[
                        str(path)
                        for path in contact_paths
                    ],
                ]
            )
        except FileNotFoundError:
            print(
                "Aseprite not found; "
                "review PNGs were still written."
            )


if __name__ == "__main__":
    main()
