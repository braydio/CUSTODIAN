"""Tests for terminal command processing behavior."""

from types import SimpleNamespace

from game.simulations.world_state.core.config import (
    ARCHIVE_LOSS_LIMIT,
    COMMAND_BREACH_RECOVERY_TICKS,
    COMMAND_CENTER_BREACH_DAMAGE,
)
from game.simulations.world_state.core import assaults
from game.simulations.world_state.core.state import GameState, check_failure
from game.simulations.world_state.core.structures import StructureState
from game.simulations.world_state.terminal.commands.wait import WaitTickInfo
from game.simulations.world_state.terminal.processor import process_command


def _disable_wait_tick_pause(monkeypatch) -> None:
    monkeypatch.setattr("game.simulations.world_state.terminal.commands.wait.time.sleep", lambda *_: None)


def test_wait_advances_five_ticks(monkeypatch) -> None:
    """WAIT should advance one wait unit (5 ticks) and report advancement."""

    _disable_wait_tick_pause(monkeypatch)

    state = GameState()

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert state.time == 5
    assert result.text == "TIME ADVANCED."


def test_wait_nx_advances_units_of_five_ticks(monkeypatch) -> None:
    """WAIT NX should advance time by N wait units (5 ticks each)."""

    _disable_wait_tick_pause(monkeypatch)

    state = GameState()

    def _quiet_step(local_state: GameState) -> bool:
        local_state.time += 1
        local_state.ambient_threat = 0.4
        local_state.assault_timer = None
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _quiet_step,
    )

    result = process_command(state, "WAIT 5X")

    assert result.ok is True
    assert state.time == 25
    assert result.text == "TIME ADVANCED."
    assert result.lines is None


def test_wait_suppresses_repeated_event_blocks(monkeypatch) -> None:
    """Repeated tick signals should not be emitted back-to-back."""

    _disable_wait_tick_pause(monkeypatch)
    state = GameState()

    def _repeat_event(_state: GameState) -> WaitTickInfo:
        _state.time += 1
        return WaitTickInfo(
            fidelity="FULL",
            fidelity_lines=[],
            debug_lines=[],
            event_name="Comms Burst",
            event_sector="COMMS",
            repair_names=[],
            fabrication_lines=[],
            relay_lines=[],
            assault_started=False,
            assault_warning=False,
            assault_active=False,
            became_failed=False,
            warning_window=6,
            assault_lines=[],
            structure_loss_lines=[],
            stability_declining=True,
        )

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait._advance_tick",
        _repeat_event,
    )

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.text == "TIME ADVANCED."
    assert result.lines == [
        "[EVENT] COMMS BURST DETECTED",
        "[STATUS SHIFT] SYSTEM STABILITY DECLINING",
    ]


def test_wait_surfaces_transit_intercept_lines(monkeypatch) -> None:
    _disable_wait_tick_pause(monkeypatch)
    monkeypatch.setattr("game.simulations.world_state.core.assaults.maybe_warn", lambda *_: None)
    state = GameState(seed=21)
    state.turret_ammo_stock = 1
    approach = assaults.AssaultApproach(
        ingress="INGRESS_N",
        target="ARCHIVE",
        route=["INGRESS_N", "T_NORTH", "ARCHIVE"],
    )
    approach.index = 1
    state.assaults = [approach]

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.lines is not None
    assert any(line.startswith("[INTERCEPT] T_NORTH") for line in result.lines)


def test_status_does_not_mutate_state() -> None:
    """STATUS should report state without changing time."""

    state = GameState()

    result = process_command(state, "STATUS")

    assert result.ok is True
    assert state.time == 0
    assert result.text.startswith("TIME: 0")


def test_focus_sets_sector_without_advancing_time() -> None:
    """FOCUS should set a focused sector and not advance time."""

    state = GameState()

    result = process_command(state, "FOCUS POWER")

    assert result.ok is True
    assert result.text == "[FOCUS SET] POWER"
    assert state.time == 0
    assert state.focused_sector == "PW"
    assert state.hardened is False


