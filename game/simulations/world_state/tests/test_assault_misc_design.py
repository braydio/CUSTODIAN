"""Tests for assault misc design integrations."""

from types import SimpleNamespace

from game.simulations.world_state.assault_outcome import AssaultOutcome
from game.simulations.world_state.core.assault_ledger import AssaultTickRecord, append_record
from game.simulations.world_state.core import assaults
from game.simulations.world_state.core.events import power_brownout
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import StructureState


def test_sector_target_weight_prefers_command_when_stable() -> None:
    state = GameState(seed=5)
    command = assaults._sector_target_weight(state, state.sectors["COMMAND"])
    storage = assaults._sector_target_weight(state, state.sectors["STORAGE"])
    assert command > storage


def test_sector_target_weight_allows_dynamic_damage_to_outweigh_static() -> None:
    state = GameState(seed=5)
    state.sectors["STORAGE"].damage = 1.8
    state.sectors["STORAGE"].alertness = 2.4
    command = assaults._sector_target_weight(state, state.sectors["COMMAND"])
    storage = assaults._sector_target_weight(state, state.sectors["STORAGE"])
    assert storage > command


def test_degrade_target_structures_tracks_loss_and_effects() -> None:
    state = GameState(seed=3)
    structure = state.structures["CM_CORE"]
    structure.state = StructureState.OFFLINE

    assaults._degrade_target_structures(state, {"COMMS"})
    baseline_lines = list(state.last_structure_loss_lines)
    assaults._degrade_target_structures(state, {"COMMS"})

    assert structure.state == StructureState.DESTROYED
    assert "CM_CORE" in state.pending_structure_losses
    assert any("COMMS CORE LOST" in line for line in baseline_lines)
    assert state.last_structure_loss_lines == baseline_lines


def test_autonomy_override_applies_on_severe_non_command_outcome() -> None:
    state = GameState(seed=3)
    state.autonomy_strength_bonus = 10.0
    assault = SimpleNamespace(target_sectors=[state.sectors["POWER"]])
    outcome = AssaultOutcome(
        threat_budget=100,
        duration=20,
        spawned=10,
        killed=1,
        retreated=1,
        remaining=8,
    )

    message = assaults._apply_assault_outcome(state, assault, outcome, {"POWER"})

    assert message == "[ASSAULT] AUTONOMOUS SYSTEMS HELD PERIMETER."


def test_autonomy_override_does_not_bypass_command_breach() -> None:
    state = GameState(seed=3)
    state.autonomy_strength_bonus = 100.0
    assault = SimpleNamespace(target_sectors=[state.sectors["COMMAND"]])
    outcome = AssaultOutcome(
        threat_budget=100,
        duration=20,
        spawned=10,
        killed=1,
        retreated=1,
        remaining=8,
    )

    message = assaults._apply_assault_outcome(state, assault, outcome, {"COMMAND"})

    assert message == "[ASSAULT] COMMAND BREACHED."


def test_compute_route_from_ingress_to_archive() -> None:
    route = assaults.compute_route("INGRESS_N", "ARCHIVE")
    assert route == ["INGRESS_N", "T_NORTH", "ARCHIVE"]


def test_spawn_assault_creates_approach_and_eta() -> None:
    state = GameState(seed=9)
    state.ambient_threat = 3.5
    state.rng.random = lambda: 0.0
    state.rng.choice = lambda choices: "INGRESS_N"

    assaults.maybe_spawn_assault(state)

    assert len(state.assaults) == 1
    approach = state.assaults[0]
    assert approach.state == "APPROACHING"
    assert approach.route[0] == "INGRESS_N"
    assert state.assault_timer is not None


def test_advance_assaults_moves_on_edge_tick_budget() -> None:
    state = GameState(seed=9)
    state.ambient_threat = 3.5
    state.rng.random = lambda: 0.0
    state.rng.choice = lambda choices: "INGRESS_N"
    assaults.maybe_spawn_assault(state)
    approach = state.assaults[0]
    start_node = approach.current_node()

    assaults.advance_assaults(state)
    assert approach.current_node() == start_node
    assaults.advance_assaults(state)
    assert approach.current_node() != start_node


def test_transit_intercept_spends_ammo_and_reduces_threat_multiplier(monkeypatch) -> None:
    state = GameState(seed=9)
    state.turret_ammo_stock = 3
    monkeypatch.setattr(assaults, "maybe_warn", lambda *_: None)
    approach = assaults.AssaultApproach(
        ingress="INGRESS_N",
        target="ARCHIVE",
        route=["INGRESS_N", "T_NORTH", "ARCHIVE"],
    )
    approach.index = 1
    state.assaults = [approach]

    assaults.advance_assaults(state)

    assert state.turret_ammo_stock == 2
    assert approach.threat_mult < 1.0
    assert any(line.startswith("[INTERCEPT] T_NORTH") for line in state.last_assault_lines)


