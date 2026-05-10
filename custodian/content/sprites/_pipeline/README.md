# Sprite Intake Pipeline

This directory is the intake area for sprite pipeline work. Godot runtime scenes do **not**
read from here directly.

## Layout

```text
content/sprites/_pipeline/
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
