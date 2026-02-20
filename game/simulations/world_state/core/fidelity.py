"""Comms fidelity helpers with surveillance buffering."""

from __future__ import annotations

from .policies import FIDELITY_BUFFER


def surveillance_buffer_multiplier(state) -> float:
    level = int(state.policies.surveillance_coverage)
    return float(FIDELITY_BUFFER[level])


def buffered_effectiveness(base_effectiveness: float, state) -> float:
    value = float(base_effectiveness) * surveillance_buffer_multiplier(state)
    if "signal_interference" in state.global_effects:
        value *= 0.85
    return max(0.0, min(1.0, value))

