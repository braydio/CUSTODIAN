# Vigil-Pattern Dagger

- **Status:** implemented-v1
- **Owner:** gameplay/weapons
- **Runtime target:** Godot 4 (`custodian/`)

## Role

The Vigil-Pattern Dagger is the default starting melee weapon and reference
implementation for profile-owned attack drive. It is independent from the
Sword-Cleaver and Fallen Star Katana.

## Current Fast Chain

| Link | Presentation | Drive | Stamina |
|---|---|---:|---:|
| Fast 01 | Shared 10-frame Chain 01 + dagger overlay | 7 px | 5 |
| Fast 02 | Dedicated 8-frame Chain 02 body, dagger, and FX | 9 px | 6 |
| Fast 03 | Provisional Chain 01 reuse | 11 px | 8 |

All links have distinct semantic animation names and attack profiles. Body,
dagger, and FX use separate synchronized 156×96 `SpriteFrames` resources at
18 FPS. Fast 02 is sourced from the authored modular lower-body, upper-body,
Vigil dagger, and upper-FX Chain 02 layers; the pipeline composites and binds
their E/W eight-frame runtime strips. Contact remains zero-based frame 5 and
commit remains frame 6.

The held weapon remains the native 24×24 dagger texture. Heavy remains disabled
through an empty `secondary_intent`.

## Runtime Files

```text
custodian/game/actors/operator/
├── vigil_pattern_dagger_definition.tres
├── vigil_pattern_dagger_frames.tres
├── vigil_pattern_dagger_body_frames.tres
├── vigil_pattern_dagger_melee_overlay_frames.tres
├── vigil_pattern_dagger_fx_frames.tres
└── attacks/vigil_pattern_dagger_fast_{01,02,03}.tres
```

Pipeline outputs are under:

```text
content/sprites/operator/runtime/body/melee_1h/shared/
content/sprites/operator/runtime/fx/melee_1h/shared/
content/sprites/operator/runtime/weapon/melee_1h/vigil_pattern_dagger/
```

## Acceptance

- `operator.tscn` assigns the dagger to its melee slot.
- Three fast links select independent profiles.
- Body, weapon, and FX remain frame-synchronized.
- Drive respects collision and interruption without target tracking or
  snapback.
- Heavy input cannot invoke missing content.
- Cleaver and Katana definitions remain independently loadable.

## Next Agent Slice

Goal: replace provisional Fast 03 reuse with dedicated authored sheets.

Constraints: preserve semantic keys/profiles and do not map Katana content onto
the dagger.

Acceptance: replacing the SpriteFrames entries requires no weapon-specific
branch in `operator.gd`.
