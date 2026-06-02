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
```

The current operator scene still renders one body `AnimatedSprite2D` plus overlays, so these lower-body module strips are used as the default Fists movement body clips through `operator_runtime_frames.tres`. A later layered rig can consume the same module folder directly.

## Fallback Policy

- `run_01` prefers `modular_lower_body run_01`.
- `walk_01` prefers `modular_lower_body walk_01`, then falls back to `action_01`, then `run_01`.
- `idle_01` prefers authored idle where available, then falls back to `action_01`, then `run_01`.

Missing true source sheets are tracked in `REQUIRED_ASSETS.md`.
