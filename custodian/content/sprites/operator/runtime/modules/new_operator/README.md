# New Operator Runtime Modules

This folder is the stable runtime home for modular operator parts generated from:

`res://content/sprites/operator/new_operator/modular/`

Runtime scenes and `SpriteFrames` resources should reference this folder, not the modular source folders. Rebuild the generated module sheets with:

```sh
python3 custodian/tools/pipelines/build_operator_modular_runtime.py
godot --headless --path custodian --script res://tools/pipelines/update_operator_curated_resources.gd
```

Modular Operator PNGs can also be dropped into the shared sprite inbox when they use canonical names such as:

```text
operator__modular_upper_body__unarmed__idle_01__s__5f__96.png
operator__modular_lower_body__unarmed__walk_01__e__5f__96.png
```

Then run:

```sh
python3 custodian/tools/pipelines/generate_inbox_manifests.py
```

Generated manifests route `operator__modular_*` files into `res://content/sprites/operator/new_operator/modular/` and run `operator_modular_runtime`, which rebuilds this runtime module folder and refreshes the live `operator_modular_lower_body_frames.tres` / `operator_modular_upper_body_frames.tres` resources.

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

The operator scene has optional `ModularLowerBodySprite` and `ModularUpperBodySprite` layers. The lower-body layer owns movement presentation (`idle_01`, `walk_01`, `run_01`) and resolves direction from movement. The upper-body layer owns action/aim presentation and resolves direction from aim/action state, so the lower body can walk north while the upper body faces south. Unarmed fast strike currently uses `upper_body/actions/unarmed/fast_attack/fast_strike_01/`.

The legacy body `AnimatedSprite2D` remains the timing/source-of-truth sprite for attack state, hit windows, portal arrival, ranged states, and any non-modular fallback state. It is hidden visually when modular layers cover the current unarmed locomotion state, including Fists idle.

## Fallback Policy

- `run_01` prefers `modular_lower_body run_01`.
- `walk_01` prefers `modular_lower_body walk_01`, then falls back to `action_01`, then `run_01`.
- `idle_01` prefers authored idle where available, then falls back to `action_01`, then `run_01`.
- Upper-body locomotion prefers matching authored upper sheets, then falls back through `action_01` and available upper `run_01` by direction or nearest direction.
- Upper-body unarmed fast strike uses authored `modular_upper_body fast_strike_01` sheets for all 8 directions and resolves direction from attack aim, not lower-body movement.

Missing true source sheets are tracked in `REQUIRED_ASSETS.md`.
