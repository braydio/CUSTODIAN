# Sprite Intake Pipeline

This directory is the intake area for sprite pipeline work. Godot runtime scenes do **not**
read from here directly.

## Layout

```text
content/sprites/_pipeline/
  aseprite/    # Drop raw Aseprite PNG exports here before normalization
  inbox/       # Drop PNG + sidecar JSON manifest pairs here
  normalized/  # Debug previews of the parsed source frames
  logs/        # Last ingest result per manifest
  archive/     # Processed source PNG/JSON pairs
```

## Contract

- Every ingest job is a `PNG` plus a sidecar `JSON` manifest with the same basename.
- Output paths are always relative to `res://content/sprites/`.
- New sprite sheets should use `<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png`.
- The pipeline writes into the **live** runtime domains already used by the project:
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

## Example Manifest

```json
{
  "source": "drone__body__locomotion__idle__s__4f__96.png",
  "mode": "strip",
  "frame_size": [96, 96],
  "outputs": [
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
```

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
command_terminal__body__interaction__pickup__omni__4f__48.png
portal_ring__fx__interaction__activate__omni__12f__161.png
props__harvesting_nodes__blackwood_deadfall__node__idle__6f__96.png
```

Saved file examples by domain:

```text
content/sprites/weapons/fallen_star_katana/animations/fallen_star_katana__melee_1h__fast_weapon__n__6f__96.png
content/sprites/weapons/carbine_rifle/animations/carbine_rifle__ranged__stance__e__6f__96.png
content/sprites/enemies/drone/runtime/idle/drone__body__locomotion__idle__s__4f__96.png
content/sprites/effects/runtime/hit_spark/hit_spark__fx__impact__default__omni__4f__64.png
content/sprites/vehicles/hover_buggy/runtime/hover_buggy__body__move__east__6f__96.png
content/sprites/turrets/gunner/turret-gunner-firing.png
content/sprites/environment/props/terminal/runtime/body/command_terminal__body__interaction__pickup__omni__4f__48.png
content/sprites/props/harvesting_nodes/blackwood_deadfall/blackwood_deadfall__node__idle__6f__96.png
content/sprites/items/resources/blackwood_node.png
content/sprites/items/shrumb_drops/faint_recollection.png
```
