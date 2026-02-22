"""Logistics throughput cap and overload penalties."""

from __future__ import annotations


def _queue_load(state) -> float:
    repair_load = 1.0 if state.active_repairs else 0.0
    fab_load = min(2.0, len(state.fabrication_queue) * 0.4)
    assault_load = 0.8 if (state.current_assault is not None or state.in_major_assault) else 0.0
    relay_load = 0.6 if (state.active_task and getattr(state.active_task, "type", "") == "RELAY") else 0.0
    return repair_load + fab_load + assault_load + relay_load


def update_logistics(state) -> None:
    """Compute logistics load, throughput, and subsystem multipliers."""

    # Base throughput tracks power posture and surveillance posture.
    base_throughput = 3.0
    base_throughput += max(0.0, 4.0 - float(state.power_load)) * 0.35
    base_throughput += max(0.0, 2.0 - float(state.policies.surveillance_coverage)) * 0.2
    base_throughput = max(1.5, min(5.0, base_throughput))

    load = float(state.power_load) * 0.45 + _queue_load(state)
    pressure = max(0.0, load - base_throughput)

    # Soft penalty curve: overload gradually slows logistics-sensitive systems.
    throughput_mult = 1.0 - min(0.55, pressure * 0.18)
    throughput_mult = max(0.45, throughput_mult)

    state.logistics_throughput = round(base_throughput, 3)
    state.logistics_load = round(load, 3)
    state.logistics_pressure = round(pressure, 3)
    state.logistics_multiplier = round(throughput_mult, 3)
    state.repair_throughput_mult = state.logistics_multiplier
    state.fabrication_throughput_mult = state.logistics_multiplier
