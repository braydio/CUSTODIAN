from game.simulations.world_state.core.state import GameState
from game.simulations.world_state.core.topology_profiles import (
    MAX_INTERCEPT_MOD,
    MAX_MOD,
    MIN_INTERCEPT_MOD,
    MIN_MOD,
    select_topology_profile,
)


def test_topology_profile_is_deterministic_for_same_seed() -> None:
    left = select_topology_profile(12345)
    right = select_topology_profile(12345)
    assert left == right


def test_topology_profile_changes_across_seed_suite() -> None:
    ids = {select_topology_profile(seed)["profile_id"] for seed in range(100, 160)}
    assert len(ids) >= 4


def test_topology_profile_modifier_bounds_hold() -> None:
    profile = select_topology_profile(321)
    for key in ("transit_bias", "ingress_bias"):
        for value in profile[key].values():
            assert MIN_MOD <= value <= MAX_MOD
    for key in ("intercept_modifier", "fortify_effectiveness_modifier"):
        for value in profile[key].values():
            assert MIN_INTERCEPT_MOD <= value <= MAX_INTERCEPT_MOD


def test_snapshot_surfaces_topology_profile_and_summary_without_internal_tokens() -> None:
    state = GameState(seed=42)
    snapshot = state.snapshot()
    summary = snapshot["topology_profile"]["summary"]
    assert "T_NORTH" not in summary
    assert "T_SOUTH" not in summary
    assert "INGRESS_N" not in summary
    assert "INGRESS_S" not in summary
