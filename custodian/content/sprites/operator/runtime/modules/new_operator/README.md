# New Operator Runtime Modules

This folder is the stable runtime home for modular operator parts generated from:

`res://content/sprites/operator/new_operator/modular/`

Runtime scenes and `SpriteFrames` resources should reference this folder, not the modular source folders. Rebuild the generated module sheets with:

```sh
python3 custodian/tools/pipelines/build_operator_modular_runtime.py --dry-run --remove-superseded
python3 custodian/tools/pipelines/build_operator_modular_runtime.py --remove-superseded
godot --headless --path custodian --import --quit
godot --headless --path custodian --script res://tools/pipelines/update_operator_curated_resources.gd
```

Use this direct builder workflow when the source PNGs already live under
`res://content/sprites/operator/new_operator/modular/`. The shared inbox is for new external exports that still
need routing into that source tree.

Modular Operator PNGs can also be dropped into the shared sprite inbox when they use canonical names such as:

```text
operator__modular_upper_body__unarmed__idle_01__s__5f__96.png
operator__modular_lower_body__unarmed__walk_01__e__5f__96.png
operator__modular_upper_body__sidearm__draw_sidearm_01__se__5f__96.png
operator__modular_lower_body__sidearm__draw_sidearm_01__se__5f__96.png
operator__modular_sidearm__sidearm__draw_sidearm_01__se__5f__96.png
operator__modular_lower_body__unarmed__block_loop_01__e__5f__96.png
operator__modular_upper_body__unarmed__enter_block_01__e__4f__96.png
operator__modular_wardrobe_cape__unarmed__block_loop_01__e__5f__96.png
```

Then run:

```sh
python3 custodian/tools/pipelines/generate_inbox_manifests.py
```

Generated manifests route `operator__modular_*` files into `res://content/sprites/operator/new_operator/modular/` and run `operator_modular_runtime`, which rebuilds this runtime module folder and refreshes the live `operator_modular_lower_body_frames.tres` / `operator_modular_upper_body_frames.tres` resources. `modular_sidearm` is the canonical weapon-layer token for sidearm actions.

The preferred source contract is
`operator__<modular_layer>__<loadout>__<action>__<direction>__<frames>f__<frame_size>.png`.
Generic actions outside the purpose-built locomotion, fast-attack, sidearm, dodge, and ranged-stance builders
are normalized into `<layer>/actions/<loadout>/<action>/`. This makes new art stable and discoverable without
silently wiring an unsupported gameplay state.

The builder also normalizes supplied two-handed ranged stance layers into
`{lower_body,upper_body,ranged_weapon}/actions/ranged_2h/stance_01/`. Current live coverage is E/N/W for idle
ranged-ready; missing south/diagonal and movement/fire/reload layers continue through legacy presentation.

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
        fast_windup_01/
        fast_strike_01/
        fast_recovery_01/
    sidearm/
      draw_sidearm_01/
      fire_sidearm_01/
sidearm/
  actions/
    draw_sidearm_01/
    fire_sidearm_01/
upper_fx/
  actions/
    sidearm/
      fx_01/
wardrobe_cape/
  actions/
    <loadout>/
      <action>/
```

The operator scene has optional `ModularLowerBodySprite` and `ModularUpperBodySprite` layers. The lower-body layer owns movement presentation (`idle_01`, `walk_01`, `run_01`) and resolves direction from movement. The upper-body layer owns action/aim presentation and resolves direction from aim/action state, so the lower body can walk north while the upper body faces south. Unarmed fast attack uses modular lower/upper body sheets for windup, strike, and recovery when the requested phase/direction has both body layers. Strike also uses `upper_fx/actions/unarmed/fast_attack/fast_strike_01/` when present.

Unarmed block is live on the lower/upper modular stack. `enter_block_01` drives block entry,
`block_loop_01` drives hold, `blocking_hitreact_01` plays when a hit is blocked, and block exit replays entry
backwards. All three actions have authored E/W coverage. Curated block registration discovers each generated
sheet's current frame count instead of hardcoding it, so replacement sheets built with `--remove-superseded`
remain valid. `parry_01` now drives the live tap-parry pose through the lower/upper modular stack, with
`upper_fx/actions/unarmed/parry_01/` playing the paired parry FX.

The legacy body `AnimatedSprite2D` remains the timing/source-of-truth sprite for attack state, hit windows, portal arrival, ranged states, and any non-modular fallback state. It is hidden visually when modular layers cover the current unarmed locomotion state, including Fists idle.

## Fallback Policy

- `run_01` prefers `modular_lower_body run_01`.
- `walk_01` prefers `modular_lower_body walk_01`, then falls back to `action_01`, then `run_01`.
- `idle_01` prefers authored idle where available, then falls back to `action_01`, then `run_01`.
- Upper-body locomotion prefers matching authored upper sheets, then falls back through `action_01` and available upper `run_01` by direction or nearest direction.
- Unarmed fast attack body phases prefer authored lower/upper modular `fast_windup_01`, `fast_strike_01`, and `fast_recovery_01` sheets per direction. Missing body coverage falls back to the previous legacy path for that phase/direction; missing strike FX does not block modular body playback.

Missing true source sheets are tracked in `REQUIRED_ASSETS.md`.

The builder normalizes sidearm source strips to `96px` runtime frames. Shared-inbox files must still declare their true source frame size in the filename; for example, a `640x128` five-frame source should end in `__5f__128.png`. Sidearm FX should use the canonical `modular_upper_fx` layer token. Existing source files named `modular_upper_body__sidearm__fx_*` are accepted as compatibility input and emitted as `modular_upper_fx` runtime modules.
