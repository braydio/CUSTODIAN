"""Quickstart tutorial state machine for live sessions."""

from __future__ import annotations

from dataclasses import dataclass, replace
from typing import Callable

from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import StructureState


@dataclass(frozen=True)
class TutorialStep:
    key: str
    prompt: list[str]
    expected: str
    condition: Callable[[GameState, dict, object], bool]
    reminder: list[str] | None = None


def start_quickstart(state: GameState) -> list[str]:
    state.tutorial_active = True
    state.tutorial_step = 0
    state.tutorial_assault_seen = False
    state.tutorial_last_hint_step = -1
    state.tutorial_just_started = True
    intro = [
        "TUTORIAL QUICKSTART ACTIVE.",
        "-----",
        "[TUTORIAL] THIS RUN GUIDES YOU THROUGH THE FIRST ASSAULT.",
        "[TUTORIAL] FOLLOW THE PROMPTS. YOU CAN BREAK OFF AT ANY TIME.",
        "[TUTORIAL] TYPE 'TUTORIAL QUICKSTART' AGAIN TO RESTART.",
    ]
    return intro + _step_prompt(state)


def apply_tutorial(state: GameState, result):
    if not state.tutorial_active:
        return result
    if state.tutorial_just_started:
        state.tutorial_just_started = False
        return result
    last = state.tutorial_last_command or {}
    if last.get("verb") == "TUTORIAL":
        return result

    if state.is_failed:
        result = _append_lines(result, ["[TUTORIAL] SESSION FAILED. QUICKSTART ABORTED."])
        state.tutorial_active = False
        return result

    if state.current_assault is not None or state.in_major_assault:
        state.tutorial_assault_seen = True

    step = _current_step(state)
    if step is None:
        return result

    if step.key == "REPAIR_CHECK" and not _has_damaged_structures(state):
        result = _append_lines(result, ["[TUTORIAL] NO DAMAGED STRUCTURES DETECTED."])
        result = _finish_tutorial(state, result)
        return result

    if step.condition(state, last, result):
        state.tutorial_step += 1
        state.tutorial_last_hint_step = -1
        next_prompt = _step_prompt(state)
        if next_prompt:
            result = _append_lines(result, next_prompt)
        else:
            result = _finish_tutorial(state, result)
        return result

    if state.tutorial_last_hint_step != state.tutorial_step:
        hint = step.reminder or [
            f"[TUTORIAL] EXPECTED: {step.expected}",
            "[TUTORIAL] RUN THE PROMPTED COMMAND TO CONTINUE.",
        ]
        result = _append_lines(result, hint)
        state.tutorial_last_hint_step = state.tutorial_step

    return result


def _finish_tutorial(state: GameState, result):
    result = _append_lines(
        result,
        [
            "-----",
            "[TUTORIAL] QUICKSTART COMPLETE. CONTROL RETURNED TO OPERATOR.",
            "[TUTORIAL] USE HELP OR TUTORIAL TOPICS FOR REFERENCE.",
        ],
    )
    state.tutorial_active = False
    return result


def _append_lines(result, lines: list[str]):
    if not lines:
        return result
    merged = list(result.lines or [])
    merged.extend(lines)
    return replace(result, lines=merged)


def _step_prompt(state: GameState) -> list[str]:
    step = _current_step(state)
    if step is None:
        return []
    return ["-----", f"[TUTORIAL] {step.key}"] + step.prompt


def _current_step(state: GameState) -> TutorialStep | None:
    if state.tutorial_step < 0 or state.tutorial_step >= len(QUICKSTART_STEPS):
        return None
    return QUICKSTART_STEPS[state.tutorial_step]


def _is_verb(last: dict, verb: str) -> bool:
    return str(last.get("verb", "")).upper() == verb


def _arg_at(last: dict, index: int) -> str:
    args = last.get("args") or []
    if index < 0 or index >= len(args):
        return ""
    return str(args[index]).strip().upper()


def _has_damaged_structures(state: GameState) -> bool:
    return any(structure.state != StructureState.OPERATIONAL for structure in state.structures.values())


