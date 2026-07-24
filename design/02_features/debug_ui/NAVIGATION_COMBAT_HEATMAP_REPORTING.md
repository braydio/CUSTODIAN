# Navigation Combat Heatmap Reporting

Status: review  
Feature type: debug UI / telemetry / playtest analysis  
Codex source: `design/90_codex/simulation/navigation_combat_heatmaps.md`  
Runtime autoload: `custodian/game/systems/world/sector_heatmap.gd`  
Related observability: `custodian/game/systems/debug/dev_observatory.gd`

## Summary

This feature implements the first production slice of Navigation + Combat
Heatmaps. It records position-weighted playtest events into `SectorHeatmap`,
includes the aggregate snapshot in Developer Observatory exports, and surfaces
heatmap summaries in the local session analysis script.

`SectorHeatmap` is developer analysis infrastructure only. It reads runtime
outcomes after their authoritative systems resolve them and never feeds data
back into movement, combat, AI, world state, procedural generation, or the
encounter director.

## Non-goals

- no AI behavior changes
- no director adaptation
- no procedural generation influence
- no player-facing UI
- no balance changes
- no art or FX changes
- no persistent cross-session heatmap database

## Event Types

| Runtime observation | Heatmap event | Weight |
|---|---|---:|
| periodic player sample | `presence` | 1.0 |
| applied player damage | `damage_taken` | applied damage |
| player death | `player_death` | 10.0 |
| ranged shot created | `shot_fired` | 1.0 |
| ranged muzzle blocked | `shot_blocked` | 1.0 |
| dodge started | `dodge_started` | 0.25 |
| iframe avoided damage | `iframe_avoid` | 1.0 |
| Field Patch started | `field_patch_started` | 0.5 |
| Field Patch cancelled | `field_patch_cancelled` | 0.75 |
| Field Patch committed | `field_patch_committed` | 1.0 |
| incoming hit damaged | `incoming_hit_damaged` | applied damage, minimum 1.0 |
| incoming hit blocked | `incoming_hit_blocked` | 1.0 |
| incoming hit parried | `incoming_hit_parried` | 1.0 |
| incoming hit dodged | `incoming_hit_dodged` | 1.0 |
| enemy killed | `enemy_killed` | 3.0 |
| enemy attack whiffed | `enemy_attack_whiff` | 0.5 |
| enemy attack damaged | `enemy_attack_hit` | applied damage, minimum 1.0 |
| enemy attack blocked | `enemy_attack_blocked` | 1.0 |
| enemy attack parried | `enemy_attack_parried` | 1.0 |
| enemy attack dodged | `enemy_attack_dodged` | 1.0 |

## Runtime Contract

`SectorHeatmap` exposes:

- `add(world_position, event_type, weight)`
- `add_event(world_position, event_type, weight, data)`
- `get_summary()`
- `export_snapshot()`
- `clear()`

World positions map to bounded 64 px cells. Export keys use the JSON-safe
`"x,y"` form. Each cell records its origin, aggregate weight, sample count,
first and last timestamps, and weights grouped by event type. Event metadata is
not retained, keeping this artifact bounded and free of gameplay-object
references.

The legacy channel query methods remain available for the existing F9 overlay.
Developer Observatory adds current cell/sample gauges and embeds a
`custodian.sector_heatmap.v1` snapshot in every session export.

## Acceptance

- Player presence creates heatmap samples.
- Damage and death create danger cells.
- Ranged fire and blocked shots create combat cells.
- Enemy kills and enemy attack outcomes create combat cells.
- Developer Observatory export includes a `heatmap` object.
- `custodian/tools/analysis/analyze_dev_observatory_session.py` prints a
  `HEATMAP` section with top, danger, and combat cells.
- No gameplay behavior changes.

## Validation

```bash
python -m py_compile custodian/tools/analysis/analyze_dev_observatory_session.py
python tools/validate_design_codex.py
cd custodian
godot --headless --path . \
  --script res://tools/validation/sector_heatmap_smoke.gd
```

Manual validation uses a short F9-enabled movement/combat session, F10 export,
and the analyzer against `dev_observatory/latest_session.json`.