def test_harden_sets_posture_without_advancing_time() -> None:
    """HARDEN should set hardened posture and clear focus."""

    state = GameState()
    process_command(state, "FOCUS POWER")

    result = process_command(state, "HARDEN")

    assert result.ok is True
    assert result.text == "[HARDENING SYSTEMS]"
    assert state.time == 0
    assert state.hardened is True
    assert state.focused_sector is None


def test_unknown_command_returns_locked_error_lines() -> None:
    """Unknown commands should return the locked error phrasing."""

    state = GameState()

    result = process_command(state, "nonesuch")

    assert result.ok is False
    assert result.text == "UNKNOWN COMMAND."
    assert result.lines == ["TYPE HELP FOR AVAILABLE COMMANDS."]


def test_failure_mode_locks_non_reset_commands(monkeypatch) -> None:
    """After failure, non-reset commands should be rejected."""

    state = GameState()
    state.sectors["COMMAND"].damage = COMMAND_CENTER_BREACH_DAMAGE
    _disable_wait_tick_pause(monkeypatch)

    wait_result = None
    for _ in range(COMMAND_BREACH_RECOVERY_TICKS + 6):
        wait_result = process_command(state, "WAIT")
        if wait_result.lines and wait_result.lines[-2:] == ["COMMAND CENTER LOST", "SESSION TERMINATED."]:
            break
    status_result = process_command(state, "STATUS")

    assert wait_result.ok is True
    assert wait_result is not None
    assert wait_result.lines[-2:] == ["COMMAND CENTER LOST", "SESSION TERMINATED."]
    assert status_result.ok is False
    assert status_result.text == "COMMAND CENTER LOST"
    assert status_result.lines == ["REBOOT REQUIRED. ONLY RESET OR REBOOT ACCEPTED."]


def test_reset_command_restores_session_after_failure(monkeypatch) -> None:
    """RESET should clear failure mode and restore baseline state."""

    state = GameState()
    state.sectors["COMMAND"].damage = COMMAND_CENTER_BREACH_DAMAGE
    _disable_wait_tick_pause(monkeypatch)
    for _ in range(COMMAND_BREACH_RECOVERY_TICKS + 6):
        wait_result = process_command(state, "WAIT")
        if wait_result.lines and wait_result.lines[-2:] == ["COMMAND CENTER LOST", "SESSION TERMINATED."]:
            break

    result = process_command(state, "RESET")

    assert result.ok is True
    assert result.text == "SYSTEM REBOOTED."
    assert result.lines == ["SESSION READY."]
    assert state.is_failed is False
    assert state.failure_reason is None
    assert state.time == 0


def test_wait_quiet_tick_emits_pressure_line(monkeypatch) -> None:
    """WAIT should emit only the primary line when no event or signal occurs."""

    state = GameState()
    _disable_wait_tick_pause(monkeypatch)

    def _quiet_step(local_state: GameState) -> bool:
        local_state.time += 1
        local_state.ambient_threat = 1.8
        local_state.assault_timer = 17
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _quiet_step,
    )

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.text == "TIME ADVANCED."
    assert result.lines is None


def test_wait_quiet_tick_pressure_line_has_no_empty_entries(monkeypatch) -> None:
    """WAIT quiet-tick fallback should emit only the primary line."""

    state = GameState()
    _disable_wait_tick_pause(monkeypatch)

    def _quiet_step(local_state: GameState) -> bool:
        local_state.time += 1
        local_state.ambient_threat = 0.4
        local_state.assault_timer = None
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _quiet_step,
    )

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.lines is None


def test_archive_loss_triggers_failure(monkeypatch) -> None:
    """Archive loss threshold should trigger failure on the next tick."""

    state = GameState()
    state.archive_losses = ARCHIVE_LOSS_LIMIT
    _disable_wait_tick_pause(monkeypatch)

    def _failure_step(local_state: GameState) -> bool:
        local_state.time += 1
        return check_failure(local_state)

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _failure_step,
    )

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.lines == ["ARCHIVAL INTEGRITY LOST", "SESSION TERMINATED."]


def test_deploy_transitions_to_field_mode() -> None:
    state = GameState()

    result = process_command(state, "DEPLOY NORTH")

    assert result.ok is True
    assert result.text == "DEPLOYING TO T_NORTH."
    assert state.player_mode == "FIELD"


