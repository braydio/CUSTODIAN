# Developer Observatory System

Status: review
Feature type: tooling / debug infrastructure
Runtime target: Godot 4.x
Primary runtime path: `custodian/scripts/debug/dev_observatory.gd`
Overlay scene: `custodian/scenes/debug/dev_observatory_overlay.tscn`
Last reviewed: 2026-07-12

## Summary

Developer Observatory is the first shared debug visibility layer for CUSTODIAN. It provides a lightweight F9 overlay for runtime telemetry, counters, gauges, and recent events.

This is intentionally the smallest useful version. It is not the full replay system, heatmap system, AI visualization system, or world-state graph viewer yet. It creates the shared instrumentation surface those systems can use later.

## Why this should be built first

CUSTODIAN is becoming a systems-heavy Godot project: combat feel, repair gameplay, enemy behavior, wave spawning, sector state, procedural layout, animation timing, and world-state transitions all need visibility.

Without shared telemetry, debugging will continue to depend on scattered print statements and subjective testing.

The Observatory gives the project a central place to answer:

- What just happened?
- What state is the player in?
- How many enemies/projectiles/particles are active?
- What world events fired recently?
- What systems are exceeding budget?
- Where should future overlays plug in?

## Non-goals for this first pass

This first pass does not implement:

- heatmap drawing
- replay export
- AI vision cones
- sound propagation visualization
- pathfinding visualization
- world-state graph editor
- performance enforcement
- save/load debugging
- editor plugins

Those should graduate later as separate implementation specs or child specs.

## Player-facing behavior

None. This is a developer-only tool.

The only visible behavior is:

- Press F9 to toggle a debug overlay.
- Overlay displays counters, gauges, recent events, and basic runtime stats.
- Systems can call `DevObservatory.log_event(...)`, `DevObservatory.increment(...)`, and `DevObservatory.set_gauge(...)`.

## Runtime files

Add:

- `custodian/scripts/debug/dev_observatory.gd`
- `custodian/scripts/debug/dev_observatory_overlay.gd`
- `custodian/scenes/debug/dev_observatory_overlay.tscn`

Optional:

- `custodian/scripts/debug/debug_instrumentation_examples.gd`
- `custodian/docs/ai_context/CURRENT_STATE_DEV_OBSERVATORY_NOTE.md`

## Autoload

Add this autoload in Godot Project Settings:

Name:

- `DevObservatory`

Path:

- `res://scripts/debug/dev_observatory.gd`

The script also creates the `debug_observatory` input action at runtime if it is missing.

## Minimal API

### `DevObservatory.log_event(kind: StringName, data := {})`

Records a timestamped event.

Example:

`DevObservatory.log_event("player_damage", {"amount": 8, "source": "grunt_fast_attack"})`

### `DevObservatory.increment(name: StringName, amount := 1)`

Increments a counter.

Example:

`DevObservatory.increment("shots_fired")`

### `DevObservatory.set_gauge(name: StringName, value)`

Sets a live value.

Example:

`DevObservatory.set_gauge("active_enemies", 12)`

### `DevObservatory.mark_warning(message: String, data := {})`

Records a warning event and increments warning count.

Example:

`DevObservatory.mark_warning("Enemy had invalid simulation tier", {"enemy": name})`

## Implementation shape

The autoload owns:

- enabled/disabled state
- event ring buffer
- counters
- gauges
- warnings
- periodic base runtime sampling
- overlay scene creation

The overlay scene owns:

- visual display
- text formatting
- no game logic

## Required first instrumentation points

Wire at least these during first real integration:

1. Player damage
2. Player death
3. Enemy death
4. Projectile fired
5. Active enemy count
6. Current player position
7. Current player health if easy to access

## Acceptance criteria

The system is acceptable when:

- Pressing F9 toggles the overlay.
- The overlay shows FPS, uptime, counters, gauges, and recent events.
- Events are capped by a max ring-buffer size.
- Missing input action does not crash.
- Missing overlay scene does not crash the game.
- Runtime systems can call the API without knowing about the overlay.
- The implementation is safe to leave in development builds.

## Validation

Manual validation:

1. Launch the Godot project.
2. Confirm there are no autoload errors.
3. Press F9.
4. Confirm overlay appears.
5. Call `DevObservatory.log_event("manual_test", {"ok": true})` from a temporary script or console.
6. Confirm event appears in overlay.
7. Press F9 again.
8. Confirm overlay hides.

Suggested command when feasible:

`cd custodian && godot`

## Documentation updates

When implemented, update:

- `custodian/docs/ai_context/CURRENT_STATE.md`

Minimum note:

- Developer Observatory autoload added.
- F9 debug overlay available.
- Runtime systems can log counters, gauges, and events.

## Follow-up specs

After this lands, create separate specs for:

- Sector Heatmap overlay
- Performance Budget Manager
- Developer Replay System
- World State Graph debug tab
- AI state/vision overlay
