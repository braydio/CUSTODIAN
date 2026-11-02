# Minimap System

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-05
- Created: 2026-05-05
- Last updated: 2026-05-05

## Task

Implement the custom tactical minimap described by `design/MINIMAP_SPEC.md`, moving the active implementation spec into the proper `design/features/implementation/` grouping and wiring the runtime UI.

## Outcome

The Godot HUD has a custom data-driven minimap that renders generated procgen terrain, tracks dynamic player/enemy/objective pips, and updates destroyed wall terrain without relying on the existing minimap addon.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Source note: `design/MINIMAP_SPEC.md`
- Active implementation docs: `design/features/implementation/MINIMAP_SYSTEM.md`, `design/features/implementation/MINIMAP_SYSTEM_CODE.md`
- Runtime files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/ui/minimap/`, `custodian/scenes/game.tscn`, `custodian/game/ui/hud/ui.gd`

## Work Surface

- Expected changes: procgen minimap hooks, new minimap UI scripts/scene, scene integration, HUD console status, active docs/context.
- Out of scope: generated bitmap UI frame asset, fog/reveal masking, click-to-ping commands, expanded tactical map.

## Constraints

- Determinism concerns: minimap terrain comes from authoritative procgen state, not a secondary scan with different rules.
- Simulation/UI boundary concerns: minimap is presentation only; it must not own gameplay state.
- Compatibility concerns: existing DevConsole `toggle_minimap` workflow should continue.
- Asset requirements: none for v1.

## Implementation Plan

1. Create canonical minimap design/code docs under `design/features/implementation/`.
2. Add procgen data arrays, coordinate helpers, group registration, and tile-change signal.
3. Implement `MinimapView` and `MinimapController`.
4. Replace the addon minimap node in `game.tscn` with the custom minimap panel.
5. Update HUD minimap console status.
6. Validate with Godot headless boot and update docs/context.

## Acceptance

- Minimap node exists under `UI` and is toggleable.
- Minimap can discover runtime procgen after contract map instancing.
- Terrain texture is built from `floor_cells` and `wall_cells`.
- Player pip tracks the `player` group.
- Enemy pips read the `enemy` group.
- Wall destruction emits targeted terrain update.
- No SubViewport or minimap addon dependency is used.
- `godot --headless --quit` completes without new script errors.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do design docs need an update? Yes.

## Completion Notes

- Implemented: canonical minimap design/code docs; procgen floor/wall minimap data, coordinate helpers, group registration, and wall-destruction tile-change signal; custom `MinimapController`, `MinimapView`, and `minimap_panel.tscn`; `game.tscn` replacement of the addon minimap node; generic DevConsole minimap status.
- Validated: `godot --headless --quit`.
- Deferred: fog/reveal masking, expanded map mode, click interaction, authored minimap frame/overlay assets, and manual in-editor visual tuning.