def test_deploy_autoroutes_sector_when_fidelity_full() -> None:
    state = GameState()

    result = process_command(state, "DEPLOY ARCHIVE")

    assert result.ok is True
    assert result.text == "DEPLOYING TO T_NORTH."
    assert state.player_mode == "FIELD"


def test_deploy_autoroutes_gateway_to_south_transit() -> None:
    state = GameState()

    result = process_command(state, "DEPLOY GATEWAY")

    assert result.ok is True
    assert result.text == "DEPLOYING TO T_SOUTH."
    assert state.player_mode == "FIELD"


def test_deploy_degraded_returns_args_and_context() -> None:
    state = GameState()
    state.structures["CM_CORE"].state = StructureState.DAMAGED

    result = process_command(state, "DEPLOY ARCHIVE")

    assert result.ok is True
    assert result.text == "INVALID DEPLOYMENT TARGET."
    assert result.lines == [
        "TRANSIT LOCK: USE DEPLOY NORTH OR DEPLOY SOUTH.",
        "UNRESOLVED ROUTE TOKEN: ARCHIVE.",
    ]


def test_wait_emits_fidelity_upgrade_event(monkeypatch) -> None:
    _disable_wait_tick_pause(monkeypatch)
    state = GameState()
    state.structures["CM_CORE"].state = StructureState.DAMAGED
    state.sectors["COMMS"].power = 0.6
    state.fidelity = "DEGRADED"
    state.structures["CM_CORE"].state = StructureState.OPERATIONAL
    state.sectors["COMMS"].power = 1.0

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.text == "TIME ADVANCED."
    assert result.lines is not None
    assert "[EVENT] SIGNAL CLARITY RESTORED" in result.lines


def test_wait_surfaces_structure_loss_once_at_full_fidelity(monkeypatch) -> None:
    state = GameState()
    state.pending_structure_losses.add("CM_CORE")

    def _quiet_step(local_state: GameState) -> bool:
        local_state.time += 1
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _quiet_step,
    )

    first = process_command(state, "WAIT")
    second = process_command(state, "WAIT")

    assert first.ok is True
    assert first.lines is not None
    assert "[EVENT] STRUCTURE LOST: CM_CORE" in first.lines
    assert second.ok is True
    assert second.lines is None


def test_wait_lost_fidelity_suppresses_structure_identity(monkeypatch) -> None:
    state = GameState()
    state.pending_structure_losses.add("CM_CORE")
    state.structures["CM_CORE"].state = StructureState.DESTROYED
    state.sectors["COMMS"].power = 0.0

    def _quiet_step(local_state: GameState) -> bool:
        local_state.time += 1
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _quiet_step,
    )

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.lines is None


def test_status_includes_approach_eta_in_command_mode() -> None:
    state = GameState()
    state.assaults = [
        SimpleNamespace(
            state="APPROACHING",
            target="ARCHIVE",
            eta_ticks=lambda: 4,
        )
    ]

    result = process_command(state, "STATUS")

    assert result.ok is True
    assert result.lines is not None
    assert any(line.startswith("THREAT: ARCHIVE ETA~4") for line in result.lines)


def test_deploy_fragmented_keeps_terse_invalid_target() -> None:
    state = GameState()
    state.structures["CM_CORE"].state = StructureState.DAMAGED
    state.sectors["COMMS"].power = 0.5

    result = process_command(state, "DEPLOY ARCHIVE")

    assert result.ok is True
    assert result.text == "INVALID DEPLOYMENT TARGET."


def test_debug_blocked_when_dev_mode_disabled() -> None:
    state = GameState()

    result = process_command(state, "DEBUG ASSAULT")

    assert result.ok is False
    assert result.text == "DEV MODE DISABLED."


def test_debug_assault_forces_assault_in_dev_mode(monkeypatch) -> None:
    state = GameState()
    state.dev_mode = True
    monkeypatch.setattr(
        "game.simulations.world_state.terminal.processor.start_assault",
        lambda local_state: setattr(local_state, "in_major_assault", True),
    )

    result = process_command(state, "DEBUG ASSAULT")

    assert result.ok is True
    assert result.text == "ASSAULT FORCED."
    assert state.in_major_assault is True


