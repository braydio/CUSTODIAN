# SECTOR HEATMAP SYSTEM

Status: in_progress
Owner: gameplay/tools
Runtime target: Godot 4 (`custodian/`)

## Goal

Accumulate spatial player/combat signals in tile-space so level iteration, observability, and future AI tooling can inspect what actually happened in a run.

## Runtime Contract

- `SectorHeatmap` is an autoload spatial accumulator.
- Channels are named independently, such as:
  - `player_presence`
  - `damage_taken`
  - `player_death`
- The initial slice samples player presence automatically and accepts explicit writes for damage/death.

## Initial Slice

1. Add `SectorHeatmap` autoload.
2. Sample the player position every `0.25s` into `player_presence`.
3. Expose:
   - `add(position, channel, amount)`
   - `get_value(position, channel)`
   - `get_hot_cells(channel, minimum)`
4. Feed current channel summaries into `DevObservatory`.

## Constraints

- Spatial storage stays bounded to touched cells.
- Heatmap accumulation is diagnostic data, not gameplay authority.
- Visualization and recording remain separate.

## Acceptance

- Player movement generates `player_presence` data in a live run.
- Damage and death hooks can add to heatmap channels.
- The observatory can inspect top hot cells without mutating heat data.
