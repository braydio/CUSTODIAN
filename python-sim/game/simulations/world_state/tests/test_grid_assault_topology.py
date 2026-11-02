"""Tests for grid-topology influence on assault pressure."""

from game.simulations.world_state.core import assaults
from game.simulations.world_state.core.grid_assault import (
    perimeter_wall_continuity,
    perimeter_wall_coverage,
    topology_damage_multiplier,
    weakest_perimeter_segment,
)
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command


def _remove_walls_on_left_edge(state: GameState, sector_name: str) -> None:
    ids = []
    for sid, instance in state.structure_instances.items():
        if instance.sector != sector_name or instance.type != "WALL":
            continue
        x, _ = instance.position
        if x == 0:
            ids.append(sid)
    for sid in sorted(ids):
        state.remove_structure_instance(sid)


def test_topology_multiplier_reduces_pressure_when_perimeter_is_intact() -> None:
    state = GameState(seed=21)
    state.sector_fort_levels["POWER"] = 2
    baseline = assaults._incoming_damage_multiplier(state, "POWER")

    process_command(state, "FORTIFY PW 2")
    with_walls = assaults._incoming_damage_multiplier(state, "POWER")

    assert with_walls < baseline
    assert topology_damage_multiplier(state, "POWER") < 1.0


def test_weak_perimeter_segment_increases_incoming_pressure() -> None:
    state = GameState(seed=22)
    process_command(state, "FORTIFY PW 2")
    intact = assaults._incoming_damage_multiplier(state, "POWER")

    _remove_walls_on_left_edge(state, "POWER")
    weakened = assaults._incoming_damage_multiplier(state, "POWER")

    assert weakened > intact
    assert perimeter_wall_coverage(state, "POWER") < 1.0
    assert perimeter_wall_continuity(state, "POWER") < 1.0
    assert weakest_perimeter_segment(state, "POWER") < 1.0


def test_topology_signal_is_deterministic() -> None:
    left = GameState(seed=41)
    right = GameState(seed=41)
    for state in (left, right):
        process_command(state, "FORTIFY PW 3")
        _remove_walls_on_left_edge(state, "POWER")

    assert perimeter_wall_coverage(left, "POWER") == perimeter_wall_coverage(right, "POWER")
    assert perimeter_wall_continuity(left, "POWER") == perimeter_wall_continuity(right, "POWER")
    assert topology_damage_multiplier(left, "POWER") == topology_damage_multiplier(right, "POWER")
    assert assaults._incoming_damage_multiplier(left, "POWER") == assaults._incoming_damage_multiplier(
        right, "POWER"
    )


def test_assault_degradation_erodes_perimeter_walls_under_high_pressure() -> None:
    state = GameState(seed=55)
    process_command(state, "FORTIFY PW 2")
    before = len(
        [s for s in state.structure_instances.values() if s.sector == "POWER" and s.type == "WALL"]
    )

    state.defense_allocation = {
        "PERIMETER": 1.4,
        "POWER": 0.2,
        "SENSORS": 1.2,
        "COMMAND": 1.2,
    }
    assaults._degrade_target_structures(state, {"POWER"})

    after = len(
        [s for s in state.structure_instances.values() if s.sector == "POWER" and s.type == "WALL"]
    )
    assert after < before
