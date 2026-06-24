# Forlorn Ritualant Shader FX

Status: implemented first pass — 2026-06-24

The Forlorn Ritualant encounter uses a visual-only shader FX layer to make the broken Ash-Bell chamber read as suspended over the Unarrival void. This is world-space presentation, not gameplay, collision, navigation, or simulation authority.

Runtime files:

- `custodian/scenes/environment/forlorn_ritualant_shader_fx.tscn`
- `custodian/scripts/environment/forlorn_ritualant_shader_fx.gd`
- `custodian/game/world/events/ash_bell/shaders/void_ocean_underlay.gdshader`
- `custodian/game/world/events/ash_bell/shaders/room_edge_void_haze.gdshader`
- `custodian/game/world/events/ash_bell/shaders/temporal_overlap_haze.gdshader`
- `custodian/game/world/events/ash_bell/materials/void_ocean_underlay_material.tres`
- `custodian/game/world/events/ash_bell/materials/room_edge_shadow_material.tres`
- `custodian/game/world/events/ash_bell/materials/room_edge_rim_material.tres`
- `custodian/game/world/events/ash_bell/materials/temporal_overlap_haze_material.tres`
- `custodian/content/masks/forlorn_ritualant/room_silhouette_mask.png`

Layering contract:

1. `ForlornRitualantShaderFX` is instanced under `forlorn_ritualant_site.tscn` before floor, rubble, walls, NPCs, interactables, and VFX.
2. `CosmicUnderlay` uses the void-ocean shader on the cosmic background texture for slow, subtle drift/dimming.
3. `EdgeFX/RoomShadowMaskSprite2D` and `EdgeFX/RoomRimGlowMaskSprite2D` use the same room silhouette mask with different `ShaderMaterial` parameters to separate the room edge from the void.
4. `TemporalFX/TemporalHazeRect` is a world-space `ColorRect` using additive haze; it stays below UI and avoids carrying gameplay state.
5. The FX scene contains no collision, navigation, interactables, physics, or deterministic simulation logic.

Mask contract:

- Path: `custodian/content/masks/forlorn_ritualant/room_silhouette_mask.png`
- Dimensions: `1120x864`, aligned to the current perimeter rubble art.
- Alpha is opaque where the current room silhouette exists and transparent outside.
- The mask is presentation-only. Do not encode gameplay collision into it.

The current mask was derived from the existing alpha-bearing perimeter rubble art. If production room art changes, regenerate or replace this mask from the new transparent-edged chamber silhouette so the edge shadow/rim remains aligned.

Intensity control:

`ForlornRitualantShaderFX` exposes `encounter_intensity` and `set_encounter_intensity(value)` to tune shader parameters through exported `ShaderMaterial` references. This is intended for later state-driven presentation changes only; it must not become encounter logic authority.
