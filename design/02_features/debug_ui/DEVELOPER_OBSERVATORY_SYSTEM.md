# DEVELOPER OBSERVATORY SYSTEM

Status: in_progress
Owner: gameplay/tools
Runtime target: Godot 4 (`custodian/`)

## Goal

Provide a developer-only observability surface that makes live simulation state, recent runtime events, and spatial heat signals readable without pushing debug authority into simulation code.

## Runtime Contract

- `DevObservatory` is an opt-in autoload telemetry sink.
- `DevMode` owns runtime eligibility. Outside development eligibility, Observatory input, overlay creation, continuous sampling, and telemetry accumulation are disabled.
- `F9` toggles a lightweight observatory overlay.
- `F10` exports the current bounded telemetry session as JSON.
- The overlay is presentation-only. It reads counters, gauges, and recent events; it does not mutate gameplay state.
- Systems may report events, counters, and gauges, but gameplay authority remains in the existing runtime owners.
- Bounded event/counter ingestion remains available while the overlay is hidden, but recursive runtime sampling does not run.
- Enabling the overlay samples at the configured interval with one consolidated scene-tree traversal per sample. F10 export forces exactly one current snapshot before serialization.
- Explicit export remains callable even when continuous sampling is unavailable and still forces its final snapshot.

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
- Allied-drone stale target cleanup after enemy destruction
- Floor source under player (terrain source ID)
- Combat readability zones (active/inactive)

### Rate guidance

- **Do not** put high-frequency per-frame spam into `log_event`. Use gauges for continuous state and only log events on transitions: "stuck started," "stuck resolved," "stuck rescue fired," "falcon overlap detected."
- Temporary `print()` / `debug_draw()` is allowed for local visual debugging, but any useful playtest artifact should also appear in `DevObservatory` so F10 session exports capture it for post-run analysis.
- Recursive runtime ownership statistics are an overlay/export diagnostic, not a background service. Hidden sampling must perform zero full-tree scans; enabled sampling must not separately traverse for loaded world/procgen counts.

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
events, counters, gauges, Heatmap and Material Intelligence snapshots, and
warnings. Runtime Variants are converted into JSON-safe values without clearing or
mutating the bounded observatory buffers. Successful exports append `observatory_session_exported`; directory, open,
or write failures append a warning through `mark_warning(...)`. Successful writes print their absolute filesystem path,
and the F9 overlay retains the latest timestamped export path for immediate discovery.

Session metadata distinguishes retained tail size from cumulative activity with `event_capacity`,
`total_events_logged`, `dropped_event_count`, and `event_buffer_saturated`. Counters remain cumulative when the event
ring wraps. The analyzer discloses this tail-window boundary; for legacy exports that lack these fields, a full
300-event array is reported as possibly saturated rather than presented as a whole-session event total.

This produces a playtest artifact that can be handed to Codex or other tools for post-run analysis. It remains
observability-only and has no combat, player, enemy, heatmap, world-history, or simulation authority.

Analyze an exported session from the repository root with:

```bash
python3 custodian/tools/analysis/analyze_dev_observatory_session.py /path/to/session.json
```

After sourcing `tools/custodian_aliases.sh`, run `obsreport` to analyze the
latest discoverable export or pass an explicit session path and analyzer flags.

When the path is omitted, the script looks for `latest_session.json` in the standard Godot user-data locations. The
standard-library-only report summarizes session and scene metadata, top event kinds, recent warnings, nonzero counters,
gauges, player damage/deaths, ranged fire, dodges/iframes, Field Patch outcomes,
enemy attack outcomes, material contacts, and spatial heat cells. It also flags
buffer wrapping, one-event-type domination, unexplained damage/death, dominant
overheat failures, and dodges without observed iframe avoids. It does not
write to the export or change runtime state.

## Signal Quality Contract (2026-07-24)

- State sampled repeatedly belongs in gauges. Discrete events belong in
  `log_event`.
