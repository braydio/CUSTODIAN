# Sprite Intake Pipeline

This directory is the intake area for sprite pipeline work. Godot runtime scenes do **not**
read from here directly.

## Layout

```text
content/sprites/_pipeline/
  aseprite/    # Drop raw Aseprite PNG exports here before normalization
  inbox/       # Drop PNG + sidecar JSON manifest pairs here
  requests/    # Generated production checklists/contracts for future art batches
  normalized/  # Debug previews of the parsed source frames
  logs/        # Last ingest result per manifest
  archive/     # Processed source PNG/JSON pairs
```

## Contract

- Every ingest job is a `PNG` plus a sidecar `JSON` manifest with the same basename.
- Output paths are always relative to `res://content/sprites/`.
- New sprite sheets should use `<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png`.
- The pipeline writes into the **live** runtime domains already used by the project. Enemy actors use the domain-owned canonical shape `enemies/<actor>/runtime/<layer>/<action_group>/`; allied actors retain the owner-first shape `<actor>/runtime/<layer>/<action_group>/` with domain-prefixed allied paths emitted for compatibility:
  - `operator/...`
  - `weapons/...`
  - `enemies/...`
  - `effects/...`
  - `vehicles/...`
  - `turrets/...`
  - `environment/props/...`
  - `props/harvesting_nodes/...`
  - `items/...`
- Use explicit frame metadata per manifest. Do not assume one global sheet layout.
- Preserve source pixels by default. Resize only when the manifest explicitly requests it.

Direction codes are fixed: `n`, `ne`, `e`, `se`, `s`, `sw`, `w`, `nw`, and `omni` for non-directional effects.
Compatibility copies to older runtime paths are allowed, but the source/intake asset should keep the canonical name.

Ingest mirrors horizontal direction pairs by default: `e↔w`, `ne↔nw`, and `se↔sw`. Each selected frame is
flipped independently and written beside the source direction for every canonical output path, including
compatibility outputs. If any selected manifest explicitly supplies the counterpart, authored art wins even when
the pair is split across separate manifests. Use
`--no-mirror` for a selected run or set `"auto_mirror": false` at the manifest root for an asset-specific opt-out.
`n`, `s`, and `omni` are never duplicated.

Operator composited combat reactions may use the authored `full_body_combat` and `combat_fx` layer names. The manifest generator routes those sheets into `operator/runtime/body/<loadout>/` and `operator/runtime/overlays/<loadout>/`, then rebuilds the curated Operator `SpriteFrames` resources.

## Example Manifest

```json
{
  "source": "drone__body__locomotion__idle__s__4f__96.png",
  "mode": "strip",
  "frame_size": [96, 96],
  "outputs": [
    {
      "path": "enemies/drone/runtime/body/locomotion/drone__body__locomotion__idle__s__4f__96.png",
      "layout": "horizontal_strip",
      "select": { "type": "range", "start": 0, "count": 4 }
    },
    {
      "path": "enemies/drone/runtime/body/drone__body__locomotion__idle__s__4f__96.png",
      "layout": "horizontal_strip",
      "select": { "type": "range", "start": 0, "count": 4 }
    },
    {
      "path": "enemies/drone/runtime/idle/drone_idle.png",
      "layout": "horizontal_strip",
      "select": { "type": "range", "start": 0, "count": 4 }
    }
  ]
}
```

## Operator Example

Operator curated body updates can trigger the runtime `SpriteFrames` rebuild automatically:

```json
{
  "source": "operator__body__melee__fast_01__n__6f__96.png",
  "mode": "strip",
  "frame_size": [96, 96],
  "outputs": [
    {
      "path": "operator/runtime/body/melee/operator__body__melee__fast_01__n__6f__96.png",
      "layout": "horizontal_strip",
      "select": { "type": "range", "start": 0, "count": 6 }
    },
    {
      "path": "operator/runtime/animation_base/body/melee/fast_attack_north_base_body.png",
      "layout": "horizontal_strip",
      "select": { "type": "range", "start": 0, "count": 6 }
    }
  ],
  "post_process": ["operator_curated_resources"]
}
```

Modular Operator layer sheets use this canonical specialization:

```text
operator__<modular_layer>__<loadout>__<action>__<direction>__<frames>f__<frame_size>.png
```

