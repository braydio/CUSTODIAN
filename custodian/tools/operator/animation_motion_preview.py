"""Pure motion-calibration model and raster compositor for Operator previews."""
from __future__ import annotations

import json
import math
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

CANVAS_SIZE = (768, 384)
OPERATOR_ANCHOR = (384, 224)

CURVES = (
    "constant",
    "linear",
    "ease_in",
    "ease_out",
    "ease_in_out",
    "attack_lunge",
)

MODES = ("treadmill", "world")
CARDINAL_DIRECTIONS = ("n", "e", "s", "w")
LOOP_CYCLE_PRESETS = (2, 3, 4, 6, 8)
DISTANCE_PRESETS = (32.0, 64.0, 96.0, 128.0, 160.0, 192.0, 224.0, 256.0)

WORLD_FOLLOW_DISTANCE_PX = 96.0
RULER_STEP_PX = 32

GROUND_PRESETS_PATH = Path(__file__).with_name("motion_ground_presets.json")
GROUND_PRESET_SCHEMA = "custodian.operator_motion_ground_presets.v1"


@dataclass(frozen=True)
class GroundPreset:
    id: str
    label: str
    path: Path | None
    tile_size: tuple[int, int] = (32, 32)
    default_alpha: float = 1.0


@dataclass(frozen=True)
class MotionEventMarker:
    id: str
    label: str
    frame: int
    kind: str


@dataclass(frozen=True)
class MotionConfig:
    identity: Any
    review_fps: float = 12.0
    travel_px: float = 128.0
    curve: str = "attack_lunge"
    direction: str = "e"
    canvas_size: tuple[int, int] = CANVAS_SIZE
    ground: str = "ritualant_cavern"
    mode: str = "treadmill"
    frame_count: int = 1
    loop_cycles: int = 3


@dataclass(frozen=True)
class MotionSample:
    """One instant of motion review.

    A looping animation has two independent clocks: the ANIMATION PHASE
    (which frame is showing, always in [0, duration_sec)) and CONTINUOUS
    WORLD TRAVEL (how far the subject has gone inside the configured multi-cycle
    span). The `phase_*` fields/aliases
    describe a single cycle in isolation — this is what one-shot WORLD mode
    reviews. The `continuous_*` fields describe cumulative travel across
    however many cycles have completed — this is what TREADMILL mode's
    scrolling ground uses, so the floor does not snap at individual animation
    boundaries and resets only after `loop_cycles` cycles.
    """

    elapsed_sec: float
    duration_sec: float
    normalized: float
    frame_index: int
    progress: float
    root_displacement: tuple[float, float]
    ground_displacement: tuple[float, float]
    position_px: float
    average_speed: float
    current_speed: float
    cycle_index: int = 0
    phase_sec: float = 0.0
    continuous_position_px: float = 0.0
    continuous_root_displacement: tuple[float, float] = (0.0, 0.0)

    @property
    def phase_normalized(self) -> float:
        return self.normalized

    @property
    def phase_position_px(self) -> float:
        return self.position_px

    @property
    def phase_root_displacement(self) -> tuple[float, float]:
        return self.root_displacement


@dataclass(frozen=True)
class MotionFrame:
    image: Image.Image
    sample: MotionSample
    warnings: tuple[str, ...] = field(default_factory=tuple)


def direction_vector(direction: str) -> tuple[float, float]:
    vectors = {
        "e": (1.0, 0.0), "w": (-1.0, 0.0), "n": (0.0, -1.0),
        "s": (0.0, 1.0), "ne": (1.0, -1.0), "nw": (-1.0, -1.0),
        "se": (1.0, 1.0), "sw": (-1.0, 1.0), "omni": (1.0, 0.0),
    }
    x, y = vectors.get(direction.casefold(), vectors["e"])
    length = math.hypot(x, y)
    return x / length, y / length


def _smoothstep(value: float) -> float:
    return value * value * (3.0 - 2.0 * value)