- Infrastructure power-tier telemetry compares the previous and resolved tier
  and emits only on an actual transition. Stable allocation recalculation must
  not produce another `infrastructure_power_tier_changed` event.
- Enemy-to-player damage and enemy attacks retain their existing shared-ID
  incoming-hit and terminal-outcome telemetry. These signals are observational
  mirrors of authoritative outcomes and do not alter combat.
- Overheat failure events include heat, threshold, decay rate/delay, lockout
  remaining/total, ammo, cooldown, and held/tapped trigger context. The values
  explain failures; they do not tune the weapon.
- The analyzer uses cumulative counters where possible because retained
  detailed events remain a bounded tail when the event ring wraps.

## Follow-up Slices

- Heatmap visualization bands and mode cycling.
- Sector/world-state summaries in the overlay.
- AI/stealth/noise overlays using existing debug draw surfaces.
- Optional machine-readable report output if automated playtest aggregation needs it later.

## Audit Remediation Contract (2026-07-14)

- Ranged telemetry separates trigger samples, authoritative fire requests, shots, and debounced failures. Failures expose stable reason and `empty` / `state_locked` / `internal` category counters.
- Enemy melee windup, resolution, Operator incoming-hit resolution, and player damage share `attack_id`, attacker/target IDs, attempted/applied damage, and health-before/after fields where the receiver supports the extended contract.
- Dodge, Field Patch, and stamina telemetry records timing phases, attempts/rejection reasons, availability below half health, death with a patch available, spend/regeneration causes, and exhaustion transitions without changing their gameplay tuning.
- `director_behavior_agents` and `legacy_combat_agents` are separate gauges. `enemy_behavior_sample` is reserved for director/profile agents; non-agent enemies use `legacy_enemy_sample`.
- Node ownership/performance gauges distinguish world, procgen, props, collision, VFX, UI, physics bodies/shapes, and processing nodes.
- Procgen validation-pocket counters describe generation-time repair; Operator trap/rescue counters describe runtime failures. Stuck reports include seed, tile/region, blocker sources, a local collision mask, and reachable area. Debug rescue candidates require distance from the source, two exits, an eight-tile local reachable area, no nearby runtime blocker, and a post-move report.
- The text analyzer labels warning totals separately from the displayed tail; omitted earlier warnings are disclosed.
- Projectile collision ownership requires projectile roots to use the `projectiles` group. Active weapon gauges include
  the ranged weapon ID/state key, magazine capacity, and ammo-per-shot so zero ammo values are not interpreted without
  loadout context.
- Deliberate dodge overlaps emit one `incoming_dodge_timing_classified` event per incoming attack ID with canonical
  `iframe_avoid`, `miss_late`, or `recovery_hit` classification while retaining the older phase counters.

## Procgen Placement Prevention Contract (2026-07-16)

- Ruin-prop placement reports pre-spawn rejection separately from post-spawn remediation. The Observatory records outcomes but never participates in the placement decision.
- Rejection counters are `procgen_prop_candidates_rejected_protected_zone`, `procgen_prop_candidates_rejected_stuck_risk`, and `procgen_prop_candidates_rejected_existing_blocker`.
- Last-generation gauges are `procgen_stuck_pockets_detected_last_generation`, `procgen_stuck_pockets_remediated_last_generation`, and `procgen_prop_collision_alignment_warning_count_last_generation`; they are reset for each generation rather than accumulated across a play session.
- Prop collision warning/rejection payloads include definition ID, source tile, prop global position, global collision rectangle, collision tile footprint, protected-zone type, remediation action, and seed when available.
- Performance gauges split collision shapes and physics bodies for runtime walls, foliage, and ruin props. Classification is diagnostic and based on runtime ownership/groups; it does not alter collision behavior.

## Enemy Attack Outcome Contract (2026-07-16)

