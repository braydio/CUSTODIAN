# Forlorn Ritualant Cosmic Underlay

Status: implemented first pass — 2026-06-24

The Forlorn Ritualant room uses a world-space cosmic underlay to make the broken Ash-Bell chamber read as a cave-room suspended over the Unarrival void. This is presentation-only scene layering, not gameplay authority.

Runtime files:

- `custodian/scenes/environment/cosmic_underlay.tscn`
- `custodian/scripts/environment/cosmic_underlay.gd`
- `custodian/scenes/environment/forlorn_ritualant_shader_fx.tscn`
- `custodian/scripts/environment/forlorn_ritualant_shader_fx.gd`
- `custodian/content/backgrounds/forlorn_ritualant/cosmic-underlay.png`
- `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn`

Layering contract:

1. `CosmicUnderlay` sits below the authored room geometry in world space.
2. The chamber floor, rubble, walls, props, NPC, interactables, collision, and VFX remain above it.
3. The underlay has no collision, navigation, interactables, or simulation authority.
4. Player movement remains confined to the room's existing collision.
5. Room art should keep transparent/irregular outer edges so the underlay is visible around the broken perimeter and through any future gaps.

The current floor and perimeter rubble PNGs already carry alpha, so the underlay can render through transparent negative space. If later room art is replaced by a flattened opaque image, split that art back into a transparent-edged chamber layer plus the separate cosmic underlay rather than masking the issue in code.

The reusable `CosmicUnderlay` script exposes subtle drift and pulse controls. Keep values slow and low-amplitude; the effect should feel like abyssal pressure under the room, not arcade parallax.

Shader polish for the same layer is tracked in `design/02_features/FORLORN_RITUALANT_SHADER_FX.md`.
