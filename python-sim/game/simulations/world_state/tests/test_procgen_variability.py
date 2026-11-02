"""Baseline variability metrics for procgen instrumentation."""

from __future__ import annotations

from game.simulations.world_state.core.state import GameState


def run_seed_suite(seeds: list[int]) -> dict[str, float]:
    fingerprints = [GameState(seed=seed).snapshot()["run_fingerprint"] for seed in seeds]
    hashes = [fp["fingerprint_hash"] for fp in fingerprints]
    doctrine_ids = [fp["doctrine_profile_id"] for fp in fingerprints]

    unique_ratio = len(set(hashes)) / len(hashes) if hashes else 0.0
    switches = 0
    for idx in range(1, len(doctrine_ids)):
        if doctrine_ids[idx] != doctrine_ids[idx - 1]:
            switches += 1
    switch_rate = switches / max(1, len(doctrine_ids) - 1)
    return {
        "fingerprint_uniqueness_ratio": unique_ratio,
        "profile_switch_rate": switch_rate,
    }


def test_same_seed_stability() -> None:
    seeds = [424242] * 10
    metrics = run_seed_suite(seeds)
    assert metrics["fingerprint_uniqueness_ratio"] == 0.1


def test_cross_seed_variability_baseline() -> None:
    seeds = list(range(1000, 1020))
    metrics = run_seed_suite(seeds)
    assert metrics["fingerprint_uniqueness_ratio"] > 0.2
    assert metrics["profile_switch_rate"] >= 0.0

