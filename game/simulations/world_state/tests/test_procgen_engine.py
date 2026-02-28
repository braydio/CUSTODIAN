from __future__ import annotations

from pathlib import Path

from game.procgen.engine import GrammarEngine, VariantMemory, load_grammar_bank
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.terminal.procgen_text import render_wait_event_line


def test_grammar_engine_expands_modifiers_deterministically(tmp_path: Path) -> None:
    path = tmp_path / "grammar.json"
    path.write_text(
        '{"version":1,"symbols":{"origin":[{"text":"#w.upper#","weight":1}],"w":["alpha"]}}',
        encoding="utf-8",
    )
    engine = GrammarEngine(load_grammar_bank(path))
    memory = VariantMemory()
    assert engine.render("origin", seed=123, salt="x", memory=memory) == "ALPHA"
    assert engine.render("origin", seed=123, salt="x", memory=memory) == "ALPHA"


def test_variant_memory_avoids_immediate_repeat(tmp_path: Path) -> None:
    path = tmp_path / "grammar.json"
    path.write_text(
        '{"version":1,"symbols":{"origin":[{"text":"A","weight":1},{"text":"B","weight":1}]}}',
        encoding="utf-8",
    )
    engine = GrammarEngine(load_grammar_bank(path))
    memory = VariantMemory(max_recent=1)
    first = engine.render("origin", seed=1, salt="same", memory=memory)
    second = engine.render("origin", seed=1, salt="same", memory=memory)
    assert first in {"A", "B"}
    assert second in {"A", "B"}
    assert first != second


def test_wait_event_line_includes_event_name_at_full_fidelity() -> None:
    state = GameState(seed=2)
    line = render_wait_event_line(
        state,
        fidelity="FULL",
        event_name="Comms Burst",
        event_key="comms_burst",
        detected=True,
    )
    assert line is not None
    assert line.startswith("[EVENT] ")
    assert "COMMS BURST" in line


def test_wait_event_line_projection_flag_matches_legacy_output() -> None:
    legacy = GameState(seed=7)
    projected = GameState(seed=7)
    projected.procgen_projection_enabled = True

    legacy_line = render_wait_event_line(
        legacy,
        fidelity="FULL",
        event_name="Power Blackout",
        event_key="power_blackout",
        detected=True,
    )
    projected_line = render_wait_event_line(
        projected,
        fidelity="FULL",
        event_name="Power Blackout",
        event_key="power_blackout",
        detected=True,
    )
    assert projected_line == legacy_line
