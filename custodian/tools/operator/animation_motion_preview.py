"""Pure motion-calibration model and raster compositor for Operator previews."""
from __future__ import annotations

import math
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

CANVAS_SIZE = (768, 384)
OPERATOR_ANCHOR = (384, 224)
CURVES = ("constant", "linear", "ease_in", "ease_out", "ease_in_out", "attack_lunge")
MODES = ("treadmill", "world")
DISTANCE_PRESETS = (32.0, 64.0, 96.0, 128.0, 160.0, 192.0, 224.0, 256.0)
GROUND_PRESETS = {
    "grid32": None,
    "ritualant_cavern": "custodian/content/tiles/encounters/ritualant_set/underground/ritualant_underground__ground__cavern_repeat_01__512x512.png",
}


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


@dataclass(frozen=True)
class MotionSample:
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


def sample_motion(config: MotionConfig, elapsed_sec: float, *, loop: bool = False) -> MotionSample:
    count = max(1, int(config.frame_count))
    fps = max(0.001, float(config.review_fps))
    duration = count / fps
    elapsed = max(0.0, float(elapsed_sec))
    if loop and elapsed >= duration:
        elapsed %= duration
    else:
        elapsed = min(elapsed, duration)
    normalized = elapsed / duration
    progress = curve_progress(config.curve, normalized)
    dx, dy = direction_vector(config.direction)
    distance = max(0.0, float(config.travel_px)) * progress
    root = (dx * distance, dy * distance)
    ground = (-root[0], -root[1])
    frame = min(count - 1, int(math.floor(normalized * count)))
    average = max(0.0, float(config.travel_px)) / duration
    speed = max(0.0, float(config.travel_px)) * _curve_slope(config.curve, normalized) / duration
    return MotionSample(elapsed, duration, normalized, frame, progress, root, ground, distance, average, speed)


def scrub_motion(config: MotionConfig, ratio: float) -> MotionSample:
    duration = max(1, int(config.frame_count)) / max(0.001, float(config.review_fps))
    return sample_motion(config, min(1.0, max(0.0, ratio)) * duration)


def ground_phase(displacement: tuple[float, float], tile_size: tuple[int, int]) -> tuple[int, int]:
    return int(math.floor(displacement[0])) % max(1, tile_size[0]), int(math.floor(displacement[1])) % max(1, tile_size[1])


def ground_preset(repo_root: Path, preset_id: str) -> tuple[GroundPreset, str | None]:
    raw = GROUND_PRESETS.get(preset_id)
    if preset_id == "grid32" or raw is None:
        return GroundPreset("grid32", "GRID 32", None), None if preset_id == "grid32" else f"GROUND UNAVAILABLE: {preset_id}"
    path = Path(repo_root) / raw
    if path.exists():
        return GroundPreset(preset_id, "RITUALANT CAVERN", path, (512, 512)), None
    return GroundPreset("grid32", "GRID 32", None), f"GROUND UNAVAILABLE: {path}"


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
        if direction.casefold() not in ("e", "w", "n", "s", "omni"):
            return
        draw = ImageDraw.Draw(canvas, "RGBA")
        horizontal_travel = direction.casefold() in ("e", "w", "omni")
        sign = -1 if direction.casefold() in ("w", "n") else 1
        for distance in range(-256, 257, 32):
            signed = distance * sign
            if horizontal_travel:
                x = anchor[0] + signed + world_offset[0]
                if 0 <= x < canvas.width:
                    draw.line((x, anchor[1] + 45, x, anchor[1] + 57), fill=(225, 230, 238, 210), width=1)
                    draw.text((x + 2, anchor[1] + 59), str(distance), fill=(225, 230, 238, 220))
            else:
                y = anchor[1] + signed + world_offset[1]
                if 0 <= y < canvas.height:
                    draw.line((anchor[0] + 45, y, anchor[0] + 57, y), fill=(225, 230, 238, 210), width=1)
                    draw.text((anchor[0] + 59, y - 6), str(distance), fill=(225, 230, 238, 220))

    def render(self, config: MotionConfig, elapsed_sec: float, *, loop: bool, show_grid: bool = True,
               show_start_ghost: bool = True, show_contact_markers: bool = True) -> MotionFrame:
        sample = sample_motion(config, elapsed_sec, loop=loop)
        world_offset = sample.ground_displacement if config.mode == "treadmill" else (0.0, 0.0)
        canvas = self._background(config.canvas_size, world_offset, show_grid)
        anchor = (config.canvas_size[0] / 2, OPERATOR_ANCHOR[1])
        if show_grid:
            self._draw_ruler(canvas, config.direction, anchor, world_offset)
        if show_start_ghost and self.frames:
            ghost_offset = world_offset if config.mode == "treadmill" else (0.0, 0.0)
            self._paste_center(canvas, self.frames[0], (anchor[0] + ghost_offset[0], anchor[1] + ghost_offset[1]), 0.22)
        actor_offset = (0.0, 0.0) if config.mode == "treadmill" else sample.root_displacement
        self._paste_center(canvas, self.frames[sample.frame_index], (anchor[0] + actor_offset[0], anchor[1] + actor_offset[1]))
        if show_contact_markers:
            draw = ImageDraw.Draw(canvas, "RGBA")
            for marker in self.markers:
                marker_elapsed = min(marker.frame, config.frame_count) / config.review_fps
                marker_sample = sample_motion(config, marker_elapsed)
                point = (anchor[0] + marker_sample.root_displacement[0] + world_offset[0], anchor[1] + marker_sample.root_displacement[1] + world_offset[1])
                draw.ellipse((point[0] - 5, point[1] - 5, point[0] + 5, point[1] + 5), outline=(255, 190, 72, 255), width=2)
                draw.text((point[0] + 7, point[1] - 7), f"{marker.label} F{marker.frame + 1}", fill=(255, 220, 140, 255))
        return MotionFrame(canvas, sample, self.warnings)