Supported modular layers include `modular_lower_body`, `modular_upper_body`, `modular_upper_fx`,
`modular_wardrobe_cape`, `modular_combined_body`, and `modular_sidearm`. Use loadouts such as
`unarmed`, `sidearm`, or `ranged_2h`; keep the action in the next token.

```text
operator__modular_lower_body__unarmed__block_loop_01__e__5f__96.png
operator__modular_upper_body__unarmed__enter_block_01__e__4f__96.png
operator__modular_wardrobe_cape__unarmed__block_loop_01__e__5f__96.png
operator__modular_upper_body__ranged_2h__stance_01__w__5f__96.png
```

The manifest generator routes modular sheets into action-family buckets below
`operator/new_operator/modular/` and runs `operator_modular_runtime`. The builder creates stable,
96px-canvas runtime modules below `operator/runtime/modules/new_operator/<layer>/actions/<loadout>/<action>/`.
Explicit loadout/action names are preferred when both they and a legacy short name exist. Legacy short names
and the earlier ranged token ordering remain compatibility inputs.

Ingest and runtime-module generation do not automatically grant a new gameplay animation state. Live playback
must still be registered deliberately in the Operator state machine and curated `SpriteFrames`.

When modular source PNGs already live under `operator/new_operator/modular/`, do not move them back through the
inbox. Build and refresh them directly:

```bash
python custodian/tools/pipelines/build_operator_modular_runtime.py --dry-run --remove-superseded
python custodian/tools/pipelines/build_operator_modular_runtime.py --remove-superseded
godot --headless --path custodian --import --quit
godot --headless --path custodian --script res://tools/pipelines/update_operator_curated_resources.gd
```

Use the contract report to inspect modular production coverage without modifying art:

```bash
python custodian/tools/validation/operator_animation_contract_report.py
python custodian/tools/validation/operator_animation_contract_report.py --strict
```

Use the action preview tool to composite generated runtime modules or action-runtime strips into review images
under `custodian/animation_review/`:

```bash
python custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --action block_loop_01 --directions e,w --include-fx
python custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --sequence fast_windup_01,fast_strike_01,fast_recovery_01 --include-fx
```

Those preview images are QA artifacts only; they are not gameplay resources and should not be referenced by
runtime scenes.

Plan a new character art batch without generating placeholder PNGs:

```bash
python custodian/tools/pipelines/scaffold_character_contract.py --owner enemy_ritualist --template humanoid_combat --frame-size 96 --directions s,se,e,ne,n,nw,w,sw
```

This writes checklist, suggested contract, and expected filename files under
`content/sprites/_pipeline/requests/<owner>/`.

Dodge body drops can be full-body or modular. Full-body dodge uses `operator__body__locomotion__dodge__n__4f__96.png` plus `operator__body__locomotion__dodge_recovery__n__4f__96.png`. The aim-back hop uses `operator__body__locomotion__dodge_backstep__s__4f__96.png` plus `operator__body__locomotion__dodge_backstep_recovery__s__4f__96.png`. Modular dodge source names that start with `dodge` route to `operator/new_operator/modular/dodge/`.

## Terminal Prop Example

Current and future terminal prop sheets should use the `command_terminal` / `fabricator_terminal` prefix convention and write into the prop-owned runtime body folder:

```json
{
  "source": "command_terminal__body__interaction__pickup__omni__4f__48.png",
  "mode": "strip",
  "frame_size": [48, 48],
  "outputs": [
    {
      "path": "environment/props/terminal/runtime/body/command_terminal__body__interaction__pickup__omni__4f__48.png",
      "layout": "horizontal_strip",
      "select": { "type": "range", "start": 0, "count": 4 }
    }
  ]
}
```

For a future distinct fabricator prop, keep the same structure and swap the basename:

```json
{
  "source": "fabricator_terminal__body__interaction__pickup__omni__4f__48.png",
  "mode": "strip",
  "frame_size": [48, 48],
  "outputs": [
    {
      "path": "environment/props/terminal/runtime/body/fabricator_terminal__body__interaction__pickup__omni__4f__48.png",
      "layout": "horizontal_strip",
      "select": { "type": "range", "start": 0, "count": 4 }
    }
  ]
}
```

## Enemy Example

Current enemy sheets can also use the shared intake path. For wolf directional sheets, keep a canonical source copy and write the compatibility path read by `wolf_animation_library.gd`:

