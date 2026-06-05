# New Operator Runtime Modules

This folder is the stable runtime home for modular operator parts generated from:

`res://content/sprites/operator/new_operator/modular/`

Runtime scenes and `SpriteFrames` resources should reference this folder, not the modular source folders. Rebuild the generated module sheets with:

```sh
python3 custodian/tools/pipelines/build_operator_modular_runtime.py
```

## Layout

```text
lower_body/
  locomotion/
    idle_01/
    walk_01/
    run_01/
upper_body/
  locomotion/
    idle_01/
    walk_01/
    run_01/
  actions/
    unarmed/
      fast_attack/
        fast_strike_01/
```

The operator scene has optional `ModularLowerBodySprite` and `ModularUpperBodySprite` layers. The lower-body layer owns movement presentation (`idle_01`, `walk_01`, `run_01`). The upper-body layer normally follows locomotion, but can switch to directional action clips independently; unarmed fast strike currently uses `upper_body/actions/unarmed/fast_attack/fast_strike_01/`.

The legacy body `AnimatedSprite2D` remains the timing/source-of-truth sprite for attack state, hit windows, portal arrival, ranged states, and any non-modular fallback state. During the first modular fast-strike pass it is hidden visually while still driving the attack timeline.

## Fallback Policy

- `run_01` prefers `modular_lower_body run_01`.
- `walk_01` prefers `modular_lower_body walk_01`, then falls back to `action_01`, then `run_01`.
- `idle_01` prefers authored idle where available, then falls back to `action_01`, then `run_01`.
- Upper-body locomotion prefers matching authored upper sheets, then falls back through `action_01` and available upper `run_01` by direction or nearest direction.
- Upper-body unarmed fast strike uses authored `modular_upper_body fast_strike_01` sheets for all 8 directions and resolves direction from attack aim, not lower-body movement.

Missing true source sheets are tracked in `REQUIRED_ASSETS.md`.
