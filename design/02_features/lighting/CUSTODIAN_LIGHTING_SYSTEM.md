# CUSTODIAN Lighting System V1

## Status

Implemented as a Godot-native presentation layer under `res://game/world/lighting/`.

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

## Usage

`LightingProfile` stores ambient, directional, cosmic-underlay, fog, and transition settings.

`WorldLightingDirector` owns scene references to `CanvasModulate` and `DirectionalLight2D`, applies profiles with
tweens, tracks zone-priority profile pushes, and exposes temporary ambient flashes.

`LightingZone2D` is an `Area2D` that applies a profile when the Operator/player enters and restores the previous or
default profile on exit. The exported priority field is named `profile_priority` because `Area2D` already owns a native
`priority` property.

`LightRig2D` is for persistent authored lights such as terminals, beacons, lamps, droid eyes, cave anomalies, and
Ash-Bell fissures.

`TransientLightPool` is for cheap additive sprite flashes such as muzzle flashes, impact sparks, parry flashes, boot
pulses, and small explosions. It intentionally avoids spawning `PointLight2D` for every bullet.

## Validation

```bash
cd custodian
godot --headless --script res://tools/validation/lighting_system_smoke.gd
```

The playground scene is `res://tools/validation/lighting_playground.tscn`. It includes a `CanvasModulate`,
`DirectionalLight2D`, three `LightRig2D` examples, a `LightingZone2D`, a simple `LightOccluder2D` wall, and debug
profile/flash controls.

## Deferred

- Wiring the director into `scenes/game.tscn`.
- Level-authored profiles for Return Causeway, Sundered Keep, Ash-Bell, Forlorn-Ritualant, shoreline storms, and
  constructed interiors.
- Selective normal/specular map production for hero assets and major machinery.
- Custom shaders for cosmic underlay refraction, temporal distortion, fog bands, and fake height-map shadows.
