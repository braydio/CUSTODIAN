"""Integer-only pose timeline validation and interpolation."""
from __future__ import annotations

from fractions import Fraction
import math
import re
from pathlib import Path
from typing import Any

from .schema import DIRECTIONS, MOTION_SCHEMA, integer_pair, read_json


def round_half_away(value: Fraction) -> int:
    sign = -1 if value < 0 else 1
    magnitude = abs(value)
    quotient, remainder = divmod(magnitude.numerator, magnitude.denominator)
    return sign * (quotient + (2 * remainder >= magnitude.denominator))


def interpolate(keys: list[dict[str, Any]], frame: int) -> tuple[int, int]:
    """Piecewise rational interpolation with signed half-away rounding."""
    if not keys:
        raise ValueError("track requires keyframes")
    if frame <= keys[0]["frame"]:
        return tuple(keys[0]["offset"])
    if frame >= keys[-1]["frame"]:
        return tuple(keys[-1]["offset"])
    for left, right in zip(keys, keys[1:]):
        if left["frame"] <= frame <= right["frame"]:
            span = right["frame"] - left["frame"]
            step = frame - left["frame"]
            return tuple(round_half_away(Fraction(a * (span - step) + b * step, span))
                         for a, b in zip(left["offset"], right["offset"]))
    raise AssertionError("frame not covered by endpoints")


def load_motion(path: Path, rig: dict[str, Any]) -> dict[str, Any]:
    motion = read_json(path)
    if motion.get("schema") != MOTION_SCHEMA:
        raise ValueError("unsupported motion schema")
    if motion.get("rig_id") != rig.get("rig_id") or motion.get("direction") != rig.get("direction"):
        raise ValueError("motion rig or direction mismatch")
    if motion.get("direction") not in DIRECTIONS:
        raise ValueError("invalid motion direction")
    token_pattern = re.compile(r"^[a-z0-9_]+$")
    if any(not isinstance(motion.get(key), str) or not token_pattern.fullmatch(motion[key]) for key in ("profile", "group", "action")):
        raise ValueError("profile, group and action must be lowercase semantic tokens")
    if motion.get("profile") not in {"shared", "unarmed", "melee_1h", "melee_1h_dagger", "melee_1h_heavy", "sidearm", "ranged_2h"}:
        raise ValueError("invalid animation profile")
    if motion.get("group") not in {"locomotion", "posture", "attack", "defense", "reaction", "interaction", "transition", "cosmetic", "presentation"}:
        raise ValueError("invalid action group")
    if motion.get("action", "").startswith("legacy_") or "_legacy_" in motion.get("action", ""):
        raise ValueError("legacy action is not valid candidate content")
    count = motion.get("frame_count")
    if isinstance(count, bool) or not isinstance(count, int) or not 1 <= count <= 120:
        raise ValueError("frame_count must be in 1..120")
    if motion.get("fps") is not None and (isinstance(motion["fps"], bool) or not isinstance(motion["fps"], (int, float)) or not math.isfinite(motion["fps"]) or motion["fps"] <= 0 or motion["fps"] > 120):
        raise ValueError("authored fps must be null or positive")
    if not isinstance(motion.get("loop"), bool):
        raise ValueError("loop must be explicitly true or false")
    if motion.get("interpolation") != "linear_integer_half_away_from_zero":
        raise ValueError("unsupported interpolation mode")
    parts = {part["id"]: part for part in rig["parts"]}
    tracks = motion.get("tracks")
    if not isinstance(tracks, list):
        raise ValueError("tracks must be a list")
    track_map: dict[str, list[dict[str, Any]]] = {}
    for track in tracks:
        part_id = track.get("part") if isinstance(track, dict) else None
        if part_id not in parts or part_id in track_map:
            raise ValueError("unknown or duplicate tracked part")
        keys = track.get("keys")
        if not isinstance(keys, list) or len(keys) < 2:
            raise ValueError(f"track needs at least two keys: {part_id}")
        parsed = []
        previous = -1
        for key in keys:
            if not isinstance(key, dict):
                raise ValueError("keyframe must be an object")
            frame = key.get("frame")
            if isinstance(frame, bool) or not isinstance(frame, int) or not 0 <= frame < count or frame <= previous:
                raise ValueError("keyframes must be strictly increasing within the motion")
            offset = integer_pair(key.get("offset"), "keyframe offset")
            if part_id == "root" or (not parts[part_id]["movable"] and offset != (0, 0)):
                raise ValueError(f"locked part may not move: {part_id}")
            parsed.append({"frame": frame, "offset": offset})
            previous = frame
        if parsed[0]["frame"] != 0 or parsed[-1]["frame"] != count - 1:
            raise ValueError("every track must have first and last frame endpoints")
        track_map[part_id] = parsed
    if set(track_map) != set(parts):
        raise ValueError("every rig part requires an explicit track, including stationary zero-offset parts")
    motion["tracks"] = track_map
    motion["contacts"] = _validate_contacts(motion.get("contacts", []), parts, count, rig["frame_size"])
    motion["frame_count"] = count
    motion["fps"] = None if motion.get("fps") is None else float(motion["fps"])
    return motion


def _validate_contacts(contacts: Any, parts: dict[str, Any], count: int, size: tuple[int, int]) -> list[dict[str, Any]]:
    if not isinstance(contacts, list):
        raise ValueError("contacts must be a list")
    result = []
    for item in contacts:
        if not isinstance(item, dict) or item.get("part") not in parts:
            raise ValueError("contact references unknown part")
        frames = item.get("frames")
        if not isinstance(frames, list) or not frames or any(isinstance(f, bool) or not isinstance(f, int) or not 0 <= f < count for f in frames):
            raise ValueError("contact frames must be valid zero-based frame indices")
        if len(set(frames)) != len(frames):
            raise ValueError("contact frames must be unique")
        point = integer_pair(item.get("point"), "contact point")
        if not (0 <= point[0] < size[0] and 0 <= point[1] < size[1]):
            raise ValueError("contact point outside canvas")
        result.append({"part": item["part"], "frames": sorted(frames), "point": point})
    return result
