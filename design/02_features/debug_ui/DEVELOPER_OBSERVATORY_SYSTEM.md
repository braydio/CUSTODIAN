# DEVELOPER OBSERVATORY SYSTEM

Status: in_progress
Owner: gameplay/tools
Runtime target: Godot 4 (`custodian/`)

## Goal

Provide a developer-only observability surface that makes live simulation state, recent runtime events, and spatial heat signals readable without pushing debug authority into simulation code.

## Runtime Contract

- `DevObservatory` is an opt-in autoload telemetry sink.
- `F9` toggles a lightweight observatory overlay.
- `F10` exports the current bounded telemetry session as JSON.
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

- Use the observatory export as a developer playtest artifact, not gameplay persistence.
- Use `WorldHistory` for durable event memory.
- Use `SectorHeatmap` for spatial accumulation.
- Use `WorldStateGraph` for reactive state dependencies.

## Constraints

- No deterministic simulation logic may depend on observatory state.
- Avoid unbounded allocations; event history is capped.
- Do not replace the existing F12 debug screen. The observatory is a fast live telemetry view, not a full inspector replacement.

## Session Export

Developer Observatory supports JSON session export through the existing autoload at:

- `custodian/game/systems/debug/dev_observatory.gd`

Default export paths:

- `user://dev_observatory/latest_session.json`
- `user://dev_observatory/session_YYYYMMDD_HHMMSS.json`

Input:

- `debug_observatory_export`
- default key: `F10`

The payload includes its schema and export timestamp, project and engine metadata, current scene, uptime/session counts,
events, counters, gauges, and warnings. Runtime Variants are converted into JSON-safe values without clearing or
mutating the bounded observatory buffers. Successful exports append `observatory_session_exported`; directory, open,
or write failures append a warning through `mark_warning(...)`.

This produces a playtest artifact that can be handed to Codex or other tools for post-run analysis. It remains
observability-only and has no combat, player, enemy, heatmap, world-history, or simulation authority.

## Follow-up Slices

- Heatmap visualization bands and mode cycling.
- Sector/world-state summaries in the overlay.
- AI/stealth/noise overlays using existing debug draw surfaces.
- A small `tools/analyze_dev_observatory_session.py` report tool for exported playtest sessions.

## Acceptance

- `F9` toggles the observatory overlay in `res://scenes/game.tscn`.
- Player damage/death and presence events appear without breaking normal gameplay.
- No new simulation authority is introduced into the overlay.
- `F10` writes timestamped and stable session JSON without clearing the event buffer.

## Next Agent Slice

- Add `tools/analyze_dev_observatory_session.py` to summarize high-signal playtest outcomes from `latest_session.json`.
- Keep heatmap rendering and `WorldStateGraph` / `WorldHistory` overlay summaries as separate presentation slices.
