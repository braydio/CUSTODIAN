"""Tests for the world-state step helper."""

from game.simulations.world_state.core import simulation
from game.simulations.world_state.core.repairs import start_repair, tick_repairs
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import StructureState


def test_step_world_advances_and_spawns_assaults_when_idle(monkeypatch) -> None:
    """Ensure idle ticks use the spatial approach path."""
    state = GameState()
    calls = {
        "advance": 0,
        "event": 0,
        "advance_assaults": 0,
        "spawn": 0,
        "resolve": 0,
        "repairs": 0,
    }

    def record(name):
        def _inner(*args, **kwargs):
            calls[name] += 1

        return _inner

    monkeypatch.setattr(simulation, "advance_time", record("advance"))
    monkeypatch.setattr(simulation, "maybe_trigger_event", record("event"))
    monkeypatch.setattr(simulation, "advance_assaults", record("advance_assaults"))
    monkeypatch.setattr(simulation, "maybe_spawn_assault", record("spawn"))
    monkeypatch.setattr(simulation, "resolve_assault", record("resolve"))
    monkeypatch.setattr(simulation, "tick_repairs", lambda *_: calls.__setitem__("repairs", calls["repairs"] + 1) or [])

    simulation.step_world(state, tick_delay=0.1)

    assert calls["advance"] == 1
    assert calls["event"] == 1
    assert calls["advance_assaults"] == 1
    assert calls["spawn"] == 1
    assert calls["resolve"] == 0
    assert calls["repairs"] == 1


def test_step_world_resolves_assault_when_active(monkeypatch) -> None:
    """Ensure active assaults route through resolution."""
    state = GameState()
    state.current_assault = object()
    calls = {"advance": 0, "event": 0, "advance_assaults": 0, "spawn": 0, "repairs": 0}
    resolved = {}

    def record(name):
        def _inner(*args, **kwargs):
            calls[name] += 1

        return _inner

    def resolve_stub(*args, **kwargs):
        resolved["tick_delay"] = kwargs.get("tick_delay", 0.0)

    monkeypatch.setattr(simulation, "advance_time", record("advance"))
    monkeypatch.setattr(simulation, "maybe_trigger_event", record("event"))
    monkeypatch.setattr(simulation, "advance_assaults", record("advance_assaults"))
    monkeypatch.setattr(simulation, "maybe_spawn_assault", record("spawn"))
    monkeypatch.setattr(simulation, "resolve_assault", resolve_stub)
    monkeypatch.setattr(simulation, "tick_repairs", lambda *_: calls.__setitem__("repairs", calls["repairs"] + 1) or [])

    simulation.step_world(state, tick_delay=0.3)

    assert calls["advance"] == 1
    assert calls["event"] == 1
    assert calls["advance_assaults"] == 0
    assert calls["spawn"] == 0
    assert resolved["tick_delay"] == 0.3
    assert calls["repairs"] == 1


def test_step_world_skips_progress_when_failed(monkeypatch) -> None:
    """Failed sessions should not advance or call downstream systems."""

    state = GameState()
    state.is_failed = True
    calls = {"advance": 0, "event": 0, "advance_assaults": 0, "spawn": 0, "resolve": 0, "repairs": 0}

    def record(name):
        def _inner(*args, **kwargs):
            calls[name] += 1

        return _inner

    monkeypatch.setattr(simulation, "advance_time", record("advance"))
    monkeypatch.setattr(simulation, "maybe_trigger_event", record("event"))
    monkeypatch.setattr(simulation, "advance_assaults", record("advance_assaults"))
    monkeypatch.setattr(simulation, "maybe_spawn_assault", record("spawn"))
    monkeypatch.setattr(simulation, "resolve_assault", record("resolve"))
    monkeypatch.setattr(simulation, "tick_repairs", lambda *_: calls.__setitem__("repairs", calls["repairs"] + 1) or [])

    transitioned = simulation.step_world(state)

    assert transitioned is False
    assert calls == {"advance": 0, "event": 0, "advance_assaults": 0, "spawn": 0, "resolve": 0, "repairs": 0}
    assert state.last_repair_lines == []


def test_step_world_refreshes_comms_fidelity_and_emits_event(monkeypatch) -> None:
    state = GameState()
    state.fidelity = "FULL"
    state.structures["CM_CORE"].state = StructureState.DAMAGED
    state.sectors["COMMS"].power = 0.5

    monkeypatch.setattr(simulation, "maybe_trigger_event", lambda *_: None)
    monkeypatch.setattr(simulation, "advance_assaults", lambda *_: None)
    monkeypatch.setattr(simulation, "maybe_spawn_assault", lambda *_: None)
    monkeypatch.setattr(simulation, "tick_repairs", lambda *_: [])

    simulation.step_world(state, tick_delay=0.0)

    assert state.fidelity == "FRAGMENTED"
    assert state.last_fidelity_lines == [
        "[WARNING] SIGNAL DEGRADATION DETECTED"
    ]


