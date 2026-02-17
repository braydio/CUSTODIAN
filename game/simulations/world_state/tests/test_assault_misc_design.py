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
    assert lines[0:2] == ["AFTER ACTION SUMMARY:", "LOSS: CM_CORE"]
    assert lines[2].startswith("POLICY LOAD: ")
