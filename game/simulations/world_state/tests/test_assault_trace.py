"""Tests for dev assault trace behavior."""

from game.simulations.world_state.core.assaults import resolve_assault
from game.simulations.world_state.core.assault_instance import AssaultInstance
from game.simulations.world_state.core.state import GameState


def test_dev_trace_uses_existing_tick_field(monkeypatch, capsys) -> None:
    state = GameState(seed=7)
    state.dev_trace = True
    assault = AssaultInstance(
        faction_profile=state.faction_profile,
        target_sectors=[state.sectors["COMMS"]],
        threat_budget=10,
        start_time=state.time,
    )
    state.current_assault = assault
    state.in_major_assault = True

    monkeypatch.setattr(assault, "duration_ticks", 1)
    monkeypatch.setattr("game.simulations.world_state.core.assaults.time.sleep", lambda *_: None)

    resolve_assault(state, tick_delay=0.0)
    output = capsys.readouterr().out

    assert "'tick': 0" in output
