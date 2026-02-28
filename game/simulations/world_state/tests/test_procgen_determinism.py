"""Determinism checks for procgen signal projection infrastructure."""

from __future__ import annotations

from game.procgen.projection import project
from game.procgen.signals import Signal
from game.simulations.world_state.core.simulation import step_world
from game.simulations.world_state.core.state import GameState


def _project_sequence(seed: int, text_seed: int | None = None) -> list[str]:
    state = GameState(seed=seed, text_seed=text_seed)
    lines: list[str] = []
    for t in range(1, 41):
        state.time = t
        lines.extend(
            project(
                [Signal.EVENT_DETECTED, Signal.STATUS_DECLINING],
                fidelity="FULL",
                state=state,
                context={"event_name": "Comms Burst"},
                salt="det-seq",
            )
        )
    return lines


def test_same_seed_same_projection_output() -> None:
    first = _project_sequence(seed=424242)
    second = _project_sequence(seed=424242)
    assert first == second


def test_text_rng_consumption_does_not_change_simulation_state() -> None:
    baseline = GameState(seed=1337)
    text_noise = GameState(seed=1337)

    for _ in range(500):
        text_noise.text_rng.random()

    for _ in range(25):
        step_world(baseline)
        step_world(text_noise)

    assert baseline.snapshot() == text_noise.snapshot()


def test_different_text_seed_changes_projection_variants() -> None:
    a = _project_sequence(seed=9001, text_seed=111)
    b = _project_sequence(seed=9001, text_seed=222)
    assert a != b