def test_transit_intercept_does_not_apply_without_ammo(monkeypatch) -> None:
    state = GameState(seed=9)
    state.turret_ammo_stock = 0
    monkeypatch.setattr(assaults, "maybe_warn", lambda *_: None)
    approach = assaults.AssaultApproach(
        ingress="INGRESS_N",
        target="ARCHIVE",
        route=["INGRESS_N", "T_NORTH", "ARCHIVE"],
    )
    approach.index = 1
    state.assaults = [approach]

    assaults.advance_assaults(state)

    assert state.turret_ammo_stock == 0
    assert approach.threat_mult == 1.0
    assert not any(line.startswith("[INTERCEPT]") for line in state.last_assault_lines)


def test_transit_intercept_mitigation_applies_to_started_assault(monkeypatch) -> None:
    seeded = 11
    monkeypatch.setattr(assaults, "maybe_warn", lambda *_: None)

    with_ammo = GameState(seed=seeded)
    with_ammo.turret_ammo_stock = 1
    approach_with = assaults.AssaultApproach(
        ingress="INGRESS_N",
        target="ARCHIVE",
        route=["INGRESS_N", "T_NORTH", "ARCHIVE"],
    )
    approach_with.index = 1
    approach_with.ticks_to_next = 1
    with_ammo.assaults = [approach_with]

    without_ammo = GameState(seed=seeded)
    without_ammo.turret_ammo_stock = 0
    approach_without = assaults.AssaultApproach(
        ingress="INGRESS_N",
        target="ARCHIVE",
        route=["INGRESS_N", "T_NORTH", "ARCHIVE"],
    )
    approach_without.index = 1
    approach_without.ticks_to_next = 1
    without_ammo.assaults = [approach_without]

    assaults.advance_assaults(with_ammo)
    assaults.advance_assaults(without_ammo)

    assert with_ammo.current_assault is not None
    assert without_ammo.current_assault is not None
    assert with_ammo.current_assault.threat_budget < without_ammo.current_assault.threat_budget


def test_transit_intercept_multiplier_is_bounded_by_floor(monkeypatch) -> None:
    state = GameState(seed=7)
    state.turret_ammo_stock = 1
    monkeypatch.setattr(assaults, "maybe_warn", lambda *_: None)
    approach = assaults.AssaultApproach(
        ingress="INGRESS_N",
        target="ARCHIVE",
        route=["INGRESS_N", "T_NORTH", "ARCHIVE"],
    )
    approach.index = 1
    approach.threat_mult = 0.71
    state.assaults = [approach]

    assaults.advance_assaults(state)

    assert approach.threat_mult == assaults.ASSAULT_TRANSIT_INTERCEPT_FLOOR


def test_award_salvage_maps_penetration_to_materials() -> None:
    state = GameState(seed=1)
    base = state.materials
    partial = AssaultOutcome(
        threat_budget=100,
        duration=10,
        spawned=10,
        killed=8,
        retreated=1,
        remaining=1,
    )
    severe = AssaultOutcome(
        threat_budget=100,
        duration=10,
        spawned=10,
        killed=1,
        retreated=1,
        remaining=8,
    )

    assaults.award_salvage(state, partial)
    assaults.award_salvage(state, severe)

    assert state.materials == base + 3


def test_target_weights_captured_when_trace_enabled() -> None:
    state = GameState(seed=11)
    state.assault_trace_enabled = True

    assaults._select_focus_targets(state, 2)

    assert state.last_target_weights
    assert "CC" in state.last_target_weights


def test_structure_destruction_adds_ledger_record() -> None:
    state = GameState(seed=3)
    structure = state.structures["CM_CORE"]
    structure.state = StructureState.OFFLINE

    assaults._degrade_target_structures(state, {"COMMS"})

    assert any(record.building_destroyed == "CM_CORE" for record in state.assault_ledger.ticks)


def test_power_brownout_logs_delta_when_trace_enabled() -> None:
    state = GameState(seed=3)
    state.assault_trace_enabled = True
    sector = state.sectors["POWER"]
    sector.power = 0.9

    power_brownout(state, sector)

    assert any(record.note and record.note.startswith("BROWNOUT:POWER_DELTA=") for record in state.assault_ledger.ticks)


def test_after_action_summary_includes_destroyed_structures() -> None:
    state = GameState(seed=2)
    append_record(
        state,
        AssaultTickRecord(
            tick=1,
            targeted_sector="CM",
            target_weight=0.0,
            assault_strength=0.0,
            defense_mitigation=0.0,
            building_destroyed="CM_CORE",
        ),
    )
    lines = assaults._generate_after_action_summary(state, 0)
    assert lines[0:2] == ["ASSAULT IMPACT:", "LOSS: CM_CORE"]
    assert any(line.startswith("POLICY LOAD: ") for line in lines)
