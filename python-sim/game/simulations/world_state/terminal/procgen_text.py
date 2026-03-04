"""World-state terminal text adapter for deterministic procedural messaging."""

from __future__ import annotations

from pathlib import Path

from game.procgen.engine import GrammarEngine, VariantMemory, load_grammar_bank
from game.procgen.projection import project
from game.procgen.signals import Signal
from game.simulations.world_state.core.state import GameState


_GRAMMAR_PATH = Path(__file__).resolve().parents[1] / "content" / "terminal_grammar.json"
_GRAMMAR_BANK = load_grammar_bank(_GRAMMAR_PATH)
_GRAMMAR_ENGINE = GrammarEngine(_GRAMMAR_BANK)


def _resolve_symbol(prefix: str, fidelity: str) -> str:
    return f"{prefix}.{fidelity.strip().lower()}"


def _state_memory(state: GameState) -> VariantMemory:
    memory = getattr(state, "variant_memory", None)
    if memory is None:
        memory = VariantMemory(max_recent=3)
        setattr(state, "variant_memory", memory)
    return memory


def _text_seed(state: GameState) -> int:
    return int(getattr(state, "text_seed", state.seed))


def _projection_enabled(state: GameState) -> bool:
    return bool(getattr(state, "procgen_projection_enabled", False))


def _first_or_none(lines: list[str]) -> str | None:
    return lines[0] if lines else None


def render_wait_event_line(
    state: GameState,
    *,
    fidelity: str,
    event_name: str,
    event_key: str | None = None,
    detected: bool | None = None,
) -> str | None:
    if fidelity == "LOST":
        return None
    if _projection_enabled(state):
        lines = project(
            [Signal.EVENT_DETECTED],
            fidelity=fidelity,
            state=state,
            context={"event_name": event_name, "event_key": event_key or ""},
            salt=f"t{state.time}|{event_key or event_name}|det={int(bool(detected))}",
        )
        return _first_or_none(lines)
    symbol = _resolve_symbol("wait.event", fidelity)
    context = {"event_name": event_name, "event_key": event_key or ""}
    salt = f"t{state.time}|{event_key or event_name}|det={int(bool(detected))}"
    line = _GRAMMAR_ENGINE.render(
        symbol,
        context=context,
        seed=_text_seed(state),
        salt=salt,
        memory=_state_memory(state),
    )
    return line or None


def render_wait_repair_line(state: GameState, *, fidelity: str, repair_name: str) -> str | None:
    if fidelity == "LOST":
        return None
    if _projection_enabled(state):
        lines = project(
            [Signal.REPAIR_COMPLETED],
            fidelity=fidelity,
            state=state,
            context={"repair_name": repair_name},
            salt=f"t{state.time}|{repair_name}",
        )
        return _first_or_none(lines)
    symbol = _resolve_symbol("wait.repair", fidelity)
    context = {"repair_name": repair_name}
    line = _GRAMMAR_ENGINE.render(
        symbol,
        context=context,
        seed=_text_seed(state),
        salt=f"t{state.time}|{repair_name}",
        memory=_state_memory(state),
    )
    return line or None


def render_wait_warning_line(state: GameState, *, fidelity: str) -> str | None:
    if fidelity == "LOST":
        return None
    if _projection_enabled(state):
        lines = project(
            [Signal.ASSAULT_WARNING],
            fidelity=fidelity,
            state=state,
            salt=f"t{state.time}",
        )
        return _first_or_none(lines)
    symbol = _resolve_symbol("wait.warning", fidelity)
    line = _GRAMMAR_ENGINE.render(
        symbol,
        seed=_text_seed(state),
        salt=f"t{state.time}",
        memory=_state_memory(state),
    )
    return line or None


def render_wait_assault_line(state: GameState, *, fidelity: str) -> str | None:
    if fidelity == "LOST":
        return None
    if _projection_enabled(state):
        lines = project(
            [Signal.ASSAULT_ACTIVE],
            fidelity=fidelity,
            state=state,
            salt=f"t{state.time}",
        )
        return _first_or_none(lines)
    symbol = _resolve_symbol("wait.assault", fidelity)
    line = _GRAMMAR_ENGINE.render(
        symbol,
        seed=_text_seed(state),
        salt=f"t{state.time}",
        memory=_state_memory(state),
    )
    return line or None


def render_wait_status_shift_line(state: GameState, *, fidelity: str) -> str | None:
    if fidelity == "LOST":
        return None
    if _projection_enabled(state):
        lines = project(
            [Signal.STATUS_DECLINING],
            fidelity=fidelity,
            state=state,
            salt=f"t{state.time}",
        )
        return _first_or_none(lines)
    symbol = _resolve_symbol("wait.status_shift", fidelity)
    line = _GRAMMAR_ENGINE.render(
        symbol,
        seed=_text_seed(state),
        salt=f"t{state.time}",
        memory=_state_memory(state),
    )
    return line or None
