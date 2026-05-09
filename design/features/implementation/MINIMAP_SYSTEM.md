# Minimap System

Status: complete

## Goal

Implement a custom tactical minimap for the Godot runtime. The minimap is data-driven from `ProcGenTilemap` and renders simplified tactical geometry rather than a camera thumbnail or addon radar.

## Runtime Ownership

- Terrain data authority: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- HUD integration: `custodian/scenes/game.tscn` under the `UI` CanvasLayer
- Minimap UI code: `custodian/game/ui/minimap/`

## Design

The minimap consumes `ProcGenTilemap.level_data_ready(data)` after procgen generation. `ProcGenTilemap.get_level_data()` must include compact floor/wall tile arrays, map size, tile size, room centers, compound data, constructed interior data, and world profile.

The minimap caches the static floor/wall terrain into an `ImageTexture` once per generation. Dynamic pips for player, enemies, and objectives are drawn per frame by converting world positions to procgen tile coordinates through public procgen helpers.

## Required Runtime Behavior

- Show generated floor/wall layout.
- Show player position.
- Show room centers and compound outline.
- Show enemy/objective pips when matching groups exist.
- Update destroyed wall tiles through a targeted `minimap_tile_changed(tile, terrain_kind)` signal.
- Avoid `SubViewport` and addon dependencies.
- Remain safe when procgen has not loaded yet.

## Visual Direction

The minimap should read as a military tactical sensor panel:

- floor: dark desaturated gray-green
- wall: near-black blue-gray
- player: pale cyan
- enemies: muted red
- objectives: amber
- rooms/compound: dim olive

The panel should prioritize contrast and shape readability over showing literal tile art.

## V1 Scope

- Always north-up.
- No click interaction.
- No zoom controls.
- Full generated map visible.
- Console command can toggle visibility.

## Future Work

- Fog/reveal masking from streaming reveal state.
- Expanded tactical map mode.
- Objective pings and room labels.
- Sensor upgrades that change enemy classification rather than raw map accuracy.

## Validation

Run:

```bash
cd custodian
godot --headless --quit
```

Manual editor/game checks:

- Minimap panel can be toggled visible.
- Terrain appears after procgen finishes.
- Player pip tracks operator movement.
- Enemy pips appear for nodes in the `enemy` group.
- Destroyed walls update from wall to floor.

## Implementation Notes

Implemented as a code-drawn Control panel under `custodian/game/ui/minimap/`. The previous addon minimap node in `game.tscn` has been replaced by `minimap_panel.tscn`; no addon dependency is required for the runtime HUD minimap.