- Enemy attack lifecycle events share a stable `attack_id`, enemy/target IDs, attack type, phase, result, and reason where applicable.
- Terminal outcomes are reported once per unique `attack_id` as `damaged`, `blocked`, `parried`, `whiffed`, or
  `cancelled_by_death`. Interruption causes such as parry, hit, and target loss are a separate dimension; range, arc, and
  collision details remain reasons rather than additional terminal-outcome buckets.
- Falcon Punch tracks attempts, hits, parries, whiffs, and cancellations separately. Its ordinary `impact_lock` is hit-confirmed; a parry hard-cancels into the parry-critical branch and must not emit a successful-impact lock.
- Falcon Punch terminal telemetry includes launch distance, target distance at active-frame start, closest approach,
  lateral error, player dodge phase, collision obstruction, and configured stop-short distance.
- Falcon Punch also publishes mutually exclusive detail counters for damaged, iframe-dodged, blocked, parried, and whiffed terminals.
- Parry telemetry covers started, active, expired, success, miss-feedback spawn, and failed-parry hit-react transitions. Grunt opportunity telemetry covers vulnerable-window opened, consumed, and expired; paired execution separately counts player critical starts and confirmed hits.
- Player death snapshots include health, pre-death-reset stamina, carried Field Patches, accumulated low-health patch availability, last damage/attack kinds, nearby enemy count, and active enemy count.
- The report labels retained terminal-event totals, retained unique terminal IDs, cumulative incoming-hit results, and cumulative whiff terminals separately. Incoming-hit results exclude whiffs.
- Stuck-pocket remediation warnings include pocket ID, center cell, cell count, blocker source, and remediation action.

## Field Patch Affordance Contract (2026-07-18)

- Below 50% health with at least one carried patch, the gameplay HUD shows and pulses `FIELD PATCH READY [P]`.
- Below 25% health, the prompt changes to the stronger critical treatment. It remains advisory and never auto-consumes a patch.
- Prompt entry/severity transitions emit `field_patch_prompt_shown`; death while the prompt remains actionable emits `field_patch_prompt_ignored_on_death`.

## Ranged Reconciliation And Cumulative Resource Contract (2026-07-18)

- Sidearm primary input during draw/fire recovery is buffered once and becomes one authoritative request after the held pose and cooldown are ready. Repeated sampling while buffered is ignored and does not emit `sidearm_not_held` failures.
- Every authoritative ranged request terminates as fired, muzzle-blocked, failed, cancelled, or currently pending. Failure feedback may remain audiovisually debounced, but telemetry is never debounced.
- Zero-direction, projectile-creation, and death cancellations expose reason counters. The analyzer prints a reconciliation block and flags any nonzero remainder.
- Player damage, guarded chip damage, and healing amounts use cumulative counters so event-ring wrapping cannot understate session totals. Retained-event damage remains explicitly labeled as a tail-window value.
- `player_alive` / `player_dead` and last-live weapon, ammunition, and stamina gauges prevent post-death snapshots from being interpreted as balance evidence.
- Procgen generation/map/wall-body gauges, global node/physics/collision peaks, and loaded world/procgen root counts distinguish proportional collision cost from cleanup or handoff leakage.

## Acceptance

- `F9` toggles the observatory overlay in `res://scenes/game.tscn`.
- Player damage/death and presence events appear without breaking normal gameplay.
- No new simulation authority is introduced into the overlay.
- `F10` writes timestamped and stable session JSON without clearing the event buffer.
- With F9 hidden, periodic processing performs zero full scene-tree scans.
- With F9 visible, one sampling interval performs one consolidated scene-tree scan.
- Export forces one current runtime snapshot even when the overlay is hidden.

## Next Agent Slice

- Add heatmap rendering or `WorldStateGraph` / `WorldHistory` overlay summaries as separate presentation slices.
- Keep report automation separate from runtime telemetry and add machine-readable output only when a consumer exists.