def test_debug_tick_advances_exact_tick_count(monkeypatch) -> None:
    state = GameState()
    state.dev_mode = True

    def _advance(local_state: GameState) -> bool:
        local_state.time += 1
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.processor.step_world",
        _advance,
    )

    result = process_command(state, "DEBUG TICK 7")

    assert result.ok is True
    assert result.text == "ADVANCED 7 TICKS."
    assert state.time == 7


def test_debug_sector_mutators_accept_sector_id() -> None:
    state = GameState()
    state.dev_mode = True

    power_result = process_command(state, "DEBUG POWER CM 0.45")
    damage_result = process_command(state, "DEBUG DAMAGE PW 1.25")

    assert power_result.ok is True
    assert power_result.text == "COMMS POWER SET TO 0.45"
    assert damage_result.ok is True
    assert damage_result.text == "POWER DAMAGE SET TO 1.25"
    assert damage_result.lines == ["STRUCTURES UPDATED: 1 -> DAMAGED"]
    assert state.sectors["COMMS"].power == 0.45
    assert state.sectors["POWER"].damage == 1.25
    assert state.structures["PW_CORE"].state == StructureState.DAMAGED


def test_help_shows_debug_hint_only_in_dev_mode() -> None:
    normal_state = GameState()
    dev_state = GameState()
    dev_state.dev_mode = True

    normal = process_command(normal_state, "HELP")
    dev = process_command(dev_state, "HELP")

    assert normal.ok is True
    assert dev.ok is True
    assert normal.lines is not None
    assert dev.lines is not None
    assert "DEBUG COMMANDS (DEV MODE):" not in normal.lines
    assert "DEBUG COMMANDS (DEV MODE):" in dev.lines
    assert "- DEBUG HELP" in dev.lines


def test_help_topic_shows_focused_category() -> None:
    state = GameState()

    result = process_command(state, "HELP FABRICATION")

    assert result.ok is True
    assert result.text == "HELP > FABRICATION"
    assert result.lines == [
        "- FAB ADD <ITEM>  Queue item production",
        "- FAB QUEUE  View active fabrication queue",
        "- FAB CANCEL <ID>  Cancel queued fabrication job",
        "- FAB PRIORITY <CATEGORY>  Reorder by category priority",
    ]


def test_deploy_blocked_while_repair_active() -> None:
    state = GameState()
    state.structures["CM_CORE"].state = StructureState.DAMAGED
    repair_result = process_command(state, "REPAIR CM_CORE")
    deploy_result = process_command(state, "DEPLOY NORTH")

    assert repair_result.ok is True
    assert "REPAIR" in repair_result.text
    assert deploy_result.ok is True
    assert deploy_result.text == "ACTION IN PROGRESS."
    assert state.active_task is None


def test_repair_full_stabilizes_sector_with_extra_material_cost() -> None:
    state = GameState()
    state.materials = 3
    state.sectors["DEFENSE GRID"].damage = 1.4
    state.sectors["DEFENSE GRID"].alertness = 1.1

    result = process_command(state, "REPAIR DF_CORE FULL")

    assert result.ok is True
    assert result.text.startswith("FULL RESTORE COMPLETE: DEFENSE GRID")
    assert state.materials == 2
    assert state.sectors["DEFENSE GRID"].damage < 0.8
    assert state.sectors["DEFENSE GRID"].alertness < 0.8
    assert "DEFENSE GRID" in state.sector_recovery_windows


def test_repair_command_core_is_local_when_in_command_mode() -> None:
    state = GameState()
    state.structures["CC_CORE"].state = StructureState.DAMAGED

    result = process_command(state, "REPAIR CC_CORE")

    assert result.ok is True
    assert result.text.startswith("MANUAL REPAIR STARTED:")


def test_repair_full_command_core_uses_local_mode_when_in_command() -> None:
    state = GameState()
    state.materials = 3
    state.sectors["COMMAND"].damage = 1.2
    state.sectors["COMMAND"].alertness = 1.1

    result = process_command(state, "REPAIR CC_CORE FULL")

    assert result.ok is True
    assert result.text.startswith("FULL RESTORE COMPLETE: COMMAND")
    assert "(LOCAL," in result.text


