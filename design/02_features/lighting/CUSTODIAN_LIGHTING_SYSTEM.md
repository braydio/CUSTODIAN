# CUSTODIAN Lighting System V1

## Status

Implemented as a Godot-native presentation layer under `res://game/world/lighting/`.

The live-game atmosphere and foliage-motion consumer is specified by `design/02_features/visuals/WORLD_ATMOSPHERE_SHADER_SYSTEM.md`. The director is no longer playground-only: `res://scenes/game.tscn` instantiates its default exterior profile, native lighting nodes, and the fullscreen world-atmosphere pass below UI.

## Direction

CUSTODIAN does not use a third-party lighting plugin or custom renderer for V1. The runtime uses Godot native 2D
lighting primitives as the rendering backend:

- `CanvasModulate` for ambient mood.
- `DirectionalLight2D` for broad world direction.
- `PointLight2D` inside reusable authored rigs for persistent local lights.
- `LightOccluder2D` on major geometry only.
- Additive `Sprite2D` flashes for short-lived combat/readability effects.

The project-specific layer is a lighting direction system, not a replacement lighting engine.

## Runtime Files

- `custodian/game/world/lighting/lighting_profile.gd`
- `custodian/game/world/lighting/world_lighting_director.gd`
- `custodian/game/world/lighting/lighting_zone_2d.gd`
- `custodian/game/world/lighting/light_rig_2d.gd`
- `custodian/game/world/lighting/light_rig_2d.tscn`
- `custodian/game/world/lighting/transient_light_pool.gd`
- `custodian/game/world/lighting/world_atmosphere_2d.gd`
- `custodian/game/world/lighting/world_atmosphere_2d.tscn`
- `custodian/game/world/lighting/shaders/world_atmosphere.gdshader`
- `custodian/content/lighting/profiles/sundered_keep_exterior.tres`

## Usage

`LightingProfile` stores ambient, directional, cosmic-underlay, fog, and transition settings.

`WorldLightingDirector` owns scene references to `CanvasModulate` and `DirectionalLight2D`, applies profiles with
tweens, tracks zone-priority profile pushes, and exposes temporary ambient flashes.

`LightingZone2D` is an `Area2D` that applies a profile when the Operator/player enters and restores the previous or
default profile on exit. The exported priority field is named `profile_priority` because `Area2D` already owns a native
`priority` property.

`LightRig2D` is for persistent authored lights such as terminals, beacons, lamps, droid eyes, cave anomalies, and
Ash-Bell fissures. It accepts independent authored light/glow textures, shadow enablement, light height, and
asymmetric light/glow scaling. The generated 64×64 radial remains a fallback only.

Localized contrast is the governing visual rule: darker intervals should separate a small number of authored light
pools. Major geometry such as trunks, pillars, walls, gate edges, machinery, cliff lips, and bridge buttresses may
cast hard pixel-art shadows; tiny props and floor tiles should not. Dense authored scenes should normally expose
roughly 8–20 meaningful occluders rather than hundreds of tile-level casters.

Authored light cookies live under `custodian/content/sprites/world/lighting/`:

- `light_cookie_radial_soft_128.png`
- `light_cookie_radial_broken_128.png`
- `light_cookie_window_slash_192x128.png`
- `light_cookie_grate_128.png`
- `light_cookie_beam_96x192.png`
- `light_cookie_ring_192.png`

Painted multiply-blended contact/cast shadows live under `custodian/content/sprites/world/shadows/`. The Operator and
grunt use the character contact texture through `blob_shadow.gd`; the gatehouse test uses small/large prop shadows.

The authored profile set now includes exterior, shadowed courtyard, gatehouse interior, Return Causeway moonlight,
Ash-Bell ember-dark, and Severance anomaly roles under `custodian/content/lighting/profiles/`. These resources are
available to `LightingZone2D`; they do not globally brighten the world.

`TransientLightPool` is for cheap additive sprite flashes such as muzzle flashes, impact sparks, parry flashes, boot
pulses, and small explosions. It intentionally avoids spawning `PointLight2D` for every bullet.

## Validation

```bash
cd custodian
godot --headless --script res://tools/validation/lighting_system_smoke.gd
godot --headless --path . --script res://tools/validation/world_atmosphere_smoke.gd
```

The playground scene is `res://tools/validation/lighting_playground.tscn`. It includes a `CanvasModulate`,
`DirectionalLight2D`, three `LightRig2D` examples, a `LightingZone2D`, a simple `LightOccluder2D` wall, and debug
profile/flash controls. `res://tools/validation/gatehouse_lighting_test.tscn` is the localized-contrast reference room:
one cold window slash, two warm braziers, three pillar occluders, one gate occluder, prop contact shadows, a dark zone,
an eight-frame dust shaft, and a bright far objective. The lighting smoke validates both test scenes. The
world-atmosphere smoke separately validates the live `game.tscn` director/profile/pass,
UI layering, runtime profile propagation, combined foliage wind/occlusion material, and representative persistent
terminal and power-node lights.

## Deferred

- Placement/tuning of the new profile resources in additional production level zones beyond the gatehouse reference room.
- Selective normal/specular map production for hero assets and major machinery.
- Custom shaders for cosmic underlay refraction, temporal distortion, fog bands, and fake height-map shadows.
