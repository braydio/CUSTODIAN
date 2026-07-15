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

## Debug Instrumentation Pattern

When adding debug instrumentation, route persistent telemetry through `DevObservatory` instead of relying only on `print()` statements. The autoload exposes exactly these primitives at `/root/DevObservatory`:

- `log_event(kind: StringName, data: Dictionary)` — structured moments (state transitions, one-shot detections).
- `increment(name: StringName, amount: int)` — bump a counter.
- `set_counter(name: StringName, value: int)` — set an absolute count.
- `set_gauge(name: StringName, value: Variant)` — current live values (read every frame, updated continuously).
- `mark_warning(message: String, data: Dictionary)` — actionable anomalies.

### Event examples

Use events for **state transitions**, not per-frame spam:

```gdscript
var obs := get_node_or_null("/root/DevObservatory")
if obs != null:
	obs.log_event(&"procgen_stuck_pocket_detected", {
		"tile": tile,
		"world_position": global_position,
		"region": region_type,
		"floor_source": floor_source_id,
		"wall_source": wall_source_id,
		"runtime_prop_blocked": runtime_prop_blocked,
		"escape_neighbors": escape_neighbors,
	})
	obs.increment(&"procgen_stuck_pockets_detected")
```

### Gauge examples

Use gauges for **continuous state** that changes every frame or tick:

```gdscript
obs.set_gauge(&"procgen_runtime_prop_blocker_cells", _runtime_prop_blocker_cells.size())
obs.set_gauge(&"foliage_occlusion_active_bubbles", active_bubble_count)
obs.set_gauge(&"combat_readability_active", _is_combat_readability_active())
```

### Warning examples

Use warnings for **problems** that should appear in the F9 overlay and F10 export:

```gdscript
obs.mark_warning("Procgen stuck pocket detected", {
	"tile": tile,
	"nearby_bodies": nearby_body_names,
	"escape_neighbors": escape_neighbors,
})
```

### Typical debug surfaces to instrument

These are good candidates for observatory telemetry when they appear in gameplay or procgen:

- Stuck pockets (procgen connectivity rescue)
- Runtime prop blockers (foliage/prop collision overlap)
- Foliage occlusion bubbles (canopy fade active count)
- Falcon punch overlap / collision hits
- Enemy spacing / pathfinding failures
- Floor source under player (terrain source ID)
- Combat readability zones (active/inactive)

### Rate guidance

- **Do not** put high-frequency per-frame spam into `log_event`. Use gauges for continuous state and only log events on transitions: "stuck started," "stuck resolved," "stuck rescue fired," "falcon overlap detected."
- Temporary `print()` / `debug_draw()` is allowed for local visual debugging, but any useful playtest artifact should also appear in `DevObservatory` so F10 session exports capture it for post-run analysis.

### Live procgen stuck-pocket telemetry

`ProcGenTilemap` publishes blocker registration/unregistration counters, current blocker source/cell gauges, one validation event per scan, and warnings for every remediated pocket. Operator blocked-motion detection publishes `operator_stuck_detected`; a successful debug rescue additionally publishes `operator_unstuck_rescued` and increments the matching counters. The `stuck_report` console command also records its structured tile/source/region/blocker/neighbor snapshot as `procgen_stuck_debug_report`. None of these signals feeds back into generation or movement authority.

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
or write failures append a warning through `mark_warning(...)`. Successful writes print their absolute filesystem path,
and the F9 overlay retains the latest timestamped export path for immediate discovery.

This produces a playtest artifact that can be handed to Codex or other tools for post-run analysis. It remains
observability-only and has no combat, player, enemy, heatmap, world-history, or simulation authority.

Analyze an exported session from the repository root with:

```bash
python3 tools/analyze_dev_observatory_session.py /path/to/session.json
```

After sourcing `tools/custodian_aliases.sh`, run `obsreport` to analyze the
latest discoverable export or pass an explicit session path and analyzer flags.

When the path is omitted, the script looks for `latest_session.json` in the standard Godot user-data locations. The
standard-library-only report summarizes session and scene metadata, top event kinds, recent warnings, nonzero counters,
gauges, player damage/deaths, ranged fire, dodges/iframes, Field Patch outcomes, and enemy attack outcomes. It does not
write to the export or change runtime state.

## Follow-up Slices

- Heatmap visualization bands and mode cycling.
- Sector/world-state summaries in the overlay.
- AI/stealth/noise overlays using existing debug draw surfaces.
- Optional machine-readable report output if automated playtest aggregation needs it later.

## Acceptance

- `F9` toggles the observatory overlay in `res://scenes/game.tscn`.
- Player damage/death and presence events appear without breaking normal gameplay.
- No new simulation authority is introduced into the overlay.
- `F10` writes timestamped and stable session JSON without clearing the event buffer.

## Next Agent Slice

- Add heatmap rendering or `WorldStateGraph` / `WorldHistory` overlay summaries as separate presentation slices.
- Keep report automation separate from runtime telemetry and add machine-readable output only when a consumer exists.