def test_repair_full_requires_operational_structure() -> None:
    state = GameState()
    state.structures["DF_CORE"].state = StructureState.DAMAGED
    state.sectors["DEFENSE GRID"].damage = 1.2

    result = process_command(state, "REPAIR DF_CORE FULL")

    assert result.ok is True
    assert result.text == "STRUCTURE NOT YET OPERATIONAL. COMPLETE REPAIRS FIRST."


def test_set_fab_and_fortify_commands_apply_levels() -> None:
    state = GameState()

    set_fab = process_command(state, "SET FAB DEFENSE 4")
    fortify = process_command(state, "FORTIFY PW 3")

    assert set_fab.ok is True
    assert set_fab.text == "FABRICATION DEFENSE ALLOCATION SET TO 4."
    assert fortify.ok is True
    assert fortify.text == "FORTIFICATION POWER SET TO 3."
    assert state.fab_allocation["DEFENSE"] == 4
    assert state.sector_fort_levels["POWER"] == 3


def test_status_includes_policy_state_section() -> None:
    state = GameState()
    state.policies.repair_intensity = 4
    state.policies.defense_readiness = 1
    state.policies.surveillance_coverage = 3

    result = process_command(state, "STATUS FULL")

    assert result.ok is True
    assert result.lines is not None
    assert "POLICY STATE:" in result.lines
    assert any(line.startswith("- REPAIR INTENSITY: ") for line in result.lines)
    assert any(line.startswith("- POWER LOAD: ") for line in result.lines)


def test_status_group_fabrication_reports_queue_and_allocation() -> None:
    state = GameState(seed=7)

    result = process_command(state, "STATUS FAB")

    assert result.ok is True
    assert result.text == "STATUS GROUP: FABRICATION"
    assert result.lines is not None
    assert "FAB ALLOCATION:" in result.lines
    assert "FAB QUEUE: EMPTY" in result.lines


def test_status_group_policy_reports_doctrine_and_allocation() -> None:
    state = GameState()

    result = process_command(state, "STATUS POLICY")

    assert result.ok is True
    assert result.text == "STATUS GROUP: POLICY"
    assert result.lines is not None
    assert "DEFENSE ALLOCATION:" in result.lines
    assert any(line.startswith("- PERIMETER: ") for line in result.lines)
    assert any(line.startswith("- REPAIR INTENSITY: ") for line in result.lines)


def test_status_group_systems_reports_sector_rows() -> None:
    state = GameState()

    result = process_command(state, "STATUS SYSTEMS")

    assert result.ok is True
    assert result.text == "STATUS GROUP: SYSTEMS"
    assert result.lines is not None
    assert "SECTORS:" in result.lines
    assert any("COMMAND" in line for line in result.lines)


def test_status_group_relay_reports_network_summary() -> None:
    state = GameState()

    result = process_command(state, "STATUS RELAY")

    assert result.ok is True
    assert result.text == "STATUS GROUP: RELAY"
    assert result.lines is not None
    assert "RELAY NETWORK:" in result.lines


def test_status_invalid_group_returns_usage() -> None:
    state = GameState()

    result = process_command(state, "STATUS BOGUS")

    assert result.ok is False
    assert result.text == "STATUS <BRIEF|FULL|FAB|POSTURE|ASSAULT|POLICY|SYSTEMS|RELAY>"


def test_policy_show_and_preset_commands_apply_state() -> None:
    state = GameState()

    preset = process_command(state, "POLICY PRESET SIEGE")
    shown = process_command(state, "POLICY SHOW")

    assert preset.ok is True
    assert preset.text == "POLICY PRESET APPLIED: SIEGE."
    assert state.policies.defense_readiness == 4
    assert shown.ok is True
    assert shown.text == "POLICY STATE:"
    assert shown.lines is not None
    assert "- DEFENSE: 4" in shown.lines


def test_relay_commands_scan_stabilize_and_sync(monkeypatch) -> None:
    _disable_wait_tick_pause(monkeypatch)
    state = GameState(seed=13)

    scan = process_command(state, "SCAN RELAYS")
    assert scan.ok is True
    assert scan.text == "RELAY NETWORK:"

    deploy = process_command(state, "DEPLOY NORTH")
    assert deploy.ok is True
    process_command(state, "WAIT")
    stabilize = process_command(state, "STABILIZE RELAY R_NORTH")
    assert stabilize.ok is True
    assert stabilize.text.startswith("STABILIZING R_NORTH")

    process_command(state, "WAIT")
    process_command(state, "WAIT")
    process_command(state, "WAIT")

    back = process_command(state, "RETURN")
    assert back.ok is True
    process_command(state, "WAIT")
    sync = process_command(state, "SYNC")
    assert sync.ok is True
    assert sync.text.startswith("SYNC COMPLETE:")
    assert state.knowledge_index["RELAY_RECOVERY"] >= 1