QUICKSTART_STEPS = [
    TutorialStep(
        key="PHASE 1: STATUS BRIEF",
        prompt=[
            "[PROMPT] RUN: STATUS",
            "[WHY] ESTABLISH TIME, THREAT, AND CURRENT POSTURE BEFORE ACTING.",
        ],
        expected="STATUS",
        condition=lambda _state, last, _result: _is_verb(last, "STATUS"),
    ),
    TutorialStep(
        key="PHASE 2: POLICY BASELINE",
        prompt=[
            "[PROMPT] RUN: POLICY PRESET BALANCED",
            "[WHY] SETS A SAFE BASELINE FOR REPAIR, DEFENSE, AND SURVEILLANCE.",
        ],
        expected="POLICY PRESET <NAME>",
        condition=lambda _state, last, _result: _is_verb(last, "POLICY") and _arg_at(last, 0) == "PRESET",
    ),
    TutorialStep(
        key="PHASE 3: DOCTRINE",
        prompt=[
            "[PROMPT] RUN: CONFIG DOCTRINE COMMAND_FIRST",
            "[WHY] SHIFTS TARGET PRIORITY TOWARD COMMAND SURVIVABILITY.",
        ],
        expected="CONFIG DOCTRINE <NAME>",
        condition=lambda _state, last, _result: _is_verb(last, "CONFIG") and _arg_at(last, 0) == "DOCTRINE",
    ),
    TutorialStep(
        key="PHASE 4: DEFENSE BIAS",
        prompt=[
            "[PROMPT] RUN: ALLOCATE DEFENSE COMMAND 40",
            "[WHY] BIASES ROUTING TOWARD COMMAND WITHOUT STARVING PERIMETER.",
        ],
        expected="ALLOCATE DEFENSE <GROUP> <PERCENT>",
        condition=lambda _state, last, _result: _is_verb(last, "ALLOCATE") and _arg_at(last, 0) == "DEFENSE",
    ),
    TutorialStep(
        key="PHASE 5: TRANSIT FORTIFICATION",
        prompt=[
            "[PROMPT] RUN: FORTIFY T_NORTH 2",
            "[WHY] IMPROVES INTERCEPT PRESSURE ON THE NORTH LANE.",
        ],
        expected="FORTIFY T_NORTH <0-4>",
        condition=lambda _state, last, _result: _is_verb(last, "FORTIFY") and _arg_at(last, 0) == "T_NORTH",
    ),
    TutorialStep(
        key="PHASE 6: TRANSIT FORTIFICATION",
        prompt=[
            "[PROMPT] RUN: FORTIFY T_SOUTH 2",
            "[WHY] BALANCES INTERCEPT COVERAGE ACROSS BOTH LANES.",
        ],
        expected="FORTIFY T_SOUTH <0-4>",
        condition=lambda _state, last, _result: _is_verb(last, "FORTIFY") and _arg_at(last, 0) == "T_SOUTH",
    ),
    TutorialStep(
        key="PHASE 7: MATERIALS",
        prompt=[
            "[PROMPT] RUN: SCAVENGE 2X",
            "[WHY] BUILD A SMALL MATERIAL BUFFER BEFORE CONTACT.",
        ],
        expected="SCAVENGE NX",
        condition=lambda _state, last, _result: _is_verb(last, "SCAVENGE"),
    ),
    TutorialStep(
        key="PHASE 8: AMMO STOCK",
        prompt=[
            "[PROMPT] RUN: FAB ADD TURRET_AMMO",
            "[WHY] TRANSIT INTERCEPTS CONSUME AMMO BEFORE DIRECT ENGAGEMENT.",
        ],
        expected="FAB ADD <ITEM>",
        condition=lambda _state, last, _result: _is_verb(last, "FAB") and _arg_at(last, 0) == "ADD",
    ),
    TutorialStep(
        key="PHASE 9: ADVANCE CLOCK",
        prompt=[
            "[PROMPT] RUN: WAIT 2X",
            "[WHY] LET REPAIRS/FAB/THREAT EVOLVE BEFORE FIRST CONTACT.",
        ],
        expected="WAIT NX",
        condition=lambda _state, last, _result: _is_verb(last, "WAIT") and _arg_at(last, 0) != "UNTIL",
    ),
    TutorialStep(
        key="PHASE 10: ASSAULT TRACKING",
        prompt=[
            "[PROMPT] RUN: STATUS ASSAULT",
            "[WHY] CHECK APPROACH ETA AND ROUTE BEFORE COMMITTING TACTICAL BUFFS.",
        ],
        expected="STATUS ASSAULT",
        condition=lambda _state, last, _result: _is_verb(last, "STATUS") and _arg_at(last, 0) == "ASSAULT",
    ),
    TutorialStep(
        key="PHASE 11: FORCE CONTACT",
        prompt=[
            "[PROMPT] RUN: WAIT UNTIL ASSAULT",
            "[WHY] MOVE TO THE FIRST ACTIVE ENGAGEMENT WINDOW.",
            "[NOTE] IF THE SAFETY LIMIT TRIGGERS, RUN: WAIT 2X THEN TRY AGAIN.",
        ],
        expected="WAIT UNTIL ASSAULT",
        condition=lambda state, _last, _result: (
            state.current_assault is not None or state.in_major_assault
        ),
        reminder=[
            "[TUTORIAL] EXPECTED: WAIT UNTIL ASSAULT",
            "[TUTORIAL] IF NO ASSAULT SPAWNS, RUN WAIT 2X THEN TRY AGAIN.",
        ],
    ),
    TutorialStep(
        key="PHASE 12: TACTICAL BUFF",
        prompt=[
            "[PROMPT] RUN: BOOST DEFENSE COMMAND",
            "[WHY] SHORT-TERM MITIGATION DURING ACTIVE ASSAULT.",
        ],
        expected="BOOST DEFENSE <SECTOR>",
        condition=lambda _state, last, _result: _is_verb(last, "BOOST") and _arg_at(last, 0) == "DEFENSE",
    ),
    TutorialStep(
        key="PHASE 13: POWER SURGE",
        prompt=[
            "[PROMPT] RUN: REROUTE POWER COMMAND",
            "[WHY] TEMPORARY POWER LIFT TO THE MOST CRITICAL SECTOR.",
        ],
        expected="REROUTE POWER <SECTOR>",
        condition=lambda _state, last, _result: _is_verb(last, "REROUTE") and _arg_at(last, 0) == "POWER",
    ),
    TutorialStep(
        key="PHASE 14: REPAIR PRIORITY",
        prompt=[
            "[PROMPT] RUN: PRIORITIZE REPAIR COMMAND",
            "[WHY] BOOST REPAIR SPEED DURING ASSAULT WINDOW.",
        ],
        expected="PRIORITIZE REPAIR <SECTOR>",
        condition=lambda _state, last, _result: _is_verb(last, "PRIORITIZE") and _arg_at(last, 0) == "REPAIR",
    ),
    TutorialStep(
        key="PHASE 15: HOLD",
        prompt=[
            "[PROMPT] RUN: WAIT 3X",
            "[WHY] LET THE TACTICAL BUFFS RESOLVE OVER MULTIPLE TICKS.",
        ],
        expected="WAIT NX",
        condition=lambda _state, last, _result: _is_verb(last, "WAIT") and _arg_at(last, 0) != "UNTIL",
    ),
    TutorialStep(
        key="PHASE 15B: STAND DOWN",
        prompt=[
            "[PROMPT] RUN: WAIT 2X",
            "[WHY] WAIT UNTIL THE ASSAULT WINDOW CLOSES.",
        ],
        expected="WAIT NX",
        condition=lambda state, _last, _result: (
            state.tutorial_assault_seen and state.current_assault is None and not state.in_major_assault
        ),
        reminder=[
            "[TUTORIAL] WAIT UNTIL THE ASSAULT ENDS.",
            "[TUTORIAL] RUN: WAIT 2X IF IT IS STILL ACTIVE.",
        ],
    ),
    TutorialStep(
        key="PHASE 16: ASSESS AFTER-ACTION",
        prompt=[
            "[PROMPT] RUN: STATUS SYSTEMS",
            "[WHY] IDENTIFY DAMAGED STRUCTURES AND SECTOR STABILITY.",
        ],
        expected="STATUS SYSTEMS",
        condition=lambda _state, last, _result: _is_verb(last, "STATUS") and _arg_at(last, 0) == "SYSTEMS",
    ),
    TutorialStep(
        key="PHASE 17: RELAY SCAN",
        prompt=[
            "[PROMPT] RUN: SCAN RELAYS",
            "[WHY] DISCOVER RELAY STATUS AND STABILITY BEFORE FIELD OPERATIONS.",
        ],
        expected="SCAN RELAYS",
        condition=lambda _state, last, _result: _is_verb(last, "SCAN") and _arg_at(last, 0) == "RELAYS",
    ),
    TutorialStep(
        key="PHASE 18: RELAY DEPLOY",
        prompt=[
            "[PROMPT] RUN: DEPLOY NORTH",
            "[WHY] LEAVE COMMAND TO PERFORM FIELD RELAY OPERATIONS.",
        ],
        expected="DEPLOY <SECTOR>",
        condition=lambda _state, last, _result: _is_verb(last, "DEPLOY"),
    ),
    TutorialStep(
        key="PHASE 18B: RELAY STABILIZE",
        prompt=[
            "[PROMPT] RUN: STABILIZE RELAY R_NORTH",
            "[WHY] STABILIZE A RELAY TO GENERATE A KNOWLEDGE PACKET.",
        ],
        expected="STABILIZE RELAY <ID>",
        condition=lambda _state, last, _result: _is_verb(last, "STABILIZE"),
    ),
    TutorialStep(
        key="PHASE 19: RELAY SYNC",
        prompt=[
            "[PROMPT] RUN: RETURN THEN SYNC",
            "[WHY] RETURN TO COMMAND AND SYNC PACKETS INTO KNOWLEDGE.",
        ],
        expected="SYNC",
        condition=lambda _state, last, _result: _is_verb(last, "SYNC"),
        reminder=[
            "[TUTORIAL] EXPECTED: RETURN THEN SYNC",
            "[TUTORIAL] RUN RETURN FIRST IF STILL IN FIELD MODE.",
        ],
    ),
    TutorialStep(
        key="REPAIR_CHECK",
        prompt=[
            "[PROMPT] RUN: REPAIR <STRUCTURE_ID>",
            "[WHY] QUEUE A REPAIR ON YOUR MOST DAMAGED STRUCTURE.",
        ],
        expected="REPAIR <STRUCTURE_ID>",
        condition=lambda _state, last, _result: _is_verb(last, "REPAIR"),
    ),
]
