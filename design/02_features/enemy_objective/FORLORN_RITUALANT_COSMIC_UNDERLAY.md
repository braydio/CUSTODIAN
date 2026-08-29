# Forlorn Ritualant Cosmic Underlay

Status: implemented first pass — 2026-06-24

The Forlorn Ritualant room uses a world-space cosmic underlay to make the broken Ash-Bell chamber read as a cave-room suspended over the Unnarrival void. This is presentation-only scene layering, not gameplay authority.

Runtime files:

- `custodian/scenes/environment/cosmic_underlay.tscn`
- `custodian/scripts/environment/cosmic_underlay.gd`
- `custodian/scenes/environment/forlorn_ritualant_shader_fx.tscn`
- `custodian/scripts/environment/forlorn_ritualant_shader_fx.gd`
- `custodian/content/backgrounds/forlorn_ritualant/cosmic-underlay.png`
- `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn`

Layering contract:

1. `VoidUnderlay/RoomSizedQuad` is a stationary `1280x960` presentation quad below the authored room geometry.
2. The chamber floor, rubble, walls, props, NPC, interactables, collision, and VFX remain above it.
3. The underlay has no collision, navigation, interactables, or simulation authority.
4. Player movement remains confined to the room's existing collision.
5. `room_silhouette_mask.png` is the explicit underlay clipping input; floor and rubble alpha are not underlay authority.

The room mask, edge-shadow mask, and edge-rim mask share the same stationary `1280x960` alignment. This mask is presentation-only and must never generate collision. If intentional internal void apertures are later authored, use a dedicated reviewed reveal mask rather than incidental holes in floor art.

Cosmic motion occurs only through shader UV drift inside that fixed mask. The Ritualant room no longer moves its underlay node in world space. The generic reusable `CosmicUnderlay` remains available to unrelated scenes.

Shader polish for the same layer is tracked in `design/02_features/enemy_objective/FORLORN_RITUALANT_SHADER_FX.md`.
