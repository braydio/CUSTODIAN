# World Atmosphere Shader System

Status: implemented V1
Owner: world presentation / lighting
Runtime target: Godot 4.7 Forward Plus (`custodian/`)
Last updated: 2026-07-16

## Goal

Connect the existing native 2D lighting framework to the live game and add restrained environmental motion without weakening pixel-art or combat readability.

The V1 stack is:

1. one combined foliage-life material per generated foliage sprite;
2. one fullscreen, screen-reading world-atmosphere pass below player UI;
3. existing authored `LightRig2D` instances for selected local emitters.

Ground TileMaps remain visually stable. V1 does not add blur, chromatic aberration, scanlines, full-screen distortion, or animated floor vertices.

## Runtime Ownership

- `WorldLightingDirector` owns the active `LightingProfile`, profile blending, `CanvasModulate`, `DirectionalLight2D`, `fog_alpha`, and `cosmic_underlay_alpha`.
- `WorldAtmosphere2D` is a read-only presentation consumer. It samples the active camera and lighting director and writes their current values to its private `ShaderMaterial`.
- `ProcGenTilemap` owns foliage tuning exports and resolves planet-profile overrides before passing values into `ProcgenFoliageSpawner`.
- `ProcgenFoliageSpawner` creates the existing unique foliage material and assigns deterministic per-tile wind phase plus tree/shrub strength.
- Foliage collision, navigation blockers, and gameplay visibility remain unchanged. Wind is vertex-only presentation.
- Planet world-profile dictionaries may provide fog, cosmic, and foliage-motion values; they do not directly mutate shaders or lighting nodes.

## Scene And Layer Contract

Live `res://scenes/game.tscn` contains:

```text
GameRoot
├── World
│   ├── CanvasModulate
│   ├── DirectionalLight2D
│   ├── WorldLightingDirector
│   └── Camera2D
├── WorldAtmosphere2D       CanvasLayer 10
└── UI                      CanvasLayer 20
```

The atmosphere grades the world but never the HUD. Debug overlays may use their existing higher layer policy.

## Foliage-Life Contract

`res://game/world/procgen/foliage_life.gdshader` replaces the occlusion-only shader as the live material contract. It retains `bubble_enabled`, `bubble_count`, `bubble_center`, all eight indexed bubble centers, radius, softness, and alpha.

Wind bends from the top using `pow(1.0 - UV.y, top_flex_power)`, leaving the sprite bottom at zero displacement. Each tile receives a deterministic phase derived from the procgen tile hash. Trees and shrubs use separate conservative displacement strengths. The existing per-sprite material count and draw-layer count do not increase.

## Atmosphere Contract

`WorldAtmosphere2D` uses one unshaded fullscreen `ColorRect` with nearest-neighbor screen sampling. The shader provides:

- world-space procedural haze;
- mild profile-derived grade tint;
- restrained cosmic underlay highlights;
- soft vignette;
- screen-pixel-quantized light grain.

The controller continuously updates viewport size, camera screen center/zoom, and the director's blended fog/cosmic values. Camera movement changes world-space sampling rather than dragging fog in screen space.

Default exterior tuning:

```text
fog alpha:       0.10
cosmic alpha:    0.02
grade mix:       0.055
vignette:        0.10
grain:           0.008
tree wind:       0.90 local px
shrub wind:      0.45 local px
```

## Local Light Contract

Reuse `res://game/world/lighting/light_rig_2d.tscn` for authored terminals, portal rings, power relays, warning beacons, and anomalies. Most illumination remains static. Pulse is reserved for stateful or unusual emitters so motion retains meaning.

## Failure Policy

- Missing atmosphere material, camera, or lighting director reports through `DevObservatory` and leaves the pass inert rather than influencing gameplay.
- Missing optional planet-profile keys use conservative exported defaults.
- The UI layer must remain greater than the atmosphere layer.
- Shader or controller failures must fail the focused smoke; they must not fall back to per-tile materials.

## Validation

Automated:

```bash
cd custodian
env HOME=/tmp/custodian-godot-home godot --headless --path . --script res://tools/validation/world_atmosphere_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . --editor --quit
```

Manual acceptance:

- foliage bases and tree collision remain planted;
- all player/enemy visibility bubbles remain functional;
- haze remains world-stable during camera movement;
- world silhouettes remain readable in combat;
- UI is not graded;
- no floor seams or vertex motion appear;
- dense-foliage frame time remains stable.

## Next Agent Slice

- Add restrained `LightRig2D` instances only to authored emitters with clear state meaning.
- Profile atmosphere colors per authored level/planet after screenshot review; do not raise fog or grain simply to make the effect obvious.