def test_advance_time_allows_threat_recovery_under_stable_maintenance() -> None:
    state = GameState()
    state.ambient_threat = 2.0
    state.sectors["COMMAND"].damage = 0.2
    state.sectors["COMMS"].damage = 0.2
    state.sectors["POWER"].damage = 0.2

    simulation.advance_time(state, delta=1)

    assert state.ambient_threat < 2.0


def test_advance_time_accumulates_low_threat_before_recovery_gate() -> None:
    state = GameState()
    state.ambient_threat = 0.0
    state.sectors["COMMAND"].damage = 0.0
    state.sectors["COMMS"].damage = 0.0
    state.sectors["POWER"].damage = 0.0

    simulation.advance_time(state, delta=1)

    assert state.ambient_threat > 0.0


def test_advance_time_reaches_assault_threshold_before_stability_recovery() -> None:
    state = GameState()
    state.ambient_threat = 0.0
    state.sectors["COMMAND"].damage = 0.0
    state.sectors["COMMS"].damage = 0.0
    state.sectors["POWER"].damage = 0.0

    for _ in range(110):
        simulation.advance_time(state, delta=1)

    assert state.ambient_threat > 1.5


def test_sector_recovery_starts_only_after_repair_completion() -> None:
    state = GameState()
    state.sectors["DEFENSE GRID"].damage = 1.2
    state.sectors["DEFENSE GRID"].alertness = 1.1
    state.structures["DF_CORE"].state = StructureState.DAMAGED

    before_damage = state.sectors["DEFENSE GRID"].damage
    simulation.advance_time(state, delta=1)
    assert state.sectors["DEFENSE GRID"].damage >= before_damage

    start_repair(state, "DF_CORE", local=False)
    while state.active_repairs:
        tick_repairs(state)

    assert "DEFENSE GRID" in state.sector_recovery_windows


def test_in_person_recovery_is_faster_than_remote() -> None:
    remote_state = GameState()
    remote_state.sectors["DEFENSE GRID"].damage = 1.2
    remote_state.sectors["DEFENSE GRID"].alertness = 1.2
    remote_state.structures["DF_CORE"].state = StructureState.DAMAGED
    start_repair(remote_state, "DF_CORE", local=False)
    while remote_state.active_repairs:
        tick_repairs(remote_state)

    local_state = GameState()
    local_state.sectors["DEFENSE GRID"].damage = 1.2
    local_state.sectors["DEFENSE GRID"].alertness = 1.2
    local_state.structures["DF_CORE"].state = StructureState.DAMAGED
    start_repair(local_state, "DF_CORE", local=True)
    while local_state.active_repairs:
        tick_repairs(local_state)

    simulation.advance_time(remote_state, delta=1)
    simulation.advance_time(local_state, delta=1)

    assert local_state.sectors["DEFENSE GRID"].damage < remote_state.sectors["DEFENSE GRID"].damage
    assert local_state.sectors["DEFENSE GRID"].alertness < remote_state.sectors["DEFENSE GRID"].alertness


def test_drone_focus_recovery_is_faster_than_remote() -> None:
    remote_state = GameState()
    remote_state.sectors["DEFENSE GRID"].damage = 1.2
    remote_state.sectors["DEFENSE GRID"].alertness = 1.2
    remote_state.structures["DF_CORE"].state = StructureState.DAMAGED
    start_repair(remote_state, "DF_CORE", local=False)
    while remote_state.active_repairs:
        tick_repairs(remote_state)

    drone_state = GameState()
    drone_state.sectors["DEFENSE GRID"].damage = 1.2
    drone_state.sectors["DEFENSE GRID"].alertness = 1.2
    drone_state.structures["DF_CORE"].state = StructureState.DAMAGED
    drone_state.focused_sector = "FB"
    start_repair(drone_state, "DF_CORE", local=False)
    while drone_state.active_repairs:
        tick_repairs(drone_state)

    simulation.advance_time(remote_state, delta=1)
    simulation.advance_time(drone_state, delta=1)

    assert drone_state.sectors["DEFENSE GRID"].damage < remote_state.sectors["DEFENSE GRID"].damage
    assert drone_state.sectors["DEFENSE GRID"].alertness < remote_state.sectors["DEFENSE GRID"].alertness
