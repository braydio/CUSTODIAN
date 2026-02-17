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

    def _fake_resolve(assault_instance, on_tick, state=None):
        class _Sector:
            name = "COMMS"

            @staticmethod
            def has_hostiles() -> bool:
                return False

        on_tick([_Sector()], 0)
        return {"duration": 1, "spawned": 0, "killed": 0, "retreated": 0, "remaining": 0}

    monkeypatch.setattr(
        "game.simulations.world_state.core.assaults.resolve_tactical_assault",
        _fake_resolve,
    )
    monkeypatch.setattr("game.simulations.world_state.core.assaults.time.sleep", lambda *_: None)

    resolve_assault(state, tick_delay=0.0)
    output = capsys.readouterr().out

    assert "'tick': 1" in output

