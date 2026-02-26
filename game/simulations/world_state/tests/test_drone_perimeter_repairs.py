"""Tests for deterministic drone routing on damaged perimeter walls."""

from game.simulations.world_state.core.repairs import tick_repairs
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command


def _count_power_perimeter_walls(state: GameState) -> int:
    return len(
        [
            s
            for s in state.structure_instances.values()
            if s.sector == "POWER" and s.type == "WALL" and s.subtype == "PERIMETER"
        ]
    )


def _remove_n_power_perimeter_walls(state: GameState, n: int) -> None:
    ids = [
        sid
        for sid, instance in sorted(state.structure_instances.items())
        if instance.sector == "POWER" and instance.type == "WALL" and instance.subtype == "PERIMETER"
    ]
    for sid in ids[:n]:
        state.remove_structure_instance(sid)


def test_drone_repairs_restore_one_perimeter_wall_per_tick() -> None:
    state = GameState(seed=101)
    process_command(state, "FORTIFY PW 2")
    _remove_n_power_perimeter_walls(state, 3)
    before = _count_power_perimeter_walls(state)
    state.repair_drone_stock = 2

    lines = tick_repairs(state)
    after = _count_power_perimeter_walls(state)

    assert after == before + 1
    assert state.repair_drone_stock == 1
    assert any(line.startswith("DRONE REPAIR: PERIMETER WALL RESTORED POWER") for line in lines)


def test_drone_repairs_do_nothing_without_stock() -> None:
    state = GameState(seed=102)
    process_command(state, "FORTIFY PW 2")
    _remove_n_power_perimeter_walls(state, 2)
    before = _count_power_perimeter_walls(state)
    state.repair_drone_stock = 0

    lines = tick_repairs(state)

    assert _count_power_perimeter_walls(state) == before
    assert lines == []


def test_drone_repairs_respect_policy_off() -> None:
    state = GameState(seed=104)
    process_command(state, "FORTIFY PW 2")
    _remove_n_power_perimeter_walls(state, 2)
    before = _count_power_perimeter_walls(state)
    state.repair_drone_stock = 5
    state.drone_perimeter_repair_policy = "OFF"

    lines = tick_repairs(state)

    assert _count_power_perimeter_walls(state) == before
    assert state.repair_drone_stock == 5
    assert lines == []


def test_drone_repairs_are_deterministic_for_same_state() -> None:
    left = GameState(seed=103)
    right = GameState(seed=103)
    for state in (left, right):
        process_command(state, "FORTIFY PW 2")
        _remove_n_power_perimeter_walls(state, 4)
        state.repair_drone_stock = 3
        for _ in range(3):
            tick_repairs(state)

    left_positions = sorted(
        s.position
        for s in left.structure_instances.values()
        if s.sector == "POWER" and s.type == "WALL" and s.subtype == "PERIMETER"
    )
    right_positions = sorted(
        s.position
        for s in right.structure_instances.values()
        if s.sector == "POWER" and s.type == "WALL" and s.subtype == "PERIMETER"
    )
    assert left_positions == right_positions
