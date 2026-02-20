"""Surveillance-driven detection helpers."""

from __future__ import annotations

from .policies import DETECTION_SPEED


def surveillance_speed_multiplier(state) -> float:
    level = int(state.policies.surveillance_coverage)
    return float(DETECTION_SPEED[level])


def detection_probability(base: float, state) -> float:
    speed = surveillance_speed_multiplier(state)
    adjusted = base * speed
    return max(0.05, min(0.98, adjusted))


def warning_delay_ticks(state) -> int:
    speed = surveillance_speed_multiplier(state)
    if speed >= 1.4:
        return 0
    if speed >= 1.0:
        return 1
    return 2