def curve_progress(curve: str, normalized: float) -> float:
    t = min(1.0, max(0.0, normalized))
    name = curve.casefold()
    if name in ("constant", "linear"):
        return t
    if name == "ease_in":
        return t * t
    if name == "ease_out":
        return 1.0 - (1.0 - t) ** 2
    if name == "ease_in_out":
        return _smoothstep(t)
    if name == "attack_lunge":
        points = ((0.0, 0.0), (0.15, 0.03), (0.35, 0.25), (0.60, 0.72), (0.80, 0.94), (1.0, 1.0))
        for (left_t, left_c), (right_t, right_c) in zip(points, points[1:]):
            if t <= right_t:
                local = (t - left_t) / (right_t - left_t)
                return left_c + (right_c - left_c) * _smoothstep(local)
        return 1.0
    raise ValueError(f"unknown motion curve: {curve}")


def _curve_slope(curve: str, normalized: float) -> float:
    epsilon = 0.0001
    left = max(0.0, normalized - epsilon)
    right = min(1.0, normalized + epsilon)
    if right == left:
        return 0.0
    return (curve_progress(curve, right) - curve_progress(curve, left)) / (right - left)


def sample_motion(
    config: MotionConfig,
    elapsed_sec: float,
    *,
    loop: bool = False,
) -> MotionSample:
    count = max(1, int(config.frame_count))
    fps = max(0.001, float(config.review_fps))
    duration = count / fps

    elapsed = max(0.0, float(elapsed_sec))
    cycle_limit = max(1, int(config.loop_cycles))

    if loop:
        span = duration * cycle_limit
        span_elapsed = elapsed % span

        cycle_index = min(
            cycle_limit - 1,
            int(math.floor(span_elapsed / duration)),
        )
        phase_sec = span_elapsed - cycle_index * duration
    else:
        cycle_index = 0
        phase_sec = min(elapsed, duration)

    normalized = phase_sec / duration
    progress = curve_progress(config.curve, normalized)

    dx, dy = direction_vector(config.direction)
    travel = max(0.0, float(config.travel_px))

    phase_distance = travel * progress

    root = (dx * phase_distance, dy * phase_distance)
    ground = (-root[0], -root[1])

    continuous_distance = cycle_index * travel + phase_distance
    continuous_root = (dx * continuous_distance, dy * continuous_distance)

    frame = min(count - 1, int(math.floor(normalized * count)))
    average = travel / duration
    speed = travel * _curve_slope(config.curve, normalized) / duration

    return MotionSample(
        elapsed, duration, normalized, frame, progress, root, ground, phase_distance, average, speed,
        cycle_index, phase_sec, continuous_distance, continuous_root,
    )


def scrub_motion(config: MotionConfig, ratio: float) -> MotionSample:
    duration = max(1, int(config.frame_count)) / max(0.001, float(config.review_fps))
    return sample_motion(config, min(1.0, max(0.0, ratio)) * duration)


def ground_phase(displacement: tuple[float, float], tile_size: tuple[int, int]) -> tuple[int, int]:
    return int(math.floor(displacement[0])) % max(1, tile_size[0]), int(math.floor(displacement[1])) % max(1, tile_size[1])


@lru_cache(maxsize=1)
def _ground_preset_rows() -> tuple[dict[str, Any], ...]:
    payload = json.loads(GROUND_PRESETS_PATH.read_text())

    if payload.get("schema") != GROUND_PRESET_SCHEMA:
        raise RuntimeError(
            f"unsupported motion ground preset schema: "
            f"{payload.get('schema', '<missing>')}"
        )

    rows = payload.get("presets", ())
    if not isinstance(rows, list):
        raise RuntimeError("motion ground preset manifest has no presets list")

    return tuple(row for row in rows if isinstance(row, dict))


def ground_ids() -> tuple[str, ...]:
    return tuple(
        str(row["id"])
        for row in _ground_preset_rows()
        if row.get("id")
    )


