"""Tests for colony-sim feature wiring."""

from game.simulations.world_state.core.assaults import maybe_warn
from game.simulations.world_state.core.power import refresh_comms_fidelity
from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.structures import StructureState


def test_surveillance_changes_warning_detection_probability() -> None:
    low = GameState(seed=1)
    high = GameState(seed=1)
    low.policies.surveillance_coverage = 0
    high.policies.surveillance_coverage = 4

    low.rng.random = lambda: 0.5
    high.rng.random = lambda: 0.5

    maybe_warn(low, "T_NORTH")
    maybe_warn(high, "T_NORTH")

    assert low.last_assault_lines == ["[EVENT] SIGNAL INTERFERENCE DETECTED"]
    assert high.last_assault_lines == ["[WARNING] HOSTILE MOVEMENT NEAR T_NORTH"]


def test_fidelity_buffer_scales_effective_integrity() -> None:
    low = GameState(seed=2)
    high = GameState(seed=2)
    low.policies.surveillance_coverage = 0
    high.policies.surveillance_coverage = 4
    low.structures["CM_CORE"].state = StructureState.DAMAGED
    high.structures["CM_CORE"].state = StructureState.DAMAGED

    low_fidelity = refresh_comms_fidelity(low, emit_event=False)
    high_fidelity = refresh_comms_fidelity(high, emit_event=False)

    assert low_fidelity in {"FRAGMENTED", "DEGRADED"}
    assert high_fidelity == "FULL"

