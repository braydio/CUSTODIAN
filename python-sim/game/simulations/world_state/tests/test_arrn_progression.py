from game.simulations.world_state.core.fabrication import start_fabrication_task
from game.simulations.world_state.core.logistics import update_logistics
from game.simulations.world_state.core.relays import (
    KNOWLEDGE_DRIFT_PERIOD,
    apply_sync,
    relay_effective_fidelity_floor,
    tick_relays,
)
from game.simulations.world_state.core.state import GameState


def test_tick_relays_applies_decay_and_state_transition() -> None:
    state = GameState(seed=5)
    relay = state.relay_nodes["R_NORTH"]
    relay["status"] = "STABLE"
    relay["stability"] = 70.0

    tick_relays(state)

    assert relay["stability"] == 69.5
    assert relay["status"] == "WEAK"


def test_tick_relays_dormancy_pressure_halved_at_tier_seven() -> None:
    state = GameState(seed=7)
    for relay in state.relay_nodes.values():
        relay["status"] = "DORMANT"
        relay["stability"] = 0.0
    state.knowledge_index["RELAY_RECOVERY"] = 7

    tick_relays(state)

    assert state.dormancy_pressure == 2


def test_tick_relays_applies_knowledge_drift_under_high_dormancy() -> None:
    state = GameState(seed=11)
    state.time = KNOWLEDGE_DRIFT_PERIOD
    state.knowledge_index["RELAY_RECOVERY"] = 4
    for relay in state.relay_nodes.values():
        relay["status"] = "DORMANT"
        relay["stability"] = 0.0

    tick_relays(state)

    assert state.knowledge_index["RELAY_RECOVERY"] == 3


def test_apply_sync_is_bounded_and_reports_weak_failures(monkeypatch) -> None:
    state = GameState(seed=13)
    state.relay_packets_pending = 3
    state.relay_nodes["R_NORTH"]["status"] = "WEAK"
    state.relay_nodes["R_SOUTH"]["status"] = "WEAK"
    monkeypatch.setattr(state.rng, "random", lambda: 0.0)

    synced, level, failed = apply_sync(state)

    assert synced == 1
    assert failed == 2
    assert 0 <= level <= 7
    assert state.relay_packets_pending == 0


def test_archive_plating_requires_knowledge_tier_four() -> None:
    state = GameState(seed=17)

    locked = start_fabrication_task(state, "ARCHIVE_PLATING")
    assert locked == "FAB LOCKED: KNOWLEDGE TIER 4 REQUIRED."

    state.knowledge_index["RELAY_RECOVERY"] = 4
    tick_relays(state)
    unlocked = start_fabrication_task(state, "ARCHIVE_PLATING")
    assert unlocked == "FAB FAILED: INSUFFICIENT COMPONENTS."


def test_logistics_optimization_reduces_overload_penalty() -> None:
    baseline = GameState(seed=19)
    optimized = GameState(seed=19)
    baseline.power_load = 5.0
    optimized.power_load = 5.0
    baseline.fabrication_queue = [object() for _ in range(6)]
    optimized.fabrication_queue = [object() for _ in range(6)]
    optimized.knowledge_index["RELAY_RECOVERY"] = 5
    tick_relays(optimized)

    update_logistics(baseline)
    update_logistics(optimized)

    assert optimized.logistics_pressure < baseline.logistics_pressure
    assert optimized.logistics_multiplier > baseline.logistics_multiplier


def test_signal_reconstruction_applies_status_fidelity_floor() -> None:
    state = GameState(seed=23)
    state.knowledge_index["RELAY_RECOVERY"] = 1
    tick_relays(state)
    assert relay_effective_fidelity_floor(state, "DEGRADED") == "FULL"

    state.knowledge_index["RELAY_RECOVERY"] = 6
    tick_relays(state)
    assert relay_effective_fidelity_floor(state, "LOST") == "DEGRADED"