def ground_preset(
    repo_root: Path,
    preset_id: str,
) -> tuple[GroundPreset, str | None]:
    rows = {
        str(row.get("id", "")): row
        for row in _ground_preset_rows()
        if row.get("id")
    }

    row = rows.get(preset_id)
    if row is None:
        return GroundPreset("grid32", "GRID 32", None), f"GROUND UNAVAILABLE: {preset_id}"

    raw_size = row.get("tile_size", (32, 32))
    tile_size = (int(raw_size[0]), int(raw_size[1]))
    label = str(row.get("label", preset_id.replace("_", " ").upper()))
    raw_path = row.get("path")

    if raw_path in (None, ""):
        return GroundPreset(preset_id, label, None, tile_size), None

    path = Path(repo_root) / str(raw_path)
    if not path.exists():
        return GroundPreset("grid32", "GRID 32", None), f"GROUND UNAVAILABLE: {path}"

    return GroundPreset(preset_id, label, path, tile_size), None


def presentation_offsets(
    config: MotionConfig,
    sample: MotionSample,
    *,
    loop: bool,
) -> tuple[tuple[float, float], tuple[float, float]]:
    """Return (world_offset, actor_offset) for treadmill or followed world presentation."""
    travel_root = sample.continuous_root_displacement if loop else sample.root_displacement
    distance = sample.continuous_position_px if loop else sample.position_px

    if config.mode == "treadmill":
        return (-travel_root[0], -travel_root[1]), (0.0, 0.0)

    dx, dy = direction_vector(config.direction)
    camera_follow = max(0.0, distance - WORLD_FOLLOW_DISTANCE_PX)
    world_offset = (-dx * camera_follow, -dy * camera_follow)
    return world_offset, travel_root


def visible_ruler_distances(
    canvas_size: tuple[int, int],
    direction: str,
    anchor: tuple[float, float],
    world_offset: tuple[float, float],
    step: int = RULER_STEP_PX,
) -> tuple[int, ...]:
    name = direction.casefold()
    if name not in ("e", "w", "n", "s", "omni"):
        return ()

    dx, dy = direction_vector(name)
    horizontal = name in ("e", "w", "omni")
    axis_direction = dx if horizontal else dy
    axis_anchor = anchor[0] if horizontal else anchor[1]
    axis_offset = world_offset[0] if horizontal else world_offset[1]
    axis_extent = canvas_size[0] if horizontal else canvas_size[1]
    if abs(axis_direction) < 0.001:
        return ()

    distance_at_start = (0.0 - axis_anchor - axis_offset) / axis_direction
    distance_at_end = (float(axis_extent) - axis_anchor - axis_offset) / axis_direction
    lower = min(distance_at_start, distance_at_end)
    upper = max(distance_at_start, distance_at_end)
    first = int(math.floor(lower / step)) * step
    last = int(math.ceil(upper / step)) * step
    return tuple(range(first, last + step, step))


