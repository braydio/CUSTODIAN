"""Tests for the world-state step helper."""

from game.simulations.world_state.core import simulation
from game.simulations.world_state.core.state import GameState


def test_step_world_runs_assault_timer_when_idle(monkeypatch) -> None:
    """Ensure idle ticks use the assault timer path."""
    state = GameState()
    calls = {"advance": 0, "event": 0, "start": 0, "tick": 0, "resolve": 0}

    def record(name):
        def _inner(*args, **kwargs):
            calls[name] += 1

        return _inner

    monkeypatch.setattr(simulation, "advance_time", record("advance"))
    monkeypatch.setattr(simulation, "maybe_trigger_event", record("event"))
    monkeypatch.setattr(simulation, "maybe_start_assault_timer", record("start"))
    monkeypatch.setattr(simulation, "tick_assault_timer", record("tick"))
    monkeypatch.setattr(simulation, "resolve_assault", record("resolve"))

    simulation.step_world(state, tick_delay=0.1)

    assert calls["advance"] == 1
    assert calls["event"] == 1
    assert calls["start"] == 1
    assert calls["tick"] == 1
    assert calls["resolve"] == 0


def test_step_world_resolves_assault_when_active(monkeypatch) -> None:
    """Ensure active assaults route through resolution."""
    state = GameState()
    state.current_assault = object()
    calls = {"advance": 0, "event": 0, "start": 0, "tick": 0}
    resolved = {}

    def record(name):
        def _inner(*args, **kwargs):
            calls[name] += 1

        return _inner

    def resolve_stub(*args, **kwargs):
        resolved["tick_delay"] = kwargs.get("tick_delay", 0.0)

    monkeypatch.setattr(simulation, "advance_time", record("advance"))
    monkeypatch.setattr(simulation, "maybe_trigger_event", record("event"))
    monkeypatch.setattr(simulation, "maybe_start_assault_timer", record("start"))
    monkeypatch.setattr(simulation, "tick_assault_timer", record("tick"))
    monkeypatch.setattr(simulation, "resolve_assault", resolve_stub)

    simulation.step_world(state, tick_delay=0.3)

    assert calls["advance"] == 1
    assert calls["event"] == 1
    assert calls["start"] == 0
    assert calls["tick"] == 0
    assert resolved["tick_delay"] == 0.3
