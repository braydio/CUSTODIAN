# Enemy Animation Input Pipeline

Status: draft
Owner: gameplay/animation
Last updated: 2026-05-07

## Purpose

Give enemies the same practical animation intake path as the operator: source art lands in the shared sprite pipeline inbox, manifests normalize or copy the concrete runtime sheets, and a post-process step makes Godot imports ready for runtime use.

## Current State

- Generic ingest already writes to `res://content/sprites/enemies/...`.
- Operator has a dedicated `operator_curated_resources` post-process that rebuilds SpriteFrames resources.
- Enemies are mixed:
  - Shrumbs build `SpriteFrames` dynamically from explicit slink/knockout sheet paths on `Enemy`.
  - Wolves build `SpriteFrames` dynamically in `game/enemies/procgen/wolf_animation_library.gd`.
  - There is no enemy-wide SpriteFrames rebuild step yet.

## Intake Contract

Use the shared inbox:

```text
custodian/content/sprites/_pipeline/inbox/
```

Use the canonical naming shape:

```text
enemy_<id>__body__<action_group>__<variant>__<direction_or_set>__<frames>f__<frame_size>.png
```

Examples:

```text
enemy_wolf__body__locomotion__run__4dir__32f__64.png
enemy_wolf__body__combat__bite__4dir__24f__64.png
enemy_shrumb__body__locomotion__slink__e__8f__64x83.png
enemy_shrumb__body__death__knockout__omni__8f__64x85.png
```

For current wolf sheets, keep the compatibility outputs used by `wolf_animation_library.gd`:

```text
content/sprites/enemies/wolf/wolf-idle.png
content/sprites/enemies/wolf/wolf-run.png
content/sprites/enemies/wolf/wolf-bite.png
content/sprites/enemies/wolf/wolf-death.png
content/sprites/enemies/wolf/wolf-howl.png
```

## Post Process

Enemy manifests can use:

```json
"post_process": ["enemy_runtime_import"]
```

This runs Godot's headless import pass so newly written enemy PNGs are import-ready before the next runtime boot.

## Direction Rules

Preferred enemy runtime directions:

- `e`/`w` can use one side row plus horizontal flip when authored that way.
- `n` and `s` should use real rows when present.
- `omni` is for non-directional effects or deaths.
- For 4-row wolf sheets, current row interpretation is `south`, `west`, `east`, `north`.

## Next Implementation Slice

The next step is an enemy-specific baker/rebuild script:

```text
custodian/tools/pipelines/update_enemy_animation_resources.gd
```

Responsibilities:

1. Read enemy animation manifests from `content/sprites/enemies/<enemy_id>/generated/`.
2. Build or refresh enemy `SpriteFrames` resources.
3. Validate required clips per enemy archetype.
4. Report missing directions, frame-count mismatches, and unsupported naming.

Until that exists, enemies can still use the pipeline by writing the runtime PNGs that their current dynamic loaders already read.