```json
{
  "source": "enemy_wolf__body__locomotion__run__4dir__32f__64.png",
  "mode": "copy",
  "outputs": [
    {
      "path": "enemies/wolf/source/enemy_wolf__body__locomotion__run__4dir__32f__64.png",
      "layout": "copy"
    },
    {
      "path": "enemies/wolf/wolf-run.png",
      "layout": "copy"
    }
  ],
  "post_process": ["enemy_runtime_import"]
}
```

## Vehicle Example

Hover buggy sheets can be dropped into the inbox with canonical vehicle names. The generator writes them to `res://content/sprites/vehicles/hover_buggy/runtime/` and adds `post_process: ["vehicle_runtime_import"]`, which rebuilds `res://game/actors/vehicles/hover_buggy_idle_frames.tres`.

```text
hover_buggy__body__idle__omni__1f__256.png
hover_buggy__body__idle_start__omni__7f__256.png
hover_buggy__body__idle_loop__omni__6f__256.png
hover_buggy__body__move__e__6f__256.png
```

`VehicleBase` currently consumes the animation names `idle`, `idle_start`, `idle_loop`, and `move`, so those action names are the safest inbox targets for hover buggy replacements.

## Automation

Normalize Aseprite exports into the inbox, then optionally run manifest generation and ingest:

```bash
python custodian/tools/pipelines/aseprite_inbox.py --run-ingest
```

Useful flags:

```bash
python custodian/tools/pipelines/aseprite_inbox.py --dry-run
python custodian/tools/pipelines/aseprite_inbox.py --prompt
python custodian/tools/pipelines/aseprite_inbox.py --yes
python custodian/tools/pipelines/aseprite_inbox.py --run-ingest --skip-post
python custodian/tools/pipelines/aseprite_inbox.py --run-ingest --no-mirror
```

Generate missing inbox manifests with the Python generator, then run ingest:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py
```

Useful flags:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run
python custodian/tools/pipelines/generate_inbox_manifests.py --skip-post
python custodian/tools/pipelines/generate_inbox_manifests.py --regen
python custodian/tools/pipelines/generate_inbox_manifests.py --remove-superseded
python custodian/tools/pipelines/generate_inbox_manifests.py --no-mirror
```

Use `--remove-superseded` when a replacement changes frame count or frame size. It removes canonical sibling
PNGs in the exact destination directory that match the same owner/layer/action/variant/direction, plus their
`.import` sidecars. It also propagates through modular Operator runtime generation.

Preview removals first:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run --remove-superseded
```

Archive/history files, files in other directories, and distinct variants such as `heavy_02` and `alt` remain
untouched.

## Filename Rules

- For `items`, use a flat inbox filename of `items__<item_type>__<item_name>__<frames>f__<frame_size>.png`.
- The generator saves that to `res://content/sprites/items/<item_type>/<item_name>.png`.
- Item sheets are expected to be horizontal strips; the parser uses the filename to confirm frame count and frame size.
- Common item families include `resources`, `shrumb_drops`, and future consumable or lore pickup folders.
- For harvesting nodes, use a flat inbox filename of `props__harvesting_nodes__<node_type>__node__<state>__<frames>f__<frame_size>.png`.
- The generator saves those to `res://content/sprites/props/harvesting_nodes/<node_type>/<node_type>__node__<state>__<frames>f__<frame_size>.png`.
- Recommended layout: one directory per node type under `res://content/sprites/props/harvesting_nodes/`, with the node type repeated in the filename.
- For other domains, the filename should still follow the canonical `<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png` pattern when possible.

## Filename Examples

Flat item examples:

```text
items__resources__blackwood_node__6f__96.png
items__resources__structural_alloy_vein__6f__96.png
items__shrumb_drops__faint_recollection__4f__64.png
items__shrumb_drops__residual_instinct__4f__64.png
items__shrumb_drops__ancient_bearing__4f__64.png
```

Runtime paths they produce:

```text
res://content/sprites/items/resources/blackwood_node.png
res://content/sprites/items/resources/structural_alloy_vein.png
res://content/sprites/items/shrumb_drops/faint_recollection.png
res://content/sprites/items/shrumb_drops/residual_instinct.png
res://content/sprites/items/shrumb_drops/ancient_bearing.png
```