def test_sync_requires_command_authority() -> None:
    state = GameState()
    process_command(state, "DEPLOY NORTH")
    process_command(state, "WAIT")

    result = process_command(state, "SYNC")

    assert result.ok is False
    assert result.text == "COMMAND AUTHORITY REQUIRED."


def test_debug_help_lists_debug_commands() -> None:
    state = GameState()
    state.dev_mode = True

    result = process_command(state, "DEBUG HELP")

    assert result.ok is True
    assert result.text == "DEBUG COMMANDS:"
    assert result.lines == [
        "- DEBUG ASSAULT",
        "- DEBUG TICK <N>",
        "- DEBUG TIMER <VALUE>",
        "- DEBUG POWER <SECTOR> <VALUE>",
        "- DEBUG DAMAGE <SECTOR> <VALUE>",
        "- DEBUG TRACE",
        "- DEBUG REPORT",
        "- DEBUG HELP",
    ]


def test_fab_command_loop_add_queue_cancel_priority() -> None:
    state = GameState(seed=5)
    state.inventory["SCRAP"] = 10

    added = process_command(state, "FAB ADD COMPONENTS_BATCH")
    queued = process_command(state, "FAB QUEUE")
    set_priority = process_command(state, "FAB PRIORITY DRONES")
    canceled = process_command(state, "FAB CANCEL 1")

    assert added.ok is True
    assert added.text.startswith("FAB QUEUED:")
    assert queued.ok is True
    assert queued.text == "FAB QUEUE:"
    assert queued.lines is not None
    assert "1." in queued.lines[0]
    assert set_priority.ok is True
    assert set_priority.text == "FAB PRIORITY SET: DRONES"
    assert canceled.ok is True
    assert canceled.text == "FAB TASK 1 CANCELED."


def test_wait_uses_world_five_ticks_and_assault_one_tick(monkeypatch) -> None:
    _disable_wait_tick_pause(monkeypatch)
    state = GameState(seed=3)

    world_wait = process_command(state, "WAIT")
    assert world_wait.ok is True
    assert state.time == 5

    state.dev_mode = True
    process_command(state, "DEBUG ASSAULT")
    assault_wait = process_command(state, "WAIT")

    assert assault_wait.ok is True
    assert state.time == 6
    assert state.current_assault is not None


def test_assault_progresses_over_multiple_waits(monkeypatch) -> None:
    _disable_wait_tick_pause(monkeypatch)
    state = GameState(seed=11)
    state.dev_mode = True
    process_command(state, "DEBUG ASSAULT")

    first = process_command(state, "WAIT")
    assert first.ok is True
    assert first.lines is not None
    assert any("ASSAULT ACTIVE" in line for line in first.lines)

    for _ in range(20):
        process_command(state, "WAIT")
        if state.current_assault is None:
            break

    assert state.current_assault is None


def test_debug_trace_toggles_assault_trace_flag() -> None:
    state = GameState()
    state.dev_mode = True

    result = process_command(state, "DEBUG TRACE")

    assert result.ok is True
    assert result.text == "ASSAULT TRACE = True"
    assert state.assault_trace_enabled is True


def test_debug_assault_trace_alias_toggles_trace_flag() -> None:
    state = GameState()
    state.dev_mode = True

    result = process_command(state, "DEBUG ASSAULT_TRACE")

    assert result.ok is True
    assert result.text == "ASSAULT TRACE = True"
    assert state.assault_trace_enabled is True


