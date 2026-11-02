"""Generic deterministic projection helpers for procgen signals."""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

from game.procgen.engine import GrammarEngine, VariantMemory, load_grammar_bank
from game.procgen.signals import Signal
from game.simulations.world_state.core.state import GameState


_GRAMMAR_PATH = (
    Path(__file__).resolve().parents[1]
    / "simulations"
    / "world_state"
    / "content"
    / "terminal_grammar.json"
)
_GRAMMAR_BANK = load_grammar_bank(_GRAMMAR_PATH)
_GRAMMAR_ENGINE = GrammarEngine(_GRAMMAR_BANK)

_SYMBOL_PREFIX_BY_SIGNAL: dict[Signal, str] = {
    Signal.EVENT_DETECTED: "wait.event",
    Signal.REPAIR_COMPLETED: "wait.repair",
    Signal.ASSAULT_WARNING: "wait.warning",
    Signal.ASSAULT_INBOUND: "wait.warning",
    Signal.ASSAULT_ACTIVE: "wait.assault",
    Signal.STATUS_DECLINING: "wait.status_shift",
}


def _state_memory(state: GameState) -> VariantMemory:
    memory = getattr(state, "variant_memory", None)
    if memory is None:
        memory = VariantMemory(max_recent=3)
        setattr(state, "variant_memory", memory)
    return memory


def _text_seed(state: GameState) -> int:
    return int(getattr(state, "text_seed", state.seed))


def project(
    signals: Iterable[Signal],
    *,
    fidelity: str,
    state: GameState,
    context: dict[str, str] | None = None,
    salt: str = "",
) -> list[str]:
    """Project semantic signals into deterministic terminal lines.

    This helper is additive infrastructure and intentionally does not mutate
    simulation state (outside variant-memory tracking for anti-repeat behavior).
    """

    level = str(fidelity).strip().upper()
    if level == "LOST":
        return []

    text_context = dict(context or {})
    text_context.setdefault("event_name", "Signal anomaly")
    text_context.setdefault("repair_name", "Unknown repair")

    signal_list = list(signals)
    lines: list[str] = []
    for idx, signal in enumerate(signal_list):
        prefix = _SYMBOL_PREFIX_BY_SIGNAL.get(signal)
        if not prefix:
            continue
        symbol = f"{prefix}.{level.lower()}"
        if len(signal_list) == 1:
            signal_salt = salt
        else:
            signal_salt = f"{salt}|i{idx}|{signal.value}"
        line = _GRAMMAR_ENGINE.render(
            symbol,
            context=text_context,
            seed=_text_seed(state),
            salt=signal_salt,
            memory=_state_memory(state),
        )
        if line:
            lines.append(line)
    return lines