Non-item examples:

```text
operator__body__melee__fast_01__n__6f__96.png
enemy_wolf__body__locomotion__run__4dir__32f__64.png
drone__body__locomotion__idle__s__4f__96.png
allied_infantry_droid__body__locomotion__idle__e__5f__96.png
allied_infantry_droid__fx__ranged__muzzle_flash__e__5f__96.png
command_terminal__body__interaction__pickup__omni__4f__48.png
portal_ring__fx__interaction__activate__omni__12f__161.png
props__harvesting_nodes__blackwood_deadfall__node__idle__6f__96.png
hover_buggy__body__move__e__6f__256.png
```

Saved file examples by domain:

```text
content/sprites/weapons/fallen_star_katana/animations/fallen_star_katana__melee_1h__fast_weapon__n__6f__96.png
content/sprites/weapons/carbine_rifle/animations/carbine_rifle__ranged__stance__e__6f__96.png
content/sprites/drone/runtime/body/locomotion/drone__body__locomotion__idle__s__4f__96.png
content/sprites/allied_infantry_droid/runtime/body/locomotion/allied_infantry_droid__body__locomotion__idle__e__5f__96.png
content/sprites/allied_infantry_droid/runtime/fx/ranged/allied_infantry_droid__fx__ranged__muzzle_flash__e__5f__96.png
content/sprites/effects/runtime/hit_spark/hit_spark__fx__impact__default__omni__4f__64.png
content/sprites/vehicles/hover_buggy/runtime/hover_buggy__body__move__e__6f__256.png
content/sprites/turrets/gunner/turret-gunner-firing.png
content/sprites/environment/props/terminal/runtime/body/command_terminal__body__interaction__pickup__omni__4f__48.png
content/sprites/props/harvesting_nodes/blackwood_deadfall/blackwood_deadfall__node__idle__6f__96.png
content/sprites/items/resources/blackwood_node.png
content/sprites/items/shrumb_drops/faint_recollection.png
```

## Generic Actor SpriteFrames

Non-Operator animated actors use a simpler body/FX convention than the Operator modular runtime. Put body
silhouette and baked weapon poses in `body`; keep muzzle flashes, impact sparks, projectiles, shield hits, and
explosions in `fx`.

Allied actor inbox filenames use the same canonical naming pattern:

```text
<actor_slug>__body__<action_group>__<animation>__<direction>__<frames>f__<frame_size>.png
<actor_slug>__fx__<action_group>__<animation>__<direction>__<frames>f__<frame_size>.png
```

For example:

```text
allied_infantry_droid__body__locomotion__idle__e__5f__96.png
allied_infantry_droid__body__locomotion__run__w__6f__96.png
allied_infantry_droid__body__ranged__fire__e__5f__96.png
allied_infantry_droid__fx__ranged__muzzle_flash__e__5f__96.png
```

For quick iteration, allied actors also accept the simple compatibility form:

```text
allied_infantry_droid__idle__e__5f__96.png
allied_infantry_droid__fx_muzzle_flash__e__5f__96.png
```

The canonical form is preferred for production batches because it keeps layer and action-group intent explicit.

Successful ingest routes these canonically to:

```text
res://content/sprites/allied_infantry_droid/runtime/body/<action_group>/
res://content/sprites/allied_infantry_droid/runtime/fx/<action_group>/
```

Until existing allied consumers migrate, the same ingest also writes compatibility copies to `res://content/sprites/allies/allied_infantry_droid/runtime/body|fx/`. Enemy and drone sheets are canonical under `res://content/sprites/enemies/<actor>/`; ingest may also write flat files inside that same actor-owned tree for legacy enemy consumers, but never writes a loose `res://content/sprites/<enemy>/` tree.

Then it rebuilds:

```text
res://game/actors/allies/allied_infantry_droid/allied_infantry_droid_body_frames.tres
res://game/actors/allies/allied_infantry_droid/allied_infantry_droid_fx_frames.tres
```

Inside each `SpriteFrames` resource, animation names are `<animation>_<direction>`, such as `idle_e`,
`run_w`, `fire_e`, and `muzzle_flash_e`. Keep swappable equipment, upper/lower body separation, and curated
fallback state-machine work in the Operator-specific pipeline unless another actor truly needs that complexity.