def test_debug_report_returns_recent_ledger_rows() -> None:
    from game.simulations.world_state.core.assault_ledger import AssaultTickRecord, append_record

    state = GameState()
    state.dev_mode = True
    state.last_target_weights = {"CC": 2.0}
    append_record(
        state,
        AssaultTickRecord(
            tick=state.time,
            targeted_sector="CC",
            target_weight=2.0,
            assault_strength=3.5,
            defense_mitigation=0.8,
            note="TEST",
        ),
    )

    result = process_command(state, "DEBUG REPORT")

    assert result.ok is True
    assert result.text == "ASSAULT REPORT:"
    assert result.lines is not None
    assert any("TARGET WEIGHTS:" in line for line in result.lines)
    assert any("NOTE=TEST" in line for line in result.lines)


def test_wait_surfaces_debug_trace_lines(monkeypatch) -> None:
    _disable_wait_tick_pause(monkeypatch)
    state = GameState()
    state.dev_mode = True
    state.dev_trace = True

    def _trace_step(local_state: GameState) -> bool:
        local_state.time += 1
        print("{'tick': 1, 'active_sectors': [], 'ambient_threat': 0.0, 'alertness': {}}")
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _trace_step,
    )

    result = process_command(state, "WAIT")

    assert result.ok is True
    assert result.lines is not None
    assert any(line.startswith("[DEBUG] {'tick': 1") for line in result.lines)


def test_status_shows_recovery_window_details_at_full_fidelity() -> None:
    state = GameState()
    state.sector_recovery_windows["DEFENSE GRID"] = {
        "remaining": 3.2,
        "damage_rate": 0.05,
        "alertness_rate": 0.1,
        "mode": "LOCAL",
    }

    result = process_command(state, "STATUS FULL")

    assert result.ok is True
    assert result.lines is not None
    assert "RECOVERY:" in result.lines
    assert "- DEFENSE GRID: LOCAL (4 TICKS)" in result.lines


def test_status_shows_generic_recovery_at_degraded_fidelity() -> None:
    state = GameState()
    state.sector_recovery_windows["POWER"] = {
        "remaining": 7.0,
        "damage_rate": 0.03,
        "alertness_rate": 0.06,
        "mode": "DRONE",
    }
    state.structures["CM_CORE"].state = StructureState.DAMAGED

    result = process_command(state, "STATUS FULL")

    assert result.ok is True
    assert result.lines is not None
    assert "RECOVERY:" in result.lines
    assert "- POWER: RECOVERY ACTIVE" in result.lines


def test_status_shows_debug_trace_section_when_enabled() -> None:
    state = GameState()
    state.dev_mode = True
    state.dev_trace = True
    state.assault_trace_enabled = True

    result = process_command(state, "STATUS")

    assert result.ok is True
    assert result.lines is not None
    assert "DEBUG:" in result.lines
    assert "- ASSAULT TRACE: ON" in result.lines
    assert any(line.startswith("- LEDGER ROWS: ") for line in result.lines)


def test_move_from_transit_to_comms_is_valid() -> None:
    state = GameState()
    process_command(state, "DEPLOY NORTH")
    process_command(state, "WAIT 2X")

    result = process_command(state, "MOVE COMMS")

    assert result.ok is True
    assert result.text == "MOVING TO COMMS."


def test_focus_denied_in_field_mode() -> None:
    state = GameState()
    process_command(state, "DEPLOY NORTH")

    result = process_command(state, "FOCUS POWER")

    assert result.ok is False
    assert result.text == "COMMAND AUTHORITY REQUIRED."


def test_field_mode_assault_warning_is_delayed(monkeypatch) -> None:
    from game.simulations.world_state.terminal.commands import wait as wait_cmd

    state = GameState()
    process_command(state, "DEPLOY NORTH")

    call_count = {"n": 0}

    def _step_to_assault(local_state: GameState) -> bool:
        local_state.time += 1
        local_state.assault_timer = None
        if call_count["n"] == 0:
            local_state.in_major_assault = True
        call_count["n"] += 1
        return False

    monkeypatch.setattr(
        "game.simulations.world_state.terminal.commands.wait.step_world",
        _step_to_assault,
    )

    tick1 = wait_cmd._advance_tick(state)
    tick2 = wait_cmd._advance_tick(state)
    tick3 = wait_cmd._advance_tick(state)

    assert tick1.assault_warning is False
    assert tick1.assault_started is False
    assert tick2.assault_warning is True
    assert tick3.assault_warning is False
