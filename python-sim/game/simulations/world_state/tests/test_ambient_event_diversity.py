"""Tests for ambient event diversity pacing and category selection."""

from game.simulations.world_state.core.events import (
    build_event_catalog,
    compute_category_weights,
    filter_recent_events,
    select_ambient_event,
)
from game.simulations.world_state.core.state import GameState


def test_build_event_catalog_includes_quiet_and_infrastructure_expansion() -> None:
    state = GameState(seed=11)
    catalog = build_event_catalog(state)
    keys = {event.key for event in catalog}
    categories = {event.category for event in catalog}

    assert "quiet_perimeter_stable" in keys
    assert "quiet_night_cycle" in keys
    assert "quiet_atmospheric" in keys
    assert "fabrication_queue_delay" in keys
    assert "archive_checksum_mismatch" in keys
    assert "defense_grid_recalibration" in keys
    assert {"QUIET", "ENVIRONMENTAL", "INFRASTRUCTURE", "RECON", "HOSTILE"} <= categories


def test_filter_recent_events_blocks_exact_repeat_names() -> None:
    state = GameState(seed=12)
    catalog = build_event_catalog(state)
    sector = state.sectors["COMMAND"]
    first = next(event for event in catalog if event.key == "quiet_perimeter_stable")
    second = next(event for event in catalog if event.key == "quiet_night_cycle")
    candidates = [(first, sector), (second, sector)]

    filtered = filter_recent_events(candidates, [first.name])

    assert len(filtered) == 1
    assert filtered[0][0].name == second.name


def test_compute_category_weights_applies_context_heuristics() -> None:
    state = GameState(seed=13)
    state.ambient_threat = 3.0
    state.ticks_since_assault = 2
    state.ticks_since_hostile = 30
    state.last_event_category = "QUIET"
    for sector in state.sectors.values():
        sector.power = 0.2

    boosted = compute_category_weights(state)
    state.ticks_since_assault = 20
    state.ticks_since_hostile = 2
    state.last_event_category = None
    baseline = compute_category_weights(state)

    assert boosted["INFRASTRUCTURE"] > baseline["INFRASTRUCTURE"]
    assert boosted["RECON"] > baseline["RECON"]
    assert boosted["QUIET"] < baseline["QUIET"]


def test_select_ambient_event_updates_memory_and_avoids_recent_repeat() -> None:
    state = GameState(seed=14)
    state.time = 30
    state.ambient_threat = 2.5
    state.ticks_since_assault = 8
    state.ticks_since_hostile = 8
    state.rng.random = lambda: 0.0
    state.rng.choices = lambda categories, weights, k=1: ["QUIET"]
    state.rng.choice = lambda candidates: candidates[0]

    catalog = build_event_catalog(state)
    quiet_perimeter = next(event for event in catalog if event.key == "quiet_perimeter_stable")
    state.recent_events.append(quiet_perimeter.name)

    selected = select_ambient_event(state)

    assert selected is not None
    event, _ = selected
    assert event.category == "QUIET"
    assert event.name != quiet_perimeter.name
    assert state.last_event_category == "QUIET"
    assert state.recent_events[-1] == event.name