class MotionPreviewRenderer:
    """Caches source art and composes only offsets and overlays per tick."""

    def __init__(self, repo_root: Path, frames: tuple[Image.Image, ...], ground: str, markers: tuple[MotionEventMarker, ...] = ()) -> None:
        self.repo_root = Path(repo_root)
        self.frames = tuple(frame.convert("RGBA").copy() for frame in frames)
        self.markers = markers
        self.preset, warning = ground_preset(self.repo_root, ground)
        self.warnings = (warning,) if warning else ()
        self.ground_tile = Image.open(self.preset.path).convert("RGBA") if self.preset.path else None

    def _background(self, size: tuple[int, int], offset: tuple[float, float], show_grid: bool) -> Image.Image:
        image = Image.new("RGBA", size, (18, 22, 29, 255))
        if self.ground_tile:
            phase = ground_phase(offset, self.ground_tile.size)
            for y in range(phase[1] - self.ground_tile.height, size[1], self.ground_tile.height):
                for x in range(phase[0] - self.ground_tile.width, size[0], self.ground_tile.width):
                    image.alpha_composite(self.ground_tile, (x, y))
        if show_grid:
            draw = ImageDraw.Draw(image, "RGBA")
            ox, oy = ground_phase(offset, (32, 32))
            for x in range(ox, size[0], 32): draw.line((x, 0, x, size[1]), fill=(180, 195, 210, 70 if (x - ox) % 96 else 120), width=1)
            for y in range(oy, size[1], 32): draw.line((0, y, size[0], y), fill=(180, 195, 210, 70 if (y - oy) % 96 else 120), width=1)
        return image

    @staticmethod
    def _paste_center(canvas: Image.Image, frame: Image.Image, center: tuple[float, float], alpha: float = 1.0) -> None:
        sprite = frame
        if alpha < 1.0:
            sprite = frame.copy(); sprite.putalpha(sprite.getchannel("A").point(lambda value: round(value * alpha)))
        canvas.alpha_composite(sprite, (round(center[0] - sprite.width / 2), round(center[1] - sprite.height / 2)))

    @staticmethod
    def _draw_ruler(canvas: Image.Image, direction: str, anchor: tuple[float, float], world_offset: tuple[float, float]) -> None:
        name = direction.casefold()
        if name not in ("e", "w", "n", "s", "omni"):
            return
        draw = ImageDraw.Draw(canvas, "RGBA")
        dx, dy = direction_vector(name)
        horizontal = name in ("e", "w", "omni")
        distances = visible_ruler_distances(canvas.size, name, anchor, world_offset)
        for distance in distances:
            if horizontal:
                x = anchor[0] + dx * distance + world_offset[0]
                draw.line((x, anchor[1] + 45, x, anchor[1] + 57), fill=(225, 230, 238, 210), width=1)
                draw.text((x + 2, anchor[1] + 59), str(distance), fill=(225, 230, 238, 220))
            else:
                y = anchor[1] + dy * distance + world_offset[1]
                draw.line((anchor[0] + 45, y, anchor[0] + 57, y), fill=(225, 230, 238, 210), width=1)
                draw.text((anchor[0] + 59, y - 6), str(distance), fill=(225, 230, 238, 220))

    def render(self, config: MotionConfig, elapsed_sec: float, *, loop: bool, show_grid: bool = True,
               show_start_ghost: bool = True, show_contact_markers: bool = True) -> MotionFrame:
        sample = sample_motion(config, elapsed_sec, loop=loop)
        world_offset, actor_offset = presentation_offsets(config, sample, loop=loop)
        canvas = self._background(config.canvas_size, world_offset, show_grid)
        anchor = (config.canvas_size[0] / 2, OPERATOR_ANCHOR[1])
        if show_grid:
            self._draw_ruler(canvas, config.direction, anchor, world_offset)
        if show_start_ghost and self.frames:
            self._paste_center(canvas, self.frames[0], (anchor[0] + world_offset[0], anchor[1] + world_offset[1]), 0.22)
        self._paste_center(canvas, self.frames[sample.frame_index], (
            anchor[0] + actor_offset[0] + world_offset[0],
            anchor[1] + actor_offset[1] + world_offset[1],
        ))
        if show_contact_markers:
            draw = ImageDraw.Draw(canvas, "RGBA")
            dx, dy = direction_vector(config.direction)
            for marker in self.markers:
                marker_elapsed = min(marker.frame, config.frame_count) / config.review_fps
                marker_sample = sample_motion(config, marker_elapsed)
                if loop:
                    contact_distance = sample.cycle_index * config.travel_px + marker_sample.phase_position_px
                    marker_root = (dx * contact_distance, dy * contact_distance)
                else:
                    marker_root = marker_sample.root_displacement
                point = (anchor[0] + marker_root[0] + world_offset[0], anchor[1] + marker_root[1] + world_offset[1])
                draw.ellipse((point[0] - 5, point[1] - 5, point[0] + 5, point[1] + 5), outline=(255, 190, 72, 255), width=2)
                draw.text((point[0] + 7, point[1] - 7), f"{marker.label} F{marker.frame + 1}", fill=(255, 220, 140, 255))
        return MotionFrame(canvas, sample, self.warnings)
