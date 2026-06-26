# DEVELOPER OBSERVATORY SYSTEM

Status: in_progress
Owner: gameplay/tools
Runtime target: Godot 4 (`custodian/`)

## Goal

Provide a developer-only observability surface that makes live simulation state, recent runtime events, and spatial heat signals readable without pushing debug authority into simulation code.

## Runtime Contract

- `DevObservatory` is an opt-in autoload telemetry sink.
- `F9` toggles a lightweight observatory overlay.
- The overlay is presentation-only. It reads counters, gauges, and recent events; it does not mutate gameplay state.
- Systems may report events, counters, and gauges, but gameplay authority remains in the existing runtime owners.

## Initial Slice

1. Add `DevObservatory` autoload.
2. Add `debug_observatory` input on `F9`.
3. Add `dev_observatory_overlay.tscn` to `res://scenes/game.tscn`.
4. Show:
   - FPS
   - telemetry counters
   - telemetry gauges
   - recent event log
   - active heatmap mode label
5. First instrumentation:
   - player damage
   - player death
   - player position heat sampling
   - active enemy count gauge

## System Boundaries

- Use the observatory for debug readability, not persistence.
- Use `WorldHistory` for durable event memory.
- Use `SectorHeatmap` for spatial accumulation.
- Use `WorldStateGraph` for reactive state dependencies.

## Constraints

- No deterministic simulation logic may depend on observatory state.
- Avoid unbounded allocations; event history is capped.
- Do not replace the existing F12 debug screen. The observatory is a fast live telemetry view, not a full inspector replacement.

## Follow-up Slices

- Heatmap visualization bands and mode cycling.
- Sector/world-state summaries in the overlay.
- AI/stealth/noise overlays using existing debug draw surfaces.
- Exportable telemetry snapshots for playtest review.

## Acceptance

- `F9` toggles the observatory overlay in `res://scenes/game.tscn`.
- Player damage/death and presence events appear without breaking normal gameplay.
- No new simulation authority is introduced into the overlay.

## Next Agent Slice

- Add heatmap rendering into the observatory overlay for `player_presence`, `damage_taken`, and `player_death`.
- Surface `WorldStateGraph` snapshots and selected `WorldHistory` sector summaries beside recent events.
