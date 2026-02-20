"""Tests for infrastructure policy layer mechanics."""

from game.simulations.world_state.core.fabrication import FabricationTask, tick_fabrication
from game.simulations.world_state.core.power_load import compute_power_load
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.wear import apply_wear
from game.simulations.world_state.terminal.processor import process_command


def test_set_policy_commands_mutate_policy_state() -> None:
    state = GameState()

    set_repair = process_command(state, "SET REPAIR 4")
    set_defense = process_command(state, "SET DEFENSE 1")
    set_surveillance = process_command(state, "SET SURVEILLANCE 3")

    assert set_repair.ok is True
    assert set_defense.ok is True
    assert set_surveillance.ok is True
    assert state.policies.repair_intensity == 4
    assert state.policies.defense_readiness == 1
    assert state.policies.surveillance_coverage == 3


def test_fabrication_speed_scales_with_allocation_level() -> None:
    low = GameState()
    high = GameState()
    low.fab_allocation["DEFENSE"] = 0
    high.fab_allocation["DEFENSE"] = 4

    low.fabrication_queue = [
        FabricationTask(
            id=1,
            name="TURRET PARTS",
            ticks_remaining=10.0,
            material_cost=1,
            category="DEFENSE",
            inputs={},
            outputs={},
        )
    ]
    high.fabrication_queue = [
        FabricationTask(
            id=1,
            name="TURRET PARTS",
            ticks_remaining=10.0,
            material_cost=1,
            category="DEFENSE",
            inputs={},
            outputs={},
        )
    ]

    tick_fabrication(low)
    tick_fabrication(high)

    assert high.fabrication_queue[0].ticks_remaining < low.fabrication_queue[0].ticks_remaining


def test_power_load_increases_with_policy_levels() -> None:
    baseline = GameState()
    elevated = GameState()
    elevated.policies.repair_intensity = 4
    elevated.policies.defense_readiness = 4
    elevated.policies.surveillance_coverage = 4
    elevated.sector_fort_levels["COMMAND"] = 4

    base_load = compute_power_load(baseline)
    elevated_load = compute_power_load(elevated)

    assert elevated_load > base_load


def test_wear_scales_with_defense_readiness() -> None:
    low = GameState()
    high = GameState()
    low.policies.defense_readiness = 0
    high.policies.defense_readiness = 4

    apply_wear(low)
    apply_wear(high)

    assert high.sectors["POWER"].damage > low.sectors["POWER"].damage
