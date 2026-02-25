"""Tests for transit fortification (Assault-Resource Link Phase B)."""

from game.simulations.world_state.core import assaults
from game.simulations.world_state.core.simulation import step_world
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.processor import process_command


def _approach_on_north_transit() -> assaults.AssaultApproach:
    approach = assaults.AssaultApproach(
        ingress="INGRESS_N",
        target="ARCHIVE",
        route=["INGRESS_N", "T_NORTH", "ARCHIVE"],
    )
    approach.index = 1
    return approach


def test_fortify_command_sets_transit_level() -> None:
    state = GameState(seed=3)

    result = process_command(state, "FORTIFY T_NORTH 3")

    assert result.ok is True
    assert result.text == "FORTIFICATION T_NORTH SET TO 3."
    assert state.transit_fort_levels["T_NORTH"] == 3


def test_transit_fortification_reduces_intercept_threat_multiplier(monkeypatch) -> None:
    monkeypatch.setattr(assaults, "maybe_warn", lambda *_: None)

    baseline = GameState(seed=7)
    baseline.turret_ammo_stock = 3
    baseline.transit_fort_levels["T_NORTH"] = 0
    baseline.assaults = [_approach_on_north_transit()]

    fortified = GameState(seed=7)
    fortified.turret_ammo_stock = 3
    fortified.transit_fort_levels["T_NORTH"] = 4
    fortified.assaults = [_approach_on_north_transit()]

    assaults.advance_assaults(baseline)
    assaults.advance_assaults(fortified)

    assert fortified.assaults[0].threat_mult < baseline.assaults[0].threat_mult


def test_transit_fortification_respects_threat_floor(monkeypatch) -> None:
    monkeypatch.setattr(assaults, "maybe_warn", lambda *_: None)
    state = GameState(seed=9)
    state.turret_ammo_stock = 1
    state.transit_fort_levels["T_NORTH"] = 4
    approach = _approach_on_north_transit()
    approach.threat_mult = 0.71
    state.assaults = [approach]

    assaults.advance_assaults(state)

    assert state.assaults[0].threat_mult == assaults.THREAT_MULT_FLOOR


def test_transit_fortification_is_deterministic_over_100_ticks() -> None:
    left = GameState(seed=42)
    right = GameState(seed=42)
    for state in (left, right):
        state.transit_fort_levels["T_NORTH"] = 3
        state.transit_fort_levels["T_SOUTH"] = 2

    for _ in range(100):
        step_world(left)
        step_world(right)

    assert left.snapshot() == right.snapshot()


def test_wait_surfaces_intercept_line_with_transit_fortification(monkeypatch) -> None:
    monkeypatch.setattr("game.simulations.world_state.terminal.commands.wait.time.sleep", lambda *_: None)
    monkeypatch.setattr(assaults, "maybe_warn", lambda *_: None)
    state = GameState(seed=12)
    state.turret_ammo_stock = 1
    state.transit_fort_levels["T_NORTH"] = 2
    approach = _approach_on_north_transit()
    approach.ticks_to_next = 1
    state.assaults = [approach]

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.lines is not None
    assert any(line.startswith("[INTERCEPT] NORTH TRANSIT") for line in result.lines)


def test_status_full_reports_transit_fortification() -> None:
    state = GameState(seed=18)
    state.transit_fort_levels["T_NORTH"] = 2

    result = process_command(state, "STATUS FULL")

    assert result.ok is True
    assert result.lines is not None
    assert "- TRANSIT FORTIFICATION: T_NORTH:2" in result.lines
